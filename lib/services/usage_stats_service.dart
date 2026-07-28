import 'dart:io';
import 'package:flutter/services.dart';
import '../models/usage_model.dart';

class UsageStatsService {
  static final UsageStatsService _instance = UsageStatsService._internal();
  factory UsageStatsService() => _instance;
  UsageStatsService._internal();

  static const _channel = MethodChannel('com.yeheng.discipline/usage');

  /// 检查是否已授权
  Future<bool> checkPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod('hasPermission') as bool;
    } catch (e) {
      return false;
    }
  }

  /// 打开系统使用情况访问设置页
  Future<void> openUsageSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openUsageSettings');
    } catch (e) {
      // ignore
    }
  }

  /// 获取今日应用使用时长
  Future<List<UsageModel>> getTodayUsage() async {
    if (!Platform.isAndroid) return [];

    try {
      final result = await _channel.invokeMethod('getTodayUsage') as List?;
      if (result == null || result.isEmpty) return [];

      final now = DateTime.now();
      return result.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return UsageModel(
          packageName: map['packageName'] as String,
          appName: map['appName'] as String,
          usageDuration: map['usageDuration'] as int,
          date: now,
          lastUsed: DateTime.fromMillisecondsSinceEpoch(map['lastUsed'] as int),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// 获取近 7 天每日总使用时长（分钟）
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
    return {
      '周一': 0, '周二': 0, '周三': 0,
      '周四': 0, '周五': 0, '周六': 0, '周日': 0,
    };
  }
}
