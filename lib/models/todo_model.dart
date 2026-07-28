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
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// 预置分类
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
