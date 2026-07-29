import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/todo_model.dart';
import '../models/usage_model.dart';
import '../models/memo_model.dart';
import '../models/habit_model.dart';
import '../models/anniversary_model.dart';

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
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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
        is_daily INTEGER DEFAULT 0,
        duration_minutes INTEGER,
        last_completed_date TEXT,
        created_at INTEGER NOT NULL,
        completed_at INTEGER
      )
    ''');

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

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE memos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT DEFAULT '',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    for (final category in TodoCategory.defaults) {
      await db.insert('categories', {'name': category});
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE todos ADD COLUMN is_daily INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE todos ADD COLUMN duration_minutes INTEGER");
      await db.execute("ALTER TABLE todos ADD COLUMN last_completed_date TEXT");
      await db.execute('''
        CREATE TABLE memos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          content TEXT DEFAULT '',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE settings (
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');
    }
    if (oldVersion < 3) {
      // 清空旧的使用时长脏数据
      await db.delete('usage_stats');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE habits (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          icon TEXT DEFAULT '✅',
          target_count INTEGER DEFAULT 1,
          unit TEXT DEFAULT '次',
          category TEXT DEFAULT '默认',
          created_at INTEGER NOT NULL,
          is_archived INTEGER DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE habit_completions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          habit_id INTEGER NOT NULL,
          date INTEGER NOT NULL,
          count INTEGER DEFAULT 1,
          FOREIGN KEY (habit_id) REFERENCES habits(id),
          UNIQUE(habit_id, date)
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE anniversaries (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          date INTEGER NOT NULL,
          is_countdown INTEGER DEFAULT 1,
          icon TEXT DEFAULT '📅'
        )
      ''');
    }
    if (oldVersion < 6) {
      await db.execute("ALTER TABLE anniversaries ADD COLUMN remind_annually INTEGER DEFAULT 0");
    }
  }

  // ========== 待办 CRUD ==========

  Future<int> insertTodo(TodoModel todo) async {
    final db = await database;
    return await db.insert('todos', todo.toMap());
  }

  Future<List<TodoModel>> getAllTodos() async {
    final db = await database;
    final maps = await db.query('todos', orderBy: 'created_at DESC');
    return _processDailyTodos(maps.map((m) => TodoModel.fromMap(m)).toList());
  }

  /// 处理每日任务：昨天完成的今天自动重置
  List<TodoModel> _processDailyTodos(List<TodoModel> todos) {
    final today = _todayStr();
    return todos.map((t) {
      if (!t.isDaily) return t;
      if (!t.isCompleted) return t;
      // 每日任务已完成，检查是否是今天完成的
      if (t.lastCompletedDate == today) return t;
      // 昨天完成的，今天重置为未完成
      return t.copyWith(isCompleted: false, completedAt: null);
    }).toList();
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
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
    return _processDailyTodos(maps.map((m) => TodoModel.fromMap(m)).toList());
  }

  Future<List<TodoModel>> getTodayTodos() async {
    final db = await database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;

    final maps = await db.query(
      'todos',
      where: '(due_date >= ? AND due_date <= ?) OR is_completed = 0 OR is_daily = 1',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'created_at DESC',
    );
    return _processDailyTodos(maps.map((m) => TodoModel.fromMap(m)).toList());
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
        if (isCompleted) 'last_completed_date': _todayStr(),
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
    // 先删除该应用当天所有旧记录，再插入新数据（彻底避免重复）
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;

    await db.delete(
      'usage_stats',
      where: 'package_name = ? AND date >= ? AND date <= ?',
      whereArgs: [usage.packageName, startOfDay, endOfDay],
    );
    await db.insert('usage_stats', usage.toMap());
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

  // ========== 备忘录 CRUD ==========

  Future<int> insertMemo(MemoModel memo) async {
    final db = await database;
    return await db.insert('memos', memo.toMap());
  }

  Future<List<MemoModel>> getAllMemos() async {
    final db = await database;
    final maps = await db.query('memos', orderBy: 'updated_at DESC');
    return maps.map((m) => MemoModel.fromMap(m)).toList();
  }

  Future<int> updateMemo(MemoModel memo) async {
    final db = await database;
    return await db.update(
      'memos',
      memo.toMap(),
      where: 'id = ?',
      whereArgs: [memo.id],
    );
  }

  Future<int> deleteMemo(int id) async {
    final db = await database;
    return await db.delete('memos', where: 'id = ?', whereArgs: [id]);
  }

  // ========== 习惯打卡 CRUD ==========

  Future<int> insertHabit(HabitModel habit) async {
    final db = await database;
    return await db.insert('habits', habit.toMap());
  }

  Future<List<HabitModel>> getAllHabits() async {
    final db = await database;
    final maps = await db.query('habits', where: 'is_archived = 0', orderBy: 'created_at ASC');
    return maps.map((m) => HabitModel.fromMap(m)).toList();
  }

  Future<int> updateHabit(HabitModel habit) async {
    final db = await database;
    return await db.update('habits', habit.toMap(), where: 'id = ?', whereArgs: [habit.id]);
  }

  Future<void> toggleHabitComplete(int habitId, {int count = 1}) async {
    final db = await database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final existing = await db.query('habit_completions', where: 'habit_id = ? AND date = ?', whereArgs: [habitId, today]);
    if (existing.isNotEmpty) {
      await db.update('habit_completions', {'count': count}, where: 'id = ?', whereArgs: [existing.first['id']]);
    } else {
      await db.insert('habit_completions', {'habit_id': habitId, 'date': today, 'count': count});
    }
  }

  Future<int> getTodayHabitCount(int habitId) async {
    final db = await database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final result = await db.query('habit_completions', where: 'habit_id = ? AND date = ?', whereArgs: [habitId, today]);
    if (result.isEmpty) return 0;
    return result.first['count'] as int? ?? 0;
  }

  Future<Map<String, int>> getHabitMonthStats(int habitId, int year, int month) async {
    final db = await database;
    final firstDay = DateTime(year, month, 1).millisecondsSinceEpoch;
    final lastDay = DateTime(year, month + 1, 0, 23, 59, 59).millisecondsSinceEpoch;
    final result = await db.query('habit_completions',
        where: 'habit_id = ? AND date >= ? AND date <= ?',
        whereArgs: [habitId, firstDay, lastDay]);
    final stats = <String, int>{};
    for (final r in result) {
      final d = DateTime.fromMillisecondsSinceEpoch(r['date'] as int);
      stats['${d.day}'] = r['count'] as int? ?? 0;
    }
    return stats;
  }

  // ========== 纪念日 CRUD ==========

  Future<int> insertAnniversary(AnniversaryModel a) async {
    final db = await database;
    return await db.insert('anniversaries', a.toMap());
  }

  Future<List<AnniversaryModel>> getAllAnniversaries() async {
    final db = await database;
    final maps = await db.query('anniversaries', orderBy: 'date ASC');
    return maps.map((m) => AnniversaryModel.fromMap(m)).toList();
  }

  // ========== 设置 ==========

  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
