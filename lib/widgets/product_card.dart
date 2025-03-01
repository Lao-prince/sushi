import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../style/styles.dart';
import '../services/cart_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductCard extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String description;
  final String price;
  final List<String> options;

  const ProductCard({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.price,
    required this.options,
  }) : super(key: key);

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late String selectedOption;
  int itemCount = 1;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    selectedOption = widget.options.isNotEmpty ? widget.options.first : '';
  }

  String formatPortion(int number) {
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
    final int cartItemCount = cartProvider.getItemCount(widget.title, selectedOption);

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
          // Изображение с кнопкой сердца
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD1930D),
                      ),
                    ),
                    errorWidget: (context, url, error) => Image.asset(
                      'assets/images/zaglushka.png',
                      fit: BoxFit.cover,
                    ),
                    memCacheWidth: 600,
                    memCacheHeight: 300,
                  ),
                ),
              ),
              // Кнопка сердца
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
                      color: isFavorite ? Colors.white : Color(0xFFD1930D),
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Контент карточки
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

                // Цена и опции
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
                        value: selectedOption,
                        items: widget.options.map((option) {
                          final formattedOption = formatPortion(int.parse(option));
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(
                              formattedOption,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            if (value != null) {
                              selectedOption = value;
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
                      ' ${widget.price} \u20BD',
                      style: const TextStyle(
                        fontSize: 22,
                        fontFamily: 'HattoriHanzo',
                        fontFamilyFallback: ['Arial'],
                        color: Color(0xFFD1930D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Поведение кнопки "Добавить" или счетчик
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
                        // Уменьшение
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              cartProvider.removeItem(widget.title, selectedOption);
                            },
                            child: const Center(child: Icon(Icons.remove, color: Colors.white)),
                          ),
                        ),
                        // Количество
                        Expanded(
                          child: Center(
                            child: Text(
                              '$cartItemCount',
                              style: AppTextStyles.Subtitle.copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                        // Увеличение
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              cartProvider.addItem(
                                widget.title,
                                widget.description,
                                widget.price,
                                widget.imageUrl,
                                selectedOption,
                              );
                            },
                            child: const Center(child: Icon(Icons.add, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  )
                      : ElevatedButton(
                    onPressed: () {
                      cartProvider.addItem(
                        widget.title,
                        widget.description,
                        widget.price,
                        widget.imageUrl,
                        selectedOption,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD1930D),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(25),
                          topLeft: Radius.circular(25),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: SvgPicture.asset('assets/images/shopping.svg'),
                          ),
                        ),
                        Text('Добавить', style: AppTextStyles.Subtitle),
                      ],
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
