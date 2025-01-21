import 'package:flutter/material.dart';
import '../style/styles.dart';

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

  @override
  void initState() {
    super.initState();
    // Устанавливаем первый элемент как выбранный по умолчанию
    selectedOption = widget.options.isNotEmpty ? widget.options.first : '';
  }

  String formatPortion(int number) {
    // Получаем последние две цифры числа
    int mod100 = number % 100;
    // Получаем последнюю цифру числа
    int mod10 = number % 10;

    // Определяем правильное склонение
    if (mod100 >= 11 && mod100 <= 14) {
      return '$number порций'; // Исключение для чисел от 11 до 14
    }
    if (mod10 == 1) {
      return '$number порция'; // Окончание для чисел, оканчивающихся на 1
    }
    if (mod10 >= 2 && mod10 <= 4) {
      return '$number порции'; // Окончание для чисел, оканчивающихся на 2, 3, 4
    }
    return '$number порций'; // Окончание для всех остальных случаев
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4.5), // Отступы между карточками
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
        crossAxisAlignment: CrossAxisAlignment.stretch, // Растянуть по ширине
        children: [
          // Изображение с заглушкой
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.network(
              widget.imageUrl,
              height: 90,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                } else {
                  return Container(
                    height: 90,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 90,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                );
              },
            ),
          ),

          // Блок с текстом и элементами управления
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Название и описание
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: AppTextStyles.Subtitle.copyWith(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.description,
                        style: AppTextStyles.Caption.copyWith(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Выпадающий список и цена
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
                          value: selectedOption, // Отображаем текущее выбранное значение
                          items: widget.options
                              .map((option) {
                            final formattedOption = formatPortion(int.parse(option));
                            return DropdownMenuItem<String>(
                              value: option,
                              child: Text(
                                formattedOption,
                                style: const TextStyle(color: Colors.white), // Цвет текста в меню
                              ),
                            );
                          })
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              if (value != null) {
                                selectedOption = value; // Обновляем состояние
                              }
                            });
                          },
                          underline: const SizedBox(), // Убираем стандартную линию подчеркивания
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white, // Цвет текста в кнопке
                          ),
                          dropdownColor: const Color(0xFF3A435B), // Цвет фона выпадающего списка
                          borderRadius: BorderRadius.circular(4), // Закругленные углы
                          isDense: true, // Уменьшить размер выпадающего списка
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFD1930D)),
                        ),
                      ),
                      Text(
                        '${widget.price} ₽',
                        style: AppTextStyles.Subtitle.copyWith(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Кнопка
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        backgroundColor: const Color(0xFFD1930D),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(25),
                            topLeft: Radius.circular(25),
                          ),
                        ),
                      ),
                      child: const Text(
                        'Добавить',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
