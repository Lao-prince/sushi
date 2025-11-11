class DeliveryCost {
  final String city;
  final double value;

  DeliveryCost({
    required this.city,
    required this.value,
  });

  factory DeliveryCost.fromJson(Map<String, dynamic> json) {
    return DeliveryCost(
      city: json['name']?.toString() ?? '',
      value: (json['cost'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'value': value,
    };
  }
}
