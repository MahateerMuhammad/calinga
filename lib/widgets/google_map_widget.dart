// ignore_for_file: unused_import, use_super_parameters, deprecated_member_use, sized_box_for_whitespace

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
  final String? mapId; // Add unique map ID for hero tags

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
    this.mapId, // Make hero tags unique
  }) : super(key: key);

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> with AutomaticKeepAliveClientMixin {
  GoogleMapController? _mapController;
  final GoogleMapsService _mapsService = GoogleMapsService();
  Set<Marker> _markers = {};
  bool _isLoading = true;
  bool _mapCreated = false;

  // Keep alive to prevent recreation issues
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Delay marker creation to prevent buffer issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _createMarkers();
      }
    });
  }

  @override
  void didUpdateWidget(GoogleMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markers != widget.markers && _mapCreated) {
      _createMarkers();
    }
  }

  void _createMarkers() async {
    if (!mounted) return;
    
    Set<Marker> markers = {};
    
    // Process markers in batches to prevent buffer overflow
    const int batchSize = 5;
    for (int i = 0; i < widget.markers.length; i += batchSize) {
      if (!mounted) break;
      
      final batch = widget.markers.skip(i).take(batchSize);
      
      for (Map<String, dynamic> caregiver in batch) {
        try {
          // Use simpler default markers to avoid custom icon buffer issues
          BitmapDescriptor icon = caregiver['isAvailable'] == true 
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

          markers.add(Marker(
            markerId: MarkerId('marker_${caregiver['id']}_${widget.mapId ?? 'default'}'),
            position: LatLng(
              caregiver['latitude']?.toDouble() ?? 0.0,
              caregiver['longitude']?.toDouble() ?? 0.0,
            ),
            icon: icon,
            infoWindow: InfoWindow(
              title: caregiver['name']?.toString() ?? 'Unknown',
              snippet: _buildMarkerSnippet(caregiver),
            ),
            onTap: () => widget.onMarkerTap?.call(caregiver),
          ));
        } catch (e) {
          debugPrint('Error creating marker for ${caregiver['id']}: $e');
          // Skip problematic markers instead of crashing
          continue;
        }
      }
      
      // Small delay between batches to prevent buffer overload
      if (i + batchSize < widget.markers.length) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    if (mounted) {
      setState(() {
        _markers = markers;
        _isLoading = false;
      });
    }
  }

  String _buildMarkerSnippet(Map<String, dynamic> caregiver) {
    List<String> info = [];
    
    if (caregiver['role'] != null) {
      info.add(caregiver['role'].toString());
    }
    
    if (caregiver['formattedDistance'] != null) {
      info.add(caregiver['formattedDistance'].toString());
    }
    
    if (caregiver['hourlyRate'] != null) {
      final rate = caregiver['hourlyRate'];
      if (rate is num) {
        info.add('\$${rate.toStringAsFixed(0)}/hr');
      }
    }

    return info.join(' • ');
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!mounted) return;
    
    _mapController = controller;
    _mapCreated = true;
    
    // Style the map to reduce rendering load
    const String mapStyle = '''
    [
      {
        "featureType": "poi",
        "elementType": "labels",
        "stylers": [{"visibility": "off"}]
      },
      {
        "featureType": "transit",
        "elementType": "labels",
        "stylers": [{"visibility": "off"}]
      }
    ]
    ''';
    
    try {
      controller.setMapStyle(mapStyle);
    } catch (e) {
      debugPrint('Error setting map style: $e');
    }
  }

  void _onCameraMove(CameraPosition position) {
    widget.onCameraMove?.call(position);
  }

  void _onMapTap(LatLng position) {
    widget.onMapTap?.call(position);
  }

  Future<void> _animateToUserLocation() async {
    if (!_mapCreated || _mapController == null) return;
    
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    
    if (locationProvider.hasValidLocation) {
      try {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(
              locationProvider.currentLocation!.latitude,
              locationProvider.currentLocation!.longitude,
            ),
          ),
        );
      } catch (e) {
        debugPrint('Error animating to user location: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to navigate to your location'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to get your current location'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _animateToBounds() async {
    if (widget.markers.isEmpty || !_mapCreated || _mapController == null) return;

    try {
      double minLat = double.infinity;
      double maxLat = -double.infinity;
      double minLng = double.infinity;
      double maxLng = -double.infinity;

      for (Map<String, dynamic> marker in widget.markers) {
        double lat = marker['latitude']?.toDouble() ?? 0.0;
        double lng = marker['longitude']?.toDouble() ?? 0.0;
        
        if (lat != 0.0 && lng != 0.0) {
          minLat = min(minLat, lat);
          maxLat = max(maxLat, lat);
          minLng = min(minLng, lng);
          maxLng = max(maxLng, lng);
        }
      }

      if (minLat == double.infinity) return;

      // Add padding to bounds
      double latPadding = max((maxLat - minLat) * 0.1, 0.01);
      double lngPadding = max((maxLng - minLng) * 0.1, 0.01);

      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat - latPadding, minLng - lngPadding),
            northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
          ),
          100.0, // Increased padding
        ),
      );
    } catch (e) {
      debugPrint('Error animating to bounds: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final String uniqueId = widget.mapId ?? widget.hashCode.toString();
    
    return Container(
      height: widget.height,
      width: widget.width,
      child: Stack(
        children: [
          // Wrap GoogleMap in RepaintBoundary to isolate rendering
          RepaintBoundary(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.initialLat, widget.initialLng),
                zoom: widget.initialZoom,
              ),
              markers: _markers,
              onTap: _onMapTap,
              onCameraMove: _onCameraMove,
              myLocationEnabled: widget.showUserLocation,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
              trafficEnabled: false,
              indoorViewEnabled: false,
              buildingsEnabled: false, // Disable to reduce rendering load
              tiltGesturesEnabled: false, // Disable to reduce GPU load
              rotateGesturesEnabled: false, // Disable to reduce GPU load
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              liteModeEnabled: false, // Ensure full interactivity
            ),
          ),
          
          // Custom controls with unique hero tags
          if (widget.showControls && _mapCreated) ...[
            // Location button
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: 'location_btn_$uniqueId',
                onPressed: _animateToUserLocation,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 2,
                child: const Icon(Icons.my_location),
              ),
            ),
            
            // Fit bounds button (if there are markers)
            if (widget.markers.isNotEmpty)
              Positioned(
                top: 80,
                right: 16,
                child: FloatingActionButton.small(
                  heroTag: 'bounds_btn_$uniqueId',
                  onPressed: _animateToBounds,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 2,
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
                    heroTag: 'zoom_in_btn_$uniqueId',
                    onPressed: () {
                      _mapController?.animateCamera(CameraUpdate.zoomIn());
                    },
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 2,
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'zoom_out_btn_$uniqueId',
                    onPressed: () {
                      _mapController?.animateCamera(CameraUpdate.zoomOut());
                    },
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 2,
                    child: const Icon(Icons.remove),
                  ),
                ],
              ),
            ),
          ],
          
          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          
          // No markers message
          if (widget.markers.isEmpty && !_isLoading && _mapCreated)
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
    // Properly dispose of map controller
    _mapController?.dispose();
    _mapController = null;
    super.dispose();
  }
}