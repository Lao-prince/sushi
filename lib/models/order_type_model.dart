class DeliveryType {
  final String id;
  final String name;
  final String orderServiceType;
  final bool isDelivery;

  DeliveryType({
    required this.id,
    required this.name,
    required this.orderServiceType,
    required this.isDelivery,
  });

  factory DeliveryType.fromJson(Map<String, dynamic> json) {
    return DeliveryType(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      orderServiceType: json['orderServiceType']?.toString() ?? '',
      isDelivery: json['is_delivery'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'orderServiceType': orderServiceType,
      'is_delivery': isDelivery,
    };
  }
}
