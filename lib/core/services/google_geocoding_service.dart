import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/maps_config.dart';

/// Geocoding via Google Maps Geocoding API (REST).
class GoogleGeocodingService {
  GoogleGeocodingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<GeocodeResult?> reverseGeocode(double lat, double lng) async {
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?latlng=$lat,$lng'
      '&key=$kGoogleMapsApiKey',
    );
    final res = await _client.get(uri);
    if (res.statusCode != 200) return null;
    return _parseFirst(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<GeocodeResult?> forwardGeocode(String address) async {
    final q = Uri.encodeComponent(address.trim());
    if (q.isEmpty) return null;
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?address=$q'
      '&key=$kGoogleMapsApiKey',
    );
    final res = await _client.get(uri);
    if (res.statusCode != 200) return null;
    return _parseFirst(jsonDecode(res.body) as Map<String, dynamic>);
  }

  GeocodeResult? _parseFirst(Map<String, dynamic> json) {
    final status = json['status']?.toString() ?? '';
    if (status != 'OK' && status != 'ZERO_RESULTS') return null;
    final results = json['results'];
    if (results is! List || results.isEmpty) return null;
    final first = results.first;
    if (first is! Map) return null;
    final m = Map<String, dynamic>.from(first);
    final geom = m['geometry'];
    double? lat;
    double? lng;
    if (geom is Map && geom['location'] is Map) {
      final loc = geom['location'] as Map;
      lat = (loc['lat'] as num?)?.toDouble();
      lng = (loc['lng'] as num?)?.toDouble();
    }
    final formatted = m['formatted_address']?.toString() ?? '';
    String? city;
    String? state;
    String? pin;
    final comps = m['address_components'];
    if (comps is List) {
      for (final c in comps) {
        if (c is! Map) continue;
        final types = (c['types'] as List?)?.map((e) => e.toString()).toList() ?? [];
        final longName = c['long_name']?.toString() ?? '';
        if (types.contains('locality') || types.contains('sublocality')) {
          city ??= longName;
        }
        if (types.contains('administrative_area_level_1')) {
          state ??= longName;
        }
        if (types.contains('postal_code')) {
          pin ??= longName;
        }
      }
    }
    return GeocodeResult(
      formattedAddress: formatted,
      latitude: lat ?? 0,
      longitude: lng ?? 0,
      city: city ?? '',
      state: state ?? '',
      pinCode: pin ?? '',
    );
  }
}

class GeocodeResult {
  const GeocodeResult({
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.state,
    required this.pinCode,
  });

  final String formattedAddress;
  final double latitude;
  final double longitude;
  final String city;
  final String state;
  final String pinCode;
}
