import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';

/// Wraps the camera plugin and provides helpers for capture and live frames.
class CameraService {
  CameraService._();
  static final CameraService instance = CameraService._();

  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  StreamController<Uint8List>? _liveStreamController;
  Timer? _liveTimer;

  CameraController? get controller => _controller;

  bool get isInitialized => _controller?.value.isInitialized ?? false;

  Future<void> init({CameraLensDirection direction = CameraLensDirection.back}) async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    final camera = _cameras.firstWhere(
      (c) => c.lensDirection == direction,
      orElse: () => _cameras.first,
    );

    await _controller?.dispose();
    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _controller!.initialize();
  }

  /// Capture a single JPEG image and return its bytes.
  Future<Uint8List?> captureImage() async {
    if (_controller == null || !isInitialized) return null;
    final file = await _controller!.takePicture();
    return file.readAsBytes();
  }

  /// Start a live-analysis loop that emits a JPEG frame every [intervalSeconds].
  Stream<Uint8List> startLiveStream({int intervalSeconds = 10}) {
    _liveStreamController?.close();
    _liveStreamController = StreamController<Uint8List>.broadcast();
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(Duration(seconds: intervalSeconds), (_) async {
      final bytes = await captureImage();
      if (bytes != null) {
        _liveStreamController?.add(bytes);
      }
    });
    return _liveStreamController!.stream;
  }

  void stopLiveStream() {
    _liveTimer?.cancel();
    _liveTimer = null;
    _liveStreamController?.close();
    _liveStreamController = null;
  }

  Future<void> dispose() async {
    stopLiveStream();
    await _controller?.dispose();
    _controller = null;
  }

  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;
    final currentDirection = _controller?.description.lensDirection;
    final next = _cameras.firstWhere(
      (c) => c.lensDirection != currentDirection,
      orElse: () => _cameras.first,
    );
    await _controller?.dispose();
    _controller = CameraController(next, ResolutionPreset.medium, enableAudio: false);
    await _controller!.initialize();
  }
}
