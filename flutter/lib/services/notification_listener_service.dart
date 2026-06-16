import 'dart:io';
import 'package:flutter/services.dart';

class NotificationListenerService {
  static const MethodChannel _channel = MethodChannel('com.example.kuskas/notification_listener');

  static final NotificationListenerService _instance = NotificationListenerService._internal();

  factory NotificationListenerService() => _instance;

  NotificationListenerService._internal() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  void Function(Map<String, dynamic>)? _onTransactionDetected;

  /// Register callback for when a transaction is detected
  void registerTransactionCallback(void Function(Map<String, dynamic>) callback) {
    _onTransactionDetected = callback;
  }

  /// Unregister the callback
  void unregisterTransactionCallback() {
    _onTransactionDetected = null;
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onTransactionDetected') {
      final data = Map<String, dynamic>.from(call.arguments as Map);
      _onTransactionDetected?.call(data);
    }
  }

  /// Check if notification listener permission is enabled on Android
  Future<bool> checkPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool enabled = await _channel.invokeMethod('checkNotificationPermission') ?? false;
      return enabled;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Open system settings screen for Notification Access
  Future<void> openSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openNotificationSettings');
    } on PlatformException catch (e) {
      print("Error opening notification settings: $e");
    }
  }

  /// Get launch transaction arguments if launched via notification click
  Future<Map<String, dynamic>?> getLaunchTransaction() async {
    if (!Platform.isAndroid) return null;
    try {
      final result = await _channel.invokeMethod('getLaunchTransaction');
      if (result != null) {
        return Map<String, dynamic>.from(result as Map);
      }
    } on PlatformException catch (e) {
      print("Error getting launch transaction: $e");
    }
    return null;
  }

  /// Sync Supabase credentials to native Android SharedPreferences
  Future<bool> syncCredentials({
    required String url,
    required String key,
    required String userId,
  }) async {
    if (!Platform.isAndroid) return false;
    try {
      final bool success = await _channel.invokeMethod('syncCredentials', {
        'url': url,
        'key': key,
        'userId': userId,
      }) ?? false;
      return success;
    } on PlatformException catch (e) {
      print("Error syncing credentials: $e");
      return false;
    }
  }
}
