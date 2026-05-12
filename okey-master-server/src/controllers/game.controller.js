const prisma = require('../utils/prisma');

const saveGameResult = async (req, res) => {
  try {
    const { username, isWin, duration, gameType } = req.body;
    const user = await prisma.user.findFirst({ where: { username }, include: { stats: true } });
    
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

// BURASI ROUTES İLE AYNI OLMALI
module.exports = { saveGameResult };