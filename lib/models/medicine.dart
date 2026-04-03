class Medicine {
  final String id;
  final String name;
  final String description;
  final String category;
  final String unit;
  final int lowStockThreshold;
  final int totalStock;

  Medicine({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.unit,
    required this.lowStockThreshold,
    this.totalStock = 0,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      unit: json['unit'] ?? '',
      lowStockThreshold: json['lowStockThreshold'] ?? 0,
      totalStock: json['totalStock'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'category': category,
    'unit': unit,
    'lowStockThreshold': lowStockThreshold,
  };

  bool get isLowStock => totalStock <= lowStockThreshold;
}
