import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:transparent_screen_wallpaper/models/app_settings.dart';
import 'package:transparent_screen_wallpaper/services/camera_service.dart';
import 'package:transparent_screen_wallpaper/services/settings_service.dart';
import 'package:transparent_screen_wallpaper/widgets/effect_controls.dart';
import 'package:transparent_screen_wallpaper/widgets/demo_scene.dart';

class EffectScreen extends StatefulWidget {
  final SettingsService settingsService;
  final AppSettings settings;

  const EffectScreen({
    required this.settingsService,
    required this.settings,
    Key? key,
  }) : super(key: key);

  @override
  State<EffectScreen> createState() => _EffectScreenState();
}

class _EffectScreenState extends State<EffectScreen>
    with WidgetsBindingObserver {
  late CameraService _cameraService;
  late List<CameraDescription> _cameras;
  late int _currentCameraIndex;
  late int _transparency;
  late int _brightness;
  bool _isFullscreen = false;
  bool _cameraInitialized = false;
  String? _cameraError;
  int _demoSceneIndex = 0;
  final List<String> _demoScenes = ['Desk', 'Window', 'Street'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraService = CameraService();
    _transparency = widget.settings.transparency;
    _brightness = widget.settings.brightness;
    _currentCameraIndex = widget.settings.cameraPosition == 'front' ? 1 : 0;
    _initializeApp();
  }

  void _initializeApp() async {
    try {
      await WakelockPlus.enable();
      await _getCameras();
      await _requestCameraPermission();
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = 'Initialization error';
        });
      }
    }
  }

  Future<void> _getCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _cameraError = 'No cameras available';
        });
      } else {
        if (mounted) {
          await _initializeCamera();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = 'Failed to get cameras';
        });
      }
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();

    if (status.isDenied) {
      if (mounted) {
        setState(() {
          _cameraError = 'Camera permission denied';
        });
      }
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        setState(() {
          _cameraError = 'Camera permission permanently denied';
        });
        _showOpenSettingsDialog();
      }
    } else if (status.isGranted) {
      if (mounted && !_cameraInitialized) {
        await _initializeCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
    if (_cameras.isEmpty) return;
    if (_cameraService.isDisposed) return;

    await _cameraService.initializeCamera(
      camera: _cameras[_currentCameraIndex],
      onInitialized: () {
        if (mounted) {
          setState(() {
            _cameraInitialized = true;
            _cameraError = null;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _cameraInitialized = false;
            _cameraError = 'Camera init failed';
          });
        }
      },
    );
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    setState(() {
      _currentCameraIndex = _currentCameraIndex == 0 ? 1 : 0;
    });

    await _cameraService.switchCamera(
      camera: _cameras[_currentCameraIndex],
      onInitialized: () {
        if (mounted) {
          setState(() {
            _cameraInitialized = true;
            _cameraError = null;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _cameraInitialized = false;
            _cameraError = 'Camera switch failed';
          });
        }
      },
    );
  }

  void _toggleFullscreen() async {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
      );
    } else {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
      );
    }
  }

  void _resetControls() {
    setState(() {
      _transparency = 70;
      _brightness = 100;
    });
    _saveSettings();
  }

  void _saveSettings() async {
    widget.settings.transparency = _transparency;
    widget.settings.brightness = _brightness;
    widget.settings.cameraPosition =
        _currentCameraIndex == 0 ? 'rear' : 'front';
    await widget.settingsService.saveSettings(widget.settings);
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
            'Camera permission is permanently denied. Open settings to enable it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _cameraService.markDisposed();
    } else if (state == AppLifecycleState.resumed) {
      if (!_cameraInitialized && _cameraError == null) {
        _initializeCamera();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.disposeCamera();
    _cameraService.markDisposed();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        _saveSettings();
        return true;
      },
      child: Scaffold(
        body: GestureDetector(
          onTap: _toggleFullscreen,
          child: Stack(
            children: [
              // Camera Preview or Demo Scene
              if (_cameraInitialized && _cameraService.controller != null)
                CameraPreview(_cameraService.controller!)
              else if (_cameraError != null)
                DemoScene(sceneName: _demoScenes[_demoSceneIndex])
              else
                const Center(child: CircularProgressIndicator()),
              // Transparency Overlay
              if (_transparency > 0)
                Container(
                  color: Colors.black.withOpacity(_transparency / 100 * 0.7),
                ),
              // Brightness Overlay
              if (_brightness > 100)
                Container(
                  color: Colors.white.withOpacity(
                      ((_brightness - 100) / 100) * 0.3),
                ),
              // Controls Overlay
              if (!_isFullscreen || !_cameraInitialized)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: EffectControls(
                    transparency: _transparency,
                    brightness: _brightness,
                    onCameraSwitch: _switchCamera,
                    onBack: () {
                      _saveSettings();
                      Navigator.pop(context);
                    },
                    onReset: _resetControls,
                    onTransparencyChanged: (value) {
                      setState(() {
                        _transparency = value;
                      });
                      _saveSettings();
                    },
                    onBrightnessChanged: (value) {
                      setState(() {
                        _brightness = value;
                      });
                      _saveSettings();
                    },
                  ),
                )
              else
                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    onPressed: () {
                      setState(() {
                        _isFullscreen = false;
                      });
                      SystemChrome.setEnabledSystemUIMode(
                        SystemUiMode.edgeToEdge,
                      );
                    },
                    child: const Icon(Icons.fullscreen_exit),
                  ),
                ),
              // Error State with Retry
              if (_cameraError != null)
                Positioned(
                  bottom: 32,
                  left: 16,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _initializeCamera,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry Camera'),
                      ),
                      const SizedBox(height: 12),
                      if (_cameraError ==
                              'Camera permission permanently denied' ||
                          _cameraError == 'Camera permission denied')
                        ElevatedButton.icon(
                          onPressed: openAppSettings,
                          icon: const Icon(Icons.settings),
                          label: const Text('Open Settings'),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
