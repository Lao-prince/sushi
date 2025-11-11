import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pages/menu_page.dart'; // Убедитесь, что путь к файлу правильный
import 'pages/search_page.dart'; // Убедитесь, что путь к файлу правильный
import 'pages/cart_page.dart'; // Убедитесь, что путь к файлу правильный
import 'pages/profile_page.dart'; // Убедитесь, что путь к файлу правильный
import 'pages/splash_page.dart'; // Экран загрузки
import 'widgets/menu_bar.dart' as custom; // Используем псевдоним
import 'style/styles.dart'; // Файл со стилями текста
import 'package:provider/provider.dart';
import 'services/menu_provider.dart';
import 'services/cart_provider.dart';
import 'services/auth_provider.dart';
import 'services/delivery_type_provider.dart';
import 'services/payment_type_provider.dart';
import 'services/delivery_cost_provider.dart';
import 'services/http_client.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Настраиваем размер кэша изображений
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024;
  
  // Создаем AuthProvider
  final authProvider = AuthProvider();
  
  // Инициализируем HTTP-клиент
  HttpClient().initialize(authProvider);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => DeliveryTypeProvider()),
        ChangeNotifierProvider(create: (_) => PaymentTypeProvider()),
        ChangeNotifierProvider(create: (_) => DeliveryCostProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Суши от Саши',
      theme: ThemeData(
        fontFamily: 'HattoriHanzo', // Основной шрифт
        textTheme: ThemeData.light().textTheme.copyWith(
          headlineLarge: AppTextStyles.H1,    // H1
          headlineMedium: AppTextStyles.H2,   // H2
          headlineSmall: AppTextStyles.H3,    // H3
          titleLarge: AppTextStyles.Title,    // Title
          titleMedium: AppTextStyles.Subtitle, // Subtitle
          bodyLarge: AppTextStyles.Body,      // Body
          bodyMedium: AppTextStyles.Caption,  // Caption
        ),
        scaffoldBackgroundColor: const Color(0xFF0C1F36), // Темный фон
      ),
      supportedLocales: const[
        Locale('ru', 'RU'), // Русский язык
        Locale('en', 'US'), // Английский язык
      ],
      localizationsDelegates: const[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: const Locale('ru', 'RU'),
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({Key? key}) : super(key: key);

  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Провайдеры загружают данные автоматически в конструкторах
    // Ждем минимальное время для показа логотипа
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SplashPage();
    }
    return const MainPage();
  }
}

class MainPage extends StatefulWidget {
  final int initialIndex;
  
  const MainPage({
    Key? key,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  final List<Widget> _pages = [
    MenuPage(), // Убедитесь, что MenuPage определен корректно
    SearchPage(),
    const CartPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: custom.MenuBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
