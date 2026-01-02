import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yatra_suraksha_app/backend/providers/auth_provider.dart';
import 'package:yatra_suraksha_app/pages/auth/permission_gate.dart';
import 'dart:async';
import '../../const/app_colors.dart';
import '../auth/document_selection_page.dart';
import '../auth/login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Defer the authentication check until after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthenticationAndNavigate();
    });
  }

  void _checkAuthenticationAndNavigate() async {
    try {
      // Wait a moment for the widget tree to stabilize
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted) return;
      
      // Get auth provider
      final authProvider = Provider.of<CustomAuthProvider>(context, listen: false);
      
      // Initialize auth state first
      await authProvider.initializeAuthState();
      
      // Wait for minimum splash screen time (but at least 1.5 seconds after initialization)
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (!mounted) return; // Check if widget is still mounted
      
      // Check authentication status and navigate accordingly
      if (authProvider.isFullyAuthenticated) {
        // User is fully authenticated with profile data, navigate to permission gate
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PermissionGate()),
          );
        }
      } else if (authProvider.isLoggedIn) {
        // User is logged in but missing profile data, navigate to document selection
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DocumentSelectionPage()),
          );
        }
      } else {
        // User is not logged in, navigate to login page
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      // In case of error, navigate to login screen as fallback
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              Icon(
                Icons.security_rounded,
                size: 100,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              const Text(
                'Yatra Suraksha',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Safe Travel, Secure Journey',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}