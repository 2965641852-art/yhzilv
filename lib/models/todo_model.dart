import 'package:intl/intl.dart';

enum TodoPriority { low, medium, high }
enum TodoStatus { pending, completed, expired }

class TodoModel {
  final int? id;
  final String title;
  final String description;
  final TodoPriority priority;
  final String category;
  final DateTime? dueDate;
  final DateTime? remindTime;
  final bool isCompleted;
  final bool isDaily;
  final int? durationMinutes;
  final String? lastCompletedDate; // yyyy-MM-dd 格式，用于判断每日任务今天是否已重置
  final DateTime createdAt;
  final DateTime? completedAt;

  TodoModel({
    this.id,
    required this.title,
    this.description = '',
    this.priority = TodoPriority.medium,
    this.category = '其他',
    this.dueDate,
    this.remindTime,
    this.isCompleted = false,
    this.isDaily = false,
    this.durationMinutes,
    this.lastCompletedDate,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  TodoStatus get status {
    if (isCompleted) return TodoStatus.completed;
    if (dueDate != null && dueDate!.isBefore(DateTime.now())) {
      return TodoStatus.expired;
    }
    return TodoStatus.pending;
  }

  String get priorityText {
    switch (priority) {
      case TodoPriority.low:
        return '低';
      case TodoPriority.medium:
        return '中';
      case TodoPriority.high:
        return '高';
    }
  }

  String get formattedDate {
    if (dueDate == null) return '无截止日期';
    return DateFormat('MM/dd HH:mm').format(dueDate!);
  }

  String get durationText {
    if (durationMinutes == null || durationMinutes == 0) return '';
    if (durationMinutes! >= 60) {
      final h = durationMinutes! ~/ 60;
      final m = durationMinutes! % 60;
      return m > 0 ? '${h}小时${m}分钟' : '${h}小时';
    }
    return '${durationMinutes}分钟';
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'priority': priority.index,
      'category': category,
      'due_date': dueDate?.millisecondsSinceEpoch,
      'remind_time': remindTime?.millisecondsSinceEpoch,
      'is_completed': isCompleted ? 1 : 0,
      'is_daily': isDaily ? 1 : 0,
      'duration_minutes': durationMinutes,
      'last_completed_date': lastCompletedDate,
      'created_at': createdAt.millisecondsSinceEpoch,
      'completed_at': completedAt?.millisecondsSinceEpoch,
    };
  }

  factory TodoModel.fromMap(Map<String, dynamic> map) {
    return TodoModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      priority: TodoPriority.values[map['priority'] as int? ?? 1],
      category: map['category'] as String? ?? '其他',
      dueDate: map['due_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['due_date'] as int)
          : null,
      remindTime: map['remind_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['remind_time'] as int)
          : null,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      isDaily: (map['is_daily'] as int? ?? 0) == 1,
      durationMinutes: map['duration_minutes'] as int?,
      lastCompletedDate: map['last_completed_date'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
      completedAt: map['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'] as int)
          : null,
    );
  }

  TodoModel copyWith({
    int? id,
    String? title,
    String? description,
    TodoPriority? priority,
    String? category,
    DateTime? dueDate,
    DateTime? remindTime,
    bool? isCompleted,
    bool? isDaily,
    int? durationMinutes,
    String? lastCompletedDate,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return TodoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      remindTime: remindTime ?? this.remindTime,
      isCompleted: isCompleted ?? this.isCompleted,
      isDaily: isDaily ?? this.isDaily,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class TodoCategory {
  static const List<String> defaults = [
    '工作',
    '学习',
    '生活',
    '运动',
    '健康',
    '阅读',
    '其他',
  ];
}
