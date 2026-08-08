import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../utils/async_state.dart';
import '../../../../utils/map_api.dart';
import '../api/cost_check.dart';
import '../api/get_cost.dart' as api;

/// Состояние проверки адреса на попадание в зону доставки.
///
/// Сам запрос не делает — вызывает функцию слоя `api`. Его работа: хранить
/// состояние, дебаунсить ввод, отбрасывать ответы устаревших запросов и
/// дёргать колбэки.
///
/// ```dart
/// ChangeNotifierProvider(
///   create: (_) => GetCostModel(onSuccess: (data) => setDeliveryCost(data.price)),
///   child: Consumer<GetCostModel>(
///     builder: (_, model, __) => switch (model.state) {
///       AsyncIdle() => const SizedBox.shrink(),
///       AsyncLoading() => const CircularProgressIndicator(),
///       AsyncError(:final message) => Text(message),
///       AsyncData(:final value) => Text('${value.price} ₽'),
///     },
///   ),
/// )
/// ```
class GetCostModel extends ChangeNotifier {
  static const Duration defaultDebounce = Duration(milliseconds: 500);

  final api.GetCost _getCost;
  final Duration _debounce;
  final void Function(CostCheck data)? _onSuccess;
  final void Function(Object error)? _onError;
  final void Function()? _onFinally;

  GetCostModel({
    api.GetCost? getCost,
    Duration debounce = defaultDebounce,
    void Function(CostCheck data)? onSuccess,
    void Function(Object error)? onError,
    void Function()? onFinally,
  })  : _getCost = getCost ?? api.getCost,
        _debounce = debounce,
        _onSuccess = onSuccess,
        _onError = onError,
        _onFinally = onFinally;

  AsyncState<CostCheck> _state = const AsyncIdle<CostCheck>();

  AsyncState<CostCheck> get state => _state;

  String _query = '';

  /// Адрес, по которому был или будет сделан запрос.
  String get query => _query;

  Timer? _debounceTimer;
  MapApiCall<CostCheck>? _inFlight;
  bool _disposed = false;

  /// Номер актуального запроса. Ответ с чужим номером — устаревший, его
  /// результат не попадает ни в состояние, ни в колбэки.
  int _generation = 0;

  /// Задаёт адрес. Аналог `watch: [query]` — запрос уйдёт через `debounce`
  /// после последнего вызова. Тот же адрес повторно не запрашивается,
  /// пустой сбрасывает состояние в [AsyncIdle].
  void setQuery(String query) {
    final next = query.trim();
    if (next == _query) return;
    _query = next;

    _cancelPending();

    if (next.isEmpty) {
      _setState(const AsyncIdle<CostCheck>());
      return;
    }

    _debounceTimer = Timer(_debounce, _fetch);
  }

  /// Повторяет запрос немедленно, минуя дебаунс. Аналог `refresh()`.
  Future<void> refresh() {
    _cancelPending();

    if (_query.isEmpty) {
      _setState(const AsyncIdle<CostCheck>());
      return Future.value();
    }

    return _fetch();
  }

  Future<void> _fetch() async {
    final generation = _generation;
    _debounceTimer = null;
    _setState(const AsyncLoading<CostCheck>());

    final call = _getCost(_query);
    _inFlight = call;

    try {
      final data = await call.future;
      if (_isStale(generation)) return;

      _inFlight = null;
      _setState(AsyncData(data));
      _onSuccess?.call(data);
    } catch (error) {
      if (_isStale(generation)) return;

      _inFlight = null;
      _setState(AsyncError(_messageOf(error), error));
      _onError?.call(error);
    } finally {
      if (!_isStale(generation)) _onFinally?.call();
    }
  }

  /// Гасит таймер дебаунса и рвёт текущий запрос. Инкремент [_generation]
  /// здесь обязателен: без него ошибка от оборванного запроса приехала бы
  /// в состояние как настоящая.
  void _cancelPending() {
    _generation++;

    _debounceTimer?.cancel();
    _debounceTimer = null;

    _inFlight?.cancel();
    _inFlight = null;
  }

  bool _isStale(int generation) => _disposed || generation != _generation;

  void _setState(AsyncState<CostCheck> next) {
    if (_disposed) return;

    _state = next;
    notifyListeners();
  }

  /// Сервер отвечает 500, когда геокодер не разобрал адрес, и 422 на
  /// некорректное тело запроса. Показывать пользователю «Внутренняя ошибка
  /// сервера» бессмысленно — причина почти всегда в написании адреса.
  /// Сетевые сбои (`statusCode == null`) сообщают о себе честно.
  String _messageOf(Object error) {
    if (error is MapApiException) {
      return error.statusCode == null
          ? error.message
          : 'Не удалось определить зону доставки по этому адресу. Проверьте написание.';
    }

    return 'Не удалось проверить адрес. Попробуйте позже.';
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelPending();
    super.dispose();
  }
}
