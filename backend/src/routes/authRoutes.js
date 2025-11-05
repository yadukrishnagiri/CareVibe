const router = require('express').Router();
const { verifyFirebaseAndIssueJwt, demoAuth } = require('../controllers/authController');

router.post('/firebase', verifyFirebaseAndIssueJwt);
router.post('/demo', demoAuth);

module.exports = router;


