import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:financetrakerapp/screens/auth/login_screen.dart';
import 'package:financetrakerapp/screens/auth/register_screen.dart';
import 'package:financetrakerapp/screens/dashborad_screen.dart';

class AuthManageScreen extends StatelessWidget {
  const AuthManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLanding();
        }
        final user = snapshot.data;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          child: user == null ? const _AuthLanding() : const HomeScreen(),
        );
      },
    );
  }
}

///  Landing Screen
class _AuthLanding extends StatelessWidget {
  const _AuthLanding();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFDAEDF3), Color(0xFF2F80ED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Logo with animation
                  Hero(
                    tag: "app-logo",
                    child: AnimatedScale(
                      scale: 1,
                      duration: const Duration(milliseconds: 900),
                      child: Image.asset(
                        'images/wallet.png',
                        width: 120,
                        height: 120,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  /// App Title
                  Text(
                    "Welcome to Finance Tracker",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  /// Description
                  Text(
                    "Smart budgeting, easy tracking, and better money management – all in one app.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  /// Buttons Section
                  Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.login, size: 22),
                        label: const Text("Log In"),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 55),
                          backgroundColor: const Color(0xFF2F80ED),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 6,
                        ),
                      ),
                      const SizedBox(height: 16),

                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.person_add, size: 22),
                        label: const Text("Create Account"),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 55),
                          side: const BorderSide(color: Colors.white, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  /// Footer Text
                  Text(
                    "Track • Save • Grow 🚀",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
