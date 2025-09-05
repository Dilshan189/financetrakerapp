import 'package:financetrakerapp/providers/auth_provider.dart';
import 'package:financetrakerapp/screens/auth/login_screen.dart';
import 'package:financetrakerapp/screens/dashborad_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Finance Tracker',
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {

          if (auth.user != null) {
            return const HomeScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
