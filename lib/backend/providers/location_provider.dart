import 'package:flutter/foundation.dart';
import 'package:yatra_suraksha_app/backend/services/location_service.dart';

class LocationProvider extends ChangeNotifier {

  final LocationService _locationService = LocationService();
  
  double? _latitude;
  double? _longitude;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  double? get latitude => _latitude;
  double? get longitude => _longitude;

  Future<void> getCurrentLocation() async {
    _isLoading = true;
    final position = await _locationService.getCurrentLocation();

    if(position != null) {
      _latitude = position.latitude;
      _longitude = position.longitude;
    } else {
      _latitude = 1.6;
      _longitude = 0.8;
    }
    _isLoading = false;
    notifyListeners();
  }
}