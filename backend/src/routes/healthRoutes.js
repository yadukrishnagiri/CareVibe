const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const { getMyMetrics, seedMyMetrics, analyzeMetrics } = require('../controllers/healthController');

router.get('/metrics/me', auth, getMyMetrics);
router.post('/metrics/seed', auth, seedMyMetrics);
router.get('/metrics/analyze', auth, analyzeMetrics);

module.exports = router;



