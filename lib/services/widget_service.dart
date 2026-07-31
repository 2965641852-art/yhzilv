import 'dart:io';
import 'package:flutter/services.dart';

class WidgetService {
  static const _channel = MethodChannel('com.yeheng.discipline/usage');

  static Future<void> updateWidget({required int pending, required List<String> titles}) async {
    if (!Platform.isAndroid) return;
    try {
      final items = titles.take(5).map((t) => '• $t').join('\n');
      await _channel.invokeMethod('updateWidget', {
        'title': '叶恒的自律生活',
        'pending': pending,
        'items': items.isEmpty ? '全部完成 🎉' : items,
      });
    } catch (_) {}
  }
}
