import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/services/supabase_service.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return SupabaseService.auth.onAuthStateChange.map((e) => e.session?.user);
});

final currentUserProvider = Provider<User?>((ref) {
  return SupabaseService.auth.currentUser;
});

class AuthNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await SupabaseService.auth.signInWithPassword(
        email: email,
        password: password,
      );
    });
  }

  Future<void> signUp(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await SupabaseService.auth.signUp(
        email: email,
        password: password,
      );
    });
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await SupabaseService.auth.resetPasswordForEmail(email);
    });
  }

  Future<void> signOut() async {
    await SupabaseService.auth.signOut();
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, void>(
  AuthNotifier.new,
);
