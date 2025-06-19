class Menu {
  final Category category;
  final List<Product> products;

  Menu({required this.category, required this.products});

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      category: Category.fromJson(json['category']),
      products: (json['products'] as List)
          .map((productJson) => Product.fromJson(productJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'category': category.toJson(),
    'products': products.map((p) => p.toJson()).toList(),
  };
}

class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };
}

class Product {
  final String id;
  final String name;
  final List<String> imageLinks;
  final String description;
  final Category category;
  final List<Price> prices;

  Product({
    required this.id,
    required this.name,
    required this.imageLinks,
    required this.description,
    required this.category,
    required this.prices,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imageLinks: (json['imageLinks'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      description: json['description']?.toString() ?? '',
      category: Category.fromJson(json['category'] ?? {}),
      prices: (json['prices'] as List<dynamic>?)?.map((priceJson) => Price.fromJson(priceJson)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imageLinks': imageLinks,
    'description': description,
    'category': category.toJson(),
    'prices': prices.map((p) => p.toJson()).toList(),
  };
}

class Price {
  final Size size;
  final int price;
  final int count;

  Price({required this.size, required this.price, required this.count});

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      size: Size.fromJson(json['size'] ?? {}),
      price: (json['price'] is num) ? json['price'].toInt() : 0,
      count: (json['count'] is num) ? json['count'].toInt() : 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'size': size.toJson(),
    'price': price,
    'count': count,
  };
}

class Size {
  final String id;
  final String name;
  final bool isDefault;
  final String? mapped_name;

  Size({
    required this.id, 
    required this.name, 
    required this.isDefault,
    this.mapped_name,
  });

  factory Size.fromJson(Map<String, dynamic> json) {
    return Size(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isDefault: json['isDefault'] as bool? ?? false,
      mapped_name: json['mapped_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isDefault': isDefault,
    'mapped_name': mapped_name,
  };
}
