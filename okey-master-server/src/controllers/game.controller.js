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
    const { mode } = req.body;
    const user = await prisma.user.findUnique({ where: { firebaseUid: req.user.uid } });
    
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
    
    // 2. Süre kontrolü
    const durationSec = Math.floor((new Date() - existingGame.startedAt) / 1000);
    if (durationSec < MIN_GAME_DURATION_SEC || durationSec > MAX_GAME_DURATION_SEC) {
      return res.status(400).json({ error: 'Oyun süresi geçersiz.' });
    }

    // 3. Hash doğrulaması (Anti-Cheat)
    const playerScore = players[0]?.score || 0;
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
        data: { status: 'finished', winnerId, totalTurns, endedAt: new Date(), durationSeconds: durationSec },
      });

      for (const p of players) {
        await tx.gamePlayer.updateMany({
          where: { gameId: id, userId: p.userId },
          data: { score: p.score, tilesRemaining: p.tilesRemaining, isWinner: p.isWinner },
        });

        const stats = await tx.userStats.findUnique({ where: { userId: p.userId } });
        if(stats) {
            const newWinStreak = p.isWinner ? stats.winStreak + 1 : 0;
            await tx.userStats.update({
              where: { userId: p.userId },
              data: {
                totalGames: { increment: 1 },
                totalWins: { increment: p.isWinner ? 1 : 0 },
                totalLosses: { increment: p.isWinner ? 0 : 1 },
                winStreak: newWinStreak,
                bestWinStreak: Math.max(stats.bestWinStreak, newWinStreak),
              },
            });
        }
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
    const user = await prisma.user.findUnique({ where: { firebaseUid: req.user.uid } });
    const games = await prisma.gamePlayer.findMany({
      where: { userId: user.id },
      include: { game: true },
      orderBy: { game: { createdAt: 'desc' } },
      take: 20,
    });
    res.json(games);
  } catch(err) { next(err); }
}

module.exports = { createGame, finishGame, getHistory, createGameValidation, finishGameValidation };
