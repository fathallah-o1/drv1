import 'dart:async';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/api.dart';
import '../../core/env.dart';

// خدمات إضافية
import '../../core/bg_location_service.dart';
import '../../core/power_optimizations.dart';

class HomeController extends GetxController {
  final loading = false.obs;

  // all | month | week | today
  final range = 'all'.obs;
  final isOnline = false.obs;

  // ╔══════════════════════════════════════════════════════════╗
  // ║      بيانات السائق (مضافة)                               ║
  // ╚══════════════════════════════════════════════════════════╝
  final driverName = ''.obs;
  final driverPhone = ''.obs;
  final driverLastSeen = ''.obs;

  // إحصائيات
  final delivered = 0.obs;
  final rejected = 0.obs;
  final profitAll = 0.0.obs;
  final duesToday = 0.0.obs;
  final debtToday = 0.0.obs;

  // الطلبات
  final orders = <Map<String, dynamic>>[].obs;

  Timer? _poller;
  bool _isTicking = false; // قفل لمنع تداخل _tick
  late final GetStorage _box;

  @override
  void onInit() {
    super.onInit();
    _box = GetStorage();

    if (Env.driverId == 0) {
      Get.offAllNamed('/login');
      return;
    }

    // استرجاع حالة الأونلاين (لكن لا نُشغّل الخدمة هنا)
    final savedOnline = _box.read('driverOnline') == true;
    isOnline.value = savedOnline;

    // تحميل بيانات السائق أولاً
    loadDriverInfo();

    _tick();
    _poller = Timer.periodic(Env.pollInterval, (_) => _tick());
  }

  @override
  void onClose() {
    _poller?.cancel();
    super.onClose();
  }

  // ╔══════════════════════════════════════════════════════════╗
  // ║      تحميل بيانات السائق (مضافة)                         ║
  // ╚══════════════════════════════════════════════════════════╝
  Future<void> loadDriverInfo() async {
    try {
      // نحاول endpoint أساسي ثم بديل لو اسم الملف مختلف عندك
      Map<String, dynamic> r = await Api.getJson('driver_profile.php', {
        'driver_id': '${Env.driverId}',
      });

      // fallback لو السيرفر يستعمل اسم آخر
      if (r['status'] != 'ok' && r['driver'] == null) {
        r = await Api.getJson('driver_me.php', {
          'driver_id': '${Env.driverId}',
        });
      }

      final d = (r['driver'] ??
              r['data'] ??
              r) as Map<String, dynamic>?; // مرونة مع الـ API
      driverName.value = (d?['name'] ?? '').toString();
      driverPhone.value = (d?['phone'] ?? '').toString();
      driverLastSeen.value = (d?['last_seen'] ?? '').toString();
    } catch (_) {
      // بصمت — الواجهة ستعمل حتى بدون البيانات
    }
  }

  Future<void> _tick() async {
    if (_isTicking) return;
    _isTicking = true;
    try {
      await Future.wait([
        loadDashboard(),
        loadOrders(),
      ]);
      await _pushDriverStatus();
      if (isOnline.value) {
        await _sendDriverPing();
        // الخدمة تُشغَّل فقط لو أونلاين — هنا آمن
        await BackgroundLocationService.start(Env.driverId);
      }
    } finally {
      _isTicking = false;
    }
  }

