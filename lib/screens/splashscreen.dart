import 'package:financetrakerapp/screens/auth/authmange_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// Change screen after splash
  ///
  ///
  void changeScreen() {
    Future.delayed(const Duration(seconds: 3), () {
      Get.off(() => const AuthManageScreen());
    });
  }

  @override
  void initState() {
    super.initState();
    changeScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("images/wallet.png", width: 150, height: 150),
            const SizedBox(height: 20),
            const Text(
              "Finance Tracker",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      ),
    );
  }
}
