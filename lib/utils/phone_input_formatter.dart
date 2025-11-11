import 'package:flutter/services.dart';

class PhoneInputFormatter extends TextInputFormatter {
  static const String _prefix = '+7 (9';
  
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Если пользователь пытается удалить префикс, возвращаем его обратно
    if (!newValue.text.startsWith(_prefix)) {
      return TextEditingValue(
        text: _prefix,
        selection: TextSelection.collapsed(offset: _prefix.length),
      );
    }

    // Удаляем все нецифровые символы из ввода (кроме префикса)
    String numbers = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Убираем первую 7 и 9 (они уже в префиксе)
    if (numbers.startsWith('79')) {
      numbers = numbers.substring(2);
    } else if (numbers.startsWith('7')) {
      numbers = numbers.substring(1);
    }

    // Ограничиваем длину до 9 цифр (остальная 1 уже в префиксе: 9)
    if (numbers.length > 9) {
      numbers = numbers.substring(0, 9);
    }

    // Форматируем номер
    String formatted = _prefix;
    
    // Добавляем оставшиеся цифры кода (еще 2 цифры после 9)
        if (numbers.length > 0) {
      formatted += numbers.substring(0, numbers.length.clamp(0, 2));
        }
        
        // Добавляем закрывающую скобку и первые три цифры номера
    if (numbers.length > 2) {
      formatted += ') ${numbers.substring(2, numbers.length.clamp(2, 5))}';
        }
        
        // Добавляем дефис и следующие две цифры
    if (numbers.length > 5) {
      formatted += '-${numbers.substring(5, numbers.length.clamp(5, 7))}';
        }
        
        // Добавляем последний дефис и оставшиеся цифры
    if (numbers.length > 7) {
      formatted += '-${numbers.substring(7, numbers.length.clamp(7, 9))}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  // Метод для получения только цифр из отформатированного номера
  static String getUnformattedNumber(String formatted) {
    String numbers = formatted.replaceAll(RegExp(r'[^\d]'), '');
    // Убираем первую 7 если есть
    if (numbers.startsWith('7')) {
      numbers = numbers.substring(1);
    }
    return numbers.length == 10 ? numbers : '';
  }

  // Метод для проверки валидности номера
  static bool isValidNumber(String formatted) {
    String numbers = formatted.replaceAll(RegExp(r'[^\d]'), '');
    // Должно быть 11 цифр (7 + 10), первая цифра после 7 должна быть 9
    return numbers.length == 11 && numbers.startsWith('79');
  }

  static String formatForApi(String phone) {
    // Удаляем все нецифровые символы
    String numbers = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Формат должен быть +79XXXXXXXXX (11 цифр с +)
    if (numbers.length == 11 && numbers.startsWith('7')) {
      return '+$numbers';
    }
    
    // Если начинается с 9 и длина 10 цифр, добавляем +7
    if (numbers.length == 10 && numbers.startsWith('9')) {
      return '+7$numbers';
    }
    
    return phone; // Возвращаем исходный номер, если формат не распознан
  }
}
