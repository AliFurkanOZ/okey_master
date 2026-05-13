const prisma = require('../utils/prisma');
const { body, param, validationResult } = require('express-validator');
const crypto = require('crypto');

const MIN_GAME_DURATION_SEC = 30;
const MAX_GAME_DURATION_SEC = 7200; // 2 saat
const MAX_REASONABLE_SCORE = 200;

const createGameValidation = [body('mode').isIn(['offline_easy', 'offline_medium', 'offline_hard'])];
const finishGameValidation = [param('id').isUUID()];

const createGame = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ error: 'Geçersiz veri', details: errors.array() });
    }
    const { mode } = req.body;
    const user = await prisma.user.findUnique({ where: { firebaseUid: req.user.uid } });
    if (!user) return res.status(404).json({ error: 'Kullanıcı bulunamadı' });

    // Zombi oyun temizliği (önceden playing kalanları abandoned yap)
    await prisma.game.updateMany({
      where: {
        status: 'playing',
        players: { some: { userId: user.id } },
      },
      data: { status: 'abandoned', endedAt: new Date() }
    });

    // Aktif oyun limiti
    const activeGamesCount = await prisma.game.count({
      where: {
        status: 'playing',
        players: { some: { userId: user.id } }
      }
    });
    if (activeGamesCount >= 3) {
      return res.status(400).json({ error: 'Çok fazla aktif oyununuz var' });
    }

    // serverSeed üret ve hash'ini (commitment) istemciye dön
    const serverSeed = crypto.randomBytes(32).toString('hex');
    const seedCommitment = crypto.createHash('sha256').update(serverSeed).digest('hex');

    const game = await prisma.game.create({
      data: {
        mode,
        serverSeed,
        startedAt: new Date(),
        players: { create: { userId: user.id } },
      },
      include: { players: true },
    });

    res.json({ ...game, seedCommitment, serverSeed: undefined });
  } catch (error) { next(error); }
};

const finishGame = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ error: 'Geçersiz veri', details: errors.array() });
    }
    const { id } = req.params;
    const { winnerId, players, totalTurns, gameHash, moveLog } = req.body;

    // 1. Idempotency Key kontrolü
    const idempotencyKey = req.headers['x-idempotency-key'];
    if (idempotencyKey) {
      const existing = await prisma.idempotencyKeys.findUnique({ where: { key: idempotencyKey } });
      if (existing) return res.json(existing.response);
    }

    const existingGame = await prisma.game.findUnique({ where: { id }, include: { players: true } });
    if (!existingGame || existingGame.status !== 'playing') {
      return res.status(400).json({ error: 'Oyun bitirilemez (status geçersiz)' });
    }

    const requestingUser = await prisma.user.findUnique({ where: { firebaseUid: req.user.uid } });
    if (!requestingUser) return res.status(404).json({ error: 'Kullanıcı bulunamadı' });

    // Kullanıcı oyunun oyuncusu mu?
    if (!existingGame.players.some(p => p.userId === requestingUser.id)) {
      return res.status(403).json({ error: 'Bu oyuna müdahale yetkiniz yok' });
    }

    // Offline oyuncu sayısı kontrolü
    if (existingGame.mode.startsWith('offline_') && players.length > 1) {
      return res.status(400).json({ error: 'Offline modda tek oyuncu sonucu gönderilebilir' });
    }

    // Frequency limit (saat/oyun)
    const gamesLastHour = await prisma.game.count({
      where: {
        players: { some: { userId: requestingUser.id } },
        endedAt: { gte: new Date(Date.now() - 3600 * 1000) }
      }
    });
    if (gamesLastHour > 30) {
      return res.status(429).json({ error: 'Saatlik oyun limitini aştınız' });
    }

    // Skor sınırı kontrolü
    const playerScore = players[0]?.score || 0;
    if (playerScore > MAX_REASONABLE_SCORE) {
      return res.status(400).json({ error: 'Gerçekçi olmayan skor' });
    }

    // 2. Süre kontrolü
    const durationSec = Math.floor((new Date() - existingGame.startedAt) / 1000);
    if (durationSec < MIN_GAME_DURATION_SEC || durationSec > MAX_GAME_DURATION_SEC) {
      return res.status(400).json({ error: 'Oyun süresi geçersiz.' });
    }

    // 3. Hash doğrulaması (Anti-Cheat)
    const expectedHash = crypto.createHash('sha256')
      .update(`${existingGame.serverSeed || ''}:${moveLog}:turns=${totalTurns}:score=${playerScore}`)
      .digest('hex');
    if (expectedHash !== gameHash) {
      return res.status(400).json({ error: 'Hash doğrulama başarısız. Hile şüphesi.' });
    }

    // Prisma Transaction ile atomik güncelleme
    const result = await prisma.$transaction(async (tx) => {
      const game = await tx.game.update({
        where: { id },
        data: { status: 'finished', winnerId: winnerId === 'ai' ? null : winnerId, totalTurns, endedAt: new Date(), durationSeconds: durationSec },
      });

      for (const p of players) {
        await tx.gamePlayer.updateMany({
          where: { gameId: id, userId: p.userId },
          data: { score: p.score, tilesRemaining: p.tilesRemaining, isWinner: p.isWinner },
        });

        const stats = await tx.userStats.upsert({
          where: { userId: p.userId },
          create: { userId: p.userId },
          update: {}
        });

        const isDraw = (winnerId === null || winnerId === undefined || winnerId === 'ai');

        const newWinStreak = p.isWinner === true
          ? stats.winStreak + 1
          : (isDraw ? stats.winStreak : 0);

        await tx.userStats.update({
          where: { userId: p.userId },
          data: {
            totalGames: { increment: 1 },
            totalWins: { increment: p.isWinner === true ? 1 : 0 },
            totalLosses: { increment: (p.isWinner !== true && !isDraw) ? 1 : 0 },
            winStreak: newWinStreak,
            bestWinStreak: Math.max(stats.bestWinStreak, newWinStreak),
            avgScore: stats.totalGames > 0 ? (stats.avgScore * stats.totalGames + p.score) / (stats.totalGames + 1) : p.score,
          },
        });
      }
      return game;
    }, { timeout: 15000 }); // Backend transaction timeout

    if (idempotencyKey) {
      await prisma.idempotencyKeys.create({ data: { key: idempotencyKey, response: result } });
    }

    res.json(result);
  } catch (error) { next(error); }
};

