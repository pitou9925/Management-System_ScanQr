// lib/models/search_filter.dart
enum SearchFilter {
  all,
  name,
  category,
  barcode,
  lowStock,
  highStock,
  recentlyAdded,
  recentlyUpdated,
}

class Product {
  String barcode;
  String name;
  String category;
  int quantity;
  double price;
  DateTime createdAt;
  DateTime updatedAt;

  Product({
    required this.barcode,
    required this.name,
    required this.category,
    required this.quantity,
    required this.price,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  void updateQuantity(int newQuantity) {
    quantity = newQuantity;
    updatedAt = DateTime.now();
  }

  Map<String, dynamic> toJson() => {
    'barcode': barcode,
    'name': name,
    'category': category,
    'quantity': quantity,
    'price': price,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  static Product fromJson(Map<String, dynamic> json) => Product(
    barcode: json['barcode'] ?? '',
    name: json['name'] ?? '',
    category: json['category'] ?? '',
    quantity: json['quantity'] ?? 0,
    price: (json['price'] is int)
        ? (json['price'] as int).toDouble()
        : (json['price'] ?? 0.0),
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'])
        : DateTime.now(),
  );
}

