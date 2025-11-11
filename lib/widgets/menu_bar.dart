import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Подключаем flutter_svg
import 'package:provider/provider.dart';
import '../services/cart_provider.dart';
import '../style/styles.dart'; // Импортируем стили

class MenuBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const MenuBar({required this.selectedIndex, required this.onTap, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final totalItems = cartProvider.cart?.items.fold<int>(
          0,
          (sum, item) => sum + item.amount,
        ) ??
        0;

    // Список элементов с путями к иконкам и названиями
    final items = [
      {'icon': 'assets/images/menu.svg', 'label': 'Меню', 'type': 'svg'},
      {'icon': 'assets/images/search.svg', 'label': 'Поиск', 'type': 'svg'},
      {'icon': 'assets/images/basket.svg', 'label': 'Корзина', 'type': 'svg'},
      {'icon': 'assets/images/profile.svg', 'label': 'Профиль', 'type': 'svg'},
    ];

    return Container(
      height: 80, // Высота меню бара
      width: double.infinity, // Ширина на весь экран
      color: Colors.black, // Фон (можно заменить на любой цвет)
      padding: const EdgeInsets.symmetric(vertical: 15), // Отступы сверху и снизу
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround, // Равное расстояние между блоками
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == selectedIndex;
          final isCart = index == 2;

          return GestureDetector(
            onTap: () => onTap(index),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Пространство между иконкой и текстом
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    // Проверяем тип файла и используем соответствующий виджет
                    item['type'] == 'png'
                        ? ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              isSelected
                                  ? const Color(0xFFD1930D)
                                  : const Color(0xFFFDFDFD),
                              BlendMode.srcIn,
                            ),
                            child: Image.asset(
                              item['icon'] as String,
                              width: 30,
                              height: 30,
                            ),
                          )
                        : SvgPicture.asset(
                      item['icon'] as String, // Путь к SVG-иконке
                      width: 30,
                      height: 30,
                      colorFilter: ColorFilter.mode(
                        isSelected
                            ? const Color(0xFFD1930D)
                            : const Color(0xFFFDFDFD),
                        BlendMode.srcIn,
                      ),
                    ),
                    if (isCart && totalItems > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEE171A),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            totalItems.toString(),
                            style: AppTextStyles.Caption.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // Текст с использованием стиля Caption
                Text(
                  item['label'] as String,
                  style: AppTextStyles.Caption.copyWith(
                    color: isSelected
                        ? const Color(0xFFD1930D) // Цвет выбранного текста
                        : const Color(0xFFFDFDFD), // Цвет невыбранного текста
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
