class Product {
  final String id;
  final String farmerId;
  final String? farmerName;
  final String? farmerLocation;
  final int categoryId;
  final String? categoryName;
  final String title;
  final String? description;
  final double quantity;
  final String unit;
  final double price;
  final String location;
  final List<String> images;
  final String status;
  final List<String> paymentMethods;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.farmerId,
    this.farmerName,
    this.farmerLocation,
    required this.categoryId,
    this.categoryName,
    required this.title,
    this.description,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.location,
    this.images = const [],
    this.status = 'active',
    this.paymentMethods = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Product.fromJson(Map<String, dynamic> json) {
    num? toNum(dynamic v) {
      if (v == null) return null;
      if (v is num) return v;
      if (v is String) return num.tryParse(v);
      return null;
    }
    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return (v as num).toInt();
    }
    List<String> parseStrList(dynamic v) {
      if (v == null) return [];
      if (v is List) return v.map((e) => e.toString()).toList();
      if (v is String) {
        final trimmed = v.trim();
        if (trimmed.isEmpty) return [];
        if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
          return trimmed.substring(1, trimmed.length - 1).split(',').map((s) => s.trim()).toList();
        }
        return [trimmed];
      }
      return [];
    }
    return Product(
      id: json['id'] as String? ?? '',
      farmerId: json['farmer_id'] as String? ?? '',
      farmerName: json['farmer_name'] as String?,
      farmerLocation: json['farmer_location'] as String?,
      categoryId: toInt(json['category_id']) ?? 0,
      categoryName: json['category_name'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      quantity: toNum(json['quantity'])?.toDouble() ?? 0,
      unit: json['unit'] as String? ?? 'Quintal',
      price: toNum(json['price'])?.toDouble() ?? 0,
      location: json['location'] as String? ?? '',
      images: parseStrList(json['images']),
      status: json['status'] as String? ?? 'active',
      paymentMethods: parseStrList(json['payment_methods']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  String get priceFormatted => price.toStringAsFixed(0);
}
