const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const { getMyMedications, getTodayReminders, addMedication } = require('../controllers/medicationController');

router.get('/medications/me', auth, getMyMedications);
router.get('/medications/me/today', auth, getTodayReminders);
router.post('/medications', auth, addMedication);

module.exports = router;

