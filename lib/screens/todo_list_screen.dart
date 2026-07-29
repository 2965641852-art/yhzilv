import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/todo_model.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_tile.dart';
import 'add_todo_screen.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  DateTime _selectedDay = DateTime.now();
  bool _calendarExpanded = false;
  String _filter = '全部';

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        final filteredTodos = _filterTodos(todoProvider.todos);

        return Scaffold(
          appBar: AppBar(
            title: const Text('待办事项'),
            elevation: 0,
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(_calendarExpanded ? Icons.calendar_month : Icons.calendar_today),
                onPressed: () => setState(() => _calendarExpanded = !_calendarExpanded),
              ),
            ],
          ),
          body: Column(
            children: [
              // 日历
              if (_calendarExpanded)
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: TableCalendar(
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2030),
                    focusedDay: _selectedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = selected;
                        _filter = '按日期';
                      });
                    },
                    calendarStyle: CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                    daysOfWeekHeight: 30,
                    availableCalendarFormats: const {CalendarFormat.month: '月'},
                  ),
                ),

              // 筛选标签
              _buildFilterBar(context, todoProvider),

              // 统计概览
              _buildStatsBar(context, todoProvider),

              // 待办列表
              Expanded(
                child: filteredTodos.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => todoProvider.loadTodos(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filteredTodos.length,
                          itemBuilder: (context, index) {
                            final todo = filteredTodos[index];
                            return TodoTile(
                              todo: todo,
                              onToggle: () => todoProvider.toggleComplete(todo.id!),
                              onDelete: () => _confirmDelete(context, todoProvider, todo),
                              onTap: () => _editTodo(context, todo),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addTodo(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  List<TodoModel> _filterTodos(List<TodoModel> todos) {
    if (_filter == '按日期') {
      return todos.where((t) {
        if (t.isDaily) return true;
        if (t.dueDate != null) return isSameDay(t.dueDate!, _selectedDay);
        return isSameDay(t.createdAt, _selectedDay);
      }).toList();
    }
    switch (_filter) {
      case '今日':
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return todos.where((t) {
          if (t.isDaily) return true;
          if (t.dueDate == null) return false;
          return t.dueDate!.isAfter(start) && t.dueDate!.isBefore(end);
        }).toList();
      case '待完成':
        return todos.where((t) => !t.isCompleted).toList();
      case '已完成':
        return todos.where((t) => t.isCompleted).toList();
      default:
        return todos;
    }
  }

  Widget _buildFilterBar(BuildContext context, TodoProvider provider) {
    final filters = ['全部', '今日', '待完成', '已完成'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final selected = _filter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(f),
                selected: selected,
                onSelected: (_) => setState(() {
                  _filter = f;
                  if (f != '按日期') _calendarExpanded = false;
                }),
                backgroundColor: Colors.grey.shade100,
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                side: BorderSide(
                  color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatsBar(BuildContext context, TodoProvider provider) {
    final total = provider.todos.length;
    final pending = provider.pendingCount;
    final today = provider.completedToday;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary.withOpacity(0.8), Theme.of(context).colorScheme.primary]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('总待办', '$total'),
          _statItem('待完成', '$pending'),
          _statItem('今日完成', '$today'),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) => Column(
    children: [
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
    ],
  );

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.checklist_rounded, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('还没有待办事项', style: TextStyle(fontSize: 18, color: Colors.grey.shade500)),
        Text('点击 + 添加第一个目标吧', style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
      ],
    ),
  );

  void _addTodo(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTodoScreen()));
  }

  void _editTodo(BuildContext context, TodoModel todo) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddTodoScreen(existingTodo: todo)));
  }

  void _confirmDelete(BuildContext context, TodoProvider provider, TodoModel todo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除待办'),
        content: Text('确定要删除「${todo.title}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () { provider.deleteTodo(todo.id!); Navigator.pop(ctx); },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
