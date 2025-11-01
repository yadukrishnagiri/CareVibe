const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const { getMyMetrics, seedMyMetrics } = require('../controllers/healthController');

router.get('/metrics/me', auth, getMyMetrics);
router.post('/metrics/seed', auth, seedMyMetrics);

module.exports = router;



