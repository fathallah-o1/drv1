import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../core/api.dart';
import '../../core/env.dart';

class LoginController extends GetxController {
  final phone = ''.obs;
  final pass  = ''.obs;
  final loading = false.obs;
  final error = ''.obs;

  Future<void> submit() async {
    if (phone.value.isEmpty || pass.value.isEmpty) {
      error.value = 'أدخل الهاتف وكلمة المرور';
      return;
    }
    loading.value = true;
    error.value = '';
    try {
      final r = await Api.postJson('login.php', {
        'phone': phone.value,
        'password': pass.value,
      });
      // API يُرجع: {status:ok, data:{driver_id:..}}
      final did = int.tryParse('${(r['data'] ?? {})['driver_id']}') ?? 0;
      if (did == 0) throw 'بيانات الدخول غير صحيحة';
      Env.driverId = did;
      final box = GetStorage();
      await box.write('driverId', did);
      Get.offAllNamed('/');
    } catch (e) {
      error.value = 'فشل الدخول: $e';
    } finally {
      loading.value = false;
    }
  }
}
