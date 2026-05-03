import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../models/ai_provider.dart';
import '../models/self_photo.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../services/secure_storage_service.dart';
import '../services/self_learning_service.dart';
import 'ai_personality_provider.dart';

class SelfLearningProvider extends ChangeNotifier {
  List<SelfPhoto> _photos = [];
  bool _loading = false;
  bool _capturing = false;
  String? _errorMessage;
  Timer? _autoTimer;

  List<SelfPhoto> get photos => _photos;
  bool get loading => _loading;
  bool get capturing => _capturing;
  String? get errorMessage => _errorMessage;

  Future<void> loadPhotos(String userId) async {
    _loading = true;
    notifyListeners();
    _photos = await DatabaseService.instance.getSelfPhotos(userId);
    _loading = false;
    notifyListeners();
  }

  /// Capture a single photo, compress it, optionally have the AI label it,
  /// and persist it to the database.
  Future<SelfPhoto?> capture({
    required String userId,
    required CameraSide side,
    AIProvider? aiProvider,
    String? aiModel,
    AIPersonalityProvider? personalityProvider,
  }) async {
    _capturing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final path = await SelfLearningService.instance
          .captureAndSave(userId: userId, side: side);
      if (path == null) {
        _errorMessage = 'Failed to capture photo. Check camera permissions.';
        _capturing = false;
        notifyListeners();
        return null;
      }

      String? label;
      if (aiProvider != null && aiModel != null) {
        label = await _labelWithAI(path, aiProvider, aiModel);
      }

      final photo = SelfPhoto.create(
        userId: userId,
        cameraSide: side,
        imagePath: path,
        aiLabel: label,
      );
      await DatabaseService.instance.insertSelfPhoto(photo);
      _photos = [photo, ..._photos];

      await personalityProvider?.rewardSelfLearning();

      _capturing = false;
      notifyListeners();
      return photo;
    } catch (e) {
      _errorMessage = e.toString();
      _capturing = false;
      notifyListeners();
      return null;
    }
  }

  Future<String?> _labelWithAI(
      String imagePath, AIProvider provider, String model) async {
    try {
      final apiKey =
          await SecureStorageService.instance.getApiKey(provider.value);
      if (apiKey == null || apiKey.isEmpty) return null;
      final bytes = await File(imagePath).readAsBytes();
      final service =
          buildAIService(provider: provider, apiKey: apiKey, model: model);
      return await service.analyseImage(
        imageBytes: bytes,
        prompt: 'In one short sentence, describe what you see in this image.',
      );
    } catch (_) {
      return null;
    }
  }

  /// Start the periodic auto-capture timer.
  void startAutoCapture({
    required String userId,
    required int intervalMinutes,
    required CameraSide side,
  }) {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (_) => capture(userId: userId, side: side),
    );
  }

  /// Stop the auto-capture timer.
  void stopAutoCapture() {
    _autoTimer?.cancel();
    _autoTimer = null;
  }

  Future<void> deletePhoto(SelfPhoto photo) async {
    // Remove the local file
    final file = File(photo.imagePath);
    if (await file.exists()) await file.delete();
    await DatabaseService.instance.deleteSelfPhoto(photo.id);
    _photos.removeWhere((p) => p.id == photo.id);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }
}
