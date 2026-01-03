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
import 'package:yatra_suraksha_app/backend/services/voice_recognition_service.dart';
import 'package:yatra_suraksha_app/backend/services/gemini_ai_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yatra_suraksha_app/backend/models/emergency_contact.dart';
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

  // Voice recognition and AI services
  final VoiceRecognitionService _voiceService = VoiceRecognitionService();
  final GeminiAIService _aiService = GeminiAIService();
  bool _isListeningForHelp = false;
  String _listeningStatus = '';

  // Emergency contacts storage
  List<EmergencyContact> _emergencyContacts = [];

  // Emergency helpline numbers (India)
  static const String womenHelpline = '9963037812'; // Women Helpline
  static const String policeHelpline = '9963037812'; // Police
  static const String ambulanceHelpline = '9963037812'; // Ambulance
  static const String fireHelpline = '9963037812'; // Fire

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _loadEmergencyContacts();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _positionSubscription?.cancel();
    _voiceService.dispose();
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

  /// Load emergency contacts from SharedPreferences
  Future<void> _loadEmergencyContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = prefs.getString('emergency_contacts');

      if (contactsJson != null) {
        final List<dynamic> decoded = json.decode(contactsJson);
        setState(() {
          _emergencyContacts =
              decoded.map((item) => EmergencyContact.fromJson(item)).toList();
        });
      }
    } catch (e) {
      print('Error loading emergency contacts: $e');
    }
  }

  /// Save emergency contacts to SharedPreferences
  Future<void> _saveEmergencyContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = json.encode(
        _emergencyContacts.map((contact) => contact.toJson()).toList(),
      );
      await prefs.setString('emergency_contacts', contactsJson);
    } catch (e) {
      print('Error saving emergency contacts: $e');
    }
  }

  /// Add a new emergency contact
  Future<void> _addEmergencyContact(EmergencyContact contact) async {
    setState(() {
      _emergencyContacts.add(contact);
    });
    await _saveEmergencyContacts();
  }

  /// Delete an emergency contact
  Future<void> _deleteEmergencyContact(int index) async {
    setState(() {
      _emergencyContacts.removeAt(index);
    });
    await _saveEmergencyContacts();
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
                      const SizedBox(height: 20),

                      // Voice-activated SOS Button
                      _buildVoiceSOSButton(),
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
                  // Emergency services - 3 per row layout
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
                        AppLocalizations.of(context)?.ambulance ?? "Ambulance",
                        "108",
                        "assets/images/contact2.jpg",
                        Icons.local_hospital_outlined,
                        true,
                        () => {
                          startCountdown(5),
                          _getConfirmation(
                              context, "Ambulance", ambulanceHelpline)
                        },
                      ),
                      _buildContactCard(
                        AppLocalizations.of(context)?.fire ?? "Fire",
                        "101",
                        "assets/images/contact3.jpg",
                        Icons.fire_extinguisher,
                        true,
                        () => {
                          startCountdown(5),
                          _getConfirmation(context, "Fire", fireHelpline)
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildContactCard(
                        AppLocalizations.of(context)?.women ?? "Women",
                        "1091",
                        "assets/images/contact1.jpg",
                        Icons.woman,
                        true,
                        () => {
                          startCountdown(5),
                          _getConfirmation(
                              context, "Women Helpline", womenHelpline)
                        },
                      ),
                      _buildContactCard(
                        AppLocalizations.of(context)?.child ?? "Child",
                        "1098",
                        "assets/images/contact2.jpg",
                        Icons.child_care,
                        true,
                        () => {
                          startCountdown(5),
                          _getConfirmation(context, "Child Helpline", '1098')
                        },
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
                  // User's saved emergency contacts
                  if (_emergencyContacts.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      "Your Contacts",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color.fromARGB(221, 0, 4, 46),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Display saved contacts in rows of 3
                    ..._buildContactRows(_emergencyContacts),
                  ],
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

  /// Build the voice-activated SOS button
  Widget _buildVoiceSOSButton() {
    return Column(
      children: [
        GestureDetector(
          onTap:
              _isListeningForHelp ? _stopVoiceListening : _startVoiceListening,
          child: Container(
            height: 80,
            width: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: _isListeningForHelp
                    ? [
                        const Color.fromARGB(255, 255, 152, 0),
                        const Color.fromARGB(255, 255, 87, 34),
                      ]
                    : [
                        const Color.fromARGB(255, 76, 175, 80),
                        const Color.fromARGB(255, 56, 142, 60),
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(
                width: 4,
                color: _isListeningForHelp
                    ? const Color.fromARGB(255, 255, 167, 38)
                    : const Color.fromARGB(255, 129, 199, 132),
              ),
              boxShadow: [
                BoxShadow(
                  color: (_isListeningForHelp ? Colors.orange : Colors.green)
                      .withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              _isListeningForHelp ? Icons.mic : Icons.mic_none,
              size: 36,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isListeningForHelp ? 'Listening...' : 'Tap to speak for help',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        if (_listeningStatus.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            _listeningStatus,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  /// Start listening for voice input
  Future<void> _startVoiceListening() async {
    setState(() {
      _isListeningForHelp = true;
      _listeningStatus = 'Initializing...';
    });

    try {
      HapticFeedback.mediumImpact();

      await _voiceService.startListening(
        onResult: (String recognizedText) async {
          setState(() {
            _listeningStatus = 'Processing: "$recognizedText"';
          });

          // Use Gemini AI to check if this is a help request
          final isHelp = await _aiService.isHelpRequest(recognizedText);

          if (isHelp) {
            // Trigger SOS
            setState(() {
              _listeningStatus = 'Emergency detected! Triggering SOS...';
              _isListeningForHelp = false;
            });

            HapticFeedback.heavyImpact();

            // Wait a moment for user to see the message
            await Future.delayed(const Duration(milliseconds: 500));

            // Trigger the emergency
            if (mounted) {
              _triggerEmergency(context);
            }
          } else {
            setState(() {
              _listeningStatus = 'No emergency detected';
              _isListeningForHelp = false;
            });

            // Clear status after 2 seconds
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() {
                  _listeningStatus = '';
                });
              }
            });
          }
        },
        onListeningStateChanged: (bool isListening) {
          if (mounted) {
            setState(() {
              _isListeningForHelp = isListening;
              if (isListening) {
                _listeningStatus = 'Speak now...';
              }
            });
          }
        },
      );
    } catch (e) {
      setState(() {
        _isListeningForHelp = false;
        _listeningStatus = 'Error: ${e.toString()}';
      });

      // Clear error after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _listeningStatus = '';
          });
        }
      });
    }
  }

  /// Stop voice listening
  Future<void> _stopVoiceListening() async {
    await _voiceService.stopListening();
    setState(() {
      _isListeningForHelp = false;
      _listeningStatus = 'Cancelled';
    });

    // Clear status after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _listeningStatus = '';
        });
      }
    });
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              relation,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppTheme.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a saved contact card with delete option
  Widget _buildSavedContactCard(EmergencyContact contact, int index) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _makeCall(contact.phoneNumber);
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showDeleteContactDialog(contact, index);
      },
      child: Container(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
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
                  child: Text(
                    contact.name.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                Positioned(
                  right: -2,
                  top: -2,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showDeleteContactDialog(contact, index);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(width: 2, color: Colors.white),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              contact.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              contact.relation,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppTheme.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build rows of contacts (3 per row)
  List<Widget> _buildContactRows(List<EmergencyContact> contacts) {
    List<Widget> rows = [];
    for (int i = 0; i < contacts.length; i += 3) {
      final end = (i + 3 < contacts.length) ? i + 3 : contacts.length;
      final rowContacts = contacts.sublist(i, end);

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int j = 0; j < rowContacts.length; j++)
                _buildSavedContactCard(rowContacts[j], i + j),
              // Add spacers for incomplete rows to maintain spacing
              for (int j = rowContacts.length; j < 3; j++)
                const SizedBox(width: 80),
            ],
          ),
        ),
      );
    }
    return rows;
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
                        onPressed: () async {
                          if (nameController.text.isNotEmpty &&
                              phoneController.text.isNotEmpty &&
                              relationController.text.isNotEmpty) {
                            // Create and save the contact
                            final newContact = EmergencyContact(
                              name: nameController.text.trim(),
                              phoneNumber: phoneController.text.trim(),
                              relation: relationController.text.trim(),
                            );

                            await _addEmergencyContact(newContact);

                            if (mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle,
                                          color: Colors.white),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Emergency contact added successfully!',
                                          style: GoogleFonts.poppins(),
                                        ),
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
                            }
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

  void _showDeleteContactDialog(EmergencyContact contact, int index) {
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
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Delete Contact',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete ${contact.name}?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
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
                      onPressed: () async {
                        await _deleteEmergencyContact(index);
                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.white),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Contact deleted successfully',
                                      style: GoogleFonts.poppins(),
                                    ),
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
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Delete',
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
        );
      },
    );
  }

  void _triggerEmergency(BuildContext context) async {
    try {
      debugPrint('🚨 SOS TRIGGERED');

      // Get video service
      final videoService = Provider.of<SOSVideoService>(context, listen: false);

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );

      debugPrint('📷 Initializing camera...');

      // Initialize camera with timeout
      final cameraInitialized = await videoService.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('❌ Camera initialization timeout');
          return false;
        },
      );

      debugPrint('📷 Camera initialized: $cameraInitialized');

      if (cameraInitialized) {
        debugPrint('🎥 Starting recording...');

        // Start recording first
        await videoService.startSOSRecording();

        debugPrint('📞 Making emergency call...');

        // Make call in parallel
        _makeCall(policeHelpline);

        // Close loading dialog
        if (mounted) Navigator.of(context).pop();

        debugPrint('📱 Navigating to recording screen...');

        // Navigate to recording screen
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
        debugPrint('❌ Camera initialization failed');

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
                    'Failed to start camera. Please check permissions. Calling emergency...',
                    style: GoogleFonts.poppins(),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 5),
            ),
          );

          // Still make the call even if camera fails
          await _makeCall(policeHelpline);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Emergency trigger error: $e');
      debugPrint('Stack trace: $stackTrace');

      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context, rootNavigator: true)
            .popUntil((route) => route.isFirst);
      }

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error: $e. Making emergency call...',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 5),
          ),
        );

        // Still make the call
        await _makeCall(policeHelpline);
      }
    }
  }
}
