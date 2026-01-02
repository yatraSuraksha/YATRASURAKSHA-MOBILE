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
  final List<String>? categories;

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
    this.categories,
  });

  /// Get formatted distance string
  String get formattedDistance {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Factory to create NearbyPlace from Azure Maps Search API response
  factory NearbyPlace.fromAzureMaps(
      Map<String, dynamic> json, Position userPosition, String type) {
    final position = json['position'];
    final lat = (position['lat'] as num).toDouble();
    final lon = (position['lon'] as num).toDouble();

    // Calculate distance from user using Haversine formula (Geolocator)
    final distance = Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      lat,
      lon,
    );

    // Extract POI information
    final poi = json['poi'] ?? {};
    final address = json['address'] ?? {};

    // Get phone number from POI
    String? phone;
    if (poi['phone'] != null) {
      phone = poi['phone'];
    }

    // Get categories
    List<String>? categories;
    if (poi['categories'] != null) {
      categories = List<String>.from(poi['categories']);
    }

    // Azure Maps provides distance in 'dist' field (in meters)
    final azureDistance =
        json['dist'] != null ? (json['dist'] as num).toDouble() : distance;

    return NearbyPlace(
      id: json['id'] ?? '${lat}_$lon',
      name: poi['name'] ?? json['poi']?['name'] ?? 'Unknown',
      address: address['freeformAddress'] ??
          address['streetName'] ??
          'Address not available',
      latitude: lat,
      longitude: lon,
      distance: azureDistance,
      phoneNumber: phone,
      rating: null, // Azure Maps doesn't provide ratings in basic search
      isOpen: poi['openingHours']?['mode'] == 'open',
      placeType: type,
      categories: categories,
    );
  }
}

/// Service for fetching nearby places using Azure Maps Search API
class AzureMapsService {
  static final AzureMapsService _instance = AzureMapsService._internal();
  factory AzureMapsService() => _instance;
  AzureMapsService._internal();

  // Azure Maps credentials - hardcoded fallback for when dotenv fails
  static const String _fallbackSubscriptionKey =
      '17ttGi3OgfpeCxH6MFyfy2RGTWwb1gRQY28ZxWGk7szhtxrGOK3gJQQJ99CAACYeBjFNpVFXAAAgAZMP2Cfv';

  // Azure Maps credentials from environment variables with fallback
  static String get _subscriptionKey {
    try {
      return dotenv.env['AZURE_MAPS_SUBSCRIPTION_KEY'] ??
          _fallbackSubscriptionKey;
    } catch (e) {
      return _fallbackSubscriptionKey;
    }
  }

  // Azure Maps API endpoints
  static const String _searchBaseUrl = 'https://atlas.microsoft.com/search';
  static const String _routeBaseUrl = 'https://atlas.microsoft.com/route';
  static const String _apiVersion = '1.0';

  /// Get Azure Maps tile URL for flutter_map
  static String getTileUrl() {
    final key = _subscriptionKey;
    return 'https://atlas.microsoft.com/map/tile?api-version=2024-04-01&tilesetId=microsoft.base.road&zoom={z}&x={x}&y={y}&subscription-key=$key';
  }

  /// Get Azure Maps satellite tile URL
  static String getSatelliteTileUrl() {
    final key = _subscriptionKey;
    return 'https://atlas.microsoft.com/map/tile?api-version=2024-04-01&tilesetId=microsoft.imagery&zoom={z}&x={x}&y={y}&subscription-key=$key';
  }

  /// Fetch nearby hospitals
  Future<List<NearbyPlace>> getNearbyHospitals(Position position,
      {int radius = 5000}) async {
    return _searchNearbyPOI(position, 'hospital', radius: radius);
  }

  /// Fetch nearby police stations
  Future<List<NearbyPlace>> getNearbyPoliceStations(Position position,
      {int radius = 5000}) async {
    return _searchNearbyPOI(position, 'police station', radius: radius);
  }

  /// Fetch nearby pharmacies
  Future<List<NearbyPlace>> getNearbyPharmacies(Position position,
      {int radius = 5000}) async {
    return _searchNearbyPOI(position, 'pharmacy', radius: radius);
  }

