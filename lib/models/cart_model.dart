class CartItem {
  final String productId;
  final int amount;
  final String productSizeId;
  final String? comment;
  final double price;
  final String uuid;
  final String? productName;
  final String? productImage;
  final String? sizeName;

  CartItem({
    required this.productId,
    required this.amount,
    required this.productSizeId,
    this.comment,
    required this.price,
    required this.uuid,
    this.productName,
    this.productImage,
    this.sizeName,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'],
      amount: json['amount'],
      productSizeId: json['productSizeId'],
      comment: json['comment'] ?? '',
      price: json['price'] is int ? 
        (json['price'] as int).toDouble() : 
        (json['price'] as num).toDouble(),
      uuid: json['uuid'],
      productName: json['productName'] ?? '',
      productImage: json['productImage'] ?? '',
      sizeName: json['sizeName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'amount': amount,
    'productSizeId': productSizeId,
    'comment': comment,
    'price': price,
    'uuid': uuid,
    'productName': productName,
    'productImage': productImage,
    'sizeName': sizeName,
  };
}

class Cart {
  final List<CartItem> items;
  final double totalPrice;

  Cart({
    required this.items,
    required this.totalPrice,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      items: (json['Items'] as List)
          .map((item) => CartItem.fromJson(item))
          .toList(),
      totalPrice: json['totalPrice'] is int ? 
        (json['totalPrice'] as int).toDouble() : 
        (json['totalPrice'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'Items': items.map((item) => item.toJson()).toList(),
    'totalPrice': totalPrice,
  };
} 