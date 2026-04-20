const express = require('express');
const { verifyToken } = require('../middleware/firebase-auth');
const statsController = require('../controllers/stats.controller');

const router = express.Router();

router.get('/me', verifyToken, statsController.getMyStats);
router.get('/:userId', verifyToken, statsController.getUserStats);

module.exports = router;
