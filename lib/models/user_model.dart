class UserModel {
  final String id;
  final String phone;
  final String name;
  final String? email;

  UserModel({
    required this.id,
    required this.phone,
    required this.name,
    this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      phone: json['phone'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
    );
  }
}
