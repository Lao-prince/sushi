import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/use_get_cost.dart';
import 'delivery_cost_view.dart';

/// Подключает [DeliveryCostView] к состоянию модели — аналог родительского
/// компонента, который вызывает `useGetCost` и передаёт результат в пропсы.
///
/// Требует, чтобы выше по дереву был `ChangeNotifierProvider<GetCostModel>`:
///
/// ```dart
/// ChangeNotifierProvider(
///   create: (_) => GetCostModel(),
///   child: Column(
///     children: [
///       TextField(controller: _streetController),
///       DeliveryCostSection(),
///     ],
///   ),
/// )
/// ```
///
/// Адрес в модель отдаёт тот, кто владеет полями ввода:
/// `context.read<GetCostModel>().setQuery('$city, $street, $house')`.
class DeliveryCostSection extends StatelessWidget {
  const DeliveryCostSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GetCostModel>(
      builder: (_, model, __) => DeliveryCostView(state: model.state),
    );
  }
}
