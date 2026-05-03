import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/self_photo.dart';

/// Captures, resizes, and saves self-learning photos locally.
class SelfLearningService {
  SelfLearningService._();
  static final SelfLearningService instance = SelfLearningService._();

  CameraController? _controller;

  /// Request camera permission. Returns true if granted.
  Future<bool> requestPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Capture a compressed thumbnail from the given camera side.
  /// Returns the saved file path, or null on failure.
  Future<String?> captureAndSave({
    required String userId,
    CameraSide side = CameraSide.back,
    int thumbnailSize = 256,
  }) async {
    final granted = await requestPermission();
    if (!granted) return null;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return null;

      final direction = side == CameraSide.front
          ? CameraLensDirection.front
          : CameraLensDirection.back;

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == direction,
        orElse: () => cameras.first,
      );

      await _controller?.dispose();
      _controller = CameraController(
        camera,
        ResolutionPreset.low,
        enableAudio: false,
      );
      await _controller!.initialize();

      final xFile = await _controller!.takePicture();
      final rawBytes = await xFile.readAsBytes();

      await _controller!.dispose();
      _controller = null;

      // Resize to thumbnail
      final compressed = _compressImage(rawBytes, thumbnailSize);
      if (compressed == null) return null;

      // Save to app documents directory
      final dir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${dir.path}/self_learning');
      await photosDir.create(recursive: true);

      final fileName =
          '${side.value}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${photosDir.path}/$fileName');
      await file.writeAsBytes(compressed);

      return file.path;
    } catch (_) {
      await _controller?.dispose();
      _controller = null;
      return null;
    }
  }

  Uint8List? _compressImage(Uint8List rawBytes, int targetSize) {
    try {
      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) return null;
      final thumbnail = img.copyResize(
        decoded,
        width: targetSize,
        height: targetSize,
        interpolation: img.Interpolation.average,
      );
      return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 70));
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}
