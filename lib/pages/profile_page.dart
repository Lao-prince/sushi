import 'package:flutter/material.dart';
import '../style/styles.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  final List<String> menuItems = ['Избранное', 'Мои данные', 'Заказы', 'Сменить пароль'];
  int activeIndex = 0;

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onItemTap(int index) {
    setState(() {
      activeIndex = index;
    });

    double offset = (index * 120.0) - (MediaQuery.of(context).size.width / 2) + 60.0;
    _scrollController.animateTo(
      offset < 0 ? 0 : offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildLabeledInputField(String label, String hintText, {bool obscureText = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.Title.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFF1C2D45),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildChangePasswordForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabeledInputField('Старый пароль', 'Введите старый пароль', obscureText: true),
        _buildLabeledInputField('Новый пароль', 'Введите новый пароль', obscureText: true),
        _buildLabeledInputField('Подтверждение пароля', 'Подтвердите новый пароль', obscureText: true),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            // Logic to handle password change
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD1930D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Text('Сохранить изменения', style: AppTextStyles.Subtitle.copyWith(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }

  Widget getActiveContent() {
    switch (activeIndex) {
      case 0:
        return const Center(child: Text('Избранное', style: AppTextStyles.Body));
      case 1:
        return _buildMyDataCard();
      case 2:
        return const Center(child: Text('Заказы', style: AppTextStyles.Body));
      case 3:
        return _buildChangePasswordForm();
      default:
        return const SizedBox();
    }
  }

  Widget _buildMyDataCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD1930D), width: 1.5),
        gradient: const LinearGradient(
          colors: [Color(0xFF3A435B), Color(0xFF0A0A0A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(), // Placeholder for alignment
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  // Logic to edit profile
                },
              ),
            ],
          ),
          const Center(
            child: CircleAvatar(
              radius: 90,
              backgroundImage: AssetImage('assets/avatar.png'), // Update with your asset
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Петр Иванов',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDataBlock('Мои адреса', 'г. Москва, ул. Примерная, д. 1'),
              _buildDataBlock('Дата рождения', '01.01.1990'),
              _buildDataBlock('E-mail', 'example@mail.ru'),
              _buildDataBlock('Телефон', '+7 (999) 123-45-67'),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () {
                // Logic to delete profile
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFEB8B8D),
                textStyle: AppTextStyles.Subtitle.copyWith(color: const Color(0xFFEB8B8D)),
              ),
              child: const Text('Удалить профиль'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataBlock(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.H3.copyWith(color: const Color(0xFFD1930D)),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextStyles.Title.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 12),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Center(
              child: Text('Профиль', style: AppTextStyles.H1),
            ),
            const SizedBox(height: 20),
            Stack(
              children: [
                Positioned(
                  bottom: 0,
                  child: Container(
                    height: 2,
                    width: screenWidth,
                    color: const Color(0xFF4D4D4D),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: _scrollController,
                  child: Row(
                    children: menuItems.map((item) {
                      int index = menuItems.indexOf(item);
                      return GestureDetector(
                        onTap: () => _onItemTap(index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Column(
                            children: [
                              Text(
                                item,
                                style: AppTextStyles.H2.copyWith(
                                  color: index == activeIndex
                                      ? const Color(0xFFD1930D)
                                      : const Color(0xFF4D4D4D),
                                  fontWeight: index == activeIndex
                                      ? FontWeight.normal
                                      : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 10),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: index == activeIndex ? 2 : 0,
                                width: item.length * 12.0,
                                color: const Color(0xFFD1930D),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: getActiveContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
