import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/product_card.dart';
import '../style/styles.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({Key? key}) : super(key: key);

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  List<Category> categories = [];
  Map<String, List<Product>> categorizedProducts = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMenuData();
  }

  Future<void> _fetchMenuData() async {
    try {
      final response = await http.get(Uri.parse('http://89.223.122.180:9000/api/menu/'));
      if (response.statusCode == 200) {
        // Декодируем данные явно с указанием кодировки
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));

        Map<String, List<Product>> tempCategorizedProducts = {};
        List<Category> tempCategories = [];

        for (var item in data) {
          final category = Category(
            id: item['category']['id'].toString(),
            name: item['category']['name'], // Убедитесь, что это строка
          );
          tempCategories.add(category);

          List<Product> products = (item['products'] as List<dynamic>).map((product) {
            return Product(
              id: product['id'].toString(),
              imageUrl: product['imageLinks'].isNotEmpty ? product['imageLinks'][0] : '',
              title: product['name'], // Убедитесь, что это строка
              description: product['description'], // Убедитесь, что это строка
              price: product['prices'].firstWhere(
                    (price) => price['size']['isDefault'] == true,
                orElse: () => product['prices'][0],
              )['price']
                  .toString(),
              options: product['prices']
                  .map<String>((price) => price['size']['name'] as String)
                  .toList(),
            );
          }).toList();

          tempCategorizedProducts[category.id] = products;
        }

        setState(() {
          categories = tempCategories;
          categorizedProducts = tempCategorizedProducts;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load menu data');
      }
    } catch (error) {
      print('Error fetching menu data: $error');
      setState(() {
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Меню',
                  style: AppTextStyles.H1.copyWith(),
                ),
              ),
              const SizedBox(height: 20),
              // Category List
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFF3A435B),
                            ),
                            child: Center(
                              child: Text(
                                category.name[0],
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category.name,
                            style: AppTextStyles.Caption.copyWith(),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              const Divider(
                thickness: 1,
                color: Color(0xFF4D4D4D),
              ),
              const SizedBox(height: 10),
              // Product Grid
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final products = categorizedProducts[category.id] ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: AppTextStyles.H2.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.75,
                          ),
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: products.length,
                          itemBuilder: (context, productIndex) {
                            final product = products[productIndex];
                            return ProductCard(
                              imageUrl: product.imageUrl,
                              title: product.title,
                              description: product.description,
                              price: product.price,
                              options: product.options,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Product {
  final String id;
  final String imageUrl;
  final String title;
  final String description;
  final String price;
  final List<String> options;

  Product({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.price,
    required this.options,
  });
}

class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});
}
