import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

/// Ошибка обращения к API карт.
class MapApiException implements Exception {
  /// Текст, готовый к показу пользователю.
  final String message;

  /// HTTP-код ответа, если ответ вообще дошёл.
  final int? statusCode;

  /// Поле `detail` из тела ответа — FastAPI кладёт причину туда.
  /// Только для логов: пользователю его показывать не стоит.
  final Object? serverDetail;

  MapApiException(this.message, {this.statusCode, this.serverDetail});

  @override
  String toString() => 'MapApiException(${statusCode ?? '-'}): $message'
      '${serverDetail == null ? '' : ' | detail: $serverDetail'}';
}

/// Выполняющийся запрос, который можно оборвать.
///
/// После [cancel] соединение разрывается и [future] завершается ошибкой —
/// вызывающая сторона обязана этот результат проигнорировать.
class MapApiCall<T> {
  final Future<T> future;
  final void Function() _cancel;

  /// Конструктор публичный намеренно: так функции слоя `api` можно подменить
  /// в тестах и моках, не поднимая настоящий HTTP-клиент.
  MapApiCall(this.future, void Function() cancel) : _cancel = cancel;

  void cancel() => _cancel();
}

/// HTTP-клиент API карт: свой baseUrl, без авторизации, без ретраев.
///
/// Умышленно отдельный от `HttpClient` из `services/`: тот — синглтон,
/// подмешивает `Authorization` из `AuthProvider` и ретраит трижды с бэкоффом
/// 2с/4с. Для проверки адреса по мере ввода ретраи вредны — пользователь
/// успевает дописать адрес раньше, чем они закончатся, — а токен здесь не
/// нужен вовсе.
class MapApi {
  static const String defaultBaseUrl = AppConfig.mapBaseUrl;
  static const Duration defaultTimeout = Duration(seconds: 15);

  final String _baseUrl;
  final Duration _timeout;

  /// Фабрика клиентов. Отдельный клиент на запрос — чтобы его можно было
  /// закрыть, не задев остальные. В тестах подменяется на `MockClient`.
  final http.Client Function() _clientFactory;

  MapApi({
    String baseUrl = defaultBaseUrl,
    Duration timeout = defaultTimeout,
    http.Client Function()? clientFactory,
  })  : _baseUrl = baseUrl,
        _timeout = timeout,
        _clientFactory = clientFactory ?? http.Client.new;

  /// POST с JSON-телом. [decode] получает уже разобранный JSON-объект.
  MapApiCall<T> post<T>(
    String path, {
    Object? body,
    required T Function(Map<String, dynamic> json) decode,
  }) {
    final client = _clientFactory();
    final future = _send(client, path, body, decode).whenComplete(client.close);

    return MapApiCall(future, client.close);
  }

  Future<T> _send<T>(
    http.Client client,
    String path,
    Object? body,
    T Function(Map<String, dynamic> json) decode,
  ) async {
    final http.Response response;
    try {
      response = await client
          .post(
            _resolve(path),
            headers: const {'Content-Type': 'application/json'},
            body: body == null ? null : json.encode(body),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw MapApiException('Сервер не ответил вовремя. Попробуйте ещё раз.');
    } catch (error) {
      throw MapApiException('Нет связи с сервером. Проверьте интернет-соединение.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MapApiException(
        'Сервер вернул ошибку ${response.statusCode}.',
        statusCode: response.statusCode,
        serverDetail: _detailOf(response),
      );
    }

    final Map<String, dynamic> payload;
    try {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('ожидался JSON-объект');
      }
      payload = decoded;
    } catch (error) {
      throw MapApiException(
        'Сервер вернул неожиданный ответ.',
        statusCode: response.statusCode,
      );
    }

    try {
      return decode(payload);
    } catch (error) {
      throw MapApiException(
        'Не удалось разобрать ответ сервера.',
        statusCode: response.statusCode,
      );
    }
  }

  /// Вытаскивает `detail` из тела ошибочного ответа. Само тело может быть
  /// не-JSON — тогда причины просто нет.
  Object? _detailOf(http.Response response) {
    try {
      final decoded = json.decode(utf8.decode(response.bodyBytes));

      return decoded is Map<String, dynamic> ? decoded['detail'] : null;
    } catch (_) {
      return null;
    }
  }

  /// Склеивает baseUrl и путь, не заботясь о том, у кого из них есть слеш.
  Uri _resolve(String path) {
    final base = _baseUrl.endsWith('/') ? _baseUrl : '$_baseUrl/';
    final tail = path.startsWith('/') ? path.substring(1) : path;

    return Uri.parse('$base$tail');
  }
}
