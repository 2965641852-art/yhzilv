import 'dart:io';
import 'package:flutter/services.dart';

class WidgetService {
  static const _channel = MethodChannel('com.yeheng.discipline/usage');

  static Future<void> updateWidget({
    required int pending,
    required List<String> titles,
    required List<String> habits,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      final items = titles.take(5).map((t) => '• $t').join('\n');
      final hItems = habits.take(5).map((h) => '• $h').join('\n');
      await _channel.invokeMethod('updateWidget', {
        'title': '叶恒的自律生活',
        'pending': pending,
        'items': items.isEmpty ? '' : items,
        'habits': hItems.isEmpty ? '' : hItems,
      });
    } catch (_) {}
  }
}
