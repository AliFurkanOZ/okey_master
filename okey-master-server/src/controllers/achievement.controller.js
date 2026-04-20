const prisma = require('../utils/prisma');

const getAllAchievements = async (req, res, next) => {
  try {
    const achievements = await prisma.achievement.findMany();
    res.json(achievements);
  } catch (error) { next(error); }
};

const getMyAchievements = async (req, res, next) => {
  try {
    const user = await prisma.user.findUnique({ where: { firebaseUid: req.user.uid } });
    const myAchievements = await prisma.userAchievement.findMany({
      where: { userId: user.id },
      include: { achievement: true }
    });
    res.json(myAchievements);
  } catch (error) { next(error); }
};

const checkAchievements = async (req, res, next) => {
  // Bu uç nokta oyun bittikten sonra Flutter tarafından tetiklenip, 
  // yeni başarım kazanılıp kazanılmadığını kontrol eder.
  try {
    const user = await prisma.user.findUnique({ 
      where: { firebaseUid: req.user.uid },
      include: { stats: true }
    });
    
    if(!user || !user.stats) return res.json({ newAchievements: [] });

    // Henüz açılmamış başarımları bul
    const unlocked = await prisma.userAchievement.findMany({ where: { userId: user.id } });
    const unlockedIds = unlocked.map(u => u.achievementId);
    
    const lockedAchievements = await prisma.achievement.findMany({
      where: { id: { notIn: unlockedIds } }
    });

    const newAchievements = [];
    
    // Basit koşul kontrolleri (örn: total_wins >= 1)
    for (const ach of lockedAchievements) {
      let earned = false;
      if (ach.conditionType === 'total_wins' && user.stats.totalWins >= ach.conditionValue) earned = true;
      if (ach.conditionType === 'win_streak' && user.stats.winStreak >= ach.conditionValue) earned = true;
      if (ach.conditionType === 'total_games' && user.stats.totalGames >= ach.conditionValue) earned = true;

      if (earned) {
        await prisma.userAchievement.create({
          data: { userId: user.id, achievementId: ach.id }
        });
        newAchievements.push(ach);
      }
    }

    res.json({ newAchievements });
  } catch (error) { next(error); }
};

module.exports = { getAllAchievements, getMyAchievements, checkAchievements };
