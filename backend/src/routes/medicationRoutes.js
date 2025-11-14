const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const { getMyMedications, getTodayReminders, addMedication, deleteMedication } = require('../controllers/medicationController');

router.get('/medications/me', auth, getMyMedications);
router.get('/medications/me/today', auth, getTodayReminders);
router.post('/medications', auth, addMedication);
router.delete('/medications/:id', auth, deleteMedication);

module.exports = router;

