import 'package:flutter/material.dart';

import '../models/ai_provider.dart';
import '../models/app_settings.dart';
import '../models/user_profile.dart';
import '../services/database_service.dart';
import '../services/secure_storage_service.dart';
import '../services/tts_service.dart';

class SettingsProvider extends ChangeNotifier {
  AppSettings? _settings;
  UserProfile? _user;
  bool _loading = true;

  AppSettings? get settings => _settings;
  UserProfile? get user => _user;
  bool get loading => _loading;

  ThemeMode get themeMode => _settings?.themeMode ?? ThemeMode.system;
  AIProvider get aiProvider => _settings?.aiProvider ?? AIProvider.openai;
  String get aiModel => _settings?.aiModel ?? AIProvider.openai.defaultModel;

  /// Load or create a default user + settings on first run.
  Future<void> load() async {
    final db = DatabaseService.instance;
    final users = await db.getAllUsers();

    if (users.isEmpty) {
      final newUser = UserProfile.create(name: 'User');
      await db.upsertUser(newUser);
      final defaultSettings = AppSettings.defaults(userId: newUser.id);
      await db.upsertSettings(defaultSettings);
      _user = newUser;
      _settings = defaultSettings;
    } else {
      _user = users.first;
      final existing = await db.getSettings(_user!.id);
      if (existing == null) {
        final defaultSettings = AppSettings.defaults(userId: _user!.id);
        await db.upsertSettings(defaultSettings);
        _settings = defaultSettings;
      } else {
        _settings = existing;
      }
    }

    // Initialise TTS with saved settings
    await TtsService.instance.init(
      speed: _settings!.ttsSpeed,
      pitch: _settings!.ttsPitch,
      language: _settings!.languageCode,
      voice: _settings!.ttsVoice,
    );

    _loading = false;
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings updated) async {
    _settings = updated;
    await DatabaseService.instance.upsertSettings(updated);
    await TtsService.instance.init(
      speed: updated.ttsSpeed,
      pitch: updated.ttsPitch,
      language: updated.languageCode,
      voice: updated.ttsVoice,
    );
    notifyListeners();
  }

  Future<void> setAIProvider(AIProvider provider) async {
    if (_settings == null) return;
    final model = provider.defaultModel;
    await updateSettings(_settings!.copyWith(aiProvider: provider, aiModel: model));
  }

  Future<void> setAIModel(String model) async {
    if (_settings == null) return;
    await updateSettings(_settings!.copyWith(aiModel: model));
  }

  Future<void> setTheme(ThemeMode mode) async {
    if (_settings == null) return;
    await updateSettings(_settings!.copyWith(themeMode: mode));
  }

  Future<void> saveApiKey(String providerValue, String key) async {
    await SecureStorageService.instance.saveApiKey(providerValue, key);
  }

  Future<String?> getApiKey(String providerValue) async {
    return SecureStorageService.instance.getApiKey(providerValue);
  }

  Future<void> updateUserName(String name) async {
    if (_user == null) return;
    _user = _user!.copyWith(name: name);
    await DatabaseService.instance.upsertUser(_user!);
    notifyListeners();
  }
}
