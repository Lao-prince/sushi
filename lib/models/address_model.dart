class Address {
  final int id;
  final String city;
  final String street;
  final String house;
  final String? entrance;
  final String? floor;
  final String? doorphone;
  final String? comment;
  final bool isDefault;

  Address({
    required this.id,
    required this.city,
    required this.street,
    required this.house,
    this.entrance,
    this.floor,
    this.doorphone,
    this.comment,
    required this.isDefault,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] ?? 0,
      city: json['city'] ?? '',
      street: json['street'] ?? '',
      house: json['house'] ?? '',
      entrance: json['entrance'],
      floor: json['floor'],
      doorphone: json['doorphone'],
      comment: json['comment'],
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'street': street,
      'house': house,
      'entrance': entrance,
      'floor': floor,
      'doorphone': doorphone,
      'comment': comment,
    };
  }
}
