import 'dart:html' as html;

Future<bool> requestWebNotificationPermission() async {
  try {
    if (html.Notification.permission == 'granted') {
      return true;
    }
    if (html.Notification.permission != 'denied') {
      final permission = await html.Notification.requestPermission();
      return permission == 'granted';
    }
  } catch (e) {
    // Some browsers or environments might throw exceptions
  }
  return false;
}

void showWebNotification(String title, String body) {
  try {
    if (html.Notification.permission == 'granted') {
      html.Notification(title, body: body);
    }
  } catch (e) {
    // Ignore error
  }
}
