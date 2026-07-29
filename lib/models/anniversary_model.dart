class AnniversaryModel {
  final int? id;
  final String title;
  final DateTime date;
  final bool isCountdown;
  final bool remindAnnually; // 每年提醒（生日等）
  final String icon;

  AnniversaryModel({
    this.id,
    required this.title,
    required this.date,
    this.isCountdown = true,
    this.remindAnnually = false,
    this.icon = '📅',
  });

  int get daysDiff {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return today.difference(target).inDays;
  }

  /// 如果已过去，下一个周年日期
  DateTime? get nextAnniversary {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    if (today.isBefore(target)) return target; // 还没到
    // 已过去，找今年的周年
    var next = DateTime(now.year, date.month, date.day);
    if (next.isBefore(today) || next.isAtSameMomentAs(today)) {
      next = DateTime(now.year + 1, date.month, date.day);
    }
    return next;
  }

  int get yearsPassed {
    final diff = daysDiff;
    return diff ~/ 365;
  }

  String get yearsText {
    final y = yearsPassed;
    return y > 0 ? '${y}周年' : '';
  }

  int get daysToNext {
    final next = nextAnniversary;
    if (next == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return next.difference(today).inDays;
  }

  String get displayText {
    final diff = daysDiff;
    if (isCountdown) {
      if (diff < 0) return '还剩 ${-diff} 天';
      final y = yearsPassed;
      if (y >= 1 && daysToNext < 365 && daysToNext > 0) {
        return '${y}周年已过 · 距下个周年 ${daysToNext} 天';
      }
      return '已 $diff 天';
    }
    return diff >= 0 ? '已 $diff 天' : '还剩 ${-diff} 天';
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'date': date.millisecondsSinceEpoch,
        'is_countdown': isCountdown ? 1 : 0,
        'remind_annually': remindAnnually ? 1 : 0,
        'icon': icon,
      };

  factory AnniversaryModel.fromMap(Map<String, dynamic> m) => AnniversaryModel(
        id: m['id'] as int?,
        title: m['title'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
        isCountdown: (m['is_countdown'] as int? ?? 1) == 1,
        remindAnnually: (m['remind_annually'] as int? ?? 0) == 1,
        icon: m['icon'] as String? ?? '📅',
      );

  AnniversaryModel copyWith({
    int? id, String? title, DateTime? date, bool? isCountdown, bool? remindAnnually, String? icon,
  }) => AnniversaryModel(
        id: id ?? this.id, title: title ?? this.title, date: date ?? this.date,
        isCountdown: isCountdown ?? this.isCountdown, remindAnnually: remindAnnually ?? this.remindAnnually, icon: icon ?? this.icon,
      );
}
