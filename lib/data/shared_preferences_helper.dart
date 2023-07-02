import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static final String _selectedLanguageKey = 'selectedLanguage';
  static final String _selectedVoiceKey = 'selectedVoice';
  static final String _pitchKey = 'pitch';
  static final String _rateKey = 'rate';
  static final String _savePathKey = 'savePath';

  // Getter and setter for selectedLanguage
  static Future<String> getSelectedLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedLanguageKey) ?? 'zh-CN';
  }

  static Future<void> setSelectedLanguage(String language) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedLanguageKey, language);
  }

  // Getter and setter for selectedVoice
  static Future<int> getSelectedVoice() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_selectedVoiceKey) ?? 0;
  }

  static Future<void> setSelectedVoice(int voice) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_selectedVoiceKey, voice);
  }

  // Getter and setter for pitch
  static Future<int> getPitch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_pitchKey) ?? 0;
  }

  static Future<void> setPitch(int pitch) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pitchKey, pitch);
  }

  // Getter and setter for rate
  static Future<int> getRate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_rateKey) ?? 0;
  }

  static Future<void> setRate(int rate) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_rateKey, rate);
  }

  // Getter and setter for savePath
  static Future<String> getSavePath() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savePathKey) ?? '';
  }

  static Future<void> setSavePath(String path) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savePathKey, path);
  }
}