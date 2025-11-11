class CartItem {
  final String productId;
  final String? productSizeId;
  final int amount;
  final String comment;
  final String productName;
  final String productImage;
  final String sizeName;
  final double price;
  final String uuid;

  CartItem({
    required this.productId,
    this.productSizeId,
    required this.amount,
    required this.comment,
    required this.productName,
    required this.productImage,
    required this.sizeName,
    required this.price,
    required this.uuid,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    return CartItem(
      productId: json['productId'] as String,
      productSizeId: json['productSizeId'] as String?,
      amount: json['amount'] as int,
      comment: json['comment'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      productImage: json['productImage'] as String? ?? '',
      sizeName: json['sizeName'] as String? ?? '',
      price: parsePrice(json['price']),
      uuid: json['uuid'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
    'productId': productId,
      'productSizeId': productSizeId,
    'amount': amount,
    'comment': comment,
    'productName': productName,
    'productImage': productImage,
    'sizeName': sizeName,
      'price': price,
      'uuid': uuid,
  };
  }
}

class Cart {
  final List<CartItem> items;
  final double totalPrice;

  Cart({
    required this.items,
    required this.totalPrice,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    final items = (json['Items'] as List)
        .map((item) => CartItem.fromJson(item))
        .where((item) => item.amount > 0)
        .toList();
    
    // Вычисляем общую сумму с учетом количества каждого товара
    final totalPrice = items.fold<double>(
      0.0,
      (sum, item) => sum + (item.price * item.amount),
    );

    return Cart(
      items: items,
      totalPrice: totalPrice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
    'Items': items.map((item) => item.toJson()).toList(),
      'TotalPrice': totalPrice,
  };
  }
} 