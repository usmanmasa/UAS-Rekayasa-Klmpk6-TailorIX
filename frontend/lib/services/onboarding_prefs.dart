import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPrefs {
  static const String _kWelcomeConsentKey = 'welcome_consent';

  static Future<bool> getWelcomeConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kWelcomeConsentKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setWelcomeConsent(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kWelcomeConsentKey, value);
    } catch (_) {
      // ignore
    }
  }
}
