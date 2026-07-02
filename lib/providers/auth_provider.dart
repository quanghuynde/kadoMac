import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project/services/auth_service.dart';

final authServiceProvider = Provider((ref) => AuthService());

final authStateProvider = StateNotifierProvider<AuthNotifier, bool>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

class AuthNotifier extends StateNotifier<bool> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(false) {
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    state = await _authService.isLoggedIn();
  }

  Future<bool> login(String email, String password) async {
    final success = await _authService.login(email, password);
    if (success) state = true;
    return success;
  }

  Future<void> register(String email, String password) async {
    await _authService.register(email, password);
  }

  Future<void> logout() async {
    await _authService.logout();
    state = false;
  }
}
