/// Состояние асинхронной операции.
///
/// Заменяет тройку `isLoading` / `errorMessage` / `data`: невыразимы
/// невозможные комбинации вроде «грузится и при этом ошибка и при этом есть
/// данные», а `switch` по sealed-типу не даёт забыть ветку — компилятор
/// проверяет полноту разбора.
///
/// ```dart
/// switch (model.state) {
///   case AsyncIdle():                 return const SizedBox.shrink();
///   case AsyncLoading():              return const CircularProgressIndicator();
///   case AsyncError(:final message):  return Text(message);
///   case AsyncData(:final value):     return Text('${value.price} ₽');
/// }
/// ```
sealed class AsyncState<T> {
  const AsyncState();

  /// Данные последнего успешного ответа, иначе `null`.
  T? get valueOrNull => switch (this) {
        AsyncData<T>(:final value) => value,
        _ => null,
      };

  bool get isLoading => this is AsyncLoading<T>;
}

/// Запроса ещё не было либо он сброшен.
final class AsyncIdle<T> extends AsyncState<T> {
  const AsyncIdle();
}

/// Запрос выполняется.
final class AsyncLoading<T> extends AsyncState<T> {
  const AsyncLoading();
}

/// Запрос успешно завершён.
final class AsyncData<T> extends AsyncState<T> {
  final T value;

  const AsyncData(this.value);
}

/// Запрос завершён ошибкой.
final class AsyncError<T> extends AsyncState<T> {
  /// Текст, готовый к показу пользователю.
  final String message;

  /// Исходная ошибка — для логов и отладки.
  final Object error;

  const AsyncError(this.message, this.error);
}
