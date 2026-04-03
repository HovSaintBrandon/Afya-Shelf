import 'package:intl/intl.dart';

class Transaction {
  final String id;
  final String type;
  final String medicineId;
  final String medicineName;
  final String batchId;
  final int quantity;
  final String reason;
  final DateTime createdAt;
  final String user;

  Transaction({
    required this.id,
    required this.type,
    required this.medicineId,
    required this.medicineName,
    required this.batchId,
    required this.quantity,
    required this.reason,
    required this.createdAt,
    required this.user,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? '',
      medicineId: json['medicineId'] is Map
          ? json['medicineId']['_id'] ?? ''
          : json['medicineId'] ?? '',
      medicineName: json['medicineId'] is Map
          ? json['medicineId']['name'] ?? ''
          : json['medicineName'] ?? '',
      batchId: json['batchId'] is Map
          ? json['batchId']['_id'] ?? ''
          : json['batchId'] ?? '',
      quantity: json['quantity'] ?? 0,
      reason: json['reason'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      user: json['user'] ?? json['userId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'medicineId': medicineId,
    'batchId': batchId,
    'quantity': quantity,
    'reason': reason,
  };

  String get formattedDate => DateFormat('MMM dd, yyyy HH:mm').format(createdAt);
}
