const express = require('express');
const { verifyToken } = require('../middleware/firebase-auth');
const leaderboardController = require('../controllers/leaderboard.controller');

const router = express.Router();

router.get('/:period', verifyToken, leaderboardController.leaderboardValidation, leaderboardController.getLeaderboard);

module.exports = router;
