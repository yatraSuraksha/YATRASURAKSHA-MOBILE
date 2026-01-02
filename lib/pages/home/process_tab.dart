import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../backend/providers/location_provider.dart';

class ProcessTab extends StatefulWidget {
  const ProcessTab({super.key});

  @override
  State<ProcessTab> createState() => _ProcessTabState();
}

class _ProcessTabState extends State<ProcessTab> {
  GoogleMapController? _mapController;
  double baseRadius = 300; // meters
  double currentZoom = 15;

  // Points you want to show circles around
  final List<LatLng> points = [
    LatLng(16.5653918, 81.5215735),
    LatLng(16.5763918, 81.5215735),
    LatLng(17.3800, 78.4800),
  ];

  Set<Circle> circles = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);
      await locationProvider.getCurrentLocation();

      // Initialize circles with base radius
      setState(() {
        circles = points.map((point) {
          return Circle(
            circleId: CircleId(point.toString()),
            center: point,
            radius: baseRadius,
            fillColor: Colors.red.withOpacity(0.4),
            strokeColor: Colors.red,
            strokeWidth: 3,
          );
        }).toSet();
      });
    });
  }

  // Adjust circle radius based on zoom level
  void _onCameraMove(CameraPosition position) {
    currentZoom = position.zoom;

    setState(() {
      circles = points.map((point) {
        return Circle(
          circleId: CircleId(point.toString()),
          center: point,
          radius: baseRadius * (15 / currentZoom), // keep approx same size
          fillColor: Colors.red.withOpacity(0.4),
          strokeColor: Colors.red,
          strokeWidth: 3,
        );
      }).toSet();
    });
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
            : GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(locationProvider.latitude ?? 1,
                      locationProvider.longitude ?? 1),
                  zoom: 15,
                ),
                onMapCreated: (controller) => _mapController = controller,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                circles: circles,
                onCameraMove: _onCameraMove,
              ),
      ),
    );
  }
}