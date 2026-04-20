const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const authRoutes = require('./routes/auth.routes');
const gameRoutes = require('./routes/game.routes');
const statsRoutes = require('./routes/stats.routes');
const leaderboardRoutes = require('./routes/leaderboard.routes');
const achievementRoutes = require('./routes/achievement.routes');


const app = express();

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
app.get('/api/health', (req, res) => res.json({ status: 'OK' }));

// Global Error Handler (Tüm hataların yakalandığı son nokta)
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Sunucu hatası oluştu.' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Sunucu ${PORT} portunda çalışıyor.`));
