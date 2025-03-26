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
      id: json['id'],
      name: json['name'],
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
      id: json['id'],
      name: json['name'],
      imageLinks: List<String>.from(json['imageLinks']),
      description: json['description'],
      category: Category.fromJson(json['category']),
      prices: (json['prices'] as List)
          .map((priceJson) => Price.fromJson(priceJson))
          .toList(),
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

  Price({required this.size, required this.price});

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      size: Size.fromJson(json['size']),
      price: json['price'].toDouble().round(),
    );
  }

  Map<String, dynamic> toJson() => {
    'size': size.toJson(),
    'price': price,
  };
}

class Size {
  final String id;
  final String name;
  final bool isDefault;

  Size({required this.id, required this.name, required this.isDefault});

  factory Size.fromJson(Map<String, dynamic> json) {
    return Size(
      id: json['id'],
      name: json['name'],
      isDefault: json['isDefault'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isDefault': isDefault,
  };
}
