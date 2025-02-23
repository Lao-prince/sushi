import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pages/menu_page.dart'; // Убедитесь, что путь к файлу правильный
import 'pages/search_page.dart'; // Убедитесь, что путь к файлу правильный
import 'pages/cart_page.dart'; // Убедитесь, что путь к файлу правильный
import 'pages/profile_page.dart'; // Убедитесь, что путь к файлу правильный
import 'widgets/menu_bar.dart' as custom; // Используем псевдоним
import 'style/styles.dart'; // Файл со стилями текста
import 'package:provider/provider.dart';
import 'services/menu_provider.dart';
import 'services/cart_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
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
      title: 'Sushi Menu',
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
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

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