  Future<void> _pushDriverStatus() async {
    try {
      await Api.postJson('driver_toggle_online.php', {
        'driver_id': '${Env.driverId}',
        'online': isOnline.value ? '1' : '0',
      });
    } catch (e) {
      Get.snackbar('تنبيه', 'تعذّر تحديث حالة السائق: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _sendDriverPing() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar('الموقع مُعطّل', 'فعّل خدمة الموقع لإرسال موقعك الحي.',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        Get.snackbar('إذن الموقع', 'من فضلك امنح إذن الموقع من الإعدادات.',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      await Api.postJson('driver_ping.php', {
        'driver_id': '${Env.driverId}',
        'lat': pos.latitude.toStringAsFixed(7),
        'lng': pos.longitude.toStringAsFixed(7),
      });
    } catch (_) {
      // بصمت
    }
  }

  Future<void> loadDashboard() async {
    try {
      final m = await Api.getJson('dashboard.php', {
        'driver_id': '${Env.driverId}',
        'range': range.value,
      });
      delivered.value = (m['delivered'] ?? 0) as int;
      rejected.value = (m['rejected'] ?? 0) as int;
      profitAll.value = double.tryParse('${m['profit_all'] ?? 0}') ?? 0;
      duesToday.value = double.tryParse('${m['dues_today'] ?? 0}') ?? 0;
      debtToday.value = double.tryParse('${m['debt_today'] ?? 0}') ?? 0;
    } catch (e) {
      Get.snackbar('خطأ', 'تعذّر تحميل اللوحة: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> loadOrders() async {
    try {
      final m = await Api.getJson('orders_assigned.php', {
        'driver_id': '${Env.driverId}',
      });
      final list = (m['orders'] ?? m['data'] ?? []) as List;
      orders.assignAll(List<Map<String, dynamic>>.from(list));
    } catch (e) {
      Get.snackbar('خطأ', 'تعذّر تحميل الطلبات: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> markDelivered(int orderId) async {
    if (loading.value) return;
    loading.value = true;
    try {
      final r = await Api.postJson('order_update_status.php', {
        'order_id': '$orderId',
        'driver_id': '${Env.driverId}',
        'status': 'delivered',
      });
      if (r['status'] == 'ok') {
        Get.snackbar('تم', 'تم تعيين الطلب #$orderId كـ تم التسليم',
            snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('خطأ', 'لم يتم قبول العملية',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'تعذّر تحديث الطلب: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      loading.value = false;
      await _tick();
    }
  }

  Future<void> markRejected(int orderId, {String? reason}) async {
    if (loading.value) return;
    loading.value = true;
    try {
      final r = await Api.postJson('order_update_status.php', {
        'order_id': '$orderId',
        'driver_id': '${Env.driverId}',
        'status': 'rejected',
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
      if (r['status'] == 'ok') {
        Get.snackbar('تم', 'تم تعيين الطلب #$orderId كـ تم الرفض',
            snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('خطأ', 'لم يتم قبول العملية',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'تعذّر تحديث الطلب: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      loading.value = false;
      await _tick();
    }
  }

  Future<void> closeDriverDaily({String period = 'day'}) async {
    if (loading.value) return;
    loading.value = true;
    try {
      final r = await Api.postJson('close_driver_daily.php', {
        'driver_id': '${Env.driverId}',
        'period': period,
      });
      if (r['status'] == 'ok') {
        final msg = period == 'week'
            ? 'تم إغلاق حساب السائق للأسبوع'
            : 'تم إغلاق حساب السائق لليوم';
        Get.snackbar('تم', msg, snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('تنبيه', '${r['message'] ?? 'لم يتم الإغلاق'}',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر إغلاق حساب السائق: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      loading.value = false;
      await _tick();
    }
  }

  Future<void> closeRestaurantDaily({String period = 'day'}) async {
    if (loading.value) return;
    loading.value = true;
    try {
      final r = await Api.postJson('close_restaurant_daily.php', {
        'driver_id': '${Env.driverId}',
        'period': period,
      });
      if (r['status'] == 'ok') {
        final msg = period == 'week'
            ? 'تم إغلاق حساب المطعم للأسبوع'
            : 'تم إغلاق حساب المطعم لليوم';
        Get.snackbar('تم', msg, snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('تنبيه', '${r['message'] ?? 'لم يتم الإغلاق'}',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر إغلاق حساب المطعم: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      loading.value = false;
      await _tick();
    }
  }

  Future<void> setOnline(bool v) async {
    isOnline.value = v;
    if (v) {
      // نعرض حوار نصائح البطارية (يدوي، لا يفتح شاشات تلقائيًا)
      await PowerOptimizations.maybePromptOnce();
    }
    _box.write('driverOnline', v); // احفظ الحالة محلياً

    await _pushDriverStatus();

    if (v) {
      await _sendDriverPing();
      try {
        await BackgroundLocationService.start(Env.driverId);
      } catch (_) {}
    } else {
      try {
        await BackgroundLocationService.stop();
      } catch (_) {}
    }

    Get.snackbar(
      'الحالة',
      v ? 'السائق متصل، سيتم مشاركة الموقع' : 'السائق غير متصل، تم إخفاء الموقع',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void logout() {
    final box = GetStorage();
    box.remove('driverId');
    box.remove('driverOnline');
    Env.driverId = 0;
    Get.offAllNamed('/login');
    Get.snackbar('تم', 'تم تسجيل الخروج', snackPosition: SnackPosition.BOTTOM);
  }
}
