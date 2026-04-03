class Clinic {
  final String id;
  final String name;
  final String? location;

  Clinic({
    required this.id,
    required this.name,
    this.location,
  });
//
  factory Clinic.fromJson(Map<String, dynamic> json) {
    return Clinic(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      location: json['location'],
    );
  }
}