  /// Search for nearby Points of Interest using Azure Maps Search API
  Future<List<NearbyPlace>> _searchNearbyPOI(
    Position position,
    String query, {
    int radius = 5000,
    int limit = 20,
  }) async {
    try {
      // Azure Maps POI Search endpoint
      final url = Uri.parse(
        '$_searchBaseUrl/poi/json'
        '?api-version=$_apiVersion'
        '&subscription-key=$_subscriptionKey'
        '&query=$query'
        '&lat=${position.latitude}'
        '&lon=${position.longitude}'
        '&radius=$radius'
        '&limit=$limit'
        '&language=en-US',
      );

      debugPrint('Azure Maps API Request: $url');

      final response = await http.get(url, headers: {
        'Accept': 'application/json',
      });

      debugPrint('Azure Maps API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>? ?? [];

        debugPrint('Azure Maps returned ${results.length} results');

        final places = results
            .map((place) => NearbyPlace.fromAzureMaps(place, position, query))
            .toList();

        // Sort by distance (nearest first)
        places.sort((a, b) => a.distance.compareTo(b.distance));

        return places;
      } else {
        debugPrint('Azure Maps API error: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return _getMockPlaces(position, query);
      }
    } catch (e) {
      debugPrint('Error fetching nearby places from Azure Maps: $e');
      // Return mock data for testing when API is not available
      return _getMockPlaces(position, query);
    }
  }

  /// Search for a specific address or place using Azure Maps Search API
  Future<List<NearbyPlace>> searchAddress(
    String query,
    Position userPosition, {
    int limit = 10,
  }) async {
    try {
      final url = Uri.parse(
        '$_searchBaseUrl/address/json'
        '?api-version=$_apiVersion'
        '&subscription-key=$_subscriptionKey'
        '&query=${Uri.encodeComponent(query)}'
        '&lat=${userPosition.latitude}'
        '&lon=${userPosition.longitude}'
        '&limit=$limit',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>? ?? [];

        return results
            .map((place) =>
                NearbyPlace.fromAzureMaps(place, userPosition, 'address'))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error searching address: $e');
      return [];
    }
  }

  /// Get directions URL for Azure Maps (opens in browser/maps app)
  String getDirectionsUrl({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
  }) {
    // Use Azure Maps web routing URL
    return 'https://atlas.microsoft.com/route/directions/json'
        '?api-version=$_apiVersion'
        '&subscription-key=$_subscriptionKey'
        '&query=$startLat,$startLon:$endLat,$endLon';
  }

  /// Calculate route between two points
  Future<Map<String, dynamic>?> getRoute({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    String travelMode = 'car',
  }) async {
    try {
      final url = Uri.parse(
        '$_routeBaseUrl/directions/json'
        '?api-version=$_apiVersion'
        '&subscription-key=$_subscriptionKey'
        '&query=$startLat,$startLon:$endLat,$endLon'
        '&travelMode=$travelMode',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting route: $e');
      return null;
    }
  }

  /// Reverse geocode - get address from coordinates
  Future<String?> reverseGeocode(double lat, double lon) async {
    try {
      final url = Uri.parse(
        '$_searchBaseUrl/address/reverse/json'
        '?api-version=$_apiVersion'
        '&subscription-key=$_subscriptionKey'
        '&query=$lat,$lon',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final addresses = data['addresses'] as List<dynamic>? ?? [];
        if (addresses.isNotEmpty) {
          return addresses[0]['address']['freeformAddress'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
      return null;
    }
  }

  /// Mock data for testing when API is not available
  List<NearbyPlace> _getMockPlaces(Position position, String type) {
    final isHospital = type.toLowerCase().contains('hospital');
    final isPolice = type.toLowerCase().contains('police');

    if (isHospital) {
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
          categories: ['hospital', 'medical'],
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
          categories: ['hospital', 'emergency'],
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
          categories: ['hospital', 'public'],
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
          categories: ['hospital', 'emergency'],
        ),
      ];
    } else if (isPolice) {
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
          categories: ['police', 'government'],
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
          categories: ['police', 'headquarters'],
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
          categories: ['police', 'traffic'],
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
          categories: ['police', 'women safety'],
        ),
      ];
    }
    return [];
  }
}

// Export NearbyPlace for backward compatibility
typedef PlacesService = AzureMapsService;
