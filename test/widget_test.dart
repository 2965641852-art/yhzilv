import 'package:flutter_test/flutter_test.dart';
import 'package:yeheng_discipline/models/todo_model.dart';

void main() {
  test('TodoModel should create correctly', () {
    final todo = TodoModel(
      title: '测试待办',
      description: '这是一个测试',
      priority: TodoPriority.high,
      category: '工作',
    );

    expect(todo.title, '测试待办');
    expect(todo.isCompleted, false);
    expect(todo.priority, TodoPriority.high);
    expect(todo.status, TodoStatus.pending);
  });

  test('TodoModel toMap and fromMap', () {
    final todo = TodoModel(
      title: '测试',
      priority: TodoPriority.medium,
      category: '学习',
    );

    final map = todo.toMap();
    final restored = TodoModel.fromMap(map);

    expect(restored.title, '测试');
    expect(restored.priority, TodoPriority.medium);
    expect(restored.category, '学习');
  });
}
