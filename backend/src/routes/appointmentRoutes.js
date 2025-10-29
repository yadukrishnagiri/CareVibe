const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const { getAppointments } = require('../controllers/appointmentController');

router.get('/appointments/:userId', auth, getAppointments);

module.exports = router;


