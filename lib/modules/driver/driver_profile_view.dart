import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/ui.dart';
import 'driver_profile_controller.dart';

class DriverProfileView extends StatelessWidget {
  const DriverProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(DriverProfileController());

    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('بيانات السائق'),
          backgroundColor: Ui.orange,
        ),
        body: Obx(() {
          nameCtrl.text = c.name.value;
          phoneCtrl.text = c.phone.value; // للعرض فقط

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: (c.avatarUrl.value.isNotEmpty)
                          ? NetworkImage(c.avatarUrl.value)
                          : null,
                      child: (c.avatarUrl.value.isEmpty)
                          ? const Icon(Icons.person, size: 42, color: Colors.white70)
                          : null,
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: InkWell(
                        onTap: c.pickAndUploadAvatar,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Ui.orange),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _infoRow('آخر ظهور', c.lastSeen.value),
              _infoRow('تاريخ التسجيل', c.createdAt.value),
              const SizedBox(height: 16),

              _field(label: 'الاسم', ctrl: nameCtrl),
              const SizedBox(height: 10),

              // ===== الهاتف للعرض فقط (readOnly) =====
              TextField(
                controller: phoneCtrl,
                readOnly: true, // ✅ يمنع التعديل
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'الهاتف',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: const Color(0xFFF6F6F8),
                  suffixIcon: const Icon(Icons.lock_outline), // توضيح أنه مقفول
                ),
              ),

              const SizedBox(height: 14),
              Obx(() => ElevatedButton(
                    onPressed: c.loading.value ? null : () {
                      // نحفظ الاسم فقط — بدون تعديل الهاتف
                      c.name.value = nameCtrl.text.trim();
                      c.saveProfile();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Ui.orange, foregroundColor: Colors.white),
                    child: c.loading.value
                        ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('حفظ التغييرات', style: TextStyle(fontWeight: FontWeight.w700)),
                  )),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              const Text('تغيير كلمة المرور', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              _field(label: 'القديمة', ctrl: oldCtrl, obscure: true),
              const SizedBox(height: 8),
              _field(label: 'الجديدة', ctrl: newCtrl, obscure: true),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => c.changePassword(oldCtrl.text, newCtrl.text),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87, foregroundColor: Colors.white),
                child: const Text('تغيير كلمة المرور'),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController ctrl,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true, fillColor: const Color(0xFFF6F6F8),
      ),
    );
  }

  Widget _infoRow(String k, String v) {
    return Row(
      children: [
        Text('$k: ', style: const TextStyle(color: Colors.black54)),
        Expanded(child: Text(v.isEmpty ? '—' : v,
          textAlign: TextAlign.start, style: const TextStyle(fontWeight: FontWeight.w600))),
      ],
    );
  }
}
