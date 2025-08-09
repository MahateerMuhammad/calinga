// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/user_model.dart';
import '../../utils/constants.dart';
import '../../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'careseeker_home.dart';

class CareseekerProfileScreen extends StatefulWidget {
  const CareseekerProfileScreen({super.key});

  @override
  State<CareseekerProfileScreen> createState() =>
      _CareseekerProfileScreenState();
}

class _CareseekerProfileScreenState extends State<CareseekerProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _medicalConditionsController = TextEditingController();

  bool _isLoading = false;
  File? _profileImage;
  UserModel? _userModel;
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emergencyContactController.dispose();
    _medicalConditionsController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      _userModel = await _authService.getCurrentUserData();
      if (_userModel != null) {
        _fullNameController.text = _userModel!.fullName;
        _ageController.text = _userModel!.age?.toString() ?? '';
        _addressController.text = _userModel!.address ?? '';
        _phoneController.text = _userModel!.phoneNumber;
        _emergencyContactController.text = _userModel!.emergencyContact ?? '';
        _medicalConditionsController.text = _userModel!.medicalConditions ?? '';
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_profileImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _profileImage = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _userModel == null) return;

    setState(() => _isLoading = true);

    try {
      // Update Firestore user document
      await _firestore.collection('users').doc(_userModel!.uid).set({
        'fullName': _fullNameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()),
        'address': _addressController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'emergencyContact': _emergencyContactController.text.trim(),
        'medicalConditions': _medicalConditionsController.text.trim(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const CareseekerHome()),
              (route) => false,
            );
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Image
                    GestureDetector(
                      onTap: _showImageSourceActionSheet,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                : null,
                            child: _profileImage == null
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppConstants.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Personal Info Section
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Full Name
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Please enter your full name'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Age
                    TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        prefixIcon: Icon(Icons.cake),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Address
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.home),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phone Number
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Please enter your phone number'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Medical Info Section
                    const Text(
                      'Medical Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Emergency Contact
                    TextFormField(
                      controller: _emergencyContactController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Emergency Contact',
                        prefixIcon: Icon(Icons.emergency),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Medical Conditions
                    TextFormField(
                      controller: _medicalConditionsController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Medical Conditions',
                        prefixIcon: Icon(Icons.medical_services),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Profile'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
