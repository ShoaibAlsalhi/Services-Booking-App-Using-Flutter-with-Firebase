import 'package:flutter/material.dart';
import 'package:service_booking_app/modules/login/login_screen.dart';

import '../../shared/components/components.dart';

class AccountBlockedScreen extends StatelessWidget {
  const AccountBlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الحساب محظور'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 100,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              const Text(
                'تم حظر حسابك.',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.right, // Right-align text for Arabic
              ),
              const SizedBox(height: 20),
              const Text(
                'يرجى الاتصال بالدعم للحصول على المساعدة.',
                textAlign: TextAlign.center, // Center-aligned for readability
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'اتصال الدعم:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.right, // Right-align text for Arabic
              ),
              const SizedBox(height: 10),
              const Text(
                'البريد الإلكتروني: shoaibalsalhi@gmail.com',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.right, // Right-align text for Arabic
              ),
              const SizedBox(height: 10),
              const Text(
                'الهاتف: +967 775217117',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.right, // Right-align text for Arabic
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  replacementNavigateTo(context,LoginScreen());
                },
                child: const Text('إعادة المحاولة '),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
