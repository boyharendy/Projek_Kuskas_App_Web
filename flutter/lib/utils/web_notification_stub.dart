Future<bool> requestWebNotificationPermission() async {
  return false;
}

void showWebNotification(String title, String body) {
  // No-op on non-web platforms
}
