import 'dart:convert';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class OsmPlace {
  OsmPlace({required this.name, required this.category, required this.lat, required this.lon, required this.addressLine, required this.distanceMeters});

  final String name;
  final String category;
  final double lat;
  final double lon;
  final String addressLine;
  final double distanceMeters;
}

class OsmPlacesService {
  static const _endpoint = 'https://nominatim.openstreetmap.org/search';

  static Future<List<OsmPlace>> fetchNearbyDoctors({
    required double lat,
    required double lon,
    String keywords = 'doctor clinic',
    int limit = 30,
    double radiusKm = 10,
  }) async {
    final q = (keywords.isEmpty ? 'doctor clinic' : keywords).trim();

    // Build bounding box for ~radiusKm around (lat, lon)
    final deltaLat = radiusKm / 111.0;
    final rad = lat * 3.1415926535 / 180.0;
    final cosLat = math.cos(rad);
    final safeCos = cosLat.abs() < 0.017 ? 0.017 : cosLat;
    final deltaLon = radiusKm / (111.0 * safeCos);
    final latMin = (lat - deltaLat).toStringAsFixed(6);
    final latMax = (lat + deltaLat).toStringAsFixed(6);
    final lonMin = (lon - deltaLon).toStringAsFixed(6);
    final lonMax = (lon + deltaLon).toStringAsFixed(6);
    final viewbox = '$lonMin,$latMin,$lonMax,$latMax';

    final uri = Uri.parse(_endpoint).replace(queryParameters: {
      'format': 'jsonv2',
      'q': q,
      'lat': lat.toString(),
      'lon': lon.toString(),
      'addressdetails': '1',
      'extratags': '1',
      'namedetails': '1',
      'bounded': '1',
      'viewbox': viewbox,
      'limit': limit.toString(),
    });

    final res = await http.get(
      uri,
      headers: {
        'User-Agent': 'CareVibeDemo/1.0 (contact: support@carevibe.example)',
        'Accept-Language': 'en',
      },
    );
    if (res.statusCode != 200) {
      throw Exception('OSM/Nominatim error: ${res.statusCode}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    final results = list.map((e) {
      final namedetails = (e['namedetails'] is Map) ? (e['namedetails'] as Map) : null;
      final latStr = e['lat']?.toString() ?? '0';
      final lonStr = e['lon']?.toString() ?? '0';
      final display = e['display_name']?.toString() ?? '';
      final name = (e['name']?.toString() ?? (namedetails?['name:en']?.toString() ?? display.split(',').first)).trim();
      final category = ((e['class']?.toString() ?? '') + ' ' + (e['type']?.toString() ?? 'clinic'))
          .trim()
          .replaceAll('_', ' ');
      final address = e['display_name']?.toString() ?? '';
      final plat = double.tryParse(latStr) ?? 0;
      final plon = double.tryParse(lonStr) ?? 0;
      final dist = Geolocator.distanceBetween(lat, lon, plat, plon);
      return OsmPlace(name: name, category: category, lat: plat, lon: plon, addressLine: address, distanceMeters: dist);
    }).where((p) => p.distanceMeters <= radiusKm * 1000 + 50).toList()
      ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return results;
  }
}


