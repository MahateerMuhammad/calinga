import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../services/google_maps_service.dart';
import '../models/location_model.dart';

class GoogleMapWidget extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final double initialZoom;
  final List<Map<String, dynamic>> markers;
  final Function(Map<String, dynamic>)? onMarkerTap;
  final Function(LatLng)? onMapTap;
  final Function(CameraPosition)? onCameraMove;
  final bool showUserLocation;
  final bool showControls;
  final double? height;
  final double? width;

  const GoogleMapWidget({
    Key? key,
    required this.initialLat,
    required this.initialLng,
    this.initialZoom = 15.0,
    required this.markers,
    this.onMarkerTap,
    this.onMapTap,
    this.onCameraMove,
    this.showUserLocation = true,
    this.showControls = true,
    this.height,
    this.width,
  }) : super(key: key);

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  GoogleMapController? _mapController;
  final GoogleMapsService _mapsService = GoogleMapsService();
  Set<Marker> _markers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  @override
  void didUpdateWidget(GoogleMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markers != widget.markers) {
      _createMarkers();
    }
  }

  void _createMarkers() async {
    Set<Marker> markers = {};
    
    for (Map<String, dynamic> caregiver in widget.markers) {
      try {
        BitmapDescriptor icon = await _mapsService.createCustomMarkerIcon(
          role: caregiver['role'] ?? 'Caregiver',
          isAvailable: caregiver['isAvailable'] ?? false,
        );

        markers.add(Marker(
          markerId: MarkerId(caregiver['id']),
          position: LatLng(caregiver['latitude'], caregiver['longitude']),
          icon: icon,
          infoWindow: InfoWindow(
            title: caregiver['name'] ?? 'Unknown',
            snippet: _buildMarkerSnippet(caregiver),
          ),
          onTap: () => widget.onMarkerTap?.call(caregiver),
        ));
      } catch (e) {
        debugPrint('Error creating marker: $e');
        // Add default marker if custom icon fails
        markers.add(Marker(
          markerId: MarkerId(caregiver['id']),
          position: LatLng(caregiver['latitude'], caregiver['longitude']),
          infoWindow: InfoWindow(
            title: caregiver['name'] ?? 'Unknown',
            snippet: _buildMarkerSnippet(caregiver),
          ),
          onTap: () => widget.onMarkerTap?.call(caregiver),
        ));
      }
    }

    setState(() {
      _markers = markers;
      _isLoading = false;
    });
  }

  String _buildMarkerSnippet(Map<String, dynamic> caregiver) {
    List<String> info = [];
    
    if (caregiver['role'] != null) {
      info.add(caregiver['role']);
    }
    
    if (caregiver['formattedDistance'] != null) {
      info.add(caregiver['formattedDistance']);
    }
    
    if (caregiver['hourlyRate'] != null) {
      info.add('\$${caregiver['hourlyRate'].toStringAsFixed(0)}/hr');
    }

    return info.join(' • ');
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onCameraMove(CameraPosition position) {
    widget.onCameraMove?.call(position);
  }

  void _onMapTap(LatLng position) {
    widget.onMapTap?.call(position);
  }

  Future<void> _animateToUserLocation() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    
    if (locationProvider.hasValidLocation && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(
            locationProvider.currentLocation!.latitude,
            locationProvider.currentLocation!.longitude,
          ),
        ),
      );
    } else {
      // Show snackbar if location is not available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to get your current location'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _animateToBounds() async {
    if (widget.markers.isEmpty || _mapController == null) return;

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (Map<String, dynamic> marker in widget.markers) {
      double lat = marker['latitude'];
      double lng = marker['longitude'];
      
      minLat = min(minLat, lat);
      maxLat = max(maxLat, lat);
      minLng = min(minLng, lng);
      maxLng = max(maxLng, lng);
    }

    // Add padding to bounds
    double latPadding = (maxLat - minLat) * 0.1;
    double lngPadding = (maxLng - minLng) * 0.1;

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - latPadding, minLng - lngPadding),
          northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
        ),
        50.0, // padding
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: widget.width,
      child: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.initialLat, widget.initialLng),
              zoom: widget.initialZoom,
            ),
            markers: _markers,
            onTap: _onMapTap,
            onCameraMove: _onCameraMove,
            myLocationEnabled: widget.showUserLocation,
            myLocationButtonEnabled: false, // We'll add custom button
            zoomControlsEnabled: false, // We'll add custom controls
            mapToolbarEnabled: false,
            compassEnabled: true,
            trafficEnabled: false,
            indoorViewEnabled: false,
            buildingsEnabled: true,
            tiltGesturesEnabled: true,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
          ),
          
          // Custom controls
          if (widget.showControls) ...[
            // Location button
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton.small(
                onPressed: _animateToUserLocation,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                child: const Icon(Icons.my_location),
              ),
            ),
            
            // Fit bounds button (if there are markers)
            if (widget.markers.isNotEmpty)
              Positioned(
                top: 80,
                right: 16,
                child: FloatingActionButton.small(
                  onPressed: _animateToBounds,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  child: const Icon(Icons.fit_screen),
                ),
              ),
            
            // Zoom controls
            Positioned(
              top: widget.markers.isNotEmpty ? 144 : 80,
              right: 16,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    onPressed: () {
                      _mapController?.animateCamera(
                        CameraUpdate.zoomIn(),
                      );
                    },
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    onPressed: () {
                      _mapController?.animateCamera(
                        CameraUpdate.zoomOut(),
                      );
                    },
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    child: const Icon(Icons.remove),
                  ),
                ],
              ),
            ),
          ],
          
          // Loading indicator
          if (_isLoading)
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          
          // Error indicator
          if (widget.markers.isEmpty && !_isLoading)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No caregivers found in this area',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
} 