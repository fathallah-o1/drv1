import 'package:get/get.dart';
import '../../core/api.dart';
import '../../core/env.dart';
import 'history_types.dart';

class HistoryController extends GetxController {
  HistoryController({required this.kind});
  final HistoryKind kind;

  final range = 'today'.obs; // today|week|month|all
  final loading = false.obs;
  final orders = <Map<String, dynamic>>[].obs;
  final closures = <Map<String, dynamic>>[].obs; // لسجلات الإغلاق (dues/debt/profit)

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    loading.value = true;
    try {
      await Future.wait([loadOrders(), loadClosures()]);
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadOrders() async {
    final m = await Api.getJson('orders_history.php', {
      'driver_id': '${Env.driverId}',
      'type': kind.apiType,
      'range': range.value,
    });
    final list = (m['data'] ?? []) as List;
    orders.assignAll(List<Map<String, dynamic>>.from(list));
  }

  Future<void> loadClosures() async {
    // للسجلات ذات الإغلاق فقط
    if (kind == HistoryKind.dues || kind == HistoryKind.debt || kind == HistoryKind.profit) {
      final m = await Api.getJson('closures_history.php', {
        'driver_id': '${Env.driverId}',
        'type': kind.apiType, // 'dues' | 'debt' | 'profit'
        'range': range.value,
      });
      final list = (m['data'] ?? []) as List;
      closures.assignAll(List<Map<String, dynamic>>.from(list));
    } else {
      closures.clear();
    }
  }

  // القيمة المعروضة لكل طلب حسب النوع
  String valueOf(Map<String, dynamic> o) {
    switch (kind) {
      case HistoryKind.delivered:
      case HistoryKind.rejected:
        return (o['total'] ?? 0).toString(); // المجموع الكلي إن أردتها
      case HistoryKind.profit:
      case HistoryKind.dues:
        return (o['delivery_fee'] ?? 0).toString();
      case HistoryKind.debt:
        final t = (o['total'] ?? 0) * 1.0;
        final f = (o['delivery_fee'] ?? 0) * 1.0;
        return (t - f).toStringAsFixed(2);
    }
  }
}
