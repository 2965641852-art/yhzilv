class PomodoroRecord {
  final int? id;
  final int duration; // 分钟
  final String category; // 学习/运动/科研等
  final DateTime date;
  final bool completed;

  PomodoroRecord({this.id, required this.duration, required this.category, required this.date, this.completed = true});

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'duration': duration,
        'category': category,
        'date': date.millisecondsSinceEpoch,
        'completed': completed ? 1 : 0,
      };

  factory PomodoroRecord.fromMap(Map<String, dynamic> m) => PomodoroRecord(
        id: m['id'] as int?, duration: m['duration'] as int,
        category: m['category'] as String, date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
        completed: (m['completed'] as int? ?? 1) == 1,
      );
}
