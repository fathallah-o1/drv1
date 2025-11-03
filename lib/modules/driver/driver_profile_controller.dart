import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api.dart';
import '../../core/env.dart';

class DriverProfileController extends GetxController {
  final loading = false.obs;

  // بيانات السائق
  final name = ''.obs;
  final phone = ''.obs;
  final avatarUrl = ''.obs;
  final lastSeen = ''.obs;
  final createdAt = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    try {
      final r = await Api.getJson('driver_profile.php', {
        'driver_id': '${Env.driverId}',
      });
      if (r['status'] == 'ok') {
        final d = r['driver'] ?? {};
        name.value = '${d['name'] ?? ''}';
        phone.value = '${d['phone'] ?? ''}';
        avatarUrl.value = '${d['avatar_url'] ?? ''}';
        lastSeen.value = '${d['last_seen'] ?? ''}';
        createdAt.value = '${d['created_at'] ?? ''}';
      } else {
        Get.snackbar('تنبيه', '${r['message'] ?? 'تعذّر تحميل البيانات'}',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'تعذّر الاتصال: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> saveProfile() async {
    if (loading.value) return;
    loading.value = true;
    try {
      final r = await Api.postJson('driver_update_profile.php', {
        'driver_id': '${Env.driverId}',
        'name': name.value.trim(),
        'phone': phone.value.trim(),
      });
      if (r['status'] == 'ok') {
        Get.back(); // رجوع اختياري
        Get.snackbar('تم', 'تم حفظ التغييرات',
            snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('تنبيه', '${r['message'] ?? 'لم يتم الحفظ'}',
            snackPosition: SnackPosition.BOTTOM);
      }
    } finally {
      loading.value = false;
    }
  }

  Future<void> changePassword(String oldPass, String newPass) async {
    if (oldPass.isEmpty || newPass.isEmpty) {
      Get.snackbar('تنبيه', 'أدخل كلمة المرور القديمة والجديدة',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    try {
      final r = await Api.postJson('driver_change_password.php', {
        'driver_id': '${Env.driverId}',
        'old_password': oldPass,
        'new_password': newPass,
      });
      if (r['status'] == 'ok') {
        Get.snackbar('تم', 'تم تغيير كلمة المرور',
            snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('خطأ', '${r['message'] ?? 'فشل تغيير كلمة المرور'}',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'تعذّر الاتصال: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;

    try {
      final r = await Api.postMultipart(
        'driver_upload_avatar.php',
        fields: {'driver_id': '${Env.driverId}'},
        files: {'image': File(x.path)},
      );
      if (r['status'] == 'ok') {
        avatarUrl.value = '${r['avatar_url']}';
        Get.snackbar('تم', 'تم تحديث الصورة الشخصية',
            snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('تنبيه', '${r['message'] ?? 'فشل رفع الصورة'}',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'تعذّر رفع الصورة: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
