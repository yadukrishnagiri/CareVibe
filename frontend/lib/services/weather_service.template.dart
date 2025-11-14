import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // ============================================================================
  // 🔑 SETUP REQUIRED: Get your free API key from https://openweathermap.org/
  // ============================================================================
  // 1. Sign up at: https://openweathermap.org/
  // 2. Go to "My API Keys" section
  // 3. Copy your API key (activation takes 10-15 minutes)
  // 4. Copy this file to 'weather_service.dart' (without .template)
  // 5. Replace 'YOUR_API_KEY_HERE' below with your actual key
  // 6. Save the file
  //
  // Example: static const String _apiKey = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6';
  //
  // ⚠️ The actual weather_service.dart is in .gitignore for security
  // See docs/WEATHER_AQI_SETUP.md for security best practices
  // ============================================================================
  
  static const String _apiKey = 'YOUR_API_KEY_HERE';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  /// Fetch weather data by city name
  Future<WeatherData?> getWeatherByCity(String city) async {
    try {
      final weatherUrl = Uri.parse(
        '$_baseUrl/weather?q=$city&appid=$_apiKey&units=metric',
      );

      print('[WeatherService] Fetching weather for: $city');
      final weatherResponse = await http.get(weatherUrl);
      print('[WeatherService] Response status: ${weatherResponse.statusCode}');

      if (weatherResponse.statusCode == 200) {
        final weatherJson = json.decode(weatherResponse.body);
        print('[WeatherService] Weather data received successfully');
        
        final lat = weatherJson['coord']['lat'];
        final lon = weatherJson['coord']['lon'];

        // Fetch AQI data using coordinates
        final aqiData = await _getAirQuality(lat, lon);

        return WeatherData.fromJson(weatherJson, aqiData);
      } else {
        print('[WeatherService] Error: ${weatherResponse.statusCode} - ${weatherResponse.body}');
      }
      return null;
    } catch (e) {
      print('[WeatherService] Error fetching weather: $e');
      return null;
    }
  }

  /// Fetch weather data by coordinates
  Future<WeatherData?> getWeatherByCoordinates(double lat, double lon) async {
    try {
      final weatherUrl = Uri.parse(
        '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric',
      );

      print('[WeatherService] Fetching weather for coordinates: $lat, $lon');
      final weatherResponse = await http.get(weatherUrl);
      print('[WeatherService] Response status: ${weatherResponse.statusCode}');

      if (weatherResponse.statusCode == 200) {
        final weatherJson = json.decode(weatherResponse.body);
        print('[WeatherService] Weather data received successfully');
        
        // Fetch AQI data
        final aqiData = await _getAirQuality(lat, lon);

        return WeatherData.fromJson(weatherJson, aqiData);
      } else {
        print('[WeatherService] Error: ${weatherResponse.statusCode} - ${weatherResponse.body}');
      }
      return null;
    } catch (e) {
      print('[WeatherService] Error fetching weather: $e');
      return null;
    }
  }

  /// Fetch air quality index data
  Future<AqiData?> _getAirQuality(double lat, double lon) async {
    try {
      final aqiUrl = Uri.parse(
        '$_baseUrl/air_pollution?lat=$lat&lon=$lon&appid=$_apiKey',
      );

      final aqiResponse = await http.get(aqiUrl);

      if (aqiResponse.statusCode == 200) {
        final aqiJson = json.decode(aqiResponse.body);
        return AqiData.fromJson(aqiJson);
      }
      return null;
    } catch (e) {
      print('Error fetching AQI: $e');
      return null;
    }
  }
}

class WeatherData {
  final double temperature;
  final String condition;
  final String description;
  final int humidity;
  final double windSpeed;
  final String cityName;
  final AqiData? aqi;

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.cityName,
    this.aqi,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json, AqiData? aqiData) {
    return WeatherData(
      temperature: (json['main']['temp'] as num).toDouble(),
      condition: json['weather'][0]['main'] as String,
      description: json['weather'][0]['description'] as String,
      humidity: json['main']['humidity'] as int,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      cityName: json['name'] as String,
      aqi: aqiData,
    );
  }

  /// Get health tip based on weather and AQI
  String getHealthTip() {
    final aqiLevel = aqi?.level ?? 1;
    final temp = temperature.round();

    // Bad AQI (4-5) - priority warning
    if (aqiLevel >= 4) {
      return 'Poor air quality detected. Consider staying indoors and using an air purifier.';
    }

    // Moderate AQI (3) with outdoor activity suggestions
    if (aqiLevel == 3) {
      return 'Moderate air quality. Limit outdoor activities if you have respiratory concerns.';
    }

    // Temperature-based suggestions with good AQI
    if (temp < 5) {
      return 'Cold weather! Bundle up and take short walks. Stay hydrated even in cold weather.';
    } else if (temp < 15) {
      return 'Cool weather—perfect for a brisk walk! Aim for 30 minutes of outdoor activity.';
    } else if (temp >= 15 && temp <= 25) {
      return 'Perfect weather for a walk! Aim for 30 minutes of outdoor activity today.';
    } else if (temp > 25 && temp <= 32) {
      return 'Warm day! Stay hydrated and take walks during cooler morning or evening hours.';
    } else {
      return 'Very hot! Limit outdoor activities, stay hydrated, and remain in cool environments.';
    }
  }

  /// Get weather icon based on condition
  String getWeatherIcon() {
    switch (condition.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
      case 'drizzle':
        return '🌧️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
      case 'haze':
        return '🌫️';
      default:
        return '🌤️';
    }
  }
}

class AqiData {
  final int level; // 1 = Good, 2 = Fair, 3 = Moderate, 4 = Poor, 5 = Very Poor
  final double pm25;
  final double pm10;
  final double o3;
  final double no2;

  AqiData({
    required this.level,
    required this.pm25,
    required this.pm10,
    required this.o3,
    required this.no2,
  });

  factory AqiData.fromJson(Map<String, dynamic> json) {
    final components = json['list'][0]['components'];
    return AqiData(
      level: json['list'][0]['main']['aqi'] as int,
      pm25: (components['pm2_5'] as num?)?.toDouble() ?? 0.0,
      pm10: (components['pm10'] as num?)?.toDouble() ?? 0.0,
      o3: (components['o3'] as num?)?.toDouble() ?? 0.0,
      no2: (components['no2'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String getLevelDescription() {
    switch (level) {
      case 1:
        return 'Good';
      case 2:
        return 'Fair';
      case 3:
        return 'Moderate';
      case 4:
        return 'Poor';
      case 5:
        return 'Very Poor';
      default:
        return 'Unknown';
    }
  }

  /// Get color for AQI level
  String getColor() {
    switch (level) {
      case 1:
        return '🟢'; // Green
      case 2:
        return '🟡'; // Yellow
      case 3:
        return '🟠'; // Orange
      case 4:
        return '🔴'; // Red
      case 5:
        return '🟣'; // Purple
      default:
        return '⚪'; // White
    }
  }
}

