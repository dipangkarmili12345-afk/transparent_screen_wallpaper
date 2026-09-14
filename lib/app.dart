import 'package:flutter/material.dart';
import 'package:transparent_screen_wallpaper/models/app_settings.dart';
import 'package:transparent_screen_wallpaper/screens/home_screen.dart';
import 'package:transparent_screen_wallpaper/services/settings_service.dart';

class MyApp extends StatefulWidget {
  final SettingsService settingsService;

  const MyApp({required this.settingsService, Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppSettings _settings;
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    _settings = await widget.settingsService.getSettings();
    _updateThemeMode();
    setState(() {});
  }

  void _updateThemeMode() {
    switch (_settings.themeMode) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }
  }

  void _onThemeModeChanged(String mode) async {
    _settings.themeMode = mode;
    await widget.settingsService.saveSettings(_settings);
    _updateThemeMode();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transparent Screen Wallpaper',
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: HomeScreen(
        settingsService: widget.settingsService,
        settings: _settings,
        onThemeModeChanged: _onThemeModeChanged,
      ),
    );
  }
}
