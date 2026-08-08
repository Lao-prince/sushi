import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config.dart';
import '../../../../style/styles.dart';
import '../../../../utils/async_state.dart';
import '../api/cost_check.dart';

/// Строка со стоимостью доставки. Ничего не запрашивает и состоянием не
/// владеет — только рисует то, что ей передали. Состояние берёт
/// `DeliveryCostSection`.
class DeliveryCostView extends StatelessWidget {
  static const Color _accent = Color(0xFFD1930D);

  final AsyncState<CostCheck> state;

  const DeliveryCostView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      // Адрес не введён — не занимаем место на экране.
      AsyncIdle() => const SizedBox.shrink(),

      AsyncLoading() => const _Block(
          child: Row(
            children: [
              Text('Стоимость доставки: ', style: AppTextStyles.Body),
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
              ),
            ],
          ),
        ),

      // Единственная ветка, где есть что показать. Проверка `price != null`
      // не формальность: вне зоны сервер присылает `price: null`.
      AsyncData(:final value) when value.inZone && value.price != null => _Block(
          child: Text(
            'Стоимость доставки: ${_amount(value.price!)} ${_rubles(value.price!)}',
            style: AppTextStyles.Body,
          ),
        ),

      // Вне зоны и любая ошибка выглядят одинаково: технических текстов
      // пользователь не видит, вместо них — телефон оператора.
      AsyncData() || AsyncError() => const _CallOperator(),
    };
  }

  /// `250.0` → `250`, но `249.5` → `249.5`. Нули после запятой в цене лишние.
  static String _amount(double price) => price == price.roundToDouble()
      ? price.toInt().toString()
      : price.toString();

  /// «191 рубль», «192 рубля», «250 рублей». Без этого получалось бы
  /// «191 рублей» — в твоём шаблоне слово было захардкожено.
  static String _rubles(double price) {
    final amount = price.round();
    final lastTwo = amount % 100;
    if (lastTwo >= 11 && lastTwo <= 14) return 'рублей';

    return switch (amount % 10) {
      1 => 'рубль',
      2 || 3 || 4 => 'рубля',
      _ => 'рублей',
    };
  }
}

/// Вертикальные отступы вокруг блока — аналог `class="q-my-md"`.
class _Block extends StatelessWidget {
  final Widget child;

  const _Block({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: child,
    );
  }
}

/// «Стоимость доставки уточняйте у оператора по телефону …» с кликабельным
/// номером. Разметка как у ссылок в оформлении заказа: `RichText` +
/// `WidgetSpan` + `GestureDetector`.
class _CallOperator extends StatelessWidget {
  const _CallOperator();

  @override
  Widget build(BuildContext context) {
    return _Block(
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.Body,
          children: [
            const TextSpan(
              text: 'Стоимость доставки уточняйте у оператора по телефону ',
            ),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                onTap: _call,
                child: Text(
                  AppConfig.operatorPhone,
                  style: AppTextStyles.Body.copyWith(
                    color: DeliveryCostView._accent,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _call() async {
    final uri = Uri.parse(AppConfig.operatorPhoneUri);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
