import 'package:flutter/foundation.dart';
import '../models/todo_model.dart';
import '../database/app_database.dart';

class TodoProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase();

  List<TodoModel> _todos = [];
  bool _isLoading = false;
  String _filter = '全部'; // 全部 / 今日 / 待完成 / 已完成

  List<TodoModel> get todos => _filteredTodos;
  bool get isLoading => _isLoading;
  String get filter => _filter;

  List<TodoModel> get _filteredTodos {
    switch (_filter) {
      case '今日':
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return _todos.where((t) {
          if (t.dueDate == null) return false;
          return t.dueDate!.isAfter(start) && t.dueDate!.isBefore(end);
        }).toList();
      case '待完成':
        return _todos.where((t) => !t.isCompleted).toList();
      case '已完成':
        return _todos.where((t) => t.isCompleted).toList();
      default:
        return _todos;
    }
  }

  int get completedToday {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return _todos.where((t) {
      if (!t.isCompleted || t.completedAt == null) return false;
      return t.completedAt!.isAfter(start) && t.completedAt!.isBefore(end);
    }).length;
  }

  int get pendingCount =>
      _todos.where((t) => !t.isCompleted).length;

  Future<void> loadTodos() async {
    _isLoading = true;
    notifyListeners();

    _todos = await _db.getAllTodos();

    _isLoading = false;
    notifyListeners();
  }

  void setFilter(String filter) {
    _filter = filter;
    notifyListeners();
  }

  Future<void> addTodo(TodoModel todo) async {
    final id = await _db.insertTodo(todo);
    _todos.insert(0, todo.copyWith(id: id));
    notifyListeners();
  }

  Future<void> updateTodo(TodoModel todo) async {
    await _db.updateTodo(todo);
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      _todos[index] = todo;
      notifyListeners();
    }
  }

  Future<void> toggleComplete(int id) async {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final todo = _todos[index];
    final newCompleted = !todo.isCompleted;
    await _db.toggleTodoComplete(id, newCompleted);
    _todos[index] = todo.copyWith(
      isCompleted: newCompleted,
      completedAt: newCompleted ? DateTime.now() : null,
    );
    notifyListeners();
  }

  Future<void> deleteTodo(int id) async {
    await _db.deleteTodo(id);
    _todos.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<Map<String, int>> getWeeklyStats() async {
    return await _db.getWeeklyTodoStats();
  }

  Future<int> getTotalCount() async {
    return await _db.getTotalCount();
  }
}
