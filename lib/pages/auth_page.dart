import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../style/styles.dart';
import '../utils/phone_input_formatter.dart';
import '../main.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isRegistration = false;
  String? _userId;
  bool _isWaitingForCode = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!_isWaitingForCode) {
      // Первый шаг регистрации - отправка телефона и пароля
      final phone = PhoneInputFormatter.formatForApi(_phoneController.text);
      final registrationResult = await authProvider.startRegistration(
        phone,
        _passwordController.text,
      );

      if (registrationResult != null) {
        setState(() {
          _userId = registrationResult;
          _isWaitingForCode = true;
          _isLoading = false;
        });
        
        // Показываем сообщение о успешной отправке кода
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Код подтверждения отправлен в WhatsApp'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ошибка регистрации. Возможно, этот номер уже зарегистрирован'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
      }
    } else {
      // Второй шаг регистрации - подтверждение кода
      final success = await authProvider.completeRegistration(
        _userId!,
        _codeController.text,
      );

      setState(() => _isLoading = false);

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Неверный код подтверждения'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final phone = PhoneInputFormatter.formatForApi(_phoneController.text);
    final success = await authProvider.login(
      phone,
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка авторизации'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final phone = PhoneInputFormatter.formatForApi(_phoneController.text);
    final registrationResult = await authProvider.startRegistration(
      phone,
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (registrationResult != null) {
      setState(() {
        _userId = registrationResult;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Код подтверждения повторно отправлен в WhatsApp'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка при повторной отправке кода'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFFD1930D),
          ),
          onPressed: () {
            if (_isWaitingForCode) {
              // Если мы на этапе ввода кода, возвращаемся к вводу телефона и пароля
              setState(() {
                _isWaitingForCode = false;
                _userId = null;
                _codeController.clear();
              });
            } else {
              // Возвращаемся на главную страницу (индекс 0 - это страница меню)
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainPage(initialIndex: 0),
                ),
              );
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isRegistration 
                    ? (_isWaitingForCode ? 'Подтверждение' : 'Регистрация')
                    : 'Вход',
                  style: AppTextStyles.H1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _phoneController,
                  enabled: !_isWaitingForCode,
                  decoration: InputDecoration(
                    labelText: 'Телефон',
                    labelStyle: AppTextStyles.Body,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: '+7 (___) ___-__-__',
                  ),
                  style: AppTextStyles.Body,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    PhoneInputFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите номер телефона';
                    }
                    if (!PhoneInputFormatter.isValidNumber(value)) {
                      return 'Введите корректный номер телефона';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  enabled: !_isWaitingForCode,
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    labelStyle: AppTextStyles.Body,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: AppTextStyles.Body,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите пароль';
                    }
                    if (value.length < 6) {
                      return 'Пароль должен быть не менее 6 символов';
                    }
                    return null;
                  },
                ),
                if (_isRegistration && _isWaitingForCode) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: 'Код из WhatsApp',
                      labelStyle: AppTextStyles.Body,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    style: AppTextStyles.Body,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите код подтверждения';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _isLoading ? null : _resendCode,
                    child: Text(
                      'Отправить код повторно',
                      style: AppTextStyles.Body.copyWith(
                        color: const Color(0xFFD1930D),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : (_isRegistration ? _submitRegistration : _submitLogin),
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
                          _isRegistration
                              ? (_isWaitingForCode ? 'Подтвердить' : 'Зарегистрироваться')
                              : 'Войти',
                          style: AppTextStyles.Body.copyWith(color: Colors.white),
                        ),
                ),
                const SizedBox(height: 16),
                if (!_isWaitingForCode)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isRegistration = !_isRegistration;
                        _codeController.clear();
                      });
                    },
                    child: Text(
                      _isRegistration
                          ? 'Уже есть аккаунт? Войти'
                          : 'Нет аккаунта? Зарегистрироваться',
                      style: AppTextStyles.Body.copyWith(
                        color: const Color(0xFFD1930D),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

