/// Ответ `v1/zones/check-by-address` — попадает ли адрес в зону доставки.
///
/// Проверено на живом API:
/// * `Ступино, Крупской, 1` → `{"in_zone":true,"zone_id":44,"price":250.0}`
/// * `Москва, Тверская, 1`  → `{"in_zone":false,"zone_id":null,"price":null}`
/// * нераспознанный адрес   → HTTP 500, до парсинга дело не доходит
class CostCheck {
  /// Доставляем ли по этому адресу.
  final bool inZone;

  /// Идентификатор зоны; `null`, когда адрес ни в одну зону не попал.
  final int? zoneId;

  /// Стоимость доставки. `null` вне зоны — именно `null`, а не `0`, чтобы
  /// «не доставляем» нельзя было случайно показать как «доставка бесплатна».
  final double? price;

  const CostCheck({
    required this.inZone,
    this.zoneId,
    this.price,
  });

  /// Касты идут через `num`, а не через `int`/`double` напрямую: `jsonDecode`
  /// возвращает `int` для `250` и `double` для `250.0`, поэтому
  /// `json['price'] as double?` упало бы на целом числе.
  ///
  /// `in_zone` сверяется с `true`, а не кастуется: пропущенное поле даёт
  /// «не доставляем» — безопасная трактовка, ложного «доставляем» не будет.
  factory CostCheck.fromJson(Map<String, dynamic> json) {
    return CostCheck(
      inZone: json['in_zone'] == true,
      zoneId: (json['zone_id'] as num?)?.toInt(),
      price: (json['price'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'in_zone': inZone,
        'zone_id': zoneId,
        'price': price,
      };

  @override
  String toString() => 'CostCheck(inZone: $inZone, zoneId: $zoneId, price: $price)';
}
