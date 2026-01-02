import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yatra_suraksha_app/backend/services/places_service.dart';
import 'package:yatra_suraksha_app/const/app_theme.dart';

/// Enum to define the type of places to display
enum PlaceType { hospital, police }

/// Enhanced Page to display nearby hospitals or police stations
/// with both List View and Map View
class NearbyPlacesPage extends StatefulWidget {
  final PlaceType placeType;
  final Position? userPosition;

  const NearbyPlacesPage({
    super.key,
    required this.placeType,
    this.userPosition,
  });

  @override
  State<NearbyPlacesPage> createState() => _NearbyPlacesPageState();
}

class _NearbyPlacesPageState extends State<NearbyPlacesPage>
    with SingleTickerProviderStateMixin {
  final PlacesService _placesService = PlacesService();
  List<NearbyPlace> _places = [];
  bool _isLoading = true;
  String? _error;
  Position? _currentPosition;

  // Map related variables
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  NearbyPlace? _selectedPlace;

  // Tab controller for switching views
  late TabController _tabController;

  // Stream subscription for location updates
  StreamSubscription<Position>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadPlaces();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _mapController?.dispose();
    _positionSubscription?.cancel();
    super.dispose();
  }

  void _onTabChanged() {
    // Tab change handler - can be used for analytics or state management
    setState(() {});
  }

  /// Start listening for real-time location updates
  void _startLocationUpdates() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50, // Update every 50 meters
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      setState(() {
        _currentPosition = position;
      });
      _updateUserMarker();
    });
  }

  /// Update user marker on the map
  void _updateUserMarker() {
    if (_currentPosition == null) return;

    setState(() {
      // Remove old user marker and add new one
      _markers
          .removeWhere((marker) => marker.markerId.value == 'user_location');
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'You are here',
          ),
          zIndex: 2,
        ),
      );
    });
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use provided position or get current location
      _currentPosition = widget.userPosition;
      if (_currentPosition == null) {
        _currentPosition = await _getCurrentPosition();
      }

      if (_currentPosition == null) {
        setState(() {
          _error =
              'Unable to get your location. Please enable location services.';
          _isLoading = false;
        });
        return;
      }

      // Fetch places based on type
      List<NearbyPlace> places;
      if (widget.placeType == PlaceType.hospital) {
        places = await _placesService.getNearbyHospitals(_currentPosition!);
      } else {
        places =
            await _placesService.getNearbyPoliceStations(_currentPosition!);
      }

      setState(() {
        _places = places;
        _isLoading = false;
      });

      // Generate markers after loading places
      _generateMarkers();
    } catch (e) {
      setState(() {
        _error = 'Failed to load nearby places. Please try again.';
        _isLoading = false;
      });
    }
  }

  /// Generate map markers for all places and user location
  void _generateMarkers() {
    if (_currentPosition == null) return;

    final Set<Marker> markers = {};

    // Add user location marker
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position:
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(
          title: 'Your Location',
          snippet: 'You are here',
        ),
        zIndex: 2,
      ),
    );

    // Add place markers
    for (int i = 0; i < _places.length; i++) {
      final place = _places[i];
      markers.add(
        Marker(
          markerId: MarkerId(place.id),
          position: LatLng(place.latitude, place.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            widget.placeType == PlaceType.hospital
                ? BitmapDescriptor.hueRed
                : BitmapDescriptor.hueBlue,
          ),
          infoWindow: InfoWindow(
            title: place.name,
            snippet: '${place.formattedDistance} away',
            onTap: () => _showPlaceDetails(place),
          ),
          onTap: () => _onMarkerTapped(place),
          zIndex: 1,
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _onMarkerTapped(NearbyPlace place) {
    setState(() {
      _selectedPlace = place;
    });
  }

  void _showPlaceDetails(NearbyPlace place) {
    setState(() {
      _selectedPlace = place;
    });
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  String get _pageTitle {
    return widget.placeType == PlaceType.hospital
        ? 'Nearby Hospitals'
        : 'Nearby Police Stations';
  }

  IconData get _placeIcon {
    return widget.placeType == PlaceType.hospital
        ? Icons.local_hospital
        : Icons.local_police;
  }

  Color get _themeColor {
    return widget.placeType == PlaceType.hospital ? Colors.red : Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: _themeColor,
        foregroundColor: Colors.white,
        title: Text(
          _pageTitle,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlaces,
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _centerOnUserLocation,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: _themeColor,
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              labelColor: _themeColor,
              unselectedLabelColor: Colors.white,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.list, size: 20),
                  text: 'List View',
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
                Tab(
                  icon: Icon(Icons.map, size: 20),
                  text: 'Map View',
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _themeColor),
            const SizedBox(height: 16),
            Text(
              'Finding nearby ${widget.placeType == PlaceType.hospital ? 'hospitals' : 'police stations'}...',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadPlaces,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _themeColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Try Again',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_places.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _placeIcon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No ${widget.placeType == PlaceType.hospital ? 'hospitals' : 'police stations'} found nearby',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildListView(),
        _buildMapView(),
      ],
    );
  }

  /// Build the list view of places
  Widget _buildListView() {
    return RefreshIndicator(
      onRefresh: _loadPlaces,
      color: _themeColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _places.length,
        itemBuilder: (context, index) {
          return _buildPlaceCard(_places[index]);
        },
      ),
    );
  }

  /// Build the map view with markers
  Widget _buildMapView() {
    if (_currentPosition == null) {
      return const Center(
        child: Text('Unable to load map. Location not available.'),
      );
    }

    return Stack(
      children: [
        // Google Map
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target:
                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 14,
          ),
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          zoomGesturesEnabled: true,
          scrollGesturesEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: true,
          compassEnabled: true,
          mapToolbarEnabled: true,
          onTap: (_) {
            // Deselect place when tapping on map
            setState(() {
              _selectedPlace = null;
            });
          },
        ),

        // Map Legend
        Positioned(
          top: 16,
          left: 16,
          child: _buildMapLegend(),
        ),

        // Selected place info card
        if (_selectedPlace != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildSelectedPlaceCard(_selectedPlace!),
          ),

        // Places count badge
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_placeIcon, size: 16, color: _themeColor),
                const SizedBox(width: 6),
                Text(
                  '${_places.length} found',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _themeColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build map legend widget
  Widget _buildMapLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Legend',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.blue[300],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Your Location',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _themeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.placeType == PlaceType.hospital
                    ? 'Hospital'
                    : 'Police Station',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build selected place info card for map view
  Widget _buildSelectedPlaceCard(NearbyPlace place) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _placeIcon,
                  color: _themeColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      place.address,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedPlace = null;
                  });
                },
                iconSize: 20,
                color: Colors.grey[400],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoBadge(
                icon: Icons.directions_walk,
                label: place.formattedDistance,
                color: _themeColor,
              ),
              const SizedBox(width: 8),
              if (place.rating != null)
                _buildInfoBadge(
                  icon: Icons.star,
                  label: place.rating!.toStringAsFixed(1),
                  color: Colors.amber,
                ),
              const SizedBox(width: 8),
              if (place.isOpen != null)
                _buildInfoBadge(
                  icon: place.isOpen! ? Icons.check_circle : Icons.cancel,
                  label: place.isOpen! ? 'Open' : 'Closed',
                  color: place.isOpen! ? Colors.green : Colors.red,
                ),
              const Spacer(),
              if (place.phoneNumber != null && place.phoneNumber!.isNotEmpty)
                Text(
                  place.phoneNumber!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.phone,
                  label: 'Call',
                  color: Colors.green,
                  onTap: () => _makeCall(place.phoneNumber),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.directions,
                  label: 'Directions',
                  color: Colors.blue,
                  onTap: () => _openMaps(place),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.near_me,
                  label: 'Focus',
                  color: _themeColor,
                  onTap: () => _focusOnPlace(place),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _centerOnUserLocation() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15,
        ),
      );
    }
  }

  void _focusOnPlace(NearbyPlace place) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(place.latitude, place.longitude),
          17,
        ),
      );
    }
  }

  Widget _buildPlaceCard(NearbyPlace place) {
    return GestureDetector(
      onTap: () {
        // Switch to map view and focus on this place
        _tabController.animateTo(1);
        Future.delayed(const Duration(milliseconds: 300), () {
          _onMarkerTapped(place);
          _focusOnPlace(place);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Main card content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon container
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _themeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _placeIcon,
                      color: _themeColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                place.address,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            // Distance badge
                            _buildInfoBadge(
                              icon: Icons.directions_walk,
                              label: place.formattedDistance,
                              color: _themeColor,
                            ),
                            // Rating badge
                            if (place.rating != null)
                              _buildInfoBadge(
                                icon: Icons.star,
                                label: place.rating!.toStringAsFixed(1),
                                color: Colors.amber,
                              ),
                            // Open/Closed badge
                            if (place.isOpen != null)
                              _buildInfoBadge(
                                icon: place.isOpen!
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                label: place.isOpen! ? 'Open' : 'Closed',
                                color:
                                    place.isOpen! ? Colors.green : Colors.red,
                              ),
                          ],
                        ),
                        // Phone number
                        if (place.phoneNumber != null &&
                            place.phoneNumber!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                place.phoneNumber!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // View on map icon
                  IconButton(
                    icon: Icon(
                      Icons.map_outlined,
                      color: _themeColor,
                    ),
                    onPressed: () {
                      _tabController.animateTo(1);
                      Future.delayed(const Duration(milliseconds: 300), () {
                        _onMarkerTapped(place);
                        _focusOnPlace(place);
                      });
                    },
                    tooltip: 'View on map',
                  ),
                ],
              ),
            ),
            // Action buttons
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.phone,
                      label: 'Call',
                      color: Colors.green,
                      onTap: () => _makeCall(place.phoneNumber),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.directions,
                      label: 'Directions',
                      color: Colors.blue,
                      onTap: () => _openMaps(place),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.share,
                      label: 'Share',
                      color: Colors.orange,
                      onTap: () => _shareLocation(place),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _makeCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Phone number not available',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await FlutterPhoneDirectCaller.callNumber(phoneNumber);
    } catch (e) {
      // Fallback to URL launcher
      final Uri telUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      }
    }
  }

  Future<void> _openMaps(NearbyPlace place) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${_currentPosition!.latitude},${_currentPosition!.longitude}'
      '&destination=${place.latitude},${place.longitude}'
      '&travelmode=driving',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareLocation(NearbyPlace place) async {
    final text = '${place.name}\n${place.address}\n'
        '${place.phoneNumber != null ? 'Phone: ${place.phoneNumber}\n' : ''}'
        'https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}';

    // Show share options
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share Location',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Location info ready to share',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _themeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Copy to Clipboard',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
