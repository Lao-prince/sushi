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

    final query = _searchQuery.toLowerCase().trim();
    final allProducts = menuProvider.categorizedProducts.values
        .expand((products) => products)
        .where((product) =>
            (product.name.toLowerCase().contains(query) ||
            product.description.toLowerCase().contains(query)) &&
            product.prices.isNotEmpty)
        .toList();

    return allProducts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Поиск',
                style: AppTextStyles.H1.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Поиск...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1C2D45),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Consumer<MenuProvider>(
                builder: (context, menuProvider, child) {
                  if (menuProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

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

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double cardWidth = (constraints.maxWidth - 10) / 2;
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: searchResults.map((product) {
                            return SizedBox(
                              width: cardWidth,
                               child: ProductCard(
                                                id: product.id,
                                                title: product.name,
                                                description: product.description,
                                                imageUrl: product.imageLinks.isNotEmpty ? product.imageLinks.first : '',
                                                price: product.prices.isNotEmpty 
                                                    ? product.prices.firstWhere(
                                                        (price) => price.size.isDefault,
                                                        orElse: () => product.prices[0]
                                                      ).price.toString()
                                                    : '0',
                                                sizes: product.prices.map((price) => {
                                                  'id': price.size.id ?? product.id,
                                                  'name': price.size.mapped_name ?? price.size.name ?? 'Порция',
                                                  'count': price.count?.toString() ?? '1',
                                                  'price': price.price.toString(),
                                                }).toList(),
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