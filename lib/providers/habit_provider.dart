import 'package:flutter/foundation.dart';
import '../models/habit_model.dart';
import '../database/app_database.dart';

class HabitProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase();
  List<HabitModel> _habits = [];
  bool _isLoading = false;

  List<HabitModel> get habits => _habits;
  bool get isLoading => _isLoading;

  Future<void> loadHabits() async {
    _isLoading = true;
    notifyListeners();
    try {
      _habits = await _db.getAllHabits();
    } catch (e) {
      _habits = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addHabit(HabitModel habit) async {
    final id = await _db.insertHabit(habit);
    _habits.add(habit.copyWith(id: id));
    notifyListeners();
  }

  Future<void> updateHabit(HabitModel habit) async {
    await _db.updateHabit(habit);
    final i = _habits.indexWhere((h) => h.id == habit.id);
    if (i != -1) _habits[i] = habit;
    notifyListeners();
  }

  Future<void> toggleComplete(int habitId) async {
    final current = await _db.getTodayHabitCount(habitId);
    final habit = _habits.firstWhere((h) => h.id == habitId);
    final newCount = current + 1;
    await _db.toggleHabitComplete(habitId, count: newCount);
    notifyListeners();
  }

  Future<int> getTodayCount(int habitId) => _db.getTodayHabitCount(habitId);
  Future<Map<String, int>> getMonthStats(int habitId, int year, int month) =>
      _db.getHabitMonthStats(habitId, year, month);
}
