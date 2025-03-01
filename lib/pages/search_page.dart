import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/menu_model.dart';
import '../widgets/product_card.dart';
import '../style/styles.dart';

class SearchPage extends StatefulWidget {
  SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Product> allProducts = [];
  List<Product> filteredProducts = [];
  bool isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMenuData();
    _searchController.addListener(_performSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_performSearch);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMenuData() async {
    try {
      final response = await http.get(Uri.parse('http://89.223.122.180:10000/api/menu/'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));

        List<Product> tempProducts = [];

        for (var item in data) {
          List<Product> products = (item['products'] as List<dynamic>).map((product) {
            return Product.fromJson(product);
          }).toList();
          tempProducts.addAll(products);
        }

        setState(() {
          allProducts = tempProducts;
          filteredProducts = [];
        });
      } else {
        throw Exception('Failed to load menu data');
      }
    } catch (error) {
      print('Ошибка при загрузке данных: $error');
    }
  }

  void _performSearch() {
    String query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        filteredProducts = [];
        isLoading = false;
      } else {
        isLoading = true;
        filteredProducts = allProducts.where((product) {
          String productName = product.name.toLowerCase().trim();
          String productDesc = product.description.toLowerCase().trim();
          return productName.contains(query) || productDesc.contains(query);
        }).toList();
        isLoading = false; // <-- добавили
      }
    });
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
                  'Поиск',
                  style: AppTextStyles.H1.copyWith(),
                ),
              ),
              const SizedBox(height: 25),
              // Поле ввода для поиска
              Container(
                width: double.infinity,
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF4D4D4D), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        keyboardType: TextInputType.text, // Разрешает ввод любого текста
                        textInputAction: TextInputAction.search, // Кнопка "Поиск" на клавиатуре
                        decoration: InputDecoration(
                          hintText: 'Введите название блюда', // Подсказка
                          hintStyle: AppTextStyles.Body.copyWith(),
                          border: InputBorder.none,
                        ),
                        style: AppTextStyles.Body.copyWith(),
                      )
                    ),
                    const SizedBox(width: 15),
                    const Icon(
                      Icons.search,
                      color: Color(0xFF848484),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredProducts.isEmpty && _searchController.text.isNotEmpty
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text(
                    'Ничего не найдено',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              )
                  : filteredProducts.isEmpty
                  ? Container() // Пустое пространство, пока нет поиска
                  : Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: filteredProducts.map((product) {
                      return SizedBox(
                        width: MediaQuery.of(context).size.width / 2 - 20, // Две колонки
                        child: ProductCard(
                          imageUrl: product.imageLinks.isNotEmpty ? product.imageLinks[0] : '',
                          title: product.name,
                          description: product.description,
                          price: product.prices
                              .firstWhere((price) => price.size.isDefault, orElse: () => product.prices[0])
                              .price
                              .toString(),
                          options: product.prices.map((price) => price.size.name).toList(),
                        ),
                      );
                    }).toList(),
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