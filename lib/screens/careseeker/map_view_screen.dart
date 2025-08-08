import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/google_map_widget.dart';

class MapViewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> professionals;

  const MapViewScreen({Key? key, required this.professionals})
    : super(key: key);

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  bool _showLegend = true;
  final String _screenId = DateTime.now().millisecondsSinceEpoch.toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90E2),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Row(
          children: [
            Icon(Icons.map, size: 24),
            SizedBox(width: 8),
            Text(
              'Map View',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _refreshMap();
            },
          ),
        ],
      ),
      body: Consumer<LocationProvider>(
        builder: (context, locationProvider, child) {
          if (!locationProvider.hasValidLocation) {
            return Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Getting your location...',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          if (locationProvider.error != null) {
            return Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_off,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      locationProvider.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        locationProvider.initializeLocation();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Stack(
            children: [
              // Map Widget with unique ID
              GoogleMapWidget(
                mapId: 'main_map_$_screenId',
                initialLat: locationProvider.currentLocation!.latitude,
                initialLng: locationProvider.currentLocation!.longitude,
                initialZoom: 13.0,
                markers: widget.professionals,
                showUserLocation: true,
                showControls: false, // We'll add custom controls
                onMarkerTap: (professional) {
                  _showProfessionalBottomSheet(professional);
                },
              ),

              // Legend
              if (_showLegend)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Legend',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showLegend = false;
                                });
                              },
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildLegendItem(Colors.blue, 'Your Location'),
                        const SizedBox(height: 8),
                        _buildLegendItem(Colors.green, 'Available CalingaPros'),
                        const SizedBox(height: 8),
                        _buildLegendItem(Colors.red, 'Busy CalingaPros'),
                      ],
                    ),
                  ),
                ),

              // Show Legend Button (when legend is hidden)
              if (!_showLegend)
                Positioned(
                  top: 16,
                  left: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'legend_btn_$_screenId',
                    onPressed: () {
                      setState(() {
                        _showLegend = true;
                      });
                    },
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 2,
                    child: const Icon(Icons.info_outline),
                  ),
                ),

              // Custom Map Controls
              Positioned(
                top: 16,
                right: 16,
                child: Column(
                  children: [
                    // My Location Button
                    FloatingActionButton.small(
                      heroTag: 'my_location_$_screenId',
                      onPressed: () {
                        locationProvider.updateCurrentLocation();
                      },
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      elevation: 2,
                      child: const Icon(Icons.my_location),
                    ),
                    const SizedBox(height: 8),
                    // Fit All Markers Button
                    if (widget.professionals.isNotEmpty)
                      FloatingActionButton.small(
                        heroTag: 'fit_markers_$_screenId',
                        onPressed: () {
                          // This functionality is handled by the map widget
                        },
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 2,
                        child: const Icon(Icons.fit_screen),
                      ),
                  ],
                ),
              ),

              // Refresh Button
              Positioned(
                bottom: 30,
                right: 16,
                child: FloatingActionButton(
                  heroTag: 'refresh_map_$_screenId',
                  onPressed: () {
                    _refreshMap();
                  },
                  backgroundColor: const Color(0xFF4A90E2),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  child: const Icon(Icons.refresh),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }

  void _showProfessionalBottomSheet(Map<String, dynamic> professional) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.7,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Professional Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blue[100],
                        backgroundImage: professional['profileImage'] != null
                            ? NetworkImage(professional['profileImage'])
                            : null,
                        child: professional['profileImage'] == null
                            ? Icon(Icons.person, size: 30, color: Colors.blue[600])
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              professional['name']?.toString() ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              professional['role']?.toString() ?? 'Caregiver',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: professional['isAvailable'] == true
                              ? Colors.green[100]
                              : Colors.red[100],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          professional['isAvailable'] == true ? 'Available' : 'Busy',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: professional['isAvailable'] == true
                                ? Colors.green[700]
                                : Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Details
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          Icons.location_on,
                          'Distance',
                          professional['formattedDistance']?.toString() ?? 'Unknown',
                        ),
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          Icons.star,
                          'Rating',
                          '${professional['rating']?.toStringAsFixed(1) ?? '0.0'} ⭐',
                        ),
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          Icons.attach_money,
                          'Rate',
                          '\$${professional['hourlyRate']?.toStringAsFixed(0) ?? '0'}/hr',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Navigate to professional profile
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.blue[600]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'View Profile',
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: professional['isAvailable'] == true
                              ? () {
                                  Navigator.pop(context);
                                  // Navigate to booking screen
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Book Now',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _refreshMap() {
    // Refresh location and reload data
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    locationProvider.updateCurrentLocation();
    
    // Trigger a rebuild of the widget
    setState(() {
      // This will cause the map to rebuild with fresh data
    });
  }
}