const getHistory = async (req, res, next) => {
  try {
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit) || 10));

    const user = await prisma.user.findUnique({ where: { firebaseUid: req.user.uid } });
    if (!user) return res.status(404).json({ error: 'Kullanıcı bulunamadı' });

    const games = await prisma.gamePlayer.findMany({
      where: { userId: user.id },
      include: { game: true },
      orderBy: { game: { createdAt: 'desc' } },
      skip: (page - 1) * limit,
      take: limit,
    });
    res.json(games);
  } catch (err) { next(err); }
};

const saveGameResult = async (req, res) => {
  try {
    const { isWin, duration, gameType } = req.body;
    const user = await prisma.user.findUnique({ where: { firebaseUid: req.user.uid }, include: { stats: true } });

    if (!user) return res.status(404).json({ error: "Kullanıcı bulunamadı" });

    let pointsToAdd = 0;
    if (gameType === "duel") pointsToAdd = isWin ? 50 : 20;

    let updateData = {
      totalGames: { increment: 1 },
      totalWins: { increment: isWin ? 1 : 0 },
      avgScore: { increment: pointsToAdd }
    };

    if (gameType.startsWith("memory") && isWin) {
      const fieldMap = { "memory_easy": "bestTimeEasy", "memory_medium": "bestTimeMedium", "memory_hard": "bestTimeHard" };
      const field = fieldMap[gameType];
      if (field) {
        const currentBest = user.stats ? user.stats[field] : 0;
        if (currentBest === 0 || duration < currentBest) updateData[field] = duration;
      }
    }

    await prisma.userStats.upsert({
      where: { userId: user.id },
      update: updateData,
      create: {
        userId: user.id,
        totalGames: 1,
        totalWins: isWin ? 1 : 0,
        avgScore: pointsToAdd,
        bestTimeEasy: gameType === "memory_easy" ? duration : 0,
        bestTimeMedium: gameType === "memory_medium" ? duration : 0,
        bestTimeHard: gameType === "memory_hard" ? duration : 0,
      }
    });
    res.json({ success: true });
  } catch (error) { res.status(500).json({ error: error.message }); }
};

module.exports = { createGame, finishGame, getHistory, createGameValidation, finishGameValidation, saveGameResult };