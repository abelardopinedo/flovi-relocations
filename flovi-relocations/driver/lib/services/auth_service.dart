import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  /// Emits on every auth change (initial session, sign-in, sign-out, token
  /// refresh, ...). New listeners immediately receive the latest state.
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  Session? get currentSession => supabase.auth.currentSession;

  User? get currentUser => supabase.auth.currentUser;

  Future<void> signInWithGoogle() {
    final redirectTo = Uri.base.origin;
    debugPrint('signInWithGoogle redirectTo: $redirectTo');

    return supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo,
    );
  }

  Future<void> signOut() {
    return supabase.auth.signOut();
  }
}
