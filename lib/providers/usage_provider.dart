import 'package:flutter/foundation.dart';
import '../models/usage_model.dart';
import '../database/app_database.dart';

class UsageProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase();

  List<UsageModel> _todayUsage = [];
  List<UsageModel> _weekUsage = [];
  DailyUsageSummary? _todaySummary;
  bool _isLoading = false;

  // 限额设置：packageName -> 分钟数
  Map<String, int> _limits = {};

  List<UsageModel> get todayUsage => _todayUsage;
  List<UsageModel> get weekUsage => _weekUsage;
  DailyUsageSummary? get todaySummary => _todaySummary;
  bool get isLoading => _isLoading;
  Map<String, int> get limits => _limits;

  Future<void> loadTodayUsage() async {
    _isLoading = true;
    notifyListeners();

    _todayUsage = await _db.getUsageForDate(DateTime.now());
    _todaySummary = DailyUsageSummary(
      date: DateTime.now(),
      totalDuration: _todayUsage.fold<int>(
        0,
        (sum, u) => sum + u.usageDuration,
      ),
      apps: _todayUsage,
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadWeekUsage() async {
    _weekUsage = await _db.getUsageForWeek();
    notifyListeners();
  }

  Future<void> saveUsage(List<UsageModel> usages) async {
    for (final usage in usages) {
      await _db.insertOrUpdateUsage(usage);
    }
  }

  void setLimit(String packageName, int minutes) {
    _limits[packageName] = minutes;
    notifyListeners();
  }

  void removeLimit(String packageName) {
    _limits.remove(packageName);
    notifyListeners();
  }

  bool isOverLimit(UsageModel usage) {
    final limit = _limits[usage.packageName];
    if (limit == null) return false;
    return usage.minutes > limit;
  }

  List<UsageModel> getOverLimitApps() {
    if (_todaySummary == null) return [];
    return _todaySummary!.apps.where((app) => isOverLimit(app)).toList();
  }
}
