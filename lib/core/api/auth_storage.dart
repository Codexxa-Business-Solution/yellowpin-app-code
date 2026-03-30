import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyToken = 'auth_token';
const String _keyUserName = 'user_name';
const String _keyUserRole = 'user_role';
const String _keyLastLoginRole = 'last_login_role';
const String _keySelectedAuthRole = 'selected_auth_role';
const String _keyProfileImageUrl = 'profile_image_url';

String _normalizeRole(String role) {
  final value = role.trim().toLowerCase();
  switch (value) {
    case 'organization':
      return 'organisation';
    case 'hr professional':
    case 'hr_professional':
      return 'hr';
    case 'job seeker':
      return 'job_seeker';
    default:
      return value;
  }
}

/// Persists and retrieves auth token and current user name for API calls and UI.
/// Also holds the latest profile image URL so dashboard/profile stay in sync after upload.
class AuthStorage {
  AuthStorage._();
  static SharedPreferences? _prefs;

  /// Notifier for profile image URL. Listen to this so dashboard avatar updates when image is updated on My Profile.
  static final ValueNotifier<String?> profileImageUrlNotifier = ValueNotifier<String?>(null);

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> setToken(String token) async {
    await init();
    await _prefs?.setString(_keyToken, token);
  }

  static Future<String?> getToken() async {
    await init();
    return _prefs?.getString(_keyToken);
  }

  static Future<void> setUserName(String? name) async {
    await init();
    if (name == null) {
      await _prefs?.remove(_keyUserName);
    } else {
      await _prefs?.setString(_keyUserName, name);
    }
  }

  static Future<String?> getUserName() async {
    await init();
    return _prefs?.getString(_keyUserName);
  }

  static Future<void> setUserRole(String? role) async {
    await init();
    if (role == null || role.isEmpty) {
      await _prefs?.remove(_keyUserRole);
    } else {
      final normalizedRole = _normalizeRole(role);
      await _prefs?.setString(_keyUserRole, normalizedRole);
      await setLastLoginRole(normalizedRole);
    }
  }

  static Future<String?> getUserRole() async {
    await init();
    return _prefs?.getString(_keyUserRole);
  }

  static Future<void> setLastLoginRole(String? role) async {
    await init();
    if (role == null || role.isEmpty) {
      await _prefs?.remove(_keyLastLoginRole);
    } else {
      await _prefs?.setString(_keyLastLoginRole, _normalizeRole(role));
    }
  }

  static Future<String?> getLastLoginRole() async {
    await init();
    return _prefs?.getString(_keyLastLoginRole);
  }

  static Future<void> setSelectedAuthRole(String? role) async {
    await init();
    if (role == null || role.isEmpty) {
      await _prefs?.remove(_keySelectedAuthRole);
    } else {
      await _prefs?.setString(_keySelectedAuthRole, _normalizeRole(role));
    }
  }

  static Future<String?> getSelectedAuthRole() async {
    await init();
    return _prefs?.getString(_keySelectedAuthRole);
  }

  static Future<void> clearToken() async {
    await init();
    await _prefs?.remove(_keyToken);
    await _prefs?.remove(_keyUserName);
    await _prefs?.remove(_keyUserRole);
    await _prefs?.remove(_keyLastLoginRole);
    await _prefs?.remove(_keySelectedAuthRole);
    await _prefs?.remove(_keyProfileImageUrl);
    profileImageUrlNotifier.value = null;
  }

  /// Set the current profile image URL (e.g. after upload). Notifies listeners so dashboard updates.
  static Future<void> setProfileImageUrl(String? url) async {
    await init();
    if (url == null || url.isEmpty) {
      await _prefs?.remove(_keyProfileImageUrl);
      profileImageUrlNotifier.value = null;
    } else {
      await _prefs?.setString(_keyProfileImageUrl, url);
      profileImageUrlNotifier.value = url;
    }
  }

  /// Current profile image URL from cache. Also load from prefs on first read.
  static String? get profileImageUrl => profileImageUrlNotifier.value;

  /// Load cached profile image URL from SharedPreferences into the notifier (call once at app start if needed).
  static Future<void> loadProfileImageUrlFromPrefs() async {
    await init();
    profileImageUrlNotifier.value = _prefs?.getString(_keyProfileImageUrl);
  }
}
