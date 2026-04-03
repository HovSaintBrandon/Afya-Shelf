import 'clinic.dart';

class User {
  final String id;
  final String username;
  final String role;
  final String clinicId;
  final String? clinicName;
  final List<Clinic> clinics;

  User({
    required this.id,
    required this.username,
    required this.role,
    required this.clinicId,
    this.clinicName,
    this.clinics = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    var clinicsList = <Clinic>[];
    if (json['clinics'] != null) {
      clinicsList = (json['clinics'] as List).map((e) => Clinic.fromJson(e)).toList();
    }
    
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? 'viewer',
      clinicId: json['clinicId'] ?? '',
      clinicName: json['clinicName'],
      clinics: clinicsList,
    );
  }
}
