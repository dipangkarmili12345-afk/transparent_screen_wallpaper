import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraService {
  CameraController? _controller;
  bool _isCameraAvailable = false;
  bool _isInitializing = false;
  bool _disposed = false;

  CameraController? get controller => _controller;
  bool get isCameraAvailable => _isCameraAvailable;
  bool get isInitializing => _isInitializing;
  bool get isDisposed => _disposed;

  Future<void> initializeCamera({
    required CameraDescription camera,
    required VoidCallback onInitialized,
    required Function(Object) onError,
  }) async {
    if (_disposed) return;
    if (_isInitializing) return;
    if (_controller != null) return;

    _isInitializing = true;
    try {
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (!_disposed) {
        _isCameraAvailable = true;
        onInitialized();
      }
    } catch (e) {
      _isCameraAvailable = false;
      onError(e);
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> switchCamera({
    required CameraDescription camera,
    required VoidCallback onInitialized,
    required Function(Object) onError,
  }) async {
    await disposeCamera();
    await Future.delayed(const Duration(milliseconds: 500));
    await initializeCamera(
      camera: camera,
      onInitialized: onInitialized,
      onError: onError,
    );
  }

  Future<void> disposeCamera() async {
    if (_controller != null && !_disposed) {
      try {
        await _controller!.dispose();
      } catch (e) {
        if (kDebugMode) print('Error disposing camera: $e');
      }
      _controller = null;
      _isCameraAvailable = false;
    }
  }

  void markDisposed() {
    _disposed = true;
  }
}
