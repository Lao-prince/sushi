import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../style/styles.dart';
import 'auth_page.dart';

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
    final _oldPasswordController = TextEditingController();
    final _newPasswordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    bool _isLoading = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _oldPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Старый пароль',
                  labelStyle: AppTextStyles.Body,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1C2D45),
                ),
                style: AppTextStyles.Body,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите старый пароль';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Новый пароль',
                  labelStyle: AppTextStyles.Body,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1C2D45),
                ),
                style: AppTextStyles.Body,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите новый пароль';
                  }
                  if (value.length < 6) {
                    return 'Пароль должен быть не менее 6 символов';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Подтверждение пароля',
                  labelStyle: AppTextStyles.Body,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1C2D45),
                ),
                style: AppTextStyles.Body,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Подтвердите новый пароль';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Пароли не совпадают';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => _isLoading = true);

                            final authProvider =
                                Provider.of<AuthProvider>(context, listen: false);
                            final success = await authProvider.changePassword(
                              _oldPasswordController.text,
                              _newPasswordController.text,
                            );

                            setState(() => _isLoading = false);

                            if (!mounted) return;

                            if (success) {
                              // Очищаем поля
                              _oldPasswordController.clear();
                              _newPasswordController.clear();
                              _confirmPasswordController.clear();

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Пароль успешно изменен'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Ошибка при смене пароля. Проверьте правильность старого пароля',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD1930D),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Сменить пароль',
                          style: AppTextStyles.Body.copyWith(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        );
      },
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
    final authProvider = Provider.of<AuthProvider>(context);
    
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
              const SizedBox(),
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
              backgroundImage: AssetImage('assets/images/avatar.png'),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              authProvider.name ?? 'Пользователь',
              style: const TextStyle(
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
              _buildDataBlock('Телефон', authProvider.phoneNumber ?? 'Не указан'),
              _buildDataBlock('E-mail', 'example@mail.ru'),
            ],
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () async {
              // Показываем диалог подтверждения
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1C2D45),
                  title: const Text(
                    'Удаление аккаунта',
                    style: AppTextStyles.H2,
                  ),
                  content: const Text(
                    'Вы уверены, что хотите удалить свой аккаунт? Это действие нельзя отменить.',
                    style: AppTextStyles.Body,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'Отмена',
                        style: AppTextStyles.Body.copyWith(
                          color: const Color(0xFFD1930D),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        'Удалить',
                        style: AppTextStyles.Body.copyWith(
                          color: const Color(0xFFEB8B8D),
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                final success = await authProvider.deleteAccount();
                if (success) {
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const AuthPage()),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ошибка при удалении аккаунта'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEB8B8D),
              textStyle: AppTextStyles.Subtitle.copyWith(
                color: const Color(0xFFEB8B8D),
              ),
            ),
            child: const Text('Удалить аккаунт'),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () async {
                await authProvider.logout();
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthPage()),
                  );
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFEB8B8D),
                textStyle: AppTextStyles.Subtitle.copyWith(
                  color: const Color(0xFFEB8B8D),
                ),
              ),
              child: const Text('Выйти'),
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
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          return const AuthPage();
        }

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
      },
    );
  }
}
