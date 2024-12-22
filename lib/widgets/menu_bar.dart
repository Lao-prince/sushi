import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Подключаем flutter_svg
import '../style/styles.dart'; // Импортируем стили

class MenuBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const MenuBar({required this.selectedIndex, required this.onTap, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Список элементов с путями к SVG-иконкам и названиями
    final items = [
      {'icon': 'assets/images/menu.svg', 'label': 'Меню'},
      {'icon': 'assets/images/search.svg', 'label': 'Поиск'},
      {'icon': 'assets/images/basket.svg', 'label': 'Корзина'},
      {'icon': 'assets/images/profile.svg', 'label': 'Профиль'},
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

          return GestureDetector(
            onTap: () => onTap(index),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Пространство между иконкой и текстом
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // SVG-иконка
                SvgPicture.asset(
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
