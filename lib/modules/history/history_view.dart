import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/ui.dart';
import 'history_controller.dart';
import 'history_types.dart';

/// ثوابت تصميم عامة
const Color _HBG = Colors.white;
const Color _HCARD = Color(0xFFF6F6F8);
const Color _HTEXT = Color(0xFF1B1B1F);
const Color _HTEXT_MUTE = Color(0xFF6B7280);
const Color _HDIVIDER = Color(0xFFE9E9EE);
final BorderRadius _HR = BorderRadius.circular(16);

class HistoryView extends StatelessWidget {
  const HistoryView({super.key, this.kind = HistoryKind.delivered});
  final HistoryKind kind;

  @override
  Widget build(BuildContext context) {
    final c = Get.put(HistoryController(kind: kind));

    const ranges = [
      ['today', 'اليوم'],
      ['week', 'هذا الأسبوع'],
      ['month', 'هذا الشهر'],
      ['all', 'كل الوقت'],
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _HBG,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          title: Text(
            kind.label,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
          ),
          centerTitle: true,
        ),
        backgroundColor: _HBG,
        body: Column(
          children: [
            const SizedBox(height: 8),
            Obx(
              () => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: ranges.map((r) {
                    final String v = r[0];
                    final String label = r[1];
                    final selected = c.range.value == v;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (_) {
                          c.range.value = v;
                          c.loadAll();
                        },
                        backgroundColor: _HCARD,
                        selectedColor: Ui.orange.withOpacity(.18),
                        labelStyle: TextStyle(
                          color: selected ? _HTEXT : _HTEXT_MUTE,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        shape: StadiumBorder(
                          side: BorderSide(color: selected ? Ui.orange : _HDIVIDER),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // للتبويب: الطلبات + سجلات الإغلاق (إن وُجدت)
            if (kind == HistoryKind.dues ||
                kind == HistoryKind.debt ||
                kind == HistoryKind.profit)
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        indicator: const UnderlineTabIndicator(
                          borderSide: BorderSide(color: Ui.orange, width: 3),
                        ),
                        labelColor: _HTEXT,
                        unselectedLabelColor: _HTEXT_MUTE,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                        tabs: const [
                          Tab(text: 'الطلبات'),
                          Tab(text: 'سجلات الإغلاق'),
                        ],
                      ),
                      const Expanded(child: _HistoryTabs()),
                    ],
                  ),
                ),
              )
            else
              const Expanded(child: _OrdersOnly()),
          ],
        ),
      ),
    );
  }
}

class _OrdersOnly extends GetView<HistoryController> {
  const _OrdersOnly({super.key});
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.loading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.orders.isEmpty) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _HCARD,
              borderRadius: _HR,
              border: Border.all(color: _HDIVIDER),
            ),
            child: const Text('لا يوجد بيانات', style: TextStyle(color: _HTEXT_MUTE)),
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(12),
        itemBuilder: (_, i) {
          final o = controller.orders[i];
          return _orderTile(o, controller.valueOf(o));
        },
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: controller.orders.length,
      );
    });
  }
}

class _HistoryTabs extends GetView<HistoryController> {
  const _HistoryTabs({super.key});
  @override
  Widget build(BuildContext context) {
    return TabBarView(
      children: [
        // تبويب الطلبات
        Obx(() {
          if (controller.loading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.orders.isEmpty) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _HCARD,
                  borderRadius: _HR,
                  border: Border.all(color: _HDIVIDER),
                ),
                child: const Text('لا يوجد بيانات', style: TextStyle(color: _HTEXT_MUTE)),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemBuilder: (_, i) {
              final o = controller.orders[i];
              return _orderTile(o, controller.valueOf(o));
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: controller.orders.length,
          );
        }),
        // تبويب سجلات الإغلاق
        Obx(() {
          if (controller.loading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.closures.isEmpty) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _HCARD,
                  borderRadius: _HR,
                  border: Border.all(color: _HDIVIDER),
                ),
                child: const Text('لا يوجد سجلات إغلاق', style: TextStyle(color: _HTEXT_MUTE)),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemBuilder: (_, i) {
              final r = controller.closures[i];
              return Card(
                color: _HCARD,
                shape: RoundedRectangleBorder(
                  borderRadius: _HR,
                  side: const BorderSide(color: _HDIVIDER),
                ),
                child: ListTile(
                  title: Text(
                    'تاريخ الإغلاق: ${r['closing_date']}',
                    style: const TextStyle(color: _HTEXT, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'القيمة: ${r['amount']} — الطلبات: ${r['order_ids']}',
                    style: const TextStyle(color: _HTEXT_MUTE),
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: controller.closures.length,
          );
        }),
      ],
    );
  }
}

/// بطاقة الطلب داخل القوائم
Widget _orderTile(Map<String, dynamic> o, String valueText) {
  final items = (o['items_text'] ?? '') as String;
  final user = (o['username'] ?? '') as String;
  final phone = (o['phone'] ?? '') as String;

  return Card(
    color: _HCARD,
    shape: RoundedRectangleBorder(
      borderRadius: _HR,
      side: const BorderSide(color: _HDIVIDER),
    ),
    child: ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Ui.orange.withOpacity(.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.receipt_long, color: Colors.black87),
      ),
      title: Text(
        '#${o['id']} — $user ($phone)',
        style: const TextStyle(color: _HTEXT, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        items.isEmpty ? '-' : items,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: _HTEXT_MUTE),
      ),
      trailing: Text(
        valueText,
        style: const TextStyle(color: _HTEXT, fontWeight: FontWeight.w800),
      ),
    ),
  );
}
