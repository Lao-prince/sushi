import 'package:flutter/services.dart';

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Удаляем все нецифровые символы из ввода
    String numbers = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Ограничиваем длину до 11 цифр (1 для кода страны + 10 для номера)
    if (numbers.length > 11) {
      numbers = numbers.substring(0, 11);
    }

    // Форматируем номер
    String formatted = '';
    if (numbers.isNotEmpty) {
      // Добавляем +7
      formatted = '+7';
      
      if (numbers.length > 1) {
        // Пропускаем первую цифру если это 7 или 8
        if (numbers[0] == '7' || numbers[0] == '8') {
          numbers = numbers.substring(1);
        }
        
        // Добавляем скобку для кода
        if (numbers.length > 0) {
          formatted += ' (${numbers.substring(0, numbers.length.clamp(0, 3))}';
        }
        
        // Добавляем закрывающую скобку и первые три цифры номера
        if (numbers.length > 3) {
          formatted += ') ${numbers.substring(3, numbers.length.clamp(3, 6))}';
        }
        
        // Добавляем дефис и следующие две цифры
        if (numbers.length > 6) {
          formatted += '-${numbers.substring(6, numbers.length.clamp(6, 8))}';
        }
        
        // Добавляем последний дефис и оставшиеся цифры
        if (numbers.length > 8) {
          formatted += '-${numbers.substring(8, numbers.length.clamp(8, 10))}';
        }
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  // Метод для получения только цифр из отформатированного номера
  static String getUnformattedNumber(String formatted) {
    String numbers = formatted.replaceAll(RegExp(r'[^\d]'), '');
    if (numbers.startsWith('7') || numbers.startsWith('8')) {
      numbers = numbers.substring(1);
    }
    return numbers.length == 10 ? numbers : '';
  }

  // Метод для проверки валидности номера
  static bool isValidNumber(String formatted) {
    return getUnformattedNumber(formatted).length == 10;
  }

  static String formatForApi(String phone) {
    // Удаляем все нецифровые символы
    String numbers = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Если номер начинается с 7 или 8, убираем эту цифру
    if (numbers.startsWith('7') || numbers.startsWith('8')) {
      numbers = numbers.substring(1);
    }
    
    // Если длина номера 10 цифр, добавляем +7
    if (numbers.length == 10) {
      return '+7$numbers';
    }
    
    return phone; // Возвращаем исходный номер, если формат не распознан
  }
}
