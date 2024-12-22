import 'package:flutter/material.dart';
import '../style/styles.dart';

class SearchPage extends StatelessWidget {
  SearchPage({Key? key}) : super(key: key);

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
              // Заголовок "Поиск"
              Center(
                child: Text(
                  'Поиск',
                  style: AppTextStyles.H1.copyWith(),
                ),
              ),
              const SizedBox(height: 30),
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
                        decoration: InputDecoration(
                          hintText: 'Введите название блюда',
                          hintStyle: AppTextStyles.Body.copyWith(),
                          border: InputBorder.none,
                        ),
                        style: AppTextStyles.Body.copyWith(),
                      ),
                    ),
                    const SizedBox(width: 15), // Отступ от краев
                    Icon(
                      Icons.search,
                      color: const Color(0xFF848484),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
