const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const { getMyProfile, updateMyProfile } = require('../controllers/profileController');

router.get('/me', auth, getMyProfile);
router.put('/me', auth, updateMyProfile);

module.exports = router;



