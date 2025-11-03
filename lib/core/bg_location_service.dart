import 'dart:async';
import 'dart:ui';
import 'package:flutter/widgets.dart'; // لإصلاح DartPluginRegistrant.ensureInitialized()
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import '../core/api.dart';

class BackgroundLocationService {
  static const _channelId = 'evoranta_driver_channel';
  static const _notifId = 9913;

  static Future<void> init() async {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _channelId,
        initialNotificationTitle: 'EVORANTA Driver',
        initialNotificationContent: 'مشاركة الموقع مفعّلة',
        foregroundServiceNotificationId: _notifId,

        // 👇 مهم جدًا مع Target SDK حديث
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  static Future<void> start(int driverId) async {
    final service = FlutterBackgroundService();
    if (!(await service.isRunning())) {
      await service.startService();
      service.invoke('set-driver', {'driver_id': driverId});
      Future.delayed(const Duration(milliseconds: 400), () {
        service.invoke('set-driver', {'driver_id': driverId});
      });
    } else {
      service.invoke('set-driver', {'driver_id': driverId});
    }
  }

  static Future<void> stop() async {
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke('stop-service');
    }
  }
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
Future<void> _onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
    service.setForegroundNotificationInfo(
      title: 'EVORANTA Driver',
      content: 'إرسال الموقع نشط…',
    );
  }

  int? driverId;
  service.on('set-driver').listen((data) {
    final id = int.tryParse('${data?['driver_id'] ?? ''}');
    if (id != null && id > 0) driverId = id;
  });

  final timer = Timer.periodic(const Duration(seconds: 8), (_) async {
    if (driverId == null || driverId == 0) return;

    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return;
    }
    if (perm == LocationPermission.deniedForever) return;

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await Api.postJson('driver_ping.php', {
        'driver_id': '$driverId',
        'lat': pos.latitude.toStringAsFixed(7),
        'lng': pos.longitude.toStringAsFixed(7),
      });

      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'EVORANTA Driver',
          content:
              'يتم إرسال موقعك… (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})',
        );
      }
    } catch (_) {
      // تجاهل الأخطاء المؤقتة
    }
  });

  service.on('stop-service').listen((event) async {
    timer.cancel();
    await service.stopSelf();
  });
}
