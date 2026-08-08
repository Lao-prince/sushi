class AppConfig {
  // Только origin, без /api и без слеша в конце:
  // все вызовы в коде дописывают путь сами ('$baseUrl/api/menu/products').
  static const String baseUrl = 'https://back.sushiotsashi.ru';

  /// API карт и зон доставки. Здесь, в отличие от [baseUrl], путь `/api/`
  /// уже включён — вызовы дописывают только версию и метод.
  static const String mapBaseUrl = 'http://89.223.122.180:8090/api/';

  /// Телефон оператора — для случаев, когда стоимость доставки посчитать
  /// не удалось.
  static const String operatorPhone = '8 (967) 160-70-00';

  /// Тот же номер в виде ссылки. `+7` вместо `8` — так набор корректно
  /// срабатывает и при роуминге.
  static const String operatorPhoneUri = 'tel:+79671607000';
}
