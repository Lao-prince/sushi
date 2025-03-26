import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../style/styles.dart';
import '../services/cart_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/menu_model.dart';

class ProductCard extends StatefulWidget {
  final String id;
  final String imageUrl;
  final String title;
  final String description;
  final String price;
  final List<Map<String, String>> sizes;

  const ProductCard({
    Key? key,
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.price,
    required this.sizes,
  }) : super(key: key);

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late String selectedSizeId;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    selectedSizeId = widget.sizes.first['id'] ?? '';
  }

  String formatPortion(String portion) {
    int? number = int.tryParse(portion);
    if (number == null) return portion;

    int mod100 = number % 100;
    int mod10 = number % 10;

    if (mod100 >= 11 && mod100 <= 14) {
      return '$number порций';
    }
    if (mod10 == 1) {
      return '$number порция';
    }
    if (mod10 >= 2 && mod10 <= 4) {
      return '$number порции';
    }
    return '$number порций';
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final int cartItemCount = cartProvider.getItemCount(widget.id, selectedSizeId);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [Color(0xFF3A435B), Color(0xFF0A0A0A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border.all(color: const Color(0xFFD1930D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.max,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl.isNotEmpty && Uri.tryParse(widget.imageUrl)?.host.isNotEmpty == true
                        ? widget.imageUrl
                        : '',
                    fit: BoxFit.cover,
                    memCacheWidth: 120,
                    memCacheHeight: 120,
                    placeholder: (context, url) => Container(
                      color: const Color(0xFF3A435B),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFD1930D),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) {
                      print('Error loading image: $error for URL: $url');
                      return Container(
                        color: const Color(0xFF3A435B),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                color: Color(0xFFD1930D),
                                size: 32,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Нет фото',
                                style: TextStyle(
                                  color: Color(0xFFD1930D),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isFavorite = !isFavorite;
                    });
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFD1930D),
                        width: 1.5,
                      ),
                      color: isFavorite ? Colors.red : Colors.transparent,
                    ),
                    child: Icon(
                      Icons.favorite,
                      color: isFavorite ? Colors.white : const Color(0xFFD1930D),
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.title, style: AppTextStyles.Title),
                const SizedBox(height: 4),
                Text(
                  widget.description,
                  style: AppTextStyles.Body.copyWith(color: const Color(0xFF555555)),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFD1930D), width: 1.5),
                      ),
                      child: DropdownButton<String>(
                        value: selectedSizeId,
                        items: widget.sizes.map((size) {
                          return DropdownMenuItem<String>(
                            value: size['id'],
                            child: Text(
                              formatPortion(size['name'] ?? ''),
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            if (value != null) {
                              selectedSizeId = value;
                            }
                          });
                        },
                        underline: const SizedBox(),
                        style: const TextStyle(fontSize: 14, color: Colors.white),
                        dropdownColor: const Color(0xFF3A435B),
                        borderRadius: BorderRadius.circular(4),
                        isDense: true,
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFD1930D)),
                      ),
                    ),
                    Text(
                      '${widget.price} ₽',
                      style: const TextStyle(
                        fontSize: 22,
                        fontFamily: 'HattoriHanzo',
                        color: Color(0xFFD1930D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: cartItemCount > 0
                      ? Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFD1930D),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(25),
                              bottomRight: Radius.circular(25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    cartProvider.updateQuantity(
                                      widget.id,
                                      cartItemCount - 1,
                                    );
                                  },
                                  child: const Center(
                                    child: Icon(Icons.remove, color: Colors.white),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    '$cartItemCount',
                                    style: AppTextStyles.Subtitle.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    cartProvider.addToCart(
                                      Product(
                                        id: widget.id,
                                        name: widget.title,
                                        imageLinks: [widget.imageUrl],
                                        description: widget.description,
                                        category: Category(id: '', name: ''),
                                        prices: widget.sizes.map((size) => 
                                          Price(
                                            size: Size(
                                              id: size['id'] ?? '',
                                              name: size['name'] ?? '',
                                              isDefault: size['id'] == selectedSizeId
                                            ),
                                            price: int.tryParse(widget.price) ?? 0
                                          )
                                        ).toList(),
                                      ),
                                      selectedSizeId,
                                      1,
                                    );
                                  },
                                  child: const Center(
                                    child: Icon(Icons.add, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () {
                            cartProvider.addToCart(
                              Product(
                                id: widget.id,
                                name: widget.title,
                                imageLinks: [widget.imageUrl],
                                description: widget.description,
                                category: Category(id: '', name: ''),
                                prices: widget.sizes.map((size) => 
                                  Price(
                                    size: Size(
                                      id: size['id'] ?? '',
                                      name: size['name'] ?? '',
                                      isDefault: size['id'] == selectedSizeId
                                    ),
                                    price: int.tryParse(widget.price) ?? 0
                                  )
                                ).toList(),
                              ),
                              selectedSizeId,
                              1,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD1930D),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(25),
                                bottomRight: Radius.circular(25),
                              ),
                            ),
                          ),
                          child: const Text(
                            'Добавить',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
