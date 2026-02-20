import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  /// Returns null on success, error message on failure
  Future<String?> signIn(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      notifyListeners();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  /// Returns null on success, error message on failure
  Future<String?> signUp(String email, String password) async {
    try {
      await _client.auth.signUp(email: email, password: password);
      notifyListeners();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getProfile() async {
    if (currentUser == null) return null;
    try {
      return await _client
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .single();
    } catch (_) {
      return null;
    }
  }
}
