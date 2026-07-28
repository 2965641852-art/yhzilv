import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/todo_model.dart';
import '../models/usage_model.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'yeheng_discipline.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 待办表
    await db.execute('''
      CREATE TABLE todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT DEFAULT '',
        priority INTEGER DEFAULT 1,
        category TEXT DEFAULT '其他',
        due_date INTEGER,
        remind_time INTEGER,
        is_completed INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        completed_at INTEGER
      )
    ''');

    // 使用时长表
    await db.execute('''
      CREATE TABLE usage_stats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        package_name TEXT NOT NULL,
        app_name TEXT NOT NULL,
        usage_duration INTEGER NOT NULL,
        date INTEGER NOT NULL,
        last_used INTEGER NOT NULL,
        UNIQUE(package_name, date)
      )
    ''');

    // 分类表
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color INTEGER DEFAULT 0
      )
    ''');

    // 插入默认分类
    for (final category in TodoCategory.defaults) {
      await db.insert('categories', {'name': category});
    }
  }

  // ========== 待办 CRUD ==========

  Future<int> insertTodo(TodoModel todo) async {
    final db = await database;
    return await db.insert('todos', todo.toMap());
  }

  Future<List<TodoModel>> getAllTodos() async {
    final db = await database;
    final maps = await db.query(
      'todos',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => TodoModel.fromMap(map)).toList();
  }

  Future<List<TodoModel>> getTodosByStatus({bool? isCompleted}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (isCompleted != null) {
      maps = await db.query(
        'todos',
        where: 'is_completed = ?',
        whereArgs: [isCompleted ? 1 : 0],
        orderBy: 'created_at DESC',
      );
    } else {
      maps = await db.query('todos', orderBy: 'created_at DESC');
    }
    return maps.map((map) => TodoModel.fromMap(map)).toList();
  }

  Future<List<TodoModel>> getTodayTodos() async {
    final db = await database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;

    final maps = await db.query(
      'todos',
      where: '(due_date >= ? AND due_date <= ?) OR is_completed = 0',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => TodoModel.fromMap(map)).toList();
  }

  Future<int> updateTodo(TodoModel todo) async {
    final db = await database;
    return await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  Future<int> toggleTodoComplete(int id, bool isCompleted) async {
    final db = await database;
    return await db.update(
      'todos',
      {
        'is_completed': isCompleted ? 1 : 0,
        'completed_at': isCompleted ? DateTime.now().millisecondsSinceEpoch : null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTodo(int id) async {
    final db = await database;
    return await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getCompletedCountForDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).millisecondsSinceEpoch;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM todos WHERE is_completed = 1 AND completed_at >= ? AND completed_at <= ?',
      [startOfDay, endOfDay],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM todos');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ========== 使用时长 ==========

  Future<void> insertOrUpdateUsage(UsageModel usage) async {
    final db = await database;
    final existing = await db.query(
      'usage_stats',
      where: 'package_name = ? AND date = ?',
      whereArgs: [usage.packageName, usage.date.millisecondsSinceEpoch],
    );

    if (existing.isNotEmpty) {
      await db.update(
        'usage_stats',
        {'usage_duration': usage.usageDuration, 'last_used': usage.lastUsed.millisecondsSinceEpoch},
        where: 'package_name = ? AND date = ?',
        whereArgs: [usage.packageName, usage.date.millisecondsSinceEpoch],
      );
    } else {
      await db.insert('usage_stats', usage.toMap());
    }
  }

  Future<List<UsageModel>> getUsageForDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).millisecondsSinceEpoch;

    final maps = await db.query(
      'usage_stats',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'usage_duration DESC',
    );
    return maps.map((map) => UsageModel.fromMap(map)).toList();
  }

  Future<List<UsageModel>> getUsageForWeek() async {
    final db = await database;
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final maps = await db.query(
      'usage_stats',
      where: 'date >= ? AND date <= ?',
      whereArgs: [weekAgo.millisecondsSinceEpoch, now.millisecondsSinceEpoch],
      orderBy: 'date DESC',
    );
    return maps.map((map) => UsageModel.fromMap(map)).toList();
  }

  // ========== 统计数据 ==========

  Future<Map<String, int>> getWeeklyTodoStats() async {
    final db = await database;
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final stats = <String, int>{};

    for (int i = 0; i < 7; i++) {
      final date = weekAgo.add(Duration(days: i + 1));
      final dateStr = '${date.month}/${date.day}';
      final count = await getCompletedCountForDate(date);
      stats[dateStr] = count;
    }

    return stats;
  }
}
