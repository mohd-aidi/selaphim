import 'package:uuid/uuid.dart';

enum CameraSide { front, back }

extension CameraSideExtension on CameraSide {
  String get value => this == CameraSide.front ? 'front' : 'back';

  static CameraSide fromValue(String v) =>
      v == 'front' ? CameraSide.front : CameraSide.back;
}

/// A compressed thumbnail captured by the AI's self-learning feature.
class SelfPhoto {
  final String id;
  final String userId;
  final CameraSide cameraSide;
  final DateTime capturedAt;

  /// Local file path to the compressed thumbnail.
  final String imagePath;

  /// AI-generated description / label for this image.
  final String? aiLabel;

  const SelfPhoto({
    required this.id,
    required this.userId,
    required this.cameraSide,
    required this.capturedAt,
    required this.imagePath,
    this.aiLabel,
  });

  factory SelfPhoto.create({
    required String userId,
    required CameraSide cameraSide,
    required String imagePath,
    String? aiLabel,
  }) {
    return SelfPhoto(
      id: const Uuid().v4(),
      userId: userId,
      cameraSide: cameraSide,
      capturedAt: DateTime.now(),
      imagePath: imagePath,
      aiLabel: aiLabel,
    );
  }

  factory SelfPhoto.fromMap(Map<String, dynamic> map) {
    return SelfPhoto(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      cameraSide:
          CameraSideExtension.fromValue(map['camera_side'] as String),
      capturedAt: DateTime.parse(map['captured_at'] as String),
      imagePath: map['image_path'] as String,
      aiLabel: map['ai_label'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'camera_side': cameraSide.value,
      'captured_at': capturedAt.toIso8601String(),
      'image_path': imagePath,
      'ai_label': aiLabel,
    };
  }

  SelfPhoto copyWith({String? aiLabel}) {
    return SelfPhoto(
      id: id,
      userId: userId,
      cameraSide: cameraSide,
      capturedAt: capturedAt,
      imagePath: imagePath,
      aiLabel: aiLabel ?? this.aiLabel,
    );
  }
}
