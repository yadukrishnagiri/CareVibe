const router = require('express').Router();
const { getDoctors } = require('../controllers/doctorController');

router.get('/doctors', getDoctors);

module.exports = router;


