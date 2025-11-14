import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api.dart';

class WeatherService {
  // ============================================================================
  // 🔒 SECURE: API key is stored in backend .env file
  // ============================================================================
  // Your OpenWeatherMap API key is securely stored in:
  // backend/.env as WEATHER_API_KEY
  //
  // This prevents the API key from being exposed in the frontend code.
  // All weather requests go through your backend server.
  // ============================================================================

  /// Fetch weather data by city name
  Future<WeatherData?> getWeatherByCity(String city) async {
    try {
      final weatherUrl = Uri.parse('$apiBase/api/weather/city?city=$city');

      print('[WeatherService] Fetching weather for: $city');
      final response = await http.get(weatherUrl);
      print('[WeatherService] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('[WeatherService] Weather data received successfully');
        
        final weatherJson = data['weather'];
        final aqiJson = data['aqi'];
        
        AqiData? aqiData;
        if (aqiJson != null) {
          aqiData = AqiData.fromJson(aqiJson);
        }

        return WeatherData.fromJson(weatherJson, aqiData);
      } else {
        print('[WeatherService] Error: ${response.statusCode} - ${response.body}');
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
      final weatherUrl = Uri.parse('$apiBase/api/weather/coordinates?lat=$lat&lon=$lon');

      print('[WeatherService] Fetching weather for coordinates: $lat, $lon');
      final response = await http.get(weatherUrl);
      print('[WeatherService] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('[WeatherService] Weather data received successfully');
        
        final weatherJson = data['weather'];
        final aqiJson = data['aqi'];
        
        AqiData? aqiData;
        if (aqiJson != null) {
          aqiData = AqiData.fromJson(aqiJson);
        }

        return WeatherData.fromJson(weatherJson, aqiData);
      } else {
        print('[WeatherService] Error: ${response.statusCode} - ${response.body}');
      }
      return null;
    } catch (e) {
      print('[WeatherService] Error fetching weather: $e');
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

