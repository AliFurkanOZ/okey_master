const prisma = require('../utils/prisma');

// Kendi istatistiklerim
const getMyStats = async (req, res, next) => {
  try {
    const user = await prisma.user.findUnique({ where: { firebaseUid: req.user.uid } });
    const stats = await prisma.userStats.findUnique({ where: { userId: user.id } });
    
    if (!stats) return res.status(404).json({ error: 'İstatistik bulunamadı.' });
    res.json(stats);
  } catch (error) { next(error); }
};

// Başka bir kullanıcının istatistikleri
const getUserStats = async (req, res, next) => {
  try {
    const { userId } = req.params;
    const stats = await prisma.userStats.findUnique({ 
      where: { userId },
      include: { user: { select: { username: true, avatarUrl: true } } }
    });
    
    if (!stats) return res.status(404).json({ error: 'Kullanıcı veya istatistik bulunamadı.' });
    res.json(stats);
  } catch (error) { next(error); }
};

module.exports = { getMyStats, getUserStats };
