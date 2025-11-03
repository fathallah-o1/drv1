import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/api.dart';
import '../../core/ui.dart';
import '../../core/env.dart';

class ClosuresView extends StatefulWidget {
  const ClosuresView({super.key});
  @override
  State<ClosuresView> createState() => _ClosuresViewState();
}

class _ClosuresViewState extends State<ClosuresView> {
  List driver = [], restaurant = [];
  bool loading = true;

  static const _bg = Colors.white;
  static const _card = Color(0xFFF6F6F8);
  static const _text = Color(0xFF1B1B1F);
  static const _textMute = Color(0xFF6B7280);
  static const _divider = Color(0xFFE9E9EE);
  static final _r = BorderRadius.circular(16);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(()=>loading=true);
    try {
      final r = await Api.getJson('closures_list.php', {'driver_id':'${Env.driverId}'});
      driver = (r['driver'] ?? []) as List;
      restaurant = (r['restaurant'] ?? []) as List;
    } catch (_) {}
    setState(()=>loading=false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          title: const Text('سجل الإغلاقات',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
          centerTitle: true,
        ),
        backgroundColor: _bg,
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _section('إغلاقات السائق اليومية', driver, isDriver: true),
                  const SizedBox(height: 12),
                  _section('إغلاقات المطعم اليومية', restaurant),
                ],
              ),
      ),
    );
  }

  Widget _section(String title, List data, {bool isDriver=false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: _r,
        border: Border.all(color: _divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.history_toggle_off, color: Ui.orange, size: 18),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(
              color: _text, fontWeight: FontWeight.w800, fontSize: 16)),
          ]),
          const SizedBox(height: 8),
          ...data.map((e) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 0),
            title: Text(
              '${e['closing_date']} — ${isDriver ? e['delivery_earnings_total'] : e['orders_total']}',
              style: const TextStyle(color: _text, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              'عدد الطلبات: ${e['deliveries_count'] ?? e['orders_count']} — رقم الطلبات: ${e['order_ids']}',
              style: const TextStyle(color: _textMute),
            ),
          )),
        ],
      ),
    );
  }
}
