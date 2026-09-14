import 'package:shared_preferences/shared_preferences.dart';
import 'package:transparent_screen_wallpaper/models/app_settings.dart';

class SettingsService {
  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  Future<AppSettings> getSettings() async {
    await _ensureInitialized();
    
    final themeModeJson = _prefs.getString('themeMode');
    final cameraPositionJson = _prefs.getString('cameraPosition');
    final autoStartJson = _prefs.getBool('autoStart');
    final transparencyJson = _prefs.getInt('transparency');
    final brightnessJson = _prefs.getInt('brightness');

    return AppSettings(
      themeMode: themeModeJson ?? 'system',
      cameraPosition: cameraPositionJson ?? 'rear',
      autoStart: autoStartJson ?? false,
      transparency: transparencyJson ?? 70,
      brightness: brightnessJson ?? 100,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _ensureInitialized();
    await _prefs.setString('themeMode', settings.themeMode);
    await _prefs.setString('cameraPosition', settings.cameraPosition);
    await _prefs.setBool('autoStart', settings.autoStart);
    await _prefs.setInt('transparency', settings.transparency);
    await _prefs.setInt('brightness', settings.brightness);
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }
}
