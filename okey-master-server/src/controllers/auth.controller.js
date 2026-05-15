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
    const displayName = username || req.user.name || 'Oyuncu';

    console.log(`[register] Giriş denemesi: uid=${firebaseUid}, username=${displayName}, email=${req.user.email || 'yok'}`);

    // 1. Kullanıcı zaten varsa, mevcut kullanıcıyı (ismini DEĞİŞTİRMEDEN) döndür
    const existingUser = await prisma.user.findUnique({
      where: { firebaseUid },
      include: { stats: true }
    });

    if (existingUser) {
      // Sadece son giriş tarihini, email ve resmi güncelliyoruz. Username'i ezmiyoruz.
      const updatedUser = await prisma.user.update({
        where: { id: existingUser.id },
        data: {
          lastLogin: new Date(),
          email: req.user.email || existingUser.email,
          avatarUrl: req.user.picture || existingUser.avatarUrl,
        },
        include: { stats: true },
      });
      console.log(`[register] Mevcut kullanıcı girişi: id=${updatedUser.id}, username=${updatedUser.username}`);
      return res.json(updatedUser);
    }

    // 2. Kullanıcı yoksa (yeni kayıt), istenen ismin benzersiz olup olmadığını kontrol et
    const nameCheck = await prisma.user.findUnique({
      where: { username: displayName }
    });

    if (nameCheck) {
      console.log(`[register] İsim zaten alınmış: ${displayName}`);
      return res.status(409).json({ error: 'Bu isim zaten alınmış' });
    }

    // 3. İsim boşta ise yeni kullanıcıyı oluştur
    const newUser = await prisma.user.create({
      data: {
        firebaseUid,
        username: displayName,
        email: req.user.email || null,
        avatarUrl: req.user.picture || null,
        stats: { create: {} },
      },
      include: { stats: true },
    });

    console.log(`[register] Başarılı yeni kayıt: id=${newUser.id}, username=${newUser.username}`);
    res.json(newUser);
  } catch (error) {
    console.error(`[register] HATA:`, error.message);
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

const updateUsername = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ error: 'Geçersiz veri', details: errors.array() });

    const { username } = req.body;
    const firebaseUid = req.user.uid;

    const existingUser = await prisma.user.findUnique({ where: { firebaseUid } });
    if (!existingUser) return res.status(404).json({ error: 'Kullanıcı bulunamadı' });

    if (existingUser.username === username) {
      return res.json({ success: true, username });
    }

    const nameCheck = await prisma.user.findUnique({ where: { username } });
    if (nameCheck) {
      return res.status(409).json({ error: 'Bu isim zaten alınmış' });
    }

    const updatedUser = await prisma.user.update({
      where: { firebaseUid },
      data: { username }
    });

    res.json({ success: true, username: updatedUser.username });
  } catch (error) {
    next(error);
  }
};

module.exports = { register, getProfile, migrate, registerValidation, updateUsername };
