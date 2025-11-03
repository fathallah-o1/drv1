import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/ui.dart';
import 'login_controller.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  static const _bg = Colors.white;
  static const _card = Color(0xFFF6F6F8);
  static const _text = Color(0xFF1B1B1F);
  static const _textMute = Color(0xFF6B7280);
  static const _divider = Color(0xFFE9E9EE);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(LoginController());
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(18),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _divider),
            ),
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delivery_dining, color: Ui.orange),
                  const SizedBox(width: 8),
                  const Text(
                    'تسجيل دخول السائق',
                    style: TextStyle(
                      color: _text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: _text),
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف',
                  labelStyle: const TextStyle(color: _textMute),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: _divider),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: _divider),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  prefixIcon: Icon(Icons.phone, color: Ui.orange),
                ),
                onChanged: (v)=>c.phone.value=v,
              ),
              const SizedBox(height: 10),
              TextField(
                obscureText: true,
                style: const TextStyle(color: _text),
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  labelStyle: const TextStyle(color: _textMute),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: _divider),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: _divider),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  prefixIcon: Icon(Icons.lock, color: Ui.orange),
                ),
                onChanged: (v)=>c.pass.value=v,
              ),
              const SizedBox(height: 8),
              Obx(()=> Text(c.error.value, style: const TextStyle(color: Colors.redAccent))),
              const SizedBox(height: 12),
              Obx(()=> ElevatedButton(
                onPressed: c.loading.value ? null : c.submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Ui.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: c.loading.value
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('دخول', style: TextStyle(fontWeight: FontWeight.w800)),
              )),
            ]),
          ),
        ),
      ),
    );
  }
}
