class TransactionItemModel {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final double subtotal;

  const TransactionItemModel({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory TransactionItemModel.fromJson(Map<String, dynamic> json) {
    return TransactionItemModel(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'product_name': productName,
        'price': price,
        'quantity': quantity,
        'subtotal': subtotal,
      };
}

class TransactionModel {
  final String id;
  final String userId;
  final double total;
  final double discount;
  final String paymentMethod;
  final List<TransactionItemModel> items;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.total,
    required this.discount,
    required this.paymentMethod,
    required this.items,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final List<TransactionItemModel> items;
    if (rawItems is List) {
      items = rawItems
          .map((e) => TransactionItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      items = [];
    }

    return TransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      total: (json['total'] as num).toDouble(),
      discount: (json['discount'] as num? ?? 0).toDouble(),
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      items: items,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'total': total,
        'discount': discount,
        'payment_method': paymentMethod,
        'items': items.map((e) => e.toJson()).toList(),
      };
}
