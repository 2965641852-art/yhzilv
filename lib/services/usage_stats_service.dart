import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/usage_model.dart';

/// Android 使用时长统计服务
/// 通过 Platform Channel 调用原生 Android UsageStatsManager
class UsageStatsService {
  static final UsageStatsService _instance = UsageStatsService._internal();
  factory UsageStatsService() => _instance;
  UsageStatsService._internal();

  /// 是否已授权
  bool hasPermission = false;

  /// 检查是否已授权使用时长访问
  Future<bool> checkPermission() async {
    if (!Platform.isAndroid) return false;
    // 实际权限检查需要通过 MethodChannel 调用原生
    // 这里先返回 false，由 UI 引导用户手动开启
    return hasPermission;
  }

  /// 模拟获取应用使用时长（实际调用原生 API）
  /// 在真实 Android 设备上，此方法通过 MethodChannel 调用原生 UsageStats
  Future<List<UsageModel>> getTodayUsage() async {
    if (!Platform.isAndroid) return [];

    // TODO: 通过 MethodChannel 调用原生 UsageStatsManager
    // 暂时返回模拟数据用于开发测试
    if (kDebugMode) {
      final now = DateTime.now();
      return [
        UsageModel(
          packageName: 'com.tencent.mm',
          appName: '微信',
          usageDuration: 2 * 3600000 + 30 * 60000, // 2小时30分
          date: now,
          lastUsed: now.subtract(const Duration(minutes: 5)),
        ),
        UsageModel(
          packageName: 'com.ss.android.ugc.aweme',
          appName: '抖音',
          usageDuration: 1 * 3600000 + 15 * 60000, // 1小时15分
          date: now,
          lastUsed: now.subtract(const Duration(minutes: 30)),
        ),
        UsageModel(
          packageName: 'com.android.chrome',
          appName: 'Chrome',
          usageDuration: 45 * 60000, // 45分
          date: now,
          lastUsed: now.subtract(const Duration(hours: 1)),
        ),
        UsageModel(
          packageName: 'com.zhihu.android',
          appName: '知乎',
          usageDuration: 30 * 60000, // 30分
          date: now,
          lastUsed: now.subtract(const Duration(hours: 2)),
        ),
        UsageModel(
          packageName: 'com.bilibili.app.in',
          appName: 'B站',
          usageDuration: 20 * 60000, // 20分
          date: now,
          lastUsed: now.subtract(const Duration(hours: 3)),
        ),
      ];
    }

    return [];
  }

  /// 模拟获取周度使用数据
  Future<Map<String, int>> getWeeklyUsageMap() async {
    // 返回模拟数据：{日期: 分钟数}
    return {
      '周一': 180,
      '周二': 210,
      '周三': 150,
      '周四': 240,
      '周五': 195,
      '周六': 320,
      '周日': 280,
    };
  }
}
