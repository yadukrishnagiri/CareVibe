const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const { getMyProfile, updateMyProfile, exportProfileTemplate } = require('../controllers/profileController');

router.get('/me', auth, getMyProfile);
router.put('/me', auth, updateMyProfile);
router.get('/export-template', auth, exportProfileTemplate);
router.post('/export-template', auth, exportProfileTemplate);

module.exports = router;



