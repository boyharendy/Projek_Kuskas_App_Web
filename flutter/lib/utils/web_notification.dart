import 'web_notification_stub.dart'
    if (dart.library.html) 'web_notification_web.dart';

class WebNotification {
  /// Request notification permission for Web browsers
  static Future<bool> requestPermission() => requestWebNotificationPermission();

  /// Display HTML5 browser notification
  static void show(String title, String body) => showWebNotification(title, body);
}
