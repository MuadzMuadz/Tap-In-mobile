class ProductModel {
  final String id;
  final String name;
  final double price;
  final String? imageUrl;
  final String? signedImageUrl;
  final bool trackStock;
  final int? stock;
  final String? category;
  final String userId;
  final DateTime? createdAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.signedImageUrl,
    this.trackStock = false,
    this.stock,
    this.category,
    required this.userId,
    this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      trackStock: json['track_stock'] as bool? ?? false,
      stock: json['stock'] as int?,
      category: json['category'] as String?,
      userId: json['user_id'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'image_url': imageUrl,
      'track_stock': trackStock,
      'stock': stock,
      'category': category,
      'user_id': userId,
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    double? price,
    String? imageUrl,
    String? signedImageUrl,
    bool? trackStock,
    int? stock,
    String? category,
    String? userId,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      signedImageUrl: signedImageUrl ?? this.signedImageUrl,
      trackStock: trackStock ?? this.trackStock,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ProductModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
