import 'dart:io';
import 'package:flutter/services.dart';
import '../models/usage_model.dart';

class UsageStatsService {
  static final UsageStatsService _instance = UsageStatsService._internal();
  factory UsageStatsService() => _instance;
  UsageStatsService._internal();

  static const _channel = MethodChannel('com.yeheng.discipline/usage');

  /// 打开系统设置
  Future<void> openUsageSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openUsageSettings');
    } catch (_) {}
  }

  /// 获取今日使用时长（始终尝试，不预检权限）
  Future<List<UsageModel>> getTodayUsage() async {
    if (!Platform.isAndroid) return [];

    try {
      final result = await _channel.invokeMethod('getTodayUsage') as List?;
      if (result == null || result.isEmpty) return [];

      // date 归一化到当天 0 点，确保数据库去重
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      return result.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return UsageModel(
          packageName: map['packageName'] as String,
          appName: map['appName'] as String,
          usageDuration: map['usageDuration'] as int,
          date: today,
          lastUsed: DateTime.fromMillisecondsSinceEpoch(map['lastUsed'] as int),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, int>> getWeeklyUsageMap() async {
    if (!Platform.isAndroid) return _emptyWeek();

    try {
      final result = await _channel.invokeMethod('getWeeklyUsage') as Map?;
      if (result == null) return _emptyWeek();
      return result.map((key, value) =>
          MapEntry(key.toString(), (value as num).toInt()));
    } catch (e) {
      return _emptyWeek();
    }
  }

  Map<String, int> _emptyWeek() {
    return {'周一': 0, '周二': 0, '周三': 0, '周四': 0, '周五': 0, '周六': 0, '周日': 0};
  }
}
