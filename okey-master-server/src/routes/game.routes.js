const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/firebase-auth');
const gameController = require('../controllers/game.controller');

router.post('/', verifyToken, gameController.createGameValidation, gameController.createGame);
router.post('/:id/finish', verifyToken, gameController.finishGameValidation, gameController.finishGame);
router.get('/history', verifyToken, gameController.getHistory);

// router.post için İKİNCİ parametrenin bir fonksiyon olduğundan eminiz
router.post('/result', verifyToken, gameController.saveGameResult);

module.exports = router;