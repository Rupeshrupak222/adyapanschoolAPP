const express = require('express');
const authController = require('../controllers/auth.controller');

const router = express.Router();

router.post('/signup', authController.signup);
router.post('/login', authController.login);
router.get('/login-events', authController.loginEvents);
router.get('/login-summary', authController.loginSummary);

module.exports = router;
