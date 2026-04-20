const prisma = require('../utils/prisma');
const { param, validationResult } = require('express-validator');

const leaderboardValidation = [
  param('period').isIn(['weekly', 'monthly', 'all_time']).withMessage('Geçersiz periyot')
];

const getLeaderboard = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ error: 'Geçersiz veri', details: errors.array() });

    const { period } = req.params;

    // Prisma ile leaderboard tablosunu sorgula (Rank'e veya Skor'a göre sıralı)
    const leaderboard = await prisma.leaderboard.findMany({
      where: { period },
      orderBy: { score: 'desc' },
      take: 50, // İlk 50 kişi
      include: {
        user: { select: { username: true, avatarUrl: true } }
      }
    });

    res.json(leaderboard);
  } catch (error) { next(error); }
};

module.exports = { getLeaderboard, leaderboardValidation };
