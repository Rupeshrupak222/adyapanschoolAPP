import 'package:flutter/services.dart';

class FlutterDnd {
  static const MethodChannel _channel = MethodChannel('com.adyapan.school/dnd');

  static const int INTERRUPTION_FILTER_NONE = 3; // matches Android's INTERRUPTION_FILTER_NONE
  static const int INTERRUPTION_FILTER_ALL = 1;  // matches Android's INTERRUPTION_FILTER_ALL

  static Future<bool?> get isNotificationPolicyAccessGranted async {
    try {
      final bool? granted = await _channel.invokeMethod<bool>('isNotificationPolicyAccessGranted');
      return granted;
    } on PlatformException catch (e) {
      return false;
    }
  }

  static Future<void> gotoPolicySettings() async {
    try {
      await _channel.invokeMethod<void>('gotoPolicySettings');
    } on PlatformException catch (e) {
      // Ignore platform exceptions
    }
  }

  static Future<void> setInterruptionFilter(int filter) async {
    try {
      String filterStr = 'ALL';
      if (filter == INTERRUPTION_FILTER_NONE) {
        filterStr = 'NONE';
      }
      await _channel.invokeMethod<void>('setInterruptionFilter', {'filter': filterStr});
    } on PlatformException catch (e) {
      // Ignore platform exceptions
    }
  }
}
