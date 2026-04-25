import 'package:uuid/uuid.dart';

/// Tracks the AI's learned skill level and experience points.
class AIPersonality {
  final String id;
  final String userId;

  /// 1 (Beginner) → 10 (Expert)
  final int skillLevel;

  /// Cumulative experience points earned through interactions.
  final int experiencePoints;

  /// List of skill names unlocked at the current level.
  final List<String> unlockedSkills;

  final DateTime updatedAt;

  const AIPersonality({
    required this.id,
    required this.userId,
    required this.skillLevel,
    required this.experiencePoints,
    required this.unlockedSkills,
    required this.updatedAt,
  });

  factory AIPersonality.create({required String userId}) {
    return AIPersonality(
      id: const Uuid().v4(),
      userId: userId,
      skillLevel: 1,
      experiencePoints: 0,
      unlockedSkills: _skillsForLevel(1),
      updatedAt: DateTime.now(),
    );
  }

  factory AIPersonality.fromMap(Map<String, dynamic> map) {
    final rawSkills = map['unlocked_skills'] as String? ?? '';
    final skills = rawSkills.isEmpty
        ? <String>[]
        : rawSkills.split(',').map((s) => s.trim()).toList();
    return AIPersonality(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      skillLevel: map['skill_level'] as int,
      experiencePoints: map['experience_points'] as int,
      unlockedSkills: skills,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'skill_level': skillLevel,
      'experience_points': experiencePoints,
      'unlocked_skills': unlockedSkills.join(','),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// XP needed to reach the next level.
  int get xpForNextLevel => skillLevel * 50;

  /// Progress (0.0–1.0) toward the next level.
  double get levelProgress {
    if (skillLevel >= 10) return 1.0;
    return (experiencePoints % xpForNextLevel) / xpForNextLevel;
  }

  /// Return a new personality after adding [xp] points (may level up).
  AIPersonality addExperience(int xp) {
    final newXp = experiencePoints + xp;
    int newLevel = skillLevel;
    // Keep levelling up as long as XP threshold is met and level < 10
    int accumulated = newXp;
    while (newLevel < 10 && accumulated >= _totalXpForLevel(newLevel + 1)) {
      newLevel++;
    }
    return AIPersonality(
      id: id,
      userId: userId,
      skillLevel: newLevel,
      experiencePoints: newXp,
      unlockedSkills: _skillsForLevel(newLevel),
      updatedAt: DateTime.now(),
    );
  }

  AIPersonality copyWith({
    int? skillLevel,
    int? experiencePoints,
    List<String>? unlockedSkills,
  }) {
    return AIPersonality(
      id: id,
      userId: userId,
      skillLevel: skillLevel ?? this.skillLevel,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      unlockedSkills: unlockedSkills ?? this.unlockedSkills,
      updatedAt: DateTime.now(),
    );
  }

  /// Total cumulative XP required to reach [level].
  static int _totalXpForLevel(int level) {
    // 1→2: 50, 2→3: 100, ..., 9→10: 450  (sum of level*50)
    int total = 0;
    for (int l = 1; l < level; l++) {
      total += l * 50;
    }
    return total;
  }

  static List<String> _skillsForLevel(int level) {
    final skills = <String>['Basic Chat'];
    if (level >= 2) skills.add('Voice Interaction');
    if (level >= 3) skills.add('Scene Analysis');
    if (level >= 4) skills.add('Self Learning Photos');
    if (level >= 5) skills.add('Daily Summaries');
    if (level >= 6) skills.add('Calendar Management');
    if (level >= 7) skills.add('Alarm Setting');
    if (level >= 7) skills.add('Web Browsing');
    if (level >= 9) skills.add('Gmail Integration');
    if (level >= 10) skills.add('Advanced Reasoning');
    return skills;
  }

  /// Human-readable level title.
  String get levelTitle {
    if (skillLevel <= 1) return 'Beginner';
    if (skillLevel <= 3) return 'Apprentice';
    if (skillLevel <= 5) return 'Intermediate';
    if (skillLevel <= 7) return 'Advanced';
    if (skillLevel <= 9) return 'Expert';
    return 'Master';
  }
}
