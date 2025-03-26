import 'package:flutter/material.dart';
import '../style/styles.dart';
import '../services/menu_provider.dart';
import '../widgets/product_card.dart';
import '../models/menu_model.dart';
import 'package:provider/provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _searchProducts(MenuProvider menuProvider) {
    if (_searchQuery.isEmpty) return [];

    final query = _searchQuery.toLowerCase();
    final allProducts = menuProvider.categorizedProducts.values
        .expand((products) => products)
        .where((product) =>
            product.name.toLowerCase().contains(query) ||
            product.description.toLowerCase().contains(query))
        .toList();

    return allProducts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Поиск',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Consumer<MenuProvider>(
                builder: (context, menuProvider, child) {
                  final searchResults = _searchProducts(menuProvider);

                  if (_searchQuery.isEmpty) {
                    return Center(
                      child: Text(
                        'Введите текст для поиска',
                        style: AppTextStyles.Body.copyWith(color: Colors.white54),
                      ),
                    );
                  }

                  if (searchResults.isEmpty) {
                    return Center(
                      child: Text(
                        'Ничего не найдено',
                        style: AppTextStyles.Body.copyWith(color: Colors.white54),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double cardWidth = (constraints.maxWidth - 10) / 2;
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: searchResults.map((product) {
                            List<Map<String, String>> sizes = product.prices.map((price) => {
                              'id': price.size.id,
                              'name': price.size.name,
                            }).toList();

                            return SizedBox(
                              width: cardWidth,
                              child: ProductCard(
                                id: product.id,
                                imageUrl: product.imageLinks.isNotEmpty ? product.imageLinks[0] : '',
                                title: product.name,
                                description: product.description,
                                price: product.prices
                                    .firstWhere((price) => price.size.isDefault, orElse: () => product.prices[0])
                                    .price
                                    .toString(),
                                sizes: sizes,
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}