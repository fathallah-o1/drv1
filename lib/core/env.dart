class Env {
  static const String baseUrl = 'https://evoranta.ly/api/driver';
  static int driverId = 0; // يُملأ بعد تسجيل الدخول ويُحفظ في GetStorage
  static const Duration pollInterval = Duration(seconds: 5);
}
