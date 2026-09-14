/// AdService provides a structured way to manage ads in the app.
/// Currently configured for demo purposes with no real AdMob implementation.
/// Can be extended to support AdMob in the future without modifying core app logic.
class AdService {
  static const String demoAdId = 'demo_ad_placeholder';
  bool _isAdSupported = false;

  bool get isAdSupported => _isAdSupported;

  void initialize() {
    // Future: Initialize AdMob here if needed
    _isAdSupported = false;
  }

  String getAdPlacementId(String placementName) {
    // Future: Return real AdMob placement IDs based on placementName
    return demoAdId;
  }

  void dispose() {
    // Future: Dispose ad resources
  }
}
