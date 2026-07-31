import 'package:flutter/foundation.dart';
import '../models/todo_model.dart';
import '../database/app_database.dart';
import '../services/widget_service.dart';

class TodoProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase();
  List<TodoModel> _todos = [];
  bool _isLoading = false;

  List<TodoModel> get todos => _todos;
  bool get isLoading => _isLoading;
  int get pendingCount => _todos.where((t) => !t.isCompleted).length;

  void _notifyWidget() {
    final pending = _todos.where((t) => !t.isCompleted).toList();
    WidgetService.updateWidget(pending: pending.length, titles: pending.map((t) => t.title).toList(), habits: []);
  }

  Future<void> loadTodos() async {
    _isLoading = true; notifyListeners();
    _todos = await _db.getAllTodos();
    _isLoading = false; notifyListeners(); _notifyWidget();
  }

  Future<void> addTodo(TodoModel todo) async {
    final maxOrder = _todos.isEmpty ? 0 : _todos.map((t) => t.sortOrder).reduce((a, b) => a > b ? a : b);
    final id = await _db.insertTodo(todo.copyWith(sortOrder: maxOrder + 1));
    _todos.add(todo.copyWith(id: id, sortOrder: maxOrder + 1));
    notifyListeners(); _notifyWidget();
  }

  Future<void> updateTodo(TodoModel todo) async {
    await _db.updateTodo(todo);
    final i = _todos.indexWhere((t) => t.id == todo.id);
    if (i != -1) _todos[i] = todo;
    notifyListeners(); _notifyWidget();
  }

  Future<void> toggleComplete(int id) async {
    final i = _todos.indexWhere((t) => t.id == id);
    if (i == -1) return;
    final todo = _todos[i];
    await _db.toggleTodoComplete(id, !todo.isCompleted);
    if (todo.type == TodoType.disposable) {
      _todos.removeAt(i);
    } else {
      _todos[i] = todo.copyWith(isCompleted: !todo.isCompleted, completedAt: todo.isCompleted ? null : DateTime.now(), lastCompletedDate: todo.isCompleted ? null : _todayStr());
    }
    notifyListeners(); _notifyWidget();
  }

  Future<void> deleteTodo(int id) async {
    await _db.deleteTodo(id);
    _todos.removeWhere((t) => t.id == id);
    notifyListeners(); _notifyWidget();
  }

  Future<void> reorderTodos(List<TodoModel> reordered) async {
    for (int i = 0; i < reordered.length; i++) {
      if (reordered[i].sortOrder != i) await _db.updateTodo(reordered[i].copyWith(sortOrder: i));
    }
    _todos = reordered; notifyListeners();
  }

  String _todayStr() { final n = DateTime.now(); return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}'; }
}
