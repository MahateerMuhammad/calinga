import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../utils/constants.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({Key? key}) : super(key: key);

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  String _selectedRole = 'CNA'; // Default role
  bool _isLoading = false;
  final Map<String, File?> _uploadedDocuments = {};

  // List of roles
  final List<String> _roles = [
    'CNA',
    'LVN',
    'RN',
    'NP',
    'PT',
    'HHA',
    'Private Caregiver',
  ];

  // Required documents per role
  final Map<String, List<String>> _requiredDocuments = {
    'CNA': [
      'California CNA Certificate (CDPH)',
      'CDPH License Verification',
      'Government ID / Real ID',
      'Proof of Address',
      'CPR/First Aid Cert',
      'Live Scan / DOJ Clearance',
      'Signed CALiNGA Independent Contractor Agreement',
    ],
    'LVN': [
      'California LVN License (BVNPT)',
      'BVNPT License Lookup',
      'Government ID / Real ID',
      'CPR Cert',
      'Live Scan / DOJ Clearance',
      'TB Test Results',
      'Proof of Work Authorization',
      'Signed CALiNGA Independent Contractor Agreement',
    ],
    'RN': [
      'California RN License (BRN)',
      'BRN License Lookup',
      'NPI Number',
      'CPR Cert (BLS/ACLS)',
      'Live Scan Background Check',
      'TB Test',
      'Government ID / Real ID',
      'Signed CALiNGA Independent Contractor Agreement',
    ],
    'NP': [
      'RN License',
      'NP Certification',
      'Furnishing Number',
      'NPI Number',
      'DEA Registration',
      'Malpractice Insurance',
      'CPR/BLS/ACLS Cert',
      'Live Scan / DOJ Clearance',
      'Government ID / Real ID',
      'Signed CALiNGA Independent Contractor Agreement',
    ],
    'PT': [
      'NPI Number',
      'CPR Cert',
      'Live Scan',
      'Government ID / Real ID',
      'Signed CALiNGA Independent Contractor Agreement',
    ],
    'Private Caregiver': [
      'CPR/First Aid (optional)',
      'Live Scan Fingerprinting',
      'TB Test or Health Screening',
      'Proof of Address',
      'Work Authorization (if non-US citizen)',
    ],
    'HHA': [
      'California HHA Certificate',
      'CNA License (Proof)',
      'Government ID / Real ID',
      'Proof of Address',
      'CPR/First Aid',
      'Live Scan / DOJ Clearance',
      'TB Test (within 1 year)',
      'Signed CALiNGA Independent Contractor Agreement',
    ],
  };

  @override
  void initState() {
    super.initState();
    _initializeDocumentMap();
  }

  void _initializeDocumentMap() {
    // Initialize all documents as null (not uploaded)
    for (final role in _roles) {
      for (final document in _requiredDocuments[role]!) {
        _uploadedDocuments['${role}_$document'] = null;
      }
    }
  }

  Future<void> _pickImage(String documentKey, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _uploadedDocuments[documentKey] = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _showImageSourceActionSheet(String documentKey) {
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
                  _pickImage(documentKey, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(documentKey, ImageSource.gallery);
                },
              ),
              if (_uploadedDocuments[documentKey] != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Document', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _uploadedDocuments[documentKey] = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadDocuments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, upload documents to Firebase Storage
      // For now, just show success message
      await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documents uploaded successfully')),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading documents: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Role Selection Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Select Role',
                      border: OutlineInputBorder(),
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
                  const SizedBox(height: 24),

                  // Required Documents Section
                  Text(
                    'Required Documents for $_selectedRole',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Document Upload List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _requiredDocuments[_selectedRole]!.length,
                    itemBuilder: (context, index) {
                      final document = _requiredDocuments[_selectedRole]![index];
                      final documentKey = '${_selectedRole}_$document';
                      final isUploaded = _uploadedDocuments[documentKey] != null;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(document),
                          subtitle: isUploaded
                              ? const Text(
                                  'Document uploaded',
                                  style: TextStyle(color: Colors.green),
                                )
                              : const Text(
                                  'Tap to upload',
                                  style: TextStyle(color: Colors.grey),
                                ),
                          leading: isUploaded
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : const Icon(Icons.upload_file),
                          trailing: isUploaded
                              ? IconButton(
                                  icon: const Icon(Icons.remove_red_eye),
                                  onPressed: () {
                                    // Show document preview
                                    showDialog(
                                      context: context,
                                      builder: (context) => Dialog(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            AppBar(
                                              title: Text(document),
                                              automaticallyImplyLeading: false,
                                              actions: [
                                                IconButton(
                                                  icon: const Icon(Icons.close),
                                                  onPressed: () => Navigator.pop(context),
                                                ),
                                              ],
                                            ),
                                            Image.file(
                                              _uploadedDocuments[documentKey]!,
                                              fit: BoxFit.contain,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : null,
                          onTap: () => _showImageSourceActionSheet(documentKey),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Upload Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _uploadDocuments,
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
                        : const Text('Upload Documents'),
                  ),
                ],
              ),
            ),
    );
  }
}