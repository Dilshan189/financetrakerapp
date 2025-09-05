import 'package:financetrakerapp/providers/auth_provider.dart';
import 'package:financetrakerapp/providers/transaction_provider.dart';
import 'package:financetrakerapp/providers/budget_provider.dart';
import 'package:financetrakerapp/screens/auth/authmange_screen.dart';
import 'package:financetrakerapp/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Finance Tracker',
        theme: AppTheme.lightTheme,
        home: const AuthManageScreen(),
      ),
    );
  }
}
