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
  final double amount;

  final String? paymentStatus;
  final String? status;
  final String? paymentMode;
  final String? shareLink;
  final String? patientPhone;

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
    required this.amount,
    this.paymentStatus,
    this.status,
    this.paymentMode,
    this.shareLink,
    this.patientPhone,
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
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      user: json['user'] ?? json['userId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      paymentStatus: json['paymentStatus'],
      status: json['status'],
      paymentMode: json['paymentMode'],
      shareLink: json['shareLink'],
      patientPhone: json['patientPhone'],
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'medicineId': medicineId,
    'batchId': batchId,
    'quantity': quantity,
    'reason': reason,
    'amount': amount,
  };

  String get formattedDate => DateFormat('MMM dd, yyyy HH:mm').format(createdAt);
}
