import 'package:financetrakerapp/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          )
        ],
      ),
      body: Center(
        child: Text("Welcome ${authProvider.user?.email ?? ''}"),
      ),
    );
  }
}
