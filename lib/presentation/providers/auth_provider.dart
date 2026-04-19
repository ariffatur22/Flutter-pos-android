import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_pos_kasir/core/constants/app_constants.dart';

class AuthState {
  final bool isLoggedIn;
  final bool isAdmin;
  final String cashierName;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isLoggedIn = false,
    this.isAdmin = false,
    this.cashierName = 'Kasir',
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isAdmin,
    String? cashierName,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isAdmin: isAdmin ?? this.isAdmin,
      cashierName: cashierName ?? this.cashierName,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  final _supabase = Supabase.instance.client;

  /// Login kasir via PIN lokal
  Future<bool> loginWithPin(String pin) async {
    state = state.copyWith(isLoading: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (pin == AppConstants.defaultCashierPin) {
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        isAdmin: false,
        cashierName: 'Kasir',
      );
      return true;
    }
    state =
        state.copyWith(isLoading: false, error: 'PIN tidak valid, coba lagi.');
    return false;
  }

  /// Login admin via Supabase email + password
  Future<bool> loginWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        state = state.copyWith(
          isLoading: false,
          isLoggedIn: true,
          isAdmin: true,
          cashierName: response.user!.email ?? 'Admin',
        );
        return true;
      }
      state = state.copyWith(
          isLoading: false, error: 'Login gagal, periksa email & password.');
      return false;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Terjadi kesalahan: ${e.toString()}');
      return false;
    }
  }

  Future<bool> registerWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user != null) {
        state = state.copyWith(isLoading: false, clearError: true);
        return true;
      }
      state = state.copyWith(
          isLoading: false,
          error: 'Pendaftaran gagal, periksa data dan coba lagi.');
      return false;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Terjadi kesalahan: ${e.toString()}');
      return false;
    }
  }

  void logout() {
    _supabase.auth.signOut();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
