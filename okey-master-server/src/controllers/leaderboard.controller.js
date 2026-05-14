const prisma = require('../utils/prisma');

const getLeaderboard = async (req, res) => {
  try {
    const { type } = req.query; // 'duel', 'memory_easy', 'memory_medium', 'memory_hard'

    console.log(`[getLeaderboard] İstek geldi: type=${type}`);

    // Okey (Duel) Tablosu: Puanı 0'dan büyük olan, en yüksek puanlı 10 kişi
    if (type === "duel") {
      const players = await prisma.userStats.findMany({
        take: 10,
        where: { avgScore: { gt: 0 } }, 
        orderBy: { avgScore: 'desc' },
        include: { user: { select: { username: true } } }
      });
      
      console.log(`[getLeaderboard] Duel sonuçları: ${players.length} oyuncu bulundu`);
      players.forEach((p, i) => console.log(`  ${i+1}. ${p.user?.username}: ${p.avgScore} puan`));
      
      return res.json(players.map((p, i) => ({ 
        rank: i + 1, 
        nickname: p.user?.username || "İsimsiz", 
        score: Math.round(p.avgScore) 
      })));
    }

    // Hafıza Tabloları: Süresi 0'dan büyük olan, en kısa süreli 10 kişi
    const fieldMap = { 
      "memory_easy": "bestTimeEasy", 
      "memory_medium": "bestTimeMedium", 
      "memory_hard": "bestTimeHard" 
    };
    const field = fieldMap[type];

    if (field) {
      const players = await prisma.userStats.findMany({
        take: 10,
        where: { [field]: { gt: 0 } }, 
        orderBy: { [field]: 'asc' }, 
        include: { user: { select: { username: true } } }
      });
      
      console.log(`[getLeaderboard] ${type} sonuçları: ${players.length} oyuncu bulundu`);
      
      return res.json(players.map((p, i) => ({ 
        rank: i + 1, 
        nickname: p.user?.username || "İsimsiz", 
        score: p[field] 
      })));
    }

    console.log(`[getLeaderboard] Geçersiz tip: ${type}`);
    res.json([]);
  } catch (error) {
    console.error("[getLeaderboard] Liderlik Hatası:", error);
    res.status(500).json({ error: error.message });
  }
};

module.exports = { getLeaderboard };