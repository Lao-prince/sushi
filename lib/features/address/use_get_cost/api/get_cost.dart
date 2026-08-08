import '../../../../utils/map_api.dart';
import 'cost_check.dart';

/// Путь эндпоинта проверки адреса относительно baseUrl API карт.
const String getCostEndpoint = 'v1/zones/check-by-address';

/// Подпись функции запроса. Именно её подменяют в тестах и моках, чтобы
/// проверять [GetCostModel] без настоящего HTTP.
typedef GetCost = MapApiCall<CostCheck> Function(String address);

/// Спрашивает у API карт, попадает ли адрес в зону доставки и сколько стоит.
///
/// Знает только про эндпоинт, тело запроса и разбор ответа. Ни о состоянии,
/// ни о дебаунсе, ни об UI не знает — это работа [GetCostModel].
///
/// Возвращает не голый `Future`, а [MapApiCall]: тот же `future` плюс
/// `cancel()`, которым запрос обрывается, если адрес успел измениться.
MapApiCall<CostCheck> getCost(String address, {MapApi? api}) {
  return (api ?? MapApi()).post('v1/zones/check-by-address',
    body: {'address': address},
    decode: CostCheck.fromJson,
  );
}
