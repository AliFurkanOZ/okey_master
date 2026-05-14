const express = require('express');
const cors = require('cors');
const http = require('http');
const socketIo = require('socket.io');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const cron = require('node-cron');
require('dotenv').config();

const prisma = require('./utils/prisma');

const authRoutes = require('./routes/auth.routes');
const gameRoutes = require('./routes/game.routes');
const statsRoutes = require('./routes/stats.routes');
const leaderboardRoutes = require('./routes/leaderboard.routes');
const achievementRoutes = require('./routes/achievement.routes');


const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

// Socket config yükle
require('./config/socket')(io);
// Proxy arkasında çalışıyorsak (Railway vb.) zorunlu
app.set('trust proxy', 1);

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '1mb' }));

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 dakika
  max: 100, // IP başına 100 istek (Saldırı önleyici)
});
app.use('/api/', limiter);

// Routes (Bağlantı Yolları)
app.use('/api/auth', authRoutes);
app.use('/api/games', gameRoutes);
app.use('/api/stats', statsRoutes);
app.use('/api/leaderboard', leaderboardRoutes);
app.use('/api/achievements', achievementRoutes);


// Health Check (Sunucu ayakta mı diye kontrol eden nabız noktası)
app.get('/api/health', async (req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.json({ status: 'OK', db: 'connected', timestamp: new Date().toISOString() });
  } catch (error) {
    res.status(503).json({ status: 'ERROR', db: 'disconnected', timestamp: new Date().toISOString() });
  }
});

// Global Error Handler (Tüm hataların yakalandığı son nokta)
app.use((err, req, res, next) => {
  console.error(`[${new Date().toISOString()}] ${req.method} ${req.path}:`, err.message);

  // Prisma hataları
  if (err.code === 'P2002') {
    return res.status(409).json({ error: 'Bu kayıt zaten mevcut.' });
  }
  if (err.code === 'P2025') {
    return res.status(404).json({ error: 'Kayıt bulunamadı.' });
  }

  // Validation hataları
  if (err.type === 'validation') {
    return res.status(400).json({ error: err.message, details: err.details });
  }

  // Genel hata
  res.status(err.status || 500).json({
    error: process.env.NODE_ENV === 'production'
      ? 'Sunucu hatası oluştu.'
      : err.message,
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log(`Sunucu ${PORT} portunda çalışıyor.`));

// Periyodik bakım görevleri (Cron Jobs)
// Her 5 dakikada bir Materialized View yenile (leaderboard)


// Her Pazar 03:00'te eski idempotency key'leri temizle (7 günden eski)
cron.schedule('0 3 * * 0', async () => {
  try {
    const result = await prisma.idempotencyKeys.deleteMany({
      where: { createdAt: { lt: new Date(Date.now() - 7 * 86400000) } },
    });
    console.log(`[CRON] Deleted ${result.count} expired idempotency keys`);
  } catch (err) {
    console.error('[CRON] Idempotency cleanup failed:', err.message);
  }
});
