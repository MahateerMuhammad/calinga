class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String role;
  String? profileImageUrl;
  String? address;
  int? age;
  String? bio;
  String? emergencyContact;
  String? medicalConditions;
  double? ratePerHour;
  bool isAvailableForWork;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.profileImageUrl,
    this.address,
    this.age,
    this.bio,
    this.emergencyContact,
    this.medicalConditions,
    this.ratePerHour,
    this.isAvailableForWork = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      role: json['role'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      address: json['address'],
      age: json['age'],
      bio: json['bio'],
      emergencyContact: json['emergencyContact'],
      medicalConditions: json['medicalConditions'],
      ratePerHour: json['ratePerHour']?.toDouble(),
      isAvailableForWork: json['isAvailableForWork'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'address': address,
      'age': age,
      'bio': bio,
      'emergencyContact': emergencyContact,
      'medicalConditions': medicalConditions,
      'ratePerHour': ratePerHour,
      'isAvailableForWork': isAvailableForWork,
    };
  }
}