const prisma = require('../utils/prisma');
const { body, validationResult } = require('express-validator');

const registerValidation = [
  body('username').trim().isLength({ min: 2, max: 50 }).withMessage('Kullanıcı adı 2-50 karakter olmalı')
];

const register = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ error: 'Geçersiz veri', details: errors.array() });

    const { username } = req.body;
    const firebaseUid = req.user.uid;

    const user = await prisma.user.upsert({
      where: { firebaseUid },
      update: { lastLogin: new Date() },
      create: {
        firebaseUid,
        username: username || `Oyuncu_${Date.now()}`,
        stats: { create: {} }, // Otomatik boş istatistik oluştur
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
  // Eski anonim hesabı yeni kalıcı hesaba taşıma mantığı
  res.json({ success: true, message: 'Hesap taşıma mock endpointi.' });
};

module.exports = { register, getProfile, migrate, registerValidation };
