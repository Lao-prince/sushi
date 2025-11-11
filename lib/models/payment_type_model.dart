class PaymentType {
  final String name;

  PaymentType({
    required this.name,
  });

  factory PaymentType.fromJson(String json) {
    return PaymentType(
      name: json,
    );
  }

  String toJson() {
    return name;
  }
}

