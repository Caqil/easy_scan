import 'package:app_tracking_transparency/app_tracking_transparency.dart';

class TrackingService {
  static Future<bool> requestTracking() async {
    try {
      // Check tracking authorization status
      var status = await AppTrackingTransparency.trackingAuthorizationStatus;

      // If not determined, request authorization
      if (status == TrackingStatus.notDetermined) {
        // Show tracking authorization dialog
        status = await AppTrackingTransparency.requestTrackingAuthorization();
      }

      return status == TrackingStatus.authorized;
    } catch (e) {
      print('Failed to request tracking authorization: $e');
      return false;
    }
  }

  static Future<String?> getAdvertisingIdentifier() async {
    try {
      // Get IDFA (Identifier for Advertisers)
      final idfa = await AppTrackingTransparency.getAdvertisingIdentifier();
      return idfa;
    } catch (e) {
      print('Failed to get advertising identifier: $e');
      return null;
    }
  }
}
