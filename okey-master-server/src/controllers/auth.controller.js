const prisma = require('../utils/prisma');
const { body, validationResult } = require('express-validator');

const registerValidation = [
  body('username').trim().isLength({ min: 2, max: 50 }).withMessage('Kullanıcı adı 2-50 karakter olmalı')
];

// src/controllers/auth.controller.js içindeki register fonksiyonu
const register = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ error: 'Geçersiz veri', details: errors.array() });

    const { username } = req.body;
    
    // BURASI ÇOK ÖNEMLİ: req.user.uid zorunlu kılındı (güvenlik yaması)
    const firebaseUid = req.user.uid;

    const user = await prisma.user.upsert({
      where: { firebaseUid },
      update: { lastLogin: new Date() },
      create: {
        firebaseUid,
        username: username || req.user.name || 'Oyuncu',
        email: req.user.email || null,
        avatarUrl: req.user.picture || null,
        stats: { create: {} },
      },
      include: { stats: true },
    });
    res.json(user);
  } catch (error) {
    next(error);
  }
};

const getProfile = async (req, res, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { firebaseUid: req.user.uid },
      include: { stats: true, achievements: { include: { achievement: true } } },
    });
    if (!user) return res.status(404).json({ error: 'Kullanıcı bulunamadı' });
    res.json(user);
  } catch (error) {
    next(error);
  }
};

const migrate = async (req, res, next) => {
  try {
    const { oldFirebaseUid } = req.body;
    const newFirebaseUid = req.user.uid;

    if (!oldFirebaseUid || oldFirebaseUid === newFirebaseUid) {
      return res.status(400).json({ error: 'Geçersiz eski hesap UID' });
    }

    const oldUser = await prisma.user.findUnique({ where: { firebaseUid: oldFirebaseUid }, include: { stats: true } });
    const newUser = await prisma.user.findUnique({ where: { firebaseUid: newFirebaseUid }, include: { stats: true } });

    if (!oldUser) return res.status(404).json({ error: 'Eski hesap bulunamadı' });
    if (!newUser) return res.status(404).json({ error: 'Yeni hesap bulunamadı' });

    // Transaction ile güvenli taşıma
    await prisma.$transaction(async (tx) => {
      await tx.gamePlayer.updateMany({
        where: { userId: oldUser.id },
        data: { userId: newUser.id }
      });

      await tx.game.updateMany({
        where: { winnerId: oldUser.id },
        data: { winnerId: newUser.id }
      });

      const oldAchievements = await tx.userAchievement.findMany({ where: { userId: oldUser.id } });
      for (const ach of oldAchievements) {
        try {
          await tx.userAchievement.update({
            where: { id: ach.id },
            data: { userId: newUser.id }
          });
        } catch(e) {
          await tx.userAchievement.delete({ where: { id: ach.id } });
        }
      }

      if (oldUser.stats && newUser.stats) {
         const newTotalGames = newUser.stats.totalGames + oldUser.stats.totalGames;
         const newAvgScore = newTotalGames > 0 
           ? ((newUser.stats.avgScore * newUser.stats.totalGames) + (oldUser.stats.avgScore * oldUser.stats.totalGames)) / newTotalGames
           : 0;

         await tx.userStats.update({
           where: { userId: newUser.id },
           data: {
             totalGames: newTotalGames,
             totalWins: newUser.stats.totalWins + oldUser.stats.totalWins,
             totalLosses: newUser.stats.totalLosses + oldUser.stats.totalLosses,
             bestWinStreak: Math.max(newUser.stats.bestWinStreak, oldUser.stats.bestWinStreak),
             totalPlayTimeMinutes: newUser.stats.totalPlayTimeMinutes + oldUser.stats.totalPlayTimeMinutes,
             avgScore: newAvgScore
           }
         });
      }

      await tx.leaderboard.deleteMany({ where: { userId: oldUser.id } });
      await tx.user.delete({ where: { id: oldUser.id } });
    });

    res.json({ success: true, message: 'Hesap başarıyla taşındı.' });
  } catch(error) {
    next(error);
  }
};

module.exports = { register, getProfile, migrate, registerValidation };
