const router = require('express').Router();
const { getWeatherByCity, getWeatherByCoordinates } = require('../controllers/weatherController');

// Public endpoints - no authentication required for weather
router.get('/weather/city', getWeatherByCity);
router.get('/weather/coordinates', getWeatherByCoordinates);

module.exports = router;

