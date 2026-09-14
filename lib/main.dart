import 'package:flutter/material.dart';
import 'package:transparent_screen_wallpaper/app.dart';
import 'package:transparent_screen_wallpaper/services/settings_service.dart';

future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    final settingsService = SettingsService();
    await settingsService.initialize();
    
    runApp(MyApp(settingsService: settingsService));
  } catch (e) {
    runApp(const ErrorApp());
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Initialization Error: Check logs'),
        ),
      ),
    );
  }
}
