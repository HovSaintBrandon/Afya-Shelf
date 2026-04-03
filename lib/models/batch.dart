class Batch {
  final String id;
  final String medicineId;
  final String batchNumber;
  final DateTime expiryDate;
  final int quantity;
  final String? notes;
  final String? medicineName;

  Batch({
    required this.id,
    required this.medicineId,
    required this.batchNumber,
    required this.expiryDate,
    required this.quantity,
    this.notes,
    this.medicineName,
  });

  factory Batch.fromJson(Map<String, dynamic> json) {
    dynamic med = json['medicine'] ?? json['medicineId'];
    return Batch(
      id: json['_id'] ?? json['id'] ?? '',
      medicineId: med is Map ? (med['_id'] ?? '') : (med ?? ''),
      batchNumber: json['batchNumber'] ?? '',
      expiryDate: DateTime.tryParse(json['expiryDate'] ?? '') ?? DateTime.now(),
      quantity: json['currentQuantity'] ?? json['quantity'] ?? 0,
      notes: json['notes'],
      medicineName: med is Map ? med['name'] : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'medicineId': medicineId,
    'batchNumber': batchNumber,
    'expiryDate': expiryDate.toIso8601String().split('T').first,
    'quantity': quantity,
    if (notes != null) 'notes': notes,
  };

  bool get isExpired => expiryDate.isBefore(DateTime.now());

  bool get isExpiringSoon {
    final thirtyDays = DateTime.now().add(const Duration(days: 30));
    return expiryDate.isBefore(thirtyDays) && !isExpired;
  }

  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;
}
