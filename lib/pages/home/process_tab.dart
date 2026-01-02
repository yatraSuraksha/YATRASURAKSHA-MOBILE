import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../backend/providers/location_provider.dart';
import '../../backend/services/azure_maps_service.dart';

class ProcessTab extends StatefulWidget {
  const ProcessTab({super.key});

  @override
  State<ProcessTab> createState() => _ProcessTabState();
}

class _ProcessTabState extends State<ProcessTab> {
  MapController? _mapController;
  double baseRadius = 300; // meters
  double currentZoom = 15;

  // Points you want to show circles around (danger zones)
  final List<LatLng> points = [
    LatLng(16.5653918, 81.5215735),
    LatLng(16.5763918, 81.5215735),
    LatLng(17.3800, 78.4800),
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);
      await locationProvider.getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // Calculate circle radius in meters based on zoom level
  // This keeps the circle visually consistent at different zoom levels
  double _getCircleRadius(double zoom) {
    return baseRadius * (15 / zoom);
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('S a f e t y  m a p'.toUpperCase()),
        automaticallyImplyLeading: false,
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: locationProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(
                        locationProvider.latitude ?? 1,
                        locationProvider.longitude ?? 1,
                      ),
                      initialZoom: currentZoom,
                      onPositionChanged: (position, hasGesture) {
                        if (position.zoom != null &&
                            position.zoom != currentZoom) {
                          setState(() {
                            currentZoom = position.zoom!;
                          });
                        }
                      },
                    ),
                    children: [
                      // Azure Maps Tile Layer
                      TileLayer(
                        urlTemplate: AzureMapsService.getTileUrl(),
                        userAgentPackageName: 'com.example.yatra_suraksha_app',
                        maxZoom: 19,
                      ),
                      // Circle Layer for danger zones
                      CircleLayer(
                        circles: points.map((point) {
                          return CircleMarker(
                            point: point,
                            radius: _getCircleRadius(currentZoom),
                            useRadiusInMeter: true,
                            color: Colors.red.withOpacity(0.4),
                            borderColor: Colors.red,
                            borderStrokeWidth: 3,
                          );
                        }).toList(),
                      ),
                      // User location marker
                      if (locationProvider.latitude != null &&
                          locationProvider.longitude != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                locationProvider.latitude!,
                                locationProvider.longitude!,
                              ),
                              width: 40,
                              height: 40,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.blue, width: 2),
                                ),
                                child: const Icon(
                                  Icons.my_location,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  // My Location Button
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.white,
                      onPressed: () {
                        if (locationProvider.latitude != null &&
                            locationProvider.longitude != null) {
                          _mapController?.move(
                            LatLng(
                              locationProvider.latitude!,
                              locationProvider.longitude!,
                            ),
                            15,
                          );
                        }
                      },
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  // Azure Maps Attribution
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '© Azure Maps',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
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
