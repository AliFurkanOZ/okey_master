const express = require('express');
const router = express.Router();
const leaderboardController = require('../controllers/leaderboard.controller');

// DİKKAT: leaderboardController.getLeaderboard'un fonksiyon olduğundan emin oluyoruz
// Eğer parantez içinde hata alıyorsan, verifyToken gibi eksik middleware'leri buradan temizle
router.get('/', leaderboardController.getLeaderboard);

module.exports = router;