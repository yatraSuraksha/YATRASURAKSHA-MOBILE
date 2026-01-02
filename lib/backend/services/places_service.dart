import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Represents a nearby place (hospital, police station, etc.)
class NearbyPlace {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double distance; // in meters
  final String? phoneNumber;
  final double? rating;
  final bool? isOpen;
  final String placeType;

  NearbyPlace({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distance,
    this.phoneNumber,
    this.rating,
    this.isOpen,
    required this.placeType,
  });

  /// Get formatted distance string
  String get formattedDistance {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
  }

  factory NearbyPlace.fromGooglePlace(
      Map<String, dynamic> json, Position userPosition, String type) {
    final location = json['geometry']['location'];
    final lat = location['lat'] as double;
    final lng = location['lng'] as double;

    // Calculate distance from user
    final distance = Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      lat,
      lng,
    );

    return NearbyPlace(
      id: json['place_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      address: json['vicinity'] ??
          json['formatted_address'] ??
          'Address not available',
      latitude: lat,
      longitude: lng,
      distance: distance,
      phoneNumber: json['formatted_phone_number'],
      rating: json['rating']?.toDouble(),
      isOpen: json['opening_hours']?['open_now'],
      placeType: type,
    );
  }
}

/// Service for fetching nearby places using Google Places API
class PlacesService {
  static final PlacesService _instance = PlacesService._internal();
  factory PlacesService() => _instance;
  PlacesService._internal();

  // Load Google Places API key from environment variables
  static String get _apiKey => dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  /// Fetch nearby hospitals
  Future<List<NearbyPlace>> getNearbyHospitals(Position position,
      {int radius = 5000}) async {
    return _getNearbyPlaces(position, 'hospital', radius: radius);
  }

  /// Fetch nearby police stations
  Future<List<NearbyPlace>> getNearbyPoliceStations(Position position,
      {int radius = 5000}) async {
    return _getNearbyPlaces(position, 'police', radius: radius);
  }

  /// Fetch nearby pharmacies
  Future<List<NearbyPlace>> getNearbyPharmacies(Position position,
      {int radius = 5000}) async {
    return _getNearbyPlaces(position, 'pharmacy', radius: radius);
  }

  /// Generic method to fetch nearby places by type
  Future<List<NearbyPlace>> _getNearbyPlaces(
    Position position,
    String type, {
    int radius = 5000,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/nearbysearch/json?'
        'location=${position.latitude},${position.longitude}'
        '&radius=$radius'
        '&type=$type'
        '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>;

        final places = results
            .map((place) => NearbyPlace.fromGooglePlace(place, position, type))
            .toList();

        // Sort by distance
        places.sort((a, b) => a.distance.compareTo(b.distance));

        return places;
      } else {
        debugPrint('Places API error: ${response.statusCode}');
        return _getMockPlaces(position, type);
      }
    } catch (e) {
      debugPrint('Error fetching nearby places: $e');
      // Return mock data for testing when API is not available
      return _getMockPlaces(position, type);
    }
  }

  /// Get place details including phone number
  Future<NearbyPlace?> getPlaceDetails(
      String placeId, Position userPosition, String type) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/details/json?'
        'place_id=$placeId'
        '&fields=name,formatted_address,formatted_phone_number,geometry,opening_hours,rating'
        '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['result'];

        if (result != null) {
          final location = result['geometry']['location'];
          final lat = location['lat'] as double;
          final lng = location['lng'] as double;

          final distance = Geolocator.distanceBetween(
            userPosition.latitude,
            userPosition.longitude,
            lat,
            lng,
          );

          return NearbyPlace(
            id: placeId,
            name: result['name'] ?? 'Unknown',
            address: result['formatted_address'] ?? 'Address not available',
            latitude: lat,
            longitude: lng,
            distance: distance,
            phoneNumber: result['formatted_phone_number'],
            rating: result['rating']?.toDouble(),
            isOpen: result['opening_hours']?['open_now'],
            placeType: type,
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching place details: $e');
      return null;
    }
  }

  /// Mock data for testing when API is not available
  List<NearbyPlace> _getMockPlaces(Position position, String type) {
    if (type == 'hospital') {
      return [
        NearbyPlace(
          id: 'h1',
          name: 'City General Hospital',
          address: '123 Main Street, City Center',
          latitude: position.latitude + 0.01,
          longitude: position.longitude + 0.01,
          distance: 1200,
          phoneNumber: '+91 9876543210',
          rating: 4.5,
          isOpen: true,
          placeType: type,
        ),
        NearbyPlace(
          id: 'h2',
          name: 'Apollo Hospital',
          address: '456 Health Avenue, Medical District',
          latitude: position.latitude + 0.02,
          longitude: position.longitude - 0.01,
          distance: 2500,
          phoneNumber: '+91 9876543211',
          rating: 4.8,
          isOpen: true,
          placeType: type,
        ),
        NearbyPlace(
          id: 'h3',
          name: 'Government Hospital',
          address: '789 Public Road, Old Town',
          latitude: position.latitude - 0.015,
          longitude: position.longitude + 0.02,
          distance: 3100,
          phoneNumber: '+91 9876543212',
          rating: 4.0,
          isOpen: true,
          placeType: type,
        ),
        NearbyPlace(
          id: 'h4',
          name: 'Emergency Care Center',
          address: '321 Emergency Lane, Urgent Block',
          latitude: position.latitude + 0.03,
          longitude: position.longitude + 0.015,
          distance: 4200,
          phoneNumber: '+91 9876543213',
          rating: 4.3,
          isOpen: true,
          placeType: type,
        ),
      ];
    } else if (type == 'police') {
      return [
        NearbyPlace(
          id: 'p1',
          name: 'Central Police Station',
          address: '100 Law Street, Downtown',
          latitude: position.latitude + 0.008,
          longitude: position.longitude - 0.005,
          distance: 800,
          phoneNumber: '100',
          rating: 4.2,
          isOpen: true,
          placeType: type,
        ),
        NearbyPlace(
          id: 'p2',
          name: 'City Police Headquarters',
          address: '200 Justice Road, Civic Center',
          latitude: position.latitude - 0.02,
          longitude: position.longitude + 0.01,
          distance: 2200,
          phoneNumber: '100',
          rating: 4.0,
          isOpen: true,
          placeType: type,
        ),
        NearbyPlace(
          id: 'p3',
          name: 'Traffic Police Station',
          address: '300 Highway Junction, Ring Road',
          latitude: position.latitude + 0.025,
          longitude: position.longitude - 0.02,
          distance: 3500,
          phoneNumber: '100',
          rating: 3.8,
          isOpen: true,
          placeType: type,
        ),
        NearbyPlace(
          id: 'p4',
          name: 'Women Police Station',
          address: '400 Safety Lane, Women Block',
          latitude: position.latitude - 0.01,
          longitude: position.longitude - 0.025,
          distance: 2800,
          phoneNumber: '1091',
          rating: 4.4,
          isOpen: true,
          placeType: type,
        ),
      ];
    }
    return [];
  }
}
