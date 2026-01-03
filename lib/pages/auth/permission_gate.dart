import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:yatra_suraksha_app/pages/home/homepage.dart';
import 'package:yatra_suraksha_app/l10n/app_localizations.dart';
import '../../const/app_colors.dart';
import '../../backend/services/location_service.dart';

/// A permission gate that ensures location permissions and services are enabled
/// before allowing access to the main app. Monitors app lifecycle to re-check
/// permissions when the user returns to the app.
class PermissionGate extends StatefulWidget {
  const PermissionGate({super.key});

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate>
    with WidgetsBindingObserver {
  bool _isLocationServiceEnabled = false;
  bool _hasAlwaysPermission = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Add this widget as an observer to monitor app lifecycle
    WidgetsBinding.instance.addObserver(this);
    // Check permissions and services on startup
    _checkPermissionsAndServices();
  }

  @override
  void dispose() {
    // Remove the observer when disposing
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When the app is resumed (user returns to the app), re-check permissions
    if (state == AppLifecycleState.resumed) {
      _checkPermissionsAndServices();
    }
  }

  /// Check both location services and always permission status
  Future<void> _checkPermissionsAndServices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      // Check if always permission is granted
      bool alwaysPermission = await ph.Permission.locationAlways.isGranted;

      setState(() {
        _isLocationServiceEnabled = serviceEnabled;
        _hasAlwaysPermission = alwaysPermission;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLocationServiceEnabled = false;
        _hasAlwaysPermission = false;
        _isLoading = false;
      });
    }
  }

  /// Start automatic location tracking in the background
  void _startAutomaticLocationTracking() {
    // Start location tracking silently in the background
    LocationService().startLocationStream();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while checking permissions
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Checking permissions...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.primaryText,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    // If both location service and always permission are enabled, show main app
    if (_isLocationServiceEnabled && _hasAlwaysPermission) {
      // Start location tracking automatically in the background
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAutomaticLocationTracking();
      });
      return const Homepage();
    }

    // Otherwise, show the enable location screen
    return EnableLocationScreen(
      onPermissionsChanged: _checkPermissionsAndServices,
      isLocationServiceEnabled: _isLocationServiceEnabled,
      hasLocationAlwaysPermission: _hasAlwaysPermission,
    );
  }
}

/// EnableLocationScreen Widget
/// Shows when location permissions are not granted
/// Provides buttons to enable location services and app permissions
class EnableLocationScreen extends StatelessWidget {
  final VoidCallback onPermissionsChanged;
  final bool isLocationServiceEnabled;
  final bool hasLocationAlwaysPermission;

  const EnableLocationScreen({
    super.key,
    required this.onPermissionsChanged,
    required this.isLocationServiceEnabled,
    required this.hasLocationAlwaysPermission,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // App Logo or Icon
              Icon(
                Icons.location_on_outlined,
                size: 120,
                color: AppColors.primary,
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                'Location Access Required',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                'Yatra Suraksha needs location access to keep you safe during your travels. We require continuous location tracking to provide emergency assistance.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Permission Status
              _buildPermissionStatus(context),

              const SizedBox(height: 32),

              // Action Buttons
              _buildActionButtons(context),

              const SizedBox(height: 24),

              // Refresh Button
              OutlinedButton.icon(
                onPressed: onPermissionsChanged,
                icon: const Icon(Icons.refresh),
                label: Text(
                    AppLocalizations.of(context)?.checkAgain ?? 'Check Again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionStatus(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            l10n?.permissionStatus ?? 'Permission Status',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
          ),
          const SizedBox(height: 12),

          // Location Service Status
          _buildStatusRow(
            context,
            icon: Icons.location_searching,
            title: l10n?.locationServices ?? 'Location Services',
            isEnabled: isLocationServiceEnabled,
          ),

          const SizedBox(height: 8),

          // Always Permission Status
          _buildStatusRow(
            context,
            icon: Icons.security,
            title: l10n?.backgroundLocation ?? 'Background Location',
            isEnabled: hasLocationAlwaysPermission,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isEnabled,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isEnabled ? AppColors.success : AppColors.error,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primaryText,
                ),
          ),
        ),
        Icon(
          isEnabled ? Icons.check_circle : Icons.cancel,
          size: 20,
          color: isEnabled ? AppColors.success : AppColors.error,
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Location Services Button
        if (!isLocationServiceEnabled) ...[
          ElevatedButton.icon(
            onPressed: () => _openLocationSettings(context),
            icon: const Icon(Icons.settings_outlined),
            label: Text(AppLocalizations.of(context)?.enableLocationServices ??
                'Enable Location Services'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // App Permissions Button
        if (!hasLocationAlwaysPermission) ...[
          ElevatedButton.icon(
            onPressed: () => _openAppSettings(context),
            icon: const Icon(Icons.app_settings_alt_outlined),
            label: Text(AppLocalizations.of(context)?.enableAppPermissions ??
                'Enable App Permissions'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Open device location settings
  Future<void> _openLocationSettings(BuildContext context) async {
    try {
      bool opened = await Geolocator.openLocationSettings();

      if (!opened && context.mounted) {
        _showErrorSnackBar(
          context,
          'Unable to open location settings. Please enable location services manually in your device settings.',
        );
      }

      // Wait a bit before rechecking permissions
      Future.delayed(const Duration(milliseconds: 500), () {
        onPermissionsChanged();
      });
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(
          context,
          'Error opening location settings. Please enable location services manually.',
        );
      }
    }
  }

  /// Open app settings for permissions
  Future<void> _openAppSettings(BuildContext context) async {
    try {
      bool opened = await ph.openAppSettings();

      if (!opened && context.mounted) {
        _showErrorSnackBar(
          context,
          'Unable to open app settings. Please enable location permissions manually in your device settings.',
        );
      }

      // Wait a bit before rechecking permissions
      Future.delayed(const Duration(milliseconds: 500), () {
        onPermissionsChanged();
      });
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(
          context,
          'Error opening app settings. Please enable location permissions manually.',
        );
      }
    }
  }

  /// Show error message to user
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
