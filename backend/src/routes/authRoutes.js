const router = require('express').Router();
const { verifyFirebaseAndIssueJwt } = require('../controllers/authController');

router.post('/firebase', verifyFirebaseAndIssueJwt);

module.exports = router;


