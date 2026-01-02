import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:yatra_suraksha_app/backend/services/auth_service.dart';
import 'package:yatra_suraksha_app/backend/services/api_service.dart';

class CustomAuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  User? _user;
  String? _accessToken;
  String? _error;
  Map<String, dynamic>? _userProfile;

  bool get isLoading => _isLoading;
  User? get user => _user;
  String? get accessToken => _accessToken;
  String? get error => _error;
  Map<String, dynamic>? get userProfile => _userProfile;
  
  // Check if user is fully authenticated with profile data
  bool get isFullyAuthenticated => _user != null && _accessToken != null && _userProfile != null;
  
  // Check if user is logged in (basic Firebase auth)
  bool get isLoggedIn => _user != null || FirebaseAuth.instance.currentUser != null;
 
  Future<String?> googleLogin() async {
    _isLoading = true;
    _error = null;
    _accessToken = null;
    notifyListeners();

    final user = await _authService.googleLogin();
    _isLoading = false;

    if(user["response"] != null && !(user["response"] is String)) {
      _user = user["response"];
      // Get the access token after successful login
      _accessToken = await _authService.getCurrentAccessToken();
      
      // Verify user account with backend API
      final verificationResult = await _authService.verifyUserAccount();
      if (verificationResult["success"] == true) {
        _userProfile = verificationResult["data"];
      } else {
        // Note: We don't treat verification failure as login failure
        // The user is still authenticated with Firebase
      }
      
      notifyListeners();
      return null;
    } else {
      _error = user["response"];
      notifyListeners();
      return user["response"];
    }
  }

  // Add a method to handle Google Sign-in for compatibility
  Future<void> handleGoogleSignIn() async {
    await googleLogin();
  }

  // Future<String?> login(String email, String password) async {
  //   try {
  //     _isLoading = true;
  //     notifyListeners();

  //     final val = await _authService.login(email, password);
  //     _isLoading = false;

  //     if(val["response"] is User) {
  //       _user = user;
  //       notifyListeners();
  //       return null;
  //     } else {
  //       notifyListeners();
  //       print(val["response"] is FirebaseAuthException);
  //       return ErrorFormatter().formatAuthError(val["response"]);
  //     }
  //   } catch(err) {
  //     return "An Unexpected error occured. Please try again later";
  //   }
  // }

  // Future<String?> createAccount(String email, String password, String name) async {
  //   _isLoading = true;
  //   notifyListeners();

  //   final user = await _authService.createAccount(email, password);

  //   if (!(user["response"] is String)) {
  //     await user["response"].updateDisplayName(name);
  //     await user["response"].reload();
  //     _user = FirebaseAuth.instance.currentUser; // safer

  //     print("Updated display name: ${_user?.displayName}");

  //     _isLoading = false;
  //     notifyListeners();
  //     return null;
  //   } else {
  //     _isLoading = false;
  //     notifyListeners();
  //     return user["response"];
  //   }
  // }

  void signout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _authService.signout();
      
      // Clear all local state
      _user = null;
      _accessToken = null;
      _userProfile = null;
      _error = null;
    } catch (e) {
      _error = "Sign out failed: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void loadUser() {
    _user = FirebaseAuth.instance.currentUser;
    notifyListeners();
  }

  // API Methods with authentication
  Future<void> updateApiToken() async {
    await _authService.updateApiToken();
  }

  // Configure API base URL and tourist ID
  void configureApi({String? baseUrl, String? touristId}) {
    ApiService.updateConfig(
      baseUrl: baseUrl,
      touristId: touristId,
    );
  }

  // GET Methods with access token
  Future<Map<String, dynamic>> getUserProfile() async {
    await updateApiToken(); // Ensure token is current
    return await _apiService.getUserProfile();
  }

  Future<Map<String, dynamic>> getLocationHistory({
    String? startDate,
    String? endDate,
    int? limit,
  }) async {
    await updateApiToken();
    return await _apiService.getLocationHistory(
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }

  Future<Map<String, dynamic>> getSafetyAlerts({
    double? latitude,
    double? longitude,
    double? radius,
  }) async {
    await updateApiToken();
    return await _apiService.getSafetyAlerts(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );
  }

  Future<Map<String, dynamic>> getEmergencyContacts() async {
    await updateApiToken();
    return await _apiService.getEmergencyContacts();
  }

  Future<Map<String, dynamic>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    double radius = 5.0,
    String? type,
  }) async {
    await updateApiToken();
    return await _apiService.getNearbyPlaces(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
      type: type,
    );
  }

  // Generic GET method for custom endpoints
  Future<Map<String, dynamic>> makeGetRequest(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    await updateApiToken();
    return await _apiService.get(endpoint, queryParams: queryParams);
  }

  // Get tourist profile information
  String? get touristId {
    return _userProfile?['data']?['user']?['touristProfile']?['id'];
  }

  String? get digitalId {
    return _userProfile?['data']?['user']?['touristProfile']?['digitalId'];
  }

  String? get touristStatus {
    return _userProfile?['data']?['user']?['touristProfile']?['status'];
  }

  String? get touristStage {
    return _userProfile?['data']?['user']?['touristProfile']?['stage'];
  }

  int? get safetyScore {
    return _userProfile?['data']?['user']?['touristProfile']?['safetyScore'];
  }

  String? get kycStatus {
    return _userProfile?['data']?['user']?['touristProfile']?['kycStatus'];
  }

  bool get isProfileComplete {
    return _userProfile?['data']?['user']?['touristProfile']?['profileComplete'] ?? false;
  }

  bool get isReadyForTracking {
    return _userProfile?['data']?['user']?['touristProfile']?['readyForTracking'] ?? false;
  }

  // Re-verify user account (useful for refreshing profile data)
  Future<Map<String, dynamic>> refreshUserProfile() async {
    final verificationResult = await _authService.verifyUserAccount();
    if (verificationResult["success"] == true) {
      _userProfile = verificationResult["data"];
      notifyListeners();
    }
    return verificationResult;
  }
  
  // Initialize auth state on app startup
  Future<void> initializeAuthState() async {
    // Don't notify listeners during initialization to prevent build-time errors
    _isLoading = true;
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _user = currentUser;
        
        // Try to get access token and user profile if available
        _accessToken = await _authService.getCurrentAccessToken();
        
        if (_accessToken != null) {
          // Try to refresh user profile data
          final verificationResult = await _authService.verifyUserAccount();
          if (verificationResult["success"] == true) {
            _userProfile = verificationResult["data"];
          }
        }
      }
    } catch (e) {
      _error = "Failed to initialize: $e";
    } finally {
      _isLoading = false;
      // Only notify listeners once at the end
      notifyListeners();
    }
  }
}