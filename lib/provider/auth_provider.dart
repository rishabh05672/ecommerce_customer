import 'package:ecommerce_customer/utils/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  User? _user;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  String? get userEmail => _user?.email;
  String? get userId => _user?.id;

  AuthProvider() {
    _initAuth();
  }

  // Initialize authentication
  Future<void> _initAuth() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        _user = session.user;
        notifyListeners();
      }
    } catch (e) {
      print('Error initializing auth: $e');
    }
  }

  // Customer Sign In
  Future<bool> signIn(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _user = response.user;
        await _saveUserSession();
        notifyListeners();
        return true;
      }

      return false;
    } on AuthException catch (e) {
      _setError(_getErrorMessage(e.message));
      return false;
    } catch (e) {
      _setError('Login failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Customer Sign Up
  Future<bool> signUp(String email, String password, {String? fullName}) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );

      if (response.user != null) {
        // Insert customer into users table
        try {
          await _supabase.from('users').insert({
            'id': response.user!.id,
            'email': email,
            'role': AppConstants.customerRole, // 'customer'
          });
        } catch (insertError) {
          print('Error inserting user data: $insertError');
          // Continue even if insert fails
        }

        _user = response.user;
        await _saveUserSession();
        notifyListeners();
        return true;
      }

      return false;
    } on AuthException catch (e) {
      _setError(_getErrorMessage(e.message));
      return false;
    } catch (e) {
      _setError('Registration failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _supabase.auth.signOut();
      _user = null;
      await _clearUserSession();
      notifyListeners();
    } catch (e) {
      print('Error signing out: $e');
      _setError('Sign out failed');
    } finally {
      _setLoading(false);
    }
  }

  // Reset Password
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabase.auth.resetPasswordForEmail(email);
      return true;
    } on AuthException catch (e) {
      _setError(_getErrorMessage(e.message));
      return false;
    } catch (e) {
      _setError('Password reset failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update Password
  Future<bool> updatePassword(String newPassword) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user != null) {
        _user = response.user;
        notifyListeners();
        return true;
      }
      return false;
    } on AuthException catch (e) {
      _setError(_getErrorMessage(e.message));
      return false;
    } catch (e) {
      _setError('Password update failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update Profile
  Future<bool> updateProfile({String? fullName, String? phone}) async {
    try {
      _setLoading(true);
      _clearError();

      Map<String, dynamic> data = {};
      if (fullName != null) data['full_name'] = fullName;
      if (phone != null) data['phone'] = phone;

      if (data.isNotEmpty) {
        final response = await _supabase.auth.updateUser(
          UserAttributes(data: data),
        );

        if (response.user != null) {
          _user = response.user;
          notifyListeners();
          return true;
        }
      }
      return false;
    } on AuthException catch (e) {
      _setError(_getErrorMessage(e.message));
      return false;
    } catch (e) {
      _setError('Profile update failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Check Authentication Status
  Future<void> checkAuthStatus() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        _user = session.user;
        notifyListeners();
      }
    } catch (e) {
      print('Error checking auth status: $e');
    }
  }

  // Get user metadata
  String? getUserMetadata(String key) {
    return _user?.userMetadata?[key]?.toString();
  }

  // Get user full name
  String? get userFullName => getUserMetadata('full_name');

  // Get user phone
  String? get userPhone => getUserMetadata('phone');

  // Save user session to local storage
  Future<void> _saveUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.isLoggedInKey, true);
      if (_user != null) {
        await prefs.setString(AppConstants.userIdKey, _user!.id);
        await prefs.setString(AppConstants.userEmailKey, _user!.email ?? '');
      }
    } catch (e) {
      print('Error saving session: $e');
    }
  }

  // Clear user session from local storage
  Future<void> _clearUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.isLoggedInKey);
      await prefs.remove(AppConstants.userIdKey);
      await prefs.remove(AppConstants.userEmailKey);
    } catch (e) {
      print('Error clearing session: $e');
    }
  }

  // Check if user is logged in from local storage
  Future<bool> isLoggedInLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(AppConstants.isLoggedInKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Convert Supabase error messages to user-friendly messages
  String _getErrorMessage(String? error) {
    if (error == null) return 'An unexpected error occurred';

    if (error.contains('Invalid login credentials')) {
      return 'Invalid email or password';
    } else if (error.contains('User already registered')) {
      return 'Account already exists with this email';
    } else if (error.contains('Password should be at least')) {
      return 'Password should be at least 6 characters';
    } else if (error.contains('Unable to validate email address')) {
      return 'Please enter a valid email address';
    } else if (error.contains('Email not confirmed')) {
      return 'Please confirm your email address';
    }
    return error;
  }
}
