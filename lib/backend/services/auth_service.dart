// ignore_for_file: unused_field, unused_catch_clause, unused_local_variable
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_service.dart';

class AuthService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // Google Login
  Future<Map<String, dynamic>> googleLogin() async {
    try {
      // Ensure previous sessions are cleared
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();

      // Trigger Google authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        return {"response": "Google Sign-in cancelled"};
      }


      // Obtain authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Access token and ID token
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      // print("Access Token: $accessToken");
      // print("ID Token: $idToken");

      // Store the access token for API calls
      if (accessToken != null) {
        // Update the API service with the access token
        ApiService.updateConfig(authToken: accessToken);
      }

      // Create a new credential for Firebase Authentication
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      // Sign in to Firebase with the Google credentials
      final userCredential = await auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        return {"response": "Sign-in failed"};
      }

      // Optionally, you can send the accessToken to another API here
      // Example: await sendAccessTokenToBackend(accessToken);

      return {"response": userCredential.user};
    } catch (e) {
      // print("Error during Google sign-in: $e");
      return {"response": e.toString()};
    }
  }

  // Sign out
  Future<void> signout() async {
    try {
      await auth.signOut();
      await GoogleSignIn().signOut();
      // print("User signed out");
    } catch (e) {
      // print("Error during sign out: $e");
    }
  }

  // Get current access token
  Future<String?> getCurrentAccessToken() async {
    try {
      final user = auth.currentUser;
      if (user != null) {
        final idTokenResult = await user.getIdTokenResult();
        return idTokenResult.token;
      }
      return null;
    } catch (e) {
      // print("Error getting access token: $e");
      return null;
    }
  }

  // Update API service with current token
  Future<void> updateApiToken() async {
    final token = await getCurrentAccessToken();
    if (token != null) {
      ApiService.updateConfig(authToken: token);
    }
  }

  // Verify user account with backend API
  Future<Map<String, dynamic>> verifyUserAccount() async {
    try {
      
      final token = await getCurrentAccessToken();
      if (token == null) {
        return {"success": false, "error": "No access token available"};
      }
      
      final baseUrl =  'http://74.225.144.0:3000';
      final endpoint =  '/api/users/verify';
      final url = '$baseUrl$endpoint';
      
      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        
        try {
          final data = jsonDecode(response.body);
          // Pretty print the response JSON
          const encoder = JsonEncoder.withIndent('  ');
          final prettyJson = encoder.convert(data);
          
          // Extract tourist ID and configure API service
          if (data['success'] == true && data['data'] != null) {
            final userData = data['data']['user'];
            final touristProfile = userData?['touristProfile'];
            
            if (touristProfile != null && touristProfile['id'] != null) {
              final touristId = touristProfile['id'];
              
              // Configure API service with the tourist ID and base URL from environment
              final locationBaseUrl = dotenv.env['API_BASE_URL'] ?? 'http://74.225.144.0:3000';
              final locationEndpoint = dotenv.env['API_LOCATION_UPDATE_ENDPOINT'] ?? '/api/tracking/location/update/me';
              final fullLocationUrl = '$locationBaseUrl$locationEndpoint';
              
              ApiService.updateConfig(
                baseUrl: fullLocationUrl,
                touristId: touristId,
                authToken: token,
              );
            } else {
              // print("⚠️ Tourist profile or ID not found in response");
              // print("   Tourist profile: $touristProfile");
            }
          } else {
            // print("⚠️ API response indicates failure or missing data");
            // print("   Success flag: ${data['success']}");
            // print("   Data exists: ${data['data'] != null}");
          }
          
          // print("🔍 ═══════════════════════════════════════════════════════════");
          return {"success": true, "data": data};
          
        } catch (jsonError) {
          // print("❌ JSON parsing failed: $jsonError");
          // print("📄 Raw response body:");
          // print(response.body);
          // print("🔍 ═══════════════════════════════════════════════════════════");
          return {
            "success": false, 
            "error": "JSON parsing failed: $jsonError",
            "rawResponse": response.body
          };
        }
      } else {
        // print("❌ API call failed with status: ${response.statusCode}");
        // print("📄 Error response body:");
        // print(response.body);
        // print("📋 Response headers:");
        response.headers.forEach((key, value) {
          // print("   $key: $value");
        });
        // print("🔍 ═══════════════════════════════════════════════════════════");
        
        return {
          "success": false, 
          "error": "Verification failed with status: ${response.statusCode}",
          "statusCode": response.statusCode,
          "message": response.body,
          "headers": response.headers
        };
      }
    } catch (e, stackTrace) {
      // print("❌ Exception during user verification: $e");
      // print("📚 Stack trace:");
      // print(stackTrace);
      // print("🔍 ═══════════════════════════════════════════════════════════");
      
      return {"success": false, "error": "Exception: $e", "stackTrace": stackTrace.toString()};
    }
  }
}