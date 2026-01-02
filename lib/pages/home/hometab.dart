import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:yatra_suraksha_app/const/app_theme.dart';
import 'package:yatra_suraksha_app/l10n/app_localizations.dart';
import 'package:yatra_suraksha_app/pages/home/nearby_places_page.dart';
import 'package:yatra_suraksha_app/pages/home/first_aid_page.dart';
import 'package:yatra_suraksha_app/pages/home/sos_recording_screen.dart';
import 'package:yatra_suraksha_app/backend/services/sos_video_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Timer? _countdownTimer;
  int countdown = 0;

  // Location state
  Position? _currentPosition;
  String _currentAddress = "";
  bool _isLoadingLocation = true;
  StreamSubscription<Position>? _positionSubscription;

  // Emergency helpline numbers (India)
  static const String womenHelpline = '9963037812'; // Women Helpline
  static const String policeHelpline = '9963037812'; // Police
  static const String ambulanceHelpline = '9963037812'; // Ambulance
  static const String fireHelpline = '9963037812'; // Fire

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

  /// Initialize location and start listening for updates
  Future<void> _initializeLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentAddress =
              AppLocalizations.of(context)?.locationServicesDisabled ??
                  "Location services disabled";
          _isLoadingLocation = false;
        });
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentAddress =
                AppLocalizations.of(context)?.locationPermissionDenied ??
                    "Location permission denied";
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentAddress =
              AppLocalizations.of(context)?.locationPermissionDenied ??
                  "Location permission denied";
          _isLoadingLocation = false;
        });
        return;
      }

      // Get initial position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      // Get address from coordinates
      await _getAddressFromCoordinates(position);

      // Start listening for location updates
      _startLocationUpdates();
    } catch (e) {
      setState(() {
        _currentAddress = AppLocalizations.of(context)?.unableToGetLocation ??
            "Unable to get location";
        _isLoadingLocation = false;
      });
    }
  }

  /// Start listening for continuous location updates
  void _startLocationUpdates() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100, // Update every 100 meters
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      setState(() {
        _currentPosition = position;
      });
      _getAddressFromCoordinates(position);
    });
  }

  /// Get human-readable address from coordinates using reverse geocoding
  Future<void> _getAddressFromCoordinates(Position position) async {
    try {
      // Using OpenStreetMap Nominatim API for reverse geocoding (free, no API key needed)
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?'
        'lat=${position.latitude}&lon=${position.longitude}'
        '&format=json&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'YatraSurakshaApp'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];

        // Build a concise address string
        String cityName = address['city'] ??
            address['town'] ??
            address['village'] ??
            address['suburb'] ??
            address['county'] ??
            'Unknown';

        String country = address['country'] ?? '';

        setState(() {
          _currentAddress = '$cityName, $country';
          _isLoadingLocation = false;
        });
      } else {
        setState(() {
          _currentAddress = "Location detected";
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = "Location detected";
        _isLoadingLocation = false;
      });
    }
  }

  void startCountdown(int seconds) {
    _countdownTimer?.cancel();

    countdown = seconds;
    setState(() {});

    const oneSec = Duration(seconds: 1);
    _countdownTimer = Timer.periodic(oneSec, (Timer timer) {
      if (countdown == 0) {
        timer.cancel();
        _countdownTimer = null;
        _makeCall(policeHelpline);
      } else {
        if (mounted) {
          setState(() {
            countdown--;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(left: 24.0, top: 32, right: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dynamic Location Container
                  _buildLocationContainer(),
                  const SizedBox(height: 46),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.doubleTapToCall ??
                            "Double tap the button to Call",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Simple SOS Button
                      _buildSOSButton(),
                      const SizedBox(height: 40),

                      // Emergency Action Cards - Responsive Layout
                      SizedBox(
                        height: 130, // Reduced from 140 to 130
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          shrinkWrap: true,
                          children: [
                            _buildEmergencyActionCard(
                              title:
                                  AppLocalizations.of(context)?.feelingUnsafe ??
                                      "I am feeling unsafe",
                              icon: Icons.security_rounded,
                              color: Colors.pink,
                              onTap: () => _callWomenHelpline(),
                            ),
                            const SizedBox(width: 12), // Reduced from 20 to 12
                            _buildEmergencyActionCard(
                              title: AppLocalizations.of(context)
                                      ?.needMedicalHelp ??
                                  "Need Medical Help",
                              icon: Icons.local_hospital_outlined,
                              color: Colors.red,
                              onTap: () => _navigateToNearbyHospitals(),
                            ),
                            const SizedBox(width: 12), // Reduced from 20 to 12
                            _buildEmergencyActionCard(
                              title: AppLocalizations.of(context)
                                      ?.needPoliceHelp ??
                                  "Need Police Help",
                              icon: Icons.local_police_outlined,
                              color: Colors.blue,
                              onTap: () => _navigateToNearbyPoliceStations(),
                            ),
                            const SizedBox(width: 12), // Reduced from 20 to 12
                            _buildEmergencyActionCard(
                              title: AppLocalizations.of(context)?.hadInjury ??
                                  "I had an Injury",
                              icon: Icons.personal_injury_outlined,
                              color: Colors.teal,
                              onTap: () => _navigateToFirstAid(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),
                    ],
                  ),

                  // Emergency Contacts Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.emergencyContacts ??
                            "Emergency Contacts",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromARGB(221, 0, 4, 46),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildContactCard(
                        AppLocalizations.of(context)?.police ?? "Police",
                        "100",
                        "assets/images/contact1.jpg",
                        Icons.local_police_outlined,
                        true,
                        () => {
                          startCountdown(5),
                          _getConfirmation(
                              context,
                              AppLocalizations.of(context)?.police ?? "Police",
                              policeHelpline)
                        },
                      ),
                      _buildContactCard(
                        AppLocalizations.of(context)?.ambulance ?? "Ambulan..",
                        "108",
                        "assets/images/contact2.jpg",
                        Icons.local_hospital_outlined,
                        true,
                        () => _makeCall(ambulanceHelpline),
                      ),
                      _buildContactCard(
                        AppLocalizations.of(context)?.fire ?? "Fire",
                        "101",
                        "assets/images/contact3.jpg",
                        Icons.fire_extinguisher,
                        true,
                        () => _makeCall(fireHelpline),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildContactCard(
                        AppLocalizations.of(context)?.women ?? "Women",
                        "1091",
                        "assets/images/contact1.jpg",
                        Icons.woman,
                        true,
                        () => _makeCall(womenHelpline),
                      ),
                      _buildContactCard(
                        AppLocalizations.of(context)?.child ?? "Child",
                        "1098",
                        "assets/images/contact2.jpg",
                        Icons.child_care,
                        true,
                        () => _makeCall('1098'),
                      ),
                      _buildContactCard(
                        AppLocalizations.of(context)?.add ?? "Add",
                        "",
                        "assets/images/contact3.jpg",
                        Icons.add,
                        true,
                        () => _showAddContactDialog(context),
                      ),
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

  /// Build the dynamic location container at the top
  Widget _buildLocationContainer() {
    return GestureDetector(
      onTap: _initializeLocation, // Refresh location on tap
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: _isLoadingLocation
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.location_on_outlined,
                    size: 20, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)?.currentLocation ??
                      "Current Location",
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
                Text(
                  _currentAddress.isEmpty
                      ? (AppLocalizations.of(context)?.detectingLocation ??
                          "Detecting location...")
                      : _currentAddress,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.primaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!_isLoadingLocation)
            Icon(
              Icons.refresh,
              size: 18,
              color: Colors.grey[400],
            ),
        ],
      ),
    );
  }

  /// Build the main SOS button
  Widget _buildSOSButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        _showSOSDialog(context);
      },
      onDoubleTap: () {
        HapticFeedback.heavyImpact();
        _triggerEmergency(context);
      },
      child: Container(
        height: 180,
        width: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 255, 85, 83),
              Color.fromARGB(255, 240, 0, 0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(
            width: 10,
            color: const Color.fromARGB(255, 255, 131, 131),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 197, 197, 197).withAlpha(60),
              blurRadius: 30,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 25,
              spreadRadius: 8,
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 54, color: Colors.white),
            Text(
              'SOS',
              style: GoogleFonts.poppins(
                fontSize: 44,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build an emergency action card with gesture detection
  /// Responsive design to prevent overflow
  Widget _buildEmergencyActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    // Calculate responsive width based on screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth =
        (screenWidth - 48 - 60) / 2; // Account for padding and spacing
    final responsiveWidth = cardWidth.clamp(140.0, 180.0); // Min 140, max 180

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        width: responsiveWidth,
        padding: const EdgeInsets.all(16), // Reduced from 24 to 16
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14, // Reduced from 16 to 14
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryTextColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6), // Reduced from 8 to 6
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16, // Reduced from 18 to 16
                    color: color,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6), // Reduced from 8 to 6
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20, // Reduced from 24 to 20
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Navigation Methods ====================

  /// Call Women Helpline immediately
  void _callWomenHelpline() {
    HapticFeedback.heavyImpact();
    _showQuickCallDialog(
      title: 'Women Safety',
      message:
          'This will immediately call the Women Helpline (1091). Are you sure?',
      phoneNumber: womenHelpline,
      color: Colors.pink,
      icon: Icons.woman,
    );
  }

  /// Navigate to nearby hospitals page
  void _navigateToNearbyHospitals() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NearbyPlacesPage(
          placeType: PlaceType.hospital,
          userPosition: _currentPosition,
        ),
      ),
    );
  }

  /// Navigate to nearby police stations page
  void _navigateToNearbyPoliceStations() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NearbyPlacesPage(
          placeType: PlaceType.police,
          userPosition: _currentPosition,
        ),
      ),
    );
  }

  /// Navigate to first aid page
  void _navigateToFirstAid() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FirstAidPage(),
      ),
    );
  }

  /// Show quick call confirmation dialog
  void _showQuickCallDialog({
    required String title,
    required String message,
    required String phoneNumber,
    required Color color,
    required IconData icon,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _makeCall(phoneNumber);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Call Now',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== Existing Methods ====================

  Future<void> _makeCall(String phoneNumber) async {
    try {
      await FlutterPhoneDirectCaller.callNumber(phoneNumber);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to make call. Please dial $phoneNumber manually.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _getConfirmation(
      BuildContext context, String serviceName, String phoneNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emergency,
                  color: Colors.red,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Calling $serviceName in',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                countdown.toString(),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        _countdownTimer?.cancel();
                        _countdownTimer = null;
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _countdownTimer?.cancel();
                        _countdownTimer = null;
                        Navigator.of(context).pop();
                        _makeCall(phoneNumber);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Call Now',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactCard(String name, String relation, String imagePath,
      IconData? icon, bool isIcon, Function? onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (onTap != null) {
          onTap();
        }
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12, bottom: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 60,
              width: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 255, 255),
                shape: BoxShape.circle,
                border: Border.all(width: 2, color: AppTheme.primaryColor),
              ),
              child: isIcon
                  ? Icon(icon, size: 30, color: AppTheme.primaryColor)
                  : Text(
                      name.substring(0, 1).toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              relation,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSOSDialog(BuildContext context) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emergency,
                  color: Colors.red,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.emergencySOS,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.emergencySOSDescription,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _triggerEmergency(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.sendSOS,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddContactDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController relationController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_add,
                    color: AppTheme.primaryColor,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Add Emergency Contact',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)?.name ?? "Name",
                    labelStyle: GoogleFonts.poppins(
                      color: Colors.grey[600],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primaryColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: GoogleFonts.poppins(
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)?.contactNumber ??
                        "Contact Number",
                    labelStyle: GoogleFonts.poppins(
                      color: Colors.grey[600],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primaryColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: GoogleFonts.poppins(
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: relationController,
                  decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(context)?.relation ?? "Relation",
                    labelStyle: GoogleFonts.poppins(
                      color: Colors.grey[600],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primaryColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: GoogleFonts.poppins(
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameController.text.isNotEmpty &&
                              phoneController.text.isNotEmpty &&
                              relationController.text.isNotEmpty) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        color: Colors.white),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Emergency contact added successfully!',
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ],
                                ),
                                backgroundColor: AppTheme.primaryColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.error,
                                        color: Colors.white),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Please fill all fields',
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Add',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _triggerEmergency(BuildContext context) async {
    // Get video service
    final videoService = Provider.of<SOSVideoService>(context, listen: false);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    // Initialize camera and start recording IMMEDIATELY
    final cameraInitialized = await videoService.initialize();

    if (cameraInitialized) {
      // Start recording in parallel with making the call
      await Future.wait([
        videoService.startSOSRecording(),
        _makeCall(policeHelpline),
      ]);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Navigate to recording screen (recording already started)
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const SOSRecordingScreen(),
          ),
        );
      }

      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.emergencySOSSent,
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } else {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Failed to start camera. Calling emergency...',
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Still make the call even if camera fails
        await _makeCall(policeHelpline);
      }
    }
  }
}
