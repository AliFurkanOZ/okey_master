const express = require('express');
const router = express.Router();
const gameController = require('../controllers/game.controller');

// router.post için İKİNCİ parametrenin bir fonksiyon olduğundan eminiz
router.post('/result', gameController.saveGameResult);

module.exports = router;