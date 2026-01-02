import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yatra_suraksha_app/backend/providers/auth_provider.dart';
import 'package:yatra_suraksha_app/backend/providers/locale_provider.dart';
import 'package:yatra_suraksha_app/pages/auth/document_selection_page.dart';
import 'package:yatra_suraksha_app/pages/components/language_selection_widget.dart';
import 'package:yatra_suraksha_app/l10n/app_localizations.dart';
import '../../const/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  CustomAuthProvider? _authProvider;

  @override
  void initState() {
    super.initState();
    // Listen for authentication state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authProvider = Provider.of<CustomAuthProvider>(context, listen: false);

      // Check if user is already logged in
      if (_authProvider!.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DocumentSelectionPage(),
          ),
        );
        return;
      }

      // Add a listener to navigate when user is authenticated
      _authProvider!.addListener(_authStateListener);
    });
  }

  @override
  void dispose() {
    // Safely remove listener only if provider was initialized
    _authProvider?.removeListener(_authStateListener);
    super.dispose();
  }

  void _authStateListener() {
    // Use the stored provider reference instead of looking it up
    if (_authProvider == null || !mounted) return;

    // If user is logged in and not loading, navigate to document selection
    if (_authProvider!.user != null && !_authProvider!.isLoading && mounted) {
      // Use a small delay to ensure the widget tree is stable
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const DocumentSelectionPage(),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider for state changes (isLoading, user, error, etc.)
    final authProvider = context.watch<CustomAuthProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  // Language selection header
                  _buildLanguageHeader(),

                  // Main Content Section
                  Column(
                    children: [
                      _buildWelcomeSection(),
                      SizedBox(height: 20),
                      _buildLoginSection(context, authProvider),
                      const SizedBox(height: 30),
                      _buildFeaturesList(),
                      SizedBox(height: 20),

                      // Security Note
                      _buildSecurityNote(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 30),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.security_rounded,
            size: 18,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 16),
        Text(
          AppLocalizations.of(context)?.welcomeToSafeTravel ??
              'Welcome to Safe Travel',
          textAlign: TextAlign.left,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.of(context)?.trustedCompanionDescription ??
              'Your trusted companion for secure and monitored travel experiences. Join thousands of travelers who prioritize safety.',
          textAlign: TextAlign.start,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.secondaryText,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesList() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)?.whyChooseYatraSuraksha ??
                  'Why Choose Yatra Suraksha?',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),

            const SizedBox(height: 16),

            _buildFeatureItem(
              Icons.location_on_rounded,
              AppLocalizations.of(context)?.realTimeLocationTracking ??
                  'Real-time Location Tracking',
              AppLocalizations.of(context)?.stayConnectedWithLovedOnes ??
                  'Stay connected with your loved ones',
            ),

            _buildFeatureItem(
              Icons.shield_rounded,
              '${AppLocalizations.of(context)?.documents ?? 'Document'} ${AppLocalizations.of(context)?.verification ?? 'Verification'}',
              AppLocalizations.of(context)?.secureIdentityVerification ??
                  'Secure identity verification process',
            ),

            _buildFeatureItem(
              Icons.support_agent_rounded,
              AppLocalizations.of(context)?.emergencySupport247 ??
                  '24/7 Emergency Support',
              AppLocalizations.of(context)?.roundTheClockAssistance ??
                  'Round-the-clock assistance when needed',
            ),

            // _buildFeatureItem(
            //   Icons.verified_user_rounded,
            //   'Trusted Platform',
            //   'Government approved safety solution',
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginSection(
      BuildContext context, CustomAuthProvider authProvider) {
    return Column(
      children: [
        // const Text(
        //   'Get Started',
        //   style: TextStyle(
        //     fontSize: 20,
        //     fontWeight: FontWeight.bold,
        //     color: AppColors.primaryText,
        //   ),
        // ),

        // const SizedBox(height: 16),

        // Show loading or login button
        authProvider.isLoading
            ? Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)?.signingYouIn ??
                          'Signing you in...',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : _buildLoginButton(context),

        // Display Error if one occurred
        if (authProvider.error != null && !authProvider.isLoading)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      authProvider.error!,
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your privacy is protected. We use industry-standard security measures to keep your data safe.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The widget for the Login Button (matches your UI request)
  Widget _buildLoginButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        icon: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Image.asset(
            'assets/google.jpg',
            height: 26.0,
            width: 26.0,
          ),
        ),
        label: Text(
          (AppLocalizations.of(context)?.continueWithGoogle ??
                  "Continue with Google")
              .toUpperCase(),
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        onPressed: () async {
          // Use context.read inside a callback
          await context.read<CustomAuthProvider>().googleLogin();

          // Navigation will be handled by the listener
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black12,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(
              color: Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildLanguageHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, child) {
              return InkWell(
                onTap: () {
                  LanguageBottomSheet.show(context);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        L10n.getFlag(localeProvider.locale.languageCode),
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        L10n.getName(localeProvider.locale.languageCode),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
