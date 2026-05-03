import 'package:flutter/foundation.dart';

import '../models/ai_personality.dart';
import '../services/database_service.dart';

/// Manages the AI's skill level and XP progression.
class AIPersonalityProvider extends ChangeNotifier {
  AIPersonality? _personality;
  bool _loading = true;

  AIPersonality? get personality => _personality;
  bool get loading => _loading;

  int get skillLevel => _personality?.skillLevel ?? 1;
  int get xp => _personality?.experiencePoints ?? 0;
  double get levelProgress => _personality?.levelProgress ?? 0.0;
  String get levelTitle => _personality?.levelTitle ?? 'Beginner';
  List<String> get unlockedSkills => _personality?.unlockedSkills ?? ['Basic Chat'];

  Future<void> loadForUser(String userId) async {
    _loading = true;
    notifyListeners();

    final db = DatabaseService.instance;
    var personality = await db.getPersonality(userId);
    if (personality == null) {
      personality = AIPersonality.create(userId: userId);
      await db.upsertPersonality(personality);
    }
    _personality = personality;
    _loading = false;
    notifyListeners();
  }

  /// Award [xp] experience points and persist any level-up.
  Future<void> addExperience(int xp) async {
    if (_personality == null) return;
    final prev = _personality!.skillLevel;
    _personality = _personality!.addExperience(xp);
    await DatabaseService.instance.upsertPersonality(_personality!);
    final levelled = _personality!.skillLevel > prev;
    notifyListeners();
    if (levelled) {
      // Callers can listen for this via the provider rebuild
    }
  }

  /// Earn XP for a chat interaction.
  Future<void> rewardChatInteraction() async => addExperience(5);

  /// Earn XP for a vision/photo interaction.
  Future<void> rewardVisionInteraction() async => addExperience(8);

  /// Earn XP for a self-learning capture.
  Future<void> rewardSelfLearning() async => addExperience(3);
}
