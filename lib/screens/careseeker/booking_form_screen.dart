import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking_model.dart';
import '../../services/google_maps_service.dart';
import '../../models/location_model.dart';
import '../../utils/constants.dart';

class BookingFormScreen extends StatefulWidget {
  final Map<String, dynamic> caregiver;
  const BookingFormScreen({super.key, required this.caregiver});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serviceTypeController = TextEditingController();
  final _specialReqController = TextEditingController();
  final _durationController = TextEditingController(text: '2');
  final _timezoneController = TextEditingController(text: 'UTC');

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _isSubmitting = false;
  final GoogleMapsService _mapsService = GoogleMapsService();
  LocationModel? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    _selectedLocation = await _mapsService.getCurrentLocation();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _serviceTypeController.dispose();
    _specialReqController.dispose();
    _durationController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a location')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;

      final booking = BookingModel(
        bookingId: '',
        careSeekerId: user.uid,
        caregiver: {
          'id': widget.caregiver['id'],
          'name': widget.caregiver['name'],
          'role': widget.caregiver['role'],
          'profileImage': widget.caregiver['profileImage'],
          'hourlyRate': widget.caregiver['hourlyRate'],
        },
        serviceDetails: {
          'type': _serviceTypeController.text.trim(),
          'specialization': widget.caregiver['role'] ?? 'Caregiver',
          'duration': int.tryParse(_durationController.text.trim()) ?? 2,
          'totalCost':
              (int.tryParse(_durationController.text.trim()) ?? 2) *
              (widget.caregiver['hourlyRate']?.toDouble() ?? 0.0),
        },
        schedule: {
          'date': _selectedDate,
          'startTime': _startTime!.format(context),
          'endTime': _endTime!.format(context),
          'timeZone': _timezoneController.text.trim(),
        },
        location: {
          'address': _selectedLocation!.address ?? 'Selected Location',
          'coordinates': {
            'latitude': _selectedLocation!.latitude,
            'longitude': _selectedLocation!.longitude,
          },
          'geohash': _selectedLocation!.generateGeohash(),
          'placeId': null,
          'estimatedTravelTime': 0,
        },
        status: 'pending',
        specialRequirements: _specialReqController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        rating: null,
        review: null,
      );

      final success = await Provider.of<BookingProvider>(
        context,
        listen: false,
      ).createBooking(booking);
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create booking: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Caregiver summary
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey.shade200,
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.caregiver['name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.caregiver['role'] ?? 'Caregiver',
                          style: TextStyle(color: AppConstants.primaryColor),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${(widget.caregiver['hourlyRate']?.toStringAsFixed(0) ?? '0')}/hr',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _serviceTypeController,
                decoration: const InputDecoration(
                  labelText: 'Service Type',
                  prefixIcon: Icon(Icons.medical_services),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter service type' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration (hours)',
                        prefixIcon: Icon(Icons.timer),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _timezoneController,
                      decoration: const InputDecoration(
                        labelText: 'Time Zone',
                        prefixIcon: Icon(Icons.public),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date & time pickers
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _selectedDate == null
                            ? 'Select Date'
                            : DateFormat('EEE, MMM d').format(_selectedDate!),
                      ),
                      onPressed: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _startTime == null
                            ? 'Start Time'
                            : _startTime!.format(context),
                      ),
                      onPressed: () => _pickTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _endTime == null
                            ? 'End Time'
                            : _endTime!.format(context),
                      ),
                      onPressed: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Location summary
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.location_on),
                title: Text(
                  _selectedLocation?.address ?? 'Using your current location',
                ),
                subtitle: _selectedLocation == null
                    ? const Text('Fetching location...')
                    : Text(
                        '${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                      ),
                trailing: IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: _initLocation,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _specialReqController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Special Requirements',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: AppConstants.primaryColor,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Confirm Booking'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
