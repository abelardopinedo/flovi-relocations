import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/login_screen.dart';
import '../screens/main_screen.dart';
import '../services/auth_service.dart';

/// Shows [LoginScreen] or [MainScreen] depending on the current auth state,
/// reacting to sign-in/sign-out as they happen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService.instance.authStateChanges,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        AuthService.instance.currentSession,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data!.session;
        return session == null ? const LoginScreen() : const MainScreen();
      },
    );
  }
}
