import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/delivery_cost_provider.dart';
import '../style/styles.dart';
import 'auth_page.dart';
import '../widgets/product_card.dart'; // Added import for ProductCard
import '../services/menu_provider.dart';
import '../utils/phone_input_formatter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  final List<String> menuItems = ['Избранное', 'Мои данные', 'Заказы', 'Сменить пароль'];
  int activeIndex = 0;

  late ScrollController _scrollController;
  late PageController _pageController;
  AuthProvider? _authProvider;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _pageController = PageController(initialPage: activeIndex);
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Сохраняем ссылку на authProvider для безопасного использования в dispose
    if (_authProvider == null) {
      _authProvider = Provider.of<AuthProvider>(context, listen: false);
      _authProvider!.addListener(_onAuthChanged);
    }
  }
  
  void _onAuthChanged() {
    // Если пользователь только что авторизовался, возвращаемся к вкладке "Избранное"
    if (_authProvider != null && _authProvider!.isAuthenticated && mounted) {
      setState(() {
        activeIndex = 0;
      });
      // Проверяем, что PageController привязан к PageView
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_onAuthChanged);
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTap(int index) {
    setState(() {
      activeIndex = index;
    });

    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    if (_scrollController.hasClients) {
    double offset = (index * 120.0) - (MediaQuery.of(context).size.width / 2) + 60.0;
    _scrollController.animateTo(
      offset < 0 ? 0 : offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    }
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
                              '', // Старый пароль не нужен
                              _newPasswordController.text,
                            );

                            setState(() => _isLoading = false);

                            if (!mounted) return;

                            if (success) {
                              _newPasswordController.clear();
                              _confirmPasswordController.clear();

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Пароль успешно изменён'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Ошибка при смене пароля.',
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


  Widget _buildFavoritesTab() {
    return Consumer2<AuthProvider, MenuProvider>(
      builder: (context, authProvider, menuProvider, _) {
        final favorites = authProvider.favoriteProductIds;
        
        if (!authProvider.isAuthenticated) {
          return const Center(child: Text('Войдите, чтобы увидеть избранное', style: AppTextStyles.Body));
        }
        
        if (favorites.isEmpty) {
          return const Center(child: Text('У вас нет избранных товаров', style: AppTextStyles.Body));
        }
        
        // Получаем все продукты из MenuProvider
        final allProducts = menuProvider.categorizedProducts.values.expand((x) => x).toList();
        
        if (allProducts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // Фильтруем избранные товары и скрываем отключенные
        final favoriteProducts = allProducts
            .where((p) => favorites.contains(p.id) && !p.disabled)
            .toList();
        
        if (favoriteProducts.isEmpty) {
          return const Center(child: Text('У вас нет избранных товаров', style: AppTextStyles.Body));
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              double cardWidth = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: favoriteProducts.map((product) {
                  return SizedBox(
                    width: cardWidth,
                    child: ProductCard(product: product),
                  );
                }).toList(),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMyDataCard() {
    return _buildEditProfileForm();
  }

  Widget _buildOrdersTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (!authProvider.isAuthenticated) {
          return const Center(
            child: Text('Войдите, чтобы увидеть заказы', style: AppTextStyles.Body),
          );
        }
        
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: authProvider.getUserOrders(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Ошибка загрузки заказов',
                  style: AppTextStyles.Body.copyWith(color: Colors.red),
                ),
              );
            }
            
            final orders = snapshot.data ?? [];
            
            if (orders.isEmpty) {
              return const Center(
                child: Text('У вас пока нет заказов', style: AppTextStyles.Body),
              );
            }
            
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final order = orders[index];
                return _buildOrderCard(order);
              },
            );
          },
        );
      },
    );
  }
  
  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['external_number'] ?? order['id'] ?? 'N/A';
    final status = order['status'] ?? 'Неизвестно';
    final createdAt = order['created_at'] ?? '';
    final totalPrice = order['total_price'] ?? 0;
    final city = order['city'] ?? '';
    final street = order['street'] ?? '';
    final house = order['house'] ?? '';
    final items = order['items'] as List<dynamic>? ?? [];
    
    // Форматируем дату
    String formattedDate = '';
    if (createdAt.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(createdAt);
        formattedDate = '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        formattedDate = createdAt;
      }
    }
    
    // Статусы на русском
    String statusRu;
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'unconfirmed':
        statusRu = 'Не подтвержден';
        statusColor = Colors.orange;
        break;
      case 'confirmed':
        statusRu = 'Подтвержден';
        statusColor = Colors.green;
        break;
      case 'cooking':
        statusRu = 'Готовится';
        statusColor = Colors.blue;
        break;
      case 'delivering':
        statusRu = 'Доставляется';
        statusColor = const Color(0xFFD1930D);
        break;
      case 'completed':
        statusRu = 'Завершен';
        statusColor = Colors.grey;
        break;
      case 'cancelled':
        statusRu = 'Отменен';
        statusColor = Colors.red;
        break;
      default:
        statusRu = status;
        statusColor = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2D45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4D4D4D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с номером заказа и статусом
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Заказ #$orderId',
                style: AppTextStyles.H3.copyWith(color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
            child: Text(
                  statusRu,
                  style: AppTextStyles.Body.copyWith(color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Дата заказа
          if (formattedDate.isNotEmpty)
            Text(
              formattedDate,
              style: AppTextStyles.Body.copyWith(color: Colors.grey),
            ),
          
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF4D4D4D)),
          const SizedBox(height: 12),
          
          // Адрес
          if (city.isNotEmpty || street.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: Color(0xFFD1930D), size: 16),
                const SizedBox(width: 8),
                Expanded(
                      child: Text(
                    'г. $city, ул. $street, д. $house',
                    style: AppTextStyles.Body.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
          
          const SizedBox(height: 12),
          
          // Товары
          if (items.isNotEmpty) ...[
            Text(
              'Товары (${items.length}):',
              style: AppTextStyles.Body.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ...items.take(3).map((item) {
              final amount = item['amount'] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $amount шт.',
                  style: AppTextStyles.Body.copyWith(color: Colors.white70),
                      ),
                    );
            }).toList(),
            if (items.length > 3)
              Text(
                '... и ещё ${items.length - 3}',
                style: AppTextStyles.Body.copyWith(color: Colors.grey),
              ),
          ],
          
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF4D4D4D)),
          const SizedBox(height: 12),
          
          // Итоговая сумма
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Итого:',
                style: AppTextStyles.H3.copyWith(color: Colors.white),
              ),
              Text(
                '${totalPrice.toInt()} ₽',
                style: AppTextStyles.H3.copyWith(
                  color: const Color(0xFFD1930D),
                  fontWeight: FontWeight.bold,
                ),
            ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfileForm() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return _EditProfileForm();
      },
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
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        activeIndex = index;
                      });
                      
                      if (_scrollController.hasClients) {
                        double offset = (index * 120.0) - (MediaQuery.of(context).size.width / 2) + 60.0;
                        _scrollController.animateTo(
                          offset < 0 ? 0 : offset,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    children: [
                      Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: _buildFavoritesTab(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: _buildMyDataCard(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: _buildOrdersTab(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: _buildChangePasswordForm(),
                      ),
                    ],
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

class _EditProfileForm extends StatefulWidget {
  @override
  _EditProfileFormState createState() => _EditProfileFormState();
}

class AddressFormData {
  int? id;
  String city = '';
  String street = '';
  String house = '';
  String entrance = '';
  String floor = '';
  String doorphone = '';
  bool isDefault = false;
  
  late final TextEditingController cityController;
  late final TextEditingController streetController;
  late final TextEditingController houseController;
  late final TextEditingController entranceController;
  late final TextEditingController floorController;
  late final TextEditingController doorphoneController;
  
  AddressFormData({this.id, this.isDefault = false}) {
    cityController = TextEditingController(text: city);
    streetController = TextEditingController(text: street);
    houseController = TextEditingController(text: house);
    entranceController = TextEditingController(text: entrance);
    floorController = TextEditingController(text: floor);
    doorphoneController = TextEditingController(text: doorphone);
    
    // Добавляем listeners для обновления данных
    cityController.addListener(() => city = cityController.text);
    streetController.addListener(() => street = streetController.text);
    houseController.addListener(() => house = houseController.text);
    entranceController.addListener(() => entrance = entranceController.text);
    floorController.addListener(() => floor = floorController.text);
    doorphoneController.addListener(() => doorphone = doorphoneController.text);
  }
  
  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'street': street,
      'house': house,
      'entrance': entrance,
      'floor': floor,
      'doorphone': doorphone,
    };
  }
  
  void dispose() {
    cityController.dispose();
    streetController.dispose();
    houseController.dispose();
    entranceController.dispose();
    floorController.dispose();
    doorphoneController.dispose();
  }
}

class _EditProfileFormState extends State<_EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _phoneController = TextEditingController(text: '+7 (9');
  
  List<AddressFormData> _addresses = [];
  bool _showAddAddressForm = false;
  String? _newAddressCity;
  final _newAddressStreetController = TextEditingController();
  final _newAddressHouseController = TextEditingController();
  final _newAddressEntranceController = TextEditingController();
  final _newAddressFloorController = TextEditingController();
  final _newAddressDoorphoneController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  String _formatPhoneForUI(String phone) {
    // Если телефон пустой, возвращаем префикс по умолчанию
    if (phone.isEmpty) return '+7 (9';
    
    // Удаляем все нецифровые символы
    String numbers = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Если номер начинается с 7, убираем её
    if (numbers.startsWith('7')) {
      numbers = numbers.substring(1);
    }
    
    // Форматируем как +7 (9XX) XXX-XX-XX (10 цифр после 7)
    if (numbers.length == 10 && numbers.startsWith('9')) {
      return '+7 (${numbers.substring(0, 3)}) ${numbers.substring(3, 6)}-${numbers.substring(6, 8)}-${numbers.substring(8)}';
    }
    
    // Если не удалось отформатировать, возвращаем префикс по умолчанию
    return '+7 (9';
  }

  String _formatPhoneForServer(String phone) {
    // Если телефон пустой, возвращаем как есть
    if (phone.isEmpty) return phone;
    
    // Удаляем все нецифровые символы
    String numbers = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Если номер начинается с 8, заменяем на 7
    if (numbers.startsWith('8')) {
      numbers = '7${numbers.substring(1)}';
    }
    
    // Если номер не начинается с 7 и имеет 10 цифр, добавляем 7
    if (!numbers.startsWith('7') && numbers.length == 10) {
      numbers = '7$numbers';
    }
    
    // Возвращаем простой числовой формат
    return numbers;
  }

  Future<void> _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = await authProvider.getUserData();
    
    if (userData != null && mounted) {
      setState(() {
        _firstNameController.text = userData['first_name'] ?? '';
        _lastNameController.text = userData['last_name'] ?? '';
        _emailController.text = userData['email'] ?? '';
        final rawPhone = userData['phone'] ?? '';
        _phoneController.text = _formatPhoneForUI(rawPhone);
        final rawBirthDate = userData['birth_date'] ?? '';
        if (rawBirthDate.isNotEmpty) {
          final parsedDate = _parseDate(rawBirthDate);
          _birthDateController.text = parsedDate != null ? _formatDate(parsedDate) : '';
        } else {
          _birthDateController.text = '';
        }
        
        // Загружаем все адреса
        _addresses.clear();
        if (userData['addresses'] != null && (userData['addresses'] as List).isNotEmpty) {
          for (var addressData in userData['addresses']) {
            final address = AddressFormData(
              id: addressData['id'],
              isDefault: addressData['is_default'] ?? false,
            );
            // Обновляем значения после создания контроллеров
            address.cityController.text = addressData['city'] ?? '';
            address.streetController.text = addressData['street'] ?? '';
            address.houseController.text = addressData['house'] ?? '';
            address.entranceController.text = addressData['entrance'] ?? '';
            address.floorController.text = addressData['floor'] ?? '';
            address.doorphoneController.text = addressData['doorphone'] ?? '';
            _addresses.add(address);
          }
        }
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Сохраняем персональные данные
      String? formattedBirthDate;
      if (_birthDateController.text.isNotEmpty) {
        final parsedDate = _parseDate(_birthDateController.text);
        formattedBirthDate = parsedDate != null ? _formatDateForServer(parsedDate) : null;
      }
      
      final userData = {
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'email': _emailController.text,
        'phone': _formatPhoneForServer(_phoneController.text),
        'birth_date': formattedBirthDate ?? '',
      };
      
      final personalSuccess = await authProvider.updateUserData(userData);
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      if (personalSuccess) {
        // Перезагружаем данные из API
        await _loadUserData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Данные успешно сохранены'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка при сохранении данных'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  
  Future<void> _removeAddress(int index) async {
    final address = _addresses[index];
    
    // Если у адреса есть id, значит он существует в БД - удаляем через API
    if (address.id != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.removeUserAddress(address.id!);
      
      if (!mounted) return;
      
                if (success) {
        // Показываем успешное удаление
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Адрес успешно удален'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Перезагружаем данные из API
        await _loadUserData();
                } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
            content: Text('Ошибка при удалении адреса'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
    } else {
      // Если адреса нет в БД, просто удаляем из локального списка
      if (mounted) {
        setState(() {
          _addresses[index].dispose();
          _addresses.removeAt(index);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabeledInputField('Имя', _firstNameController, 'Введите имя'),
            _buildLabeledInputField('Фамилия', _lastNameController, 'Введите фамилию'),
            
            const SizedBox(height: 20),
            _buildAddressesSection(),
            
            const SizedBox(height: 20),
            _buildLabeledInputField('E-mail', _emailController, 'example@mail.ru'),
            _buildDatePickerField('Дата рождения', _birthDateController, 'ДД.ММ.ГГГГ'),
            _buildLabeledInputField('Телефон', _phoneController, '+7 (9XX) XXX-XX-XX', inputFormatters: [PhoneInputFormatter()], keyboardType: TextInputType.phone),
            
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD1930D),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
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
                        : const Text(
                            'Сохранить изменения',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ],
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () async {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
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
              ),
              child: const Text('Выйти'),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildLabeledInputField(String label, TextEditingController controller, String hintText, {List<TextInputFormatter>? inputFormatters, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            label,
            style: AppTextStyles.Title.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller,
            enabled: true,
            inputFormatters: inputFormatters,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF1C2D45),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4D4D4D)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4D4D4D)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerField(String label, TextEditingController controller, String hintText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Text(
            label,
          style: AppTextStyles.Title.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: _parseDate(controller.text) ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: Color(0xFFD1930D),
                        onPrimary: Colors.white,
                        surface: Color(0xFF1C2D45),
                        onSurface: Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              
              if (pickedDate != null && mounted) {
                setState(() {
                  controller.text = _formatDate(pickedDate);
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2D45),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4D4D4D)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    controller.text.isEmpty ? hintText : controller.text,
                    style: TextStyle(
                      color: controller.text.isEmpty ? Colors.grey : Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today,
                    color: Color(0xFFD1930D),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    try {
      // Пробуем парсить ISO формат (YYYY-MM-DD)
      if (dateStr.contains('-')) {
        return DateTime.parse(dateStr);
      }
      // Пробуем парсить формат DD.MM.YYYY
      final parts = dateStr.split('.');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      // Игнорируем ошибку
    }
    return null;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatDateForServer(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildAddressesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
              children: [
        Text(
          'Адреса',
          style: AppTextStyles.H3.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 12),
        if (_addresses.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2D45),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4D4D4D)),
            ),
            child: const Center(
              child: Text(
                'Нет сохраненных адресов',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ..._addresses.asMap().entries.map((entry) {
            final index = entry.key;
            final address = entry.value;
            return _buildAddressItem(index, address);
          }),
        const SizedBox(height: 16),
        if (_showAddAddressForm)
          _buildAddAddressForm()
        else
          Center(
            child: TextButton.icon(
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _showAddAddressForm = true;
                  });
                }
              },
              icon: const Icon(Icons.add, color: Color(0xFFD1930D)),
              label: const Text(
                'Добавить адрес',
                style: TextStyle(color: Color(0xFFD1930D)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddressItem(int index, AddressFormData address) {
    // Формируем текстовое представление адреса
    List<String> addressParts = [];
    if (address.cityController.text.isNotEmpty) addressParts.add('г. ${address.cityController.text}');
    if (address.streetController.text.isNotEmpty) addressParts.add('ул. ${address.streetController.text}');
    if (address.houseController.text.isNotEmpty) addressParts.add('д. ${address.houseController.text}');
    if (address.entranceController.text.isNotEmpty) addressParts.add('п. ${address.entranceController.text}');
    if (address.floorController.text.isNotEmpty) addressParts.add('эт. ${address.floorController.text}');
    if (address.doorphoneController.text.isNotEmpty) addressParts.add('кв. ${address.doorphoneController.text}');
    
    String addressText = addressParts.join(', ');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2D45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4D4D4D)),
      ),
      child: Row(
                  children: [
          Checkbox(
            value: address.isDefault,
            onChanged: (bool? value) {
              if (value == true && address.id != null) {
                _setDefaultAddress(address.id!);
              }
            },
            activeColor: const Color(0xFFD1930D),
          ),
          Expanded(
            child: Text(
              addressText.isNotEmpty ? addressText : 'Адрес не заполнен',
              style: AppTextStyles.Body.copyWith(color: Colors.white),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Color(0xFFEB8B8D)),
            onPressed: () => _removeAddress(index),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(int index, AddressFormData address) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2D45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4D4D4D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Адрес ${index + 1}',
                style: AppTextStyles.Title.copyWith(color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Color(0xFFEB8B8D)),
                onPressed: () => _removeAddress(index),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAddressFormFields(address),
        ],
      ),
    );
  }

  Widget _buildAddressFormFields(AddressFormData address) {
    return Column(
      children: [
        _buildAddressField('Город', address.cityController),
        _buildAddressField('Улица', address.streetController),
        _buildAddressField('Дом', address.houseController),
        _buildAddressField('Подъезд', address.entranceController),
        _buildAddressField('Этаж', address.floorController),
        _buildAddressField('Домофон/Квартира', address.doorphoneController),
      ],
    );
  }

  Widget _buildAddressField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.Title.copyWith(color: Colors.white),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Введите $label',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF0A0A0A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF4D4D4D)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF4D4D4D)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddAddressForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2D45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4D4D4D)),
      ),
                              child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
            'Новый адрес',
            style: AppTextStyles.H3.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          _buildCityDropdownForNewAddress(),
          const SizedBox(height: 12),
          _buildSimpleField('Улица*', _newAddressStreetController),
          _buildSimpleField('Дом*', _newAddressHouseController),
          _buildSimpleField('Подъезд', _newAddressEntranceController, inputFormatters: [FilteringTextInputFormatter.digitsOnly], keyboardType: TextInputType.number),
          _buildSimpleField('Этаж', _newAddressFloorController, inputFormatters: [FilteringTextInputFormatter.digitsOnly], keyboardType: TextInputType.number),
          _buildSimpleField('Домофон/Квартира', _newAddressDoorphoneController, inputFormatters: [FilteringTextInputFormatter.digitsOnly], keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveNewAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD1930D),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Добавить',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelAddAddress,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF4D4D4D)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Отмена',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                                  ),
                                ],
                              ),
        ],
      ),
    );
  }

  Widget _buildSimpleField(String label, TextEditingController controller, {List<TextInputFormatter>? inputFormatters, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.Title.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            inputFormatters: inputFormatters,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Введите ${label.replaceAll('*', '')}',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF1C2D45),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4D4D4D)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4D4D4D)),
              ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildCityDropdownForNewAddress() {
    return Consumer<DeliveryCostProvider>(
      builder: (context, deliveryCostProvider, _) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Город*',
                style: AppTextStyles.Title.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2D45),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF4D4D4D)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _newAddressCity,
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Выберите город',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    isExpanded: true,
                    menuMaxHeight: 200, // Показываем ~4 города одновременно
                    items: deliveryCostProvider.deliveryCosts.map((deliveryCost) {
                      return DropdownMenuItem<String>(
                        value: deliveryCost.city,
                  child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Text(
                            deliveryCost.city,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (mounted) {
                        setState(() {
                          _newAddressCity = newValue;
                        });
                      }
                    },
                    dropdownColor: const Color(0xFF1C2D45),
                    icon: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.arrow_drop_down, color: Color(0xFFD1930D)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveNewAddress() async {
    if (_newAddressCity == null || _newAddressStreetController.text.isEmpty || _newAddressHouseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заполните обязательные поля (Город, Улица, Дом)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final addressData = {
      'city': _newAddressCity!,
      'street': _newAddressStreetController.text,
      'house': _newAddressHouseController.text,
      'entrance': _newAddressEntranceController.text,
      'floor': _newAddressFloorController.text,
      'doorphone': _newAddressDoorphoneController.text,
      'comment': '',
    };

    final addressId = await authProvider.addUserAddress(addressData);
    if (addressId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Адрес успешно добавлен'),
          backgroundColor: Colors.green,
        ),
      );
      _cancelAddAddress();
      await _loadUserData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка при добавлении адреса'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cancelAddAddress() {
    if (mounted) {
      setState(() {
        _showAddAddressForm = false;
        _newAddressCity = null;
        _newAddressStreetController.clear();
        _newAddressHouseController.clear();
        _newAddressEntranceController.clear();
        _newAddressFloorController.clear();
        _newAddressDoorphoneController.clear();
      });
    }
  }

  Future<void> _setDefaultAddress(int addressId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.setDefaultAddress(addressId);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Адрес по умолчанию установлен'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadUserData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка при установке адреса по умолчанию'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    _newAddressStreetController.dispose();
    _newAddressHouseController.dispose();
    _newAddressEntranceController.dispose();
    _newAddressFloorController.dispose();
    _newAddressDoorphoneController.dispose();
    
    // Dispose all address controllers
    for (var address in _addresses) {
      address.dispose();
    }
    
    super.dispose();
  }
}

