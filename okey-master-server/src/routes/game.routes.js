const express = require('express');
const { verifyToken } = require('../middleware/firebase-auth');
const gameController = require('../controllers/game.controller');

const router = express.Router();

router.post('/', verifyToken, gameController.createGameValidation, gameController.createGame);
router.post('/:id/finish', verifyToken, gameController.finishGameValidation, gameController.finishGame);
router.get('/history', verifyToken, gameController.getHistory);

module.exports = router;
