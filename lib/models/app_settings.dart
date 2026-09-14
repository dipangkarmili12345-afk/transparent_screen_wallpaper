class AppSettings {
  String themeMode;
  String cameraPosition;
  bool autoStart;
  int transparency;
  int brightness;

  AppSettings({
    this.themeMode = 'system',
    this.cameraPosition = 'rear',
    this.autoStart = false,
    this.transparency = 70,
    this.brightness = 100,
  });

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode,
      'cameraPosition': cameraPosition,
      'autoStart': autoStart,
      'transparency': transparency,
      'brightness': brightness,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: json['themeMode'] ?? 'system',
      cameraPosition: json['cameraPosition'] ?? 'rear',
      autoStart: json['autoStart'] ?? false,
      transparency: json['transparency'] ?? 70,
      brightness: json['brightness'] ?? 100,
    );
  }
}
