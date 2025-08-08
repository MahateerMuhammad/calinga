import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/constants.dart';
import '../../providers/location_provider.dart';
import '../../services/google_maps_service.dart';
import '../../widgets/google_map_widget.dart';
import '../../models/location_model.dart';
import 'booking_form_screen.dart';
import '../../utils/location_permissions.dart';

class FindCareScreen extends StatefulWidget {
  const FindCareScreen({super.key});

  @override
  State<FindCareScreen> createState() => _FindCareScreenState();
}

class _FindCareScreenState extends State<FindCareScreen> {
  final _searchController = TextEditingController();
  final GoogleMapsService _mapsService = GoogleMapsService();

  String _selectedRole = 'All';
  double _maxDistance = 10.0;
  double _minRate = 0.0;
  double _maxRate = 100.0;
  bool _showMap = true; // default to map view
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> _caregivers = [];
  LocationModel? _currentLocation;

  final List<String> _roles = [
    'All',
    'CNA',
    'LVN',
    'RN',
    'NP',
    'PT',
    'HHA',
    'Private Caregiver',
  ];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    // Ensure friendly permission flow
    final hasPermission = await LocationPermissions.requestPermissionWithDialog(
      context,
    );
    if (!hasPermission) {
      setState(() {
        _error = 'Location permission required to find nearby caregivers';
      });
      return;
    }

    await locationProvider.initializeLocation();

    if (locationProvider.hasValidLocation) {
      _currentLocation = locationProvider.currentLocation;
      await _searchCaregivers();
    } else {
      setState(() {
        _error = 'Unable to get your location';
      });
    }
  }

  Future<void> _searchCaregivers() async {
    if (_currentLocation == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final caregivers = await _mapsService.getNearbyCaregivers(
        centerLat: _currentLocation!.latitude,
        centerLon: _currentLocation!.longitude,
        radiusInKm: _maxDistance * 1.60934,
        role: _selectedRole == 'All' ? null : _selectedRole,
        minRate: _minRate > 0 ? _minRate : null,
        maxRate: _maxRate < 100 ? _maxRate : null,
        isAvailable: true,
      );

      final filteredCaregivers = caregivers.where((caregiver) {
        if (_searchController.text.isNotEmpty) {
          final searchText = _searchController.text.toLowerCase();
          final name = caregiver['name'].toString().toLowerCase();
          final role = caregiver['role'].toString().toLowerCase();
          final specializations =
              (caregiver['specializations'] as List<dynamic>?)
                  ?.map((s) => s.toString().toLowerCase())
                  .join(' ') ??
              '';
          if (!name.contains(searchText) &&
              !role.contains(searchText) &&
              !specializations.contains(searchText)) {
            return false;
          }
        }
        return true;
      }).toList();

      setState(() {
        _caregivers = filteredCaregivers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to search caregivers: $e';
        _isLoading = false;
      });
    }
  }

  void _onMarkerTap(Map<String, dynamic> caregiver) {
    _showCaregiverDetails(caregiver);
  }

  void _showCaregiverDetails(Map<String, dynamic> caregiver) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCaregiverDetailsSheet(caregiver),
    );
  }

  Widget _buildCaregiverDetailsSheet(Map<String, dynamic> caregiver) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey.shade200,
                        child: const Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              caregiver['name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              caregiver['role'] ?? 'Caregiver',
                              style: TextStyle(
                                color: AppConstants.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${caregiver['rating']?.toStringAsFixed(1) ?? 'N/A'}',
                                ),
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.grey,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  caregiver['formattedDistance'] ?? 'Unknown',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.attach_money, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        '\$${caregiver['hourlyRate']?.toStringAsFixed(0) ?? '0'}/hour',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    BookingFormScreen(caregiver: caregiver),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                          ),
                          child: const Text('Book Now'),
                        ),
                      ),
                    ],
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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Care'),
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search caregivers...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _searchCaregivers();
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) => _searchCaregivers(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: _roles
                            .map(
                              (role) => DropdownMenuItem<String>(
                                value: role,
                                child: Text(role),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                          _searchCaregivers();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Max Distance'),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: _maxDistance,
                                  min: 1,
                                  max: 50,
                                  divisions: 49,
                                  label: '${_maxDistance.round()} mi',
                                  onChanged: (value) =>
                                      setState(() => _maxDistance = value),
                                  onChangeEnd: (value) => _searchCaregivers(),
                                ),
                              ),
                              Text('${_maxDistance.round()} mi'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Min Rate (\$)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _minRate = double.tryParse(value) ?? 0.0;
                        },
                        onSubmitted: (value) => _searchCaregivers(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Max Rate (\$)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _maxRate = double.tryParse(value) ?? 100.0;
                        },
                        onSubmitted: (value) => _searchCaregivers(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_caregivers.length} caregivers found',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_currentLocation != null)
                  Text(
                    'Near ${_currentLocation!.address?.split(',').first ?? 'your location'}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (_showMap ? _buildMapView() : _buildListView()),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    if (_currentLocation == null)
      return const Center(child: Text('Location not available'));

    return GoogleMapWidget(
      initialLat: _currentLocation!.latitude,
      initialLng: _currentLocation!.longitude,
      initialZoom: 12.0,
      markers: _caregivers,
      onMarkerTap: _onMarkerTap,
      showControls: true,
    );
  }

  Widget _buildListView() {
    if (_caregivers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No caregivers found matching your criteria',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _caregivers.length,
      itemBuilder: (context, index) {
        final caregiver = _caregivers[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () => _showCaregiverDetails(caregiver),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey.shade200,
                    child: const Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          caregiver['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          caregiver['role'] ?? 'Caregiver',
                          style: TextStyle(
                            color: AppConstants.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${caregiver['rating']?.toStringAsFixed(1) ?? 'N/A'}',
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.location_on,
                              color: Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(caregiver['formattedDistance'] ?? 'Unknown'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${caregiver['hourlyRate']?.toStringAsFixed(0) ?? '0'}/hour',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (caregiver['specializations'] != null &&
                            (caregiver['specializations'] as List)
                                .isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            children:
                                (caregiver['specializations'] as List<dynamic>)
                                    .take(3)
                                    .map(
                                      (spec) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppConstants.primaryColor
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          spec.toString(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppConstants.primaryColor,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      OutlinedButton(
                        onPressed: () => _showCaregiverDetails(caregiver),
                        child: const Text('View'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  BookingFormScreen(caregiver: caregiver),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                        ),
                        child: const Text('Book'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
