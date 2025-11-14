const axios = require('axios');

const WEATHER_API_KEY = process.env.WEATHER_API_KEY;
const WEATHER_BASE_URL = 'https://api.openweathermap.org/data/2.5';

/**
 * Get weather by city name
 */
exports.getWeatherByCity = async (req, res) => {
  try {
    const { city } = req.query;
    
    if (!city) {
      return res.status(400).json({ error: 'City parameter is required' });
    }

    if (!WEATHER_API_KEY) {
      return res.status(503).json({ error: 'Weather service not configured' });
    }

    const weatherUrl = `${WEATHER_BASE_URL}/weather?q=${encodeURIComponent(city)}&appid=${WEATHER_API_KEY}&units=metric`;
    
    const weatherResponse = await axios.get(weatherUrl);
    
    if (weatherResponse.status === 200) {
      const weatherData = weatherResponse.data;
      const lat = weatherData.coord.lat;
      const lon = weatherData.coord.lon;

      // Fetch AQI data
      const aqiUrl = `${WEATHER_BASE_URL}/air_pollution?lat=${lat}&lon=${lon}&appid=${WEATHER_API_KEY}`;
      
      let aqiData = null;
      try {
        const aqiResponse = await axios.get(aqiUrl);
        aqiData = aqiResponse.data;
      } catch (aqiError) {
        console.warn('[Weather] AQI fetch failed:', aqiError.message);
        // Continue without AQI data
      }

      return res.json({
        weather: weatherData,
        aqi: aqiData
      });
    }

    return res.status(weatherResponse.status).json({ 
      error: 'Failed to fetch weather data' 
    });
  } catch (error) {
    console.error('[Weather] Error fetching weather by city:', error.message);
    
    if (error.response) {
      return res.status(error.response.status).json({ 
        error: error.response.data?.message || 'Weather API error' 
      });
    }
    
    return res.status(500).json({ 
      error: 'Failed to fetch weather data',
      details: error.message 
    });
  }
};

/**
 * Get weather by coordinates
 */
exports.getWeatherByCoordinates = async (req, res) => {
  try {
    const { lat, lon } = req.query;
    
    if (!lat || !lon) {
      return res.status(400).json({ error: 'Latitude and longitude parameters are required' });
    }

    if (!WEATHER_API_KEY) {
      return res.status(503).json({ error: 'Weather service not configured' });
    }

    const weatherUrl = `${WEATHER_BASE_URL}/weather?lat=${lat}&lon=${lon}&appid=${WEATHER_API_KEY}&units=metric`;
    
    const weatherResponse = await axios.get(weatherUrl);
    
    if (weatherResponse.status === 200) {
      const weatherData = weatherResponse.data;

      // Fetch AQI data
      const aqiUrl = `${WEATHER_BASE_URL}/air_pollution?lat=${lat}&lon=${lon}&appid=${WEATHER_API_KEY}`;
      
      let aqiData = null;
      try {
        const aqiResponse = await axios.get(aqiUrl);
        aqiData = aqiResponse.data;
      } catch (aqiError) {
        console.warn('[Weather] AQI fetch failed:', aqiError.message);
        // Continue without AQI data
      }

      return res.json({
        weather: weatherData,
        aqi: aqiData
      });
    }

    return res.status(weatherResponse.status).json({ 
      error: 'Failed to fetch weather data' 
    });
  } catch (error) {
    console.error('[Weather] Error fetching weather by coordinates:', error.message);
    
    if (error.response) {
      return res.status(error.response.status).json({ 
        error: error.response.data?.message || 'Weather API error' 
      });
    }
    
    return res.status(500).json({ 
      error: 'Failed to fetch weather data',
      details: error.message 
    });
  }
};

