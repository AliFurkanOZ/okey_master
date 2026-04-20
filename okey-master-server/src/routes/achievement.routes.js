const express = require('express');
const { verifyToken } = require('../middleware/firebase-auth');
const achievementController = require('../controllers/achievement.controller');

const router = express.Router();

router.get('/', verifyToken, achievementController.getAllAchievements);
router.get('/me', verifyToken, achievementController.getMyAchievements);
router.post('/check', verifyToken, achievementController.checkAchievements);

module.exports = router;
