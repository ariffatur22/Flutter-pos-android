class Product {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? barcode;
  final double price;
  final double costPrice;
  final int stock;
  final int minStock;
  final String unit;
  final String categoryId;
  final String categoryName;
  final bool isActive;

  const Product({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.barcode,
    required this.price,
    required this.costPrice,
    required this.stock,
    required this.minStock,
    this.unit = 'pcs',
    required this.categoryId,
    required this.categoryName,
    this.isActive = true,
  });

  bool get isLowStock => stock > 0 && stock <= minStock;
  bool get isOutOfStock => stock <= 0;

  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? barcode,
    double? price,
    double? costPrice,
    int? stock,
    int? minStock,
    String? unit,
    String? categoryId,
    String? categoryName,
    bool? isActive,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      unit: unit ?? this.unit,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      isActive: isActive ?? this.isActive,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      barcode: json['barcode'] as String?,
      price: (json['price'] as num).toDouble(),
      costPrice: (json['cost_price'] as num).toDouble(),
      stock: json['stock'] as int,
      minStock: (json['min_stock'] as int?) ?? 5,
      unit: (json['unit'] as String?) ?? 'pcs',
      categoryId: json['category_id'] as String,
      categoryName: (json['category_name'] as String?) ?? '',
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'image_url': imageUrl,
        'barcode': barcode,
        'price': price,
        'cost_price': costPrice,
        'stock': stock,
        'min_stock': minStock,
        'unit': unit,
        'category_id': categoryId,
        'category_name': categoryName,
        'is_active': isActive,
      };
}
