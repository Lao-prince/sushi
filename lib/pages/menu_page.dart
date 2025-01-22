import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/menu_model.dart';
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
            return Product.fromJson(product);
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
          padding: const EdgeInsets.symmetric(horizontal: 10),
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
              const SizedBox(height: 25),
              // Category List
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Column(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
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
                            style: AppTextStyles.Body.copyWith(),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 15),
              const Divider(
                thickness: 2,
                color: Color(0xFF4D4D4D),
              ),
              //const SizedBox(height: 25),
              // Product Grid
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(top: 0), // Отступ сверху
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: isLoading
                          ? [const Center(child: CircularProgressIndicator())]
                          : categories.map((category) {
                        final products = categorizedProducts[category.id] ?? [];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 25),
                            Text(
                              category.name,
                              style: AppTextStyles.H2.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, // Количество карточек в ряду
                                crossAxisSpacing: 10, // Расстояние между карточками по горизонтали
                                mainAxisSpacing: 10, // Расстояние между карточками по вертикали
                                childAspectRatio: 0.68, // Соотношение сторон карточек
                              ),
                              physics: const NeverScrollableScrollPhysics(), // Убираем независимую прокрутку
                              shrinkWrap: true, // Уменьшаем GridView до его контента
                              itemCount: products.length, // Количество карточек
                              itemBuilder: (context, productIndex) {
                                final product = products[productIndex];
                                return ProductCard(
                                  imageUrl: product.imageLinks.isNotEmpty ? product.imageLinks[0] : '',
                                  title: product.name,
                                  description: product.description,
                                  price: product.prices
                                      .firstWhere((price) => price.size.isDefault, orElse: () => product.prices[0])
                                      .price
                                      .toString(),
                                  options: product.prices.map((price) => price.size.name).toList(),
                                );
                              },
                            ),
                            //const SizedBox(height: 25),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
