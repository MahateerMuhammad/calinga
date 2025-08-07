import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class FindCareScreen extends StatefulWidget {
  const FindCareScreen({Key? key}) : super(key: key);

  @override
  State<FindCareScreen> createState() => _FindCareScreenState();
}

class _FindCareScreenState extends State<FindCareScreen> {
  final _searchController = TextEditingController();
  String _selectedRole = 'All';
  double _maxDistance = 10.0;
  
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

  // Dummy data for caregivers
  final List<Map<String, dynamic>> _caregivers = [
    {
      'name': 'Sarah Johnson',
      'role': 'CNA',
      'rating': 4.8,
      'distance': 2.3,
      'hourlyRate': 25,
      'image': null,
    },
    {
      'name': 'Michael Chen',
      'role': 'RN',
      'rating': 4.9,
      'distance': 5.1,
      'hourlyRate': 45,
      'image': null,
    },
    {
      'name': 'Emily Rodriguez',
      'role': 'HHA',
      'rating': 4.7,
      'distance': 3.8,
      'hourlyRate': 22,
      'image': null,
    },
    {
      'name': 'David Kim',
      'role': 'PT',
      'rating': 4.6,
      'distance': 7.2,
      'hourlyRate': 50,
      'image': null,
    },
    {
      'name': 'Lisa Patel',
      'role': 'LVN',
      'rating': 4.9,
      'distance': 4.5,
      'hourlyRate': 35,
      'image': null,
    },
  ];

  List<Map<String, dynamic>> get filteredCaregivers {
    return _caregivers.where((caregiver) {
      // Filter by role
      if (_selectedRole != 'All' && caregiver['role'] != _selectedRole) {
        return false;
      }
      
      // Filter by distance
      if (caregiver['distance'] > _maxDistance) {
        return false;
      }
      
      // Filter by search text
      if (_searchController.text.isNotEmpty) {
        final searchText = _searchController.text.toLowerCase();
        final name = caregiver['name'].toLowerCase();
        final role = caregiver['role'].toLowerCase();
        
        if (!name.contains(searchText) && !role.contains(searchText)) {
          return false;
        }
      }
      
      return true;
    }).toList();
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
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search caregivers...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),
                
                // Filters
                Row(
                  children: [
                    // Role Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _roles.map((role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(role),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Distance Filter
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
                                  onChanged: (value) {
                                    setState(() {
                                      _maxDistance = value;
                                    });
                                  },
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
              ],
            ),
          ),
          
          // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredCaregivers.length} caregivers found',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text('Sort by: Distance'),
              ],
            ),
          ),
          
          // Caregiver List
          Expanded(
            child: filteredCaregivers.isEmpty
                ? const Center(
                    child: Text('No caregivers found matching your criteria'),
                  )
                : ListView.builder(
                    itemCount: filteredCaregivers.length,
                    itemBuilder: (context, index) {
                      final caregiver = filteredCaregivers[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile Image
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
                              
                              // Caregiver Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      caregiver['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      caregiver['role'],
                                      style: TextStyle(
                                        color: AppConstants.primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 16),
                                        const SizedBox(width: 4),
                                        Text('${caregiver['rating']}'),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.location_on, color: Colors.grey, size: 16),
                                        const SizedBox(width: 4),
                                        Text('${caregiver['distance']} miles'),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '\$${caregiver['hourlyRate']}/hour',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton(
                                          onPressed: () {
                                            // View profile
                                          },
                                          child: const Text('View Profile'),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () {
                                            // Book now
                                          },
                                          child: const Text('Book Now'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}