const express = require('express');
const { verifyToken } = require('../middleware/firebase-auth');
const authController = require('../controllers/auth.controller');

const router = express.Router();

// Gelen her isteğin önüne "verifyToken" kapısını koyuyoruz
router.post('/register',  authController.registerValidation, authController.register);
router.get('/profile', verifyToken, authController.getProfile);
router.post('/migrate', verifyToken, authController.migrate);

module.exports = router;
