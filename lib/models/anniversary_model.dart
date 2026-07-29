class AnniversaryModel {
  final int? id;
  final String title;
  final DateTime date;
  final bool isCountdown; // true=倒计时, false=正计时
  final String icon;

  AnniversaryModel({
    this.id,
    required this.title,
    required this.date,
    this.isCountdown = true,
    this.icon = '📅',
  });

  int get daysDiff {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return today.difference(target).inDays;
  }

  String get displayText {
    final diff = daysDiff;
    if (isCountdown) {
      return diff <= 0 ? '还剩 ${-diff} 天' : '已过 $diff 天';
    }
    return diff >= 0 ? '已 $diff 天' : '还剩 ${-diff} 天';
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'date': date.millisecondsSinceEpoch,
        'is_countdown': isCountdown ? 1 : 0,
        'icon': icon,
      };

  factory AnniversaryModel.fromMap(Map<String, dynamic> m) => AnniversaryModel(
        id: m['id'] as int?,
        title: m['title'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
        isCountdown: (m['is_countdown'] as int? ?? 1) == 1,
        icon: m['icon'] as String? ?? '📅',
      );

  AnniversaryModel copyWith({int? id, String? title, DateTime? date, bool? isCountdown, String? icon}) =>
      AnniversaryModel(id: id ?? this.id, title: title ?? this.title, date: date ?? this.date,
          isCountdown: isCountdown ?? this.isCountdown, icon: icon ?? this.icon);
}
