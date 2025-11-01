import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class GeoapifyPlace {
  GeoapifyPlace({required this.id, required this.name, required this.category, required this.lat, required this.lon, required this.addressLine, required this.distanceMeters, this.openNow, this.rating});

  final String id;
  final String name;
  final String category;
  final double lat;
  final double lon;
  final String addressLine;
  final double distanceMeters;
  final bool? openNow; // Geoapify does not always provide; keep for symmetry
  final double? rating; // not common; placeholder for uniform model
}

class GeoapifyPlacesService {
  static final String _apiKey = const String.fromEnvironment('GEOAPIFY_API_KEY', defaultValue: '');
  static bool get isConfigured => _apiKey.isNotEmpty;

  static Future<List<GeoapifyPlace>> fetchNearby({
    required double lat,
    required double lon,
    required List<String> categories, // e.g., ['healthcare.hospital','healthcare.clinic']
    int radiusMeters = 10000,
    int limit = 30,
  }) async {
    if (!isConfigured) return [];
    final cats = categories.isEmpty
        ? 'healthcare.hospital,healthcare.clinic,healthcare.doctor'
        : categories.join(',');

    final uri = Uri.parse('https://api.geoapify.com/v2/places').replace(queryParameters: {
      'categories': cats,
      'filter': 'circle:$lon,$lat,$radiusMeters',
      'bias': 'proximity:$lon,$lat',
      'limit': '$limit',
      'apiKey': _apiKey,
    });

    final res = await http.get(uri, headers: {
      'User-Agent': 'CareVibeDemo/1.0 (contact: support@carevibe.example)',
      'Accept': 'application/json',
    });
    if (res.statusCode != 200) {
      throw Exception('Geoapify error: ${res.statusCode} ${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final features = (json['features'] as List?) ?? [];
    final places = features.map((f) {
      final props = (f['properties'] as Map?) ?? {};
      final geom = (f['geometry'] as Map?) ?? {};
      final coords = (geom['coordinates'] as List?) ?? [0.0, 0.0];
      final lonP = (coords[0] as num?)?.toDouble() ?? 0.0;
      final latP = (coords[1] as num?)?.toDouble() ?? 0.0;
      final name = (props['name']?.toString() ?? '').trim();
      final placeId = props['place_id']?.toString() ?? '';
      final category = (props['categories'] is List && (props['categories'] as List).isNotEmpty)
          ? ((props['categories'] as List).first.toString())
          : (props['category']?.toString() ?? 'clinic');
      final address = props['formatted']?.toString() ?? props['address_line2']?.toString() ?? '';
      final dist = Geolocator.distanceBetween(lat, lon, latP, lonP);
      return GeoapifyPlace(
        id: placeId,
        name: name.isEmpty ? 'Clinic' : name,
        category: category.replaceAll('_', ' '),
        lat: latP,
        lon: lonP,
        addressLine: address,
        distanceMeters: dist,
        openNow: null,
        rating: null,
      );
    }).toList()
      ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return places;
  }

  // Fetch place details (phone, website, opening hours) by Geoapify place_id
  static Future<GeoapifyPlaceDetails?> fetchDetails(String placeId) async {
    if (!isConfigured) return null;
    final uri = Uri.parse('https://api.geoapify.com/v2/place-details').replace(queryParameters: {
      'id': placeId,
      'apiKey': _apiKey,
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final features = (json['features'] as List?) ?? [];
    if (features.isEmpty) return null;
    final props = (features.first['properties'] as Map?) ?? {};
    final website = props['website']?.toString();
    final phone = (props['contact'] is Map) ? ((props['contact']['phone'])?.toString()) : null;
    final opening = props['opening_hours']?.toString();
    return GeoapifyPlaceDetails(website: website, phone: phone, openingHours: opening);
  }
}

class GeoapifyPlaceDetails {
  GeoapifyPlaceDetails({this.website, this.phone, this.openingHours});
  final String? website;
  final String? phone;
  final String? openingHours;
}


