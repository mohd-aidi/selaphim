import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/ai_provider.dart';

class AppSettings {
  final String id;
  final String userId;
  final AIProvider aiProvider;
  final String aiModel;
  final String aiName;
  final String? ttsVoice;
  final double ttsSpeed;
  final double ttsPitch;
  final String languageCode;
  final ThemeMode themeMode;
  final int liveVisionInterval;
  final bool notificationsEnabled;
  final bool selfLearningEnabled;
  final int selfLearningIntervalMinutes;

  const AppSettings({
    required this.id,
    required this.userId,
    required this.aiProvider,
    required this.aiModel,
    this.aiName = 'Selaphim',
    this.ttsVoice,
    required this.ttsSpeed,
    required this.ttsPitch,
    required this.languageCode,
    required this.themeMode,
    required this.liveVisionInterval,
    required this.notificationsEnabled,
    this.selfLearningEnabled = false,
    this.selfLearningIntervalMinutes = 60,
  });

  factory AppSettings.defaults({required String userId}) {
    return AppSettings(
      id: const Uuid().v4(),
      userId: userId,
      aiProvider: AIProvider.openai,
      aiModel: AIProvider.openai.defaultModel,
      aiName: 'Selaphim',
      ttsSpeed: 1.0,
      ttsPitch: 1.0,
      languageCode: 'en-US',
      themeMode: ThemeMode.system,
      liveVisionInterval: 10,
      notificationsEnabled: true,
      selfLearningEnabled: false,
      selfLearningIntervalMinutes: 60,
    );
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    final provider = AIProviderExtension.fromValue(map['ai_provider'] as String);
    final theme = _parseTheme(map['theme'] as String);
    return AppSettings(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      aiProvider: provider,
      aiModel: map['ai_model'] as String,
      aiName: (map['ai_name'] as String?) ?? 'Selaphim',
      ttsVoice: map['tts_voice'] as String?,
      ttsSpeed: (map['tts_speed'] as num).toDouble(),
      ttsPitch: (map['tts_pitch'] as num).toDouble(),
      languageCode: map['language_code'] as String,
      themeMode: theme,
      liveVisionInterval: map['live_vision_interval'] as int,
      notificationsEnabled: (map['notifications_enabled'] as int) == 1,
      selfLearningEnabled: (map['self_learning_enabled'] as int? ?? 0) == 1,
      selfLearningIntervalMinutes:
          map['self_learning_interval_minutes'] as int? ?? 60,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'ai_provider': aiProvider.value,
      'ai_model': aiModel,
      'ai_name': aiName,
      'tts_voice': ttsVoice,
      'tts_speed': ttsSpeed,
      'tts_pitch': ttsPitch,
      'language_code': languageCode,
      'theme': _themeToString(themeMode),
      'live_vision_interval': liveVisionInterval,
      'notifications_enabled': notificationsEnabled ? 1 : 0,
      'self_learning_enabled': selfLearningEnabled ? 1 : 0,
      'self_learning_interval_minutes': selfLearningIntervalMinutes,
    };
  }

  AppSettings copyWith({
    AIProvider? aiProvider,
    String? aiModel,
    String? aiName,
    String? ttsVoice,
    double? ttsSpeed,
    double? ttsPitch,
    String? languageCode,
    ThemeMode? themeMode,
    int? liveVisionInterval,
    bool? notificationsEnabled,
    bool? selfLearningEnabled,
    int? selfLearningIntervalMinutes,
  }) {
    return AppSettings(
      id: id,
      userId: userId,
      aiProvider: aiProvider ?? this.aiProvider,
      aiModel: aiModel ?? this.aiModel,
      aiName: aiName ?? this.aiName,
      ttsVoice: ttsVoice ?? this.ttsVoice,
      ttsSpeed: ttsSpeed ?? this.ttsSpeed,
      ttsPitch: ttsPitch ?? this.ttsPitch,
      languageCode: languageCode ?? this.languageCode,
      themeMode: themeMode ?? this.themeMode,
      liveVisionInterval: liveVisionInterval ?? this.liveVisionInterval,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      selfLearningEnabled: selfLearningEnabled ?? this.selfLearningEnabled,
      selfLearningIntervalMinutes:
          selfLearningIntervalMinutes ?? this.selfLearningIntervalMinutes,
    );
  }

  static ThemeMode _parseTheme(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _themeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
