class UsageModel {
  final int? id;
  final String packageName;
  final String appName;
  final int usageDuration; // 毫秒
  final DateTime date;
  final DateTime lastUsed;

  UsageModel({
    this.id,
    required this.packageName,
    required this.appName,
    required this.usageDuration,
    required this.date,
    required this.lastUsed,
  });

  /// 格式化时长（小时分钟）
  String get formattedDuration {
    final hours = usageDuration ~/ 3600000;
    final minutes = (usageDuration % 3600000) ~/ 60000;
    if (hours > 0) {
      return '${hours}小时${minutes}分钟';
    }
    return '${minutes}分钟';
  }

  /// 仅分钟数
  int get minutes => usageDuration ~/ 60000;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'package_name': packageName,
      'app_name': appName,
      'usage_duration': usageDuration,
      'date': date.millisecondsSinceEpoch,
      'last_used': lastUsed.millisecondsSinceEpoch,
    };
  }

  factory UsageModel.fromMap(Map<String, dynamic> map) {
    return UsageModel(
      id: map['id'] as int?,
      packageName: map['package_name'] as String,
      appName: map['app_name'] as String,
      usageDuration: map['usage_duration'] as int,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      lastUsed: DateTime.fromMillisecondsSinceEpoch(map['last_used'] as int),
    );
  }
}

/// 每日使用汇总
class DailyUsageSummary {
  final DateTime date;
  final int totalDuration; // 毫秒
  final List<UsageModel> apps;

  DailyUsageSummary({
    required this.date,
    required this.totalDuration,
    required this.apps,
  });

  String get formattedTotalDuration {
    final hours = totalDuration ~/ 3600000;
    final minutes = (totalDuration % 3600000) ~/ 60000;
    if (hours > 0) {
      return '${hours}小时${minutes}分钟';
    }
    return '${minutes}分钟';
  }
}
