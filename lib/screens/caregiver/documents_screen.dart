import 'package:flutter/material.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({Key? key}) : super(key: key);

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  String? _selectedRole;
  bool _showDropdown = false;
  final Map<String, bool> _uploadedDocuments = {};

  // List of roles with full names
  final List<Map<String, String>> _roles = [
    {'value': 'CNA', 'name': 'CNA - Certified Nursing Assistant'},
    {'value': 'LVN', 'name': 'LVN - Licensed Vocational Nurse'},
    {'value': 'RN', 'name': 'RN - Registered Nurse'},
    {'value': 'NP', 'name': 'NP - Nurse Practitioner'},
    {'value': 'PT', 'name': 'PT - Physical Therapist'},
    {'value': 'Private Caregiver', 'name': 'Private Caregiver'},
    {'value': 'HHA', 'name': 'HHA - Home Health Aide'},
  ];

  // Document lists for each role
  final Map<String, List<Map<String, String>>> _roleDocuments = {
    'CNA': [
      {
        'title': 'California CNA Certificate',
        'subtitle': 'Issued by CDPH (California Department of Public Health)',
        'key': 'cna_certificate',
      },
      {
        'title': 'CDPH License Verification',
        'subtitle': 'CDPH License Lookup Tool',
        'key': 'cdph_verification',
      },
      {
        'title': 'Government ID / Real ID',
        'subtitle': 'Valid government-issued identification',
        'key': 'government_id',
      },
      {
        'title': 'Proof of Address',
        'subtitle': 'Utility bill, lease agreement, or bank statement',
        'key': 'proof_address',
      },
      {
        'title': 'CPR/First Aid Certification',
        'subtitle': 'Current CPR and First Aid certification',
        'key': 'cpr_certification',
      },
      {
        'title': 'Live Scan / DOJ Clearance',
        'subtitle': 'Background check clearance',
        'key': 'live_scan',
      },
      {
        'title': 'CALiNGA Independent Contractor Agreement',
        'subtitle': 'Signed agreement document',
        'key': 'contractor_agreement',
      },
    ],
    'LVN': [
      {
        'title': 'California LVN License',
        'subtitle': 'Issued by BVNPT (Board of Vocational Nursing)',
        'key': 'lvn_license',
      },
      {
        'title': 'BVNPT License Lookup',
        'subtitle': 'License verification from BVNPT',
        'key': 'bvnpt_verification',
      },
      {
        'title': 'Government ID / Real ID',
        'subtitle': 'Valid government-issued identification',
        'key': 'government_id',
      },
      {
        'title': 'CPR Certification',
        'subtitle': 'Current CPR certification',
        'key': 'cpr_certification',
      },
      {
        'title': 'Live Scan / DOJ Clearance',
        'subtitle': 'Background check clearance',
        'key': 'live_scan',
      },
      {
        'title': 'TB Test Results',
        'subtitle': 'Tuberculosis test results (within 1 year)',
        'key': 'tb_test',
      },
      {
        'title': 'Proof of Work Authorization',
        'subtitle': 'Work authorization documentation',
        'key': 'work_authorization',
      },
      {
        'title': 'CALiNGA Independent Contractor Agreement',
        'subtitle': 'Signed agreement document',
        'key': 'contractor_agreement',
      },
    ],
    'RN': [
      {
        'title': 'California RN License',
        'subtitle': 'Issued by BRN (Board of Registered Nursing)',
        'key': 'rn_license',
      },
      {
        'title': 'BRN License Lookup',
        'subtitle': 'License verification from BRN',
        'key': 'brn_verification',
      },
      {
        'title': 'NPI Number',
        'subtitle': 'National Provider Identifier',
        'key': 'npi_number',
      },
      {
        'title': 'CPR Certification (BLS/ACLS)',
        'subtitle': 'Basic Life Support / Advanced Cardiac Life Support',
        'key': 'cpr_bls_acls',
      },
      {
        'title': 'Live Scan Background Check',
        'subtitle': 'Background check clearance',
        'key': 'live_scan',
      },
      {
        'title': 'TB Test',
        'subtitle': 'Tuberculosis test results (within 1 year)',
        'key': 'tb_test',
      },
      {
        'title': 'Government ID / Real ID',
        'subtitle': 'Valid government-issued identification',
        'key': 'government_id',
      },
      {
        'title': 'CALiNGA Independent Contractor Agreement',
        'subtitle': 'Signed agreement document',
        'key': 'contractor_agreement',
      },
    ],
    'NP': [
      {
        'title': 'RN License',
        'subtitle': 'Registered Nurse license',
        'key': 'rn_license',
      },
      {
        'title': 'NP Certification',
        'subtitle': 'Nurse Practitioner certification',
        'key': 'np_certification',
      },
      {
        'title': 'Furnishing Number',
        'subtitle': 'California furnishing number',
        'key': 'furnishing_number',
      },
      {
        'title': 'NPI Number',
        'subtitle': 'National Provider Identifier',
        'key': 'npi_number',
      },
      {
        'title': 'DEA Registration',
        'subtitle': 'Drug Enforcement Administration registration',
        'key': 'dea_registration',
      },
      {
        'title': 'Malpractice Insurance',
        'subtitle': 'Professional liability insurance',
        'key': 'malpractice_insurance',
      },
      {
        'title': 'CPR/BLS/ACLS Certification',
        'subtitle': 'CPR, Basic Life Support, Advanced Cardiac Life Support',
        'key': 'cpr_bls_acls',
      },
      {
        'title': 'Live Scan / DOJ Clearance',
        'subtitle': 'Background check clearance',
        'key': 'live_scan',
      },
      {
        'title': 'Government ID / Real ID',
        'subtitle': 'Valid government-issued identification',
        'key': 'government_id',
      },
      {
        'title': 'CALiNGA Independent Contractor Agreement',
        'subtitle': 'Signed agreement document',
        'key': 'contractor_agreement',
      },
    ],
    'PT': [
      {
        'title': 'NPI Number',
        'subtitle': 'National Provider Identifier',
        'key': 'npi_number',
      },
      {
        'title': 'CPR Certification',
        'subtitle': 'Current CPR certification',
        'key': 'cpr_certification',
      },
      {
        'title': 'Live Scan',
        'subtitle': 'Background check clearance',
        'key': 'live_scan',
      },
      {
        'title': 'Government ID / Real ID',
        'subtitle': 'Valid government-issued identification',
        'key': 'government_id',
      },
      {
        'title': 'CALiNGA Independent Contractor Agreement',
        'subtitle': 'Signed agreement document',
        'key': 'contractor_agreement',
      },
    ],
    'Private Caregiver': [
      {
        'title': 'CPR/First Aid (Optional)',
        'subtitle': 'CPR and First Aid certification',
        'key': 'cpr_first_aid',
      },
      {
        'title': 'Live Scan Fingerprinting',
        'subtitle': 'Background check clearance',
        'key': 'live_scan',
      },
      {
        'title': 'TB Test or Health Screening',
        'subtitle': 'Tuberculosis test or health screening',
        'key': 'tb_health_screening',
      },
      {
        'title': 'Proof of Address',
        'subtitle': 'Utility bill, lease agreement, or bank statement',
        'key': 'proof_address',
      },
      {
        'title': 'Work Authorization',
        'subtitle': 'Required if non-US citizen',
        'key': 'work_authorization',
      },
    ],
    'HHA': [
      {
        'title': 'California HHA Certificate',
        'subtitle': 'Home Health Aide certificate',
        'key': 'hha_certificate',
      },
      {
        'title': 'CNA License (Proof)',
        'subtitle': 'Certified Nursing Assistant license',
        'key': 'cna_license_proof',
      },
      {
        'title': 'Government ID / Real ID',
        'subtitle': 'Valid government-issued identification',
        'key': 'government_id',
      },
      {
        'title': 'Proof of Address',
        'subtitle': 'Utility bill, lease agreement, or bank statement',
        'key': 'proof_address',
      },
      {
        'title': 'CPR/First Aid',
        'subtitle': 'CPR and First Aid certification',
        'key': 'cpr_first_aid',
      },
      {
        'title': 'Live Scan / DOJ Clearance',
        'subtitle': 'Background check clearance',
        'key': 'live_scan',
      },
      {
        'title': 'TB Test',
        'subtitle': 'Tuberculosis test (within 1 year)',
        'key': 'tb_test',
      },
      {
        'title': 'CALiNGA Independent Contractor Agreement',
        'subtitle': 'Signed agreement document',
        'key': 'contractor_agreement',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    // Initialize some documents as uploaded for demo purposes
    _uploadedDocuments['cna_certificate'] = true;
    _uploadedDocuments['government_id'] = true;
  }

  void _uploadDocument(String key) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.blue),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _simulateUpload(key);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _simulateUpload(key);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Cancel'),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _simulateUpload(String key) {
    setState(() {
      _uploadedDocuments[key] = true;
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.medical_services,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Document uploaded successfully'),
          ],
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),

            // Title
            const Text(
              'CALiNGApro Compliance Documents',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E5BBA), // Original Blue
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              'Please select your role and upload the required documents to get qualified as a CALiNGApro.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // Select Your Role Section
            const Text(
              'Select Your Role:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E5BBA), // Original Blue
              ),
            ),
            const SizedBox(height: 16),

            // Role Dropdown
            GestureDetector(
              onTap: () {
                setState(() {
                  _showDropdown = !_showDropdown;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedRole == null
                          ? 'Select Role Type'
                          : _roles.firstWhere(
                              (role) => role['value'] == _selectedRole,
                            )['name']!,
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedRole == null
                            ? Colors.grey[600]
                            : Colors.black87,
                      ),
                    ),
                    Icon(
                      _showDropdown
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ),

            // Dropdown Options
            if (_showDropdown)
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: _roles.map((role) {
                    return ListTile(
                      title: Text(
                        role['name']!,
                        style: const TextStyle(fontSize: 16),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedRole = role['value'];
                          _showDropdown = false;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 32),

            // Required Documents Section
            if (_selectedRole != null &&
                _roleDocuments.containsKey(_selectedRole)) ...[
              const Text(
                'Required Documents:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E5BBA), // Original Blue
                ),
              ),
              const SizedBox(height: 20),

              // Document List
              ..._roleDocuments[_selectedRole]!.map((doc) {
                final isUploaded = _uploadedDocuments[doc['key']] == true;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (isUploaded)
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    child: const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    doc['title']!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E5BBA), // Original Blue
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (doc['subtitle']!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                doc['subtitle']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (isUploaded) {
                            // View document
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Viewing document...'),
                              ),
                            );
                          } else {
                            _uploadDocument(doc['key']!);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue, // Original Blue
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          isUploaded ? 'View Document' : 'Upload Document',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
}
