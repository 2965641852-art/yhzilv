class HabitModel {
  final int? id;
  final String name;
  final String icon; // emoji
  final int targetCount; // 每日目标次数
  final String unit; // 单位（个/分钟/次等）
  final String category;
  final DateTime createdAt;
  final bool isArchived;

  HabitModel({
    this.id,
    required this.name,
    this.icon = '✅',
    this.targetCount = 1,
    this.unit = '次',
    this.category = '默认',
    DateTime? createdAt,
    this.isArchived = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'icon': icon,
        'target_count': targetCount,
        'unit': unit,
        'category': category,
        'created_at': createdAt.millisecondsSinceEpoch,
        'is_archived': isArchived ? 1 : 0,
      };

  factory HabitModel.fromMap(Map<String, dynamic> m) => HabitModel(
        id: m['id'] as int?,
        name: m['name'] as String,
        icon: m['icon'] as String? ?? '✅',
        targetCount: m['target_count'] as int? ?? 1,
        unit: m['unit'] as String? ?? '次',
        category: m['category'] as String? ?? '默认',
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        isArchived: (m['is_archived'] as int? ?? 0) == 1,
      );

  HabitModel copyWith({
    int? id, String? name, String? icon, int? targetCount,
    String? unit, String? category, DateTime? createdAt, bool? isArchived,
  }) => HabitModel(
        id: id ?? this.id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        targetCount: targetCount ?? this.targetCount,
        unit: unit ?? this.unit,
        category: category ?? this.category,
        createdAt: createdAt ?? this.createdAt,
        isArchived: isArchived ?? this.isArchived,
      );
}

class HabitCompletion {
  final int? id;
  final int habitId;
  final DateTime date;
  final int count; // 当天完成次数

  HabitCompletion({this.id, required this.habitId, required this.date, this.count = 1});

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'habit_id': habitId,
        'date': date.millisecondsSinceEpoch,
        'count': count,
      };

  factory HabitCompletion.fromMap(Map<String, dynamic> m) => HabitCompletion(
        id: m['id'] as int?,
        habitId: m['habit_id'] as int,
        date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
        count: m['count'] as int? ?? 1,
      );
}
