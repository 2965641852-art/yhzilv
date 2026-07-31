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
      builder: (context, provider, child) {
        final filtered = _filterTodos(provider.todos);
        final dateStr = _filter == '按日期' ? DateFormat('M月d日 EEEE', 'zh_CN').format(_selectedDay) : DateFormat('M月d日 EEEE', 'zh_CN').format(DateTime.now());

        return Scaffold(
          appBar: AppBar(
            title: Column(children: [
              const Text('待办事项', style: TextStyle(fontSize: 18)),
              Text(dateStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
            ]),
            elevation: 0, centerTitle: true,
            actions: [
              IconButton(icon: Icon(_calendarExpanded ? Icons.calendar_month : Icons.calendar_today),
                onPressed: () => setState(() => _calendarExpanded = !_calendarExpanded)),
            ],
          ),
          body: Column(children: [
            if (_calendarExpanded)
              Container(
                decoration: BoxDecoration(color: Theme.of(context).cardColor, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                child: TableCalendar(
                  firstDay: DateTime(2020), lastDay: DateTime(2030),
                  focusedDay: _selectedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selected, focused) {
                    setState(() { _selectedDay = selected; _filter = '按日期'; _calendarExpanded = false; });
                  },
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
                    todayDecoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), shape: BoxShape.circle),
                  ),
                  headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                  daysOfWeekHeight: 28, availableCalendarFormats: const {CalendarFormat.month: '月'},
                ),
              ),
            _buildFilterBar(context),
            _buildStatsBar(context, provider),
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.checklist_rounded, size: 72, color: Colors.grey.shade300),
                      Text('暂无待办', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                    ]))
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      itemCount: filtered.length,
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) newIndex--;
                        final item = filtered.removeAt(oldIndex);
                        filtered.insert(newIndex, item);
                        provider.reorderTodos(filtered);
                      },
                      proxyDecorator: (child, index, animation) => Material(
                        elevation: 4, borderRadius: BorderRadius.circular(12), child: child,
                      ),
                      itemBuilder: (ctx, i) {
                        final todo = filtered[i];
                        return TodoTile(
                          key: ValueKey(todo.id),
                          todo: todo,
                          onToggle: () => provider.toggleComplete(todo.id!),
                          onDelete: () => _confirmDelete(context, provider, todo),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddTodoScreen(existingTodo: todo))),
                        );
                      },
                    ),
            ),
          ]),
          floatingActionButton: FloatingActionButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTodoScreen())), child: const Icon(Icons.add)),
        );
      },
    );
  }

  List<TodoModel> _filterTodos(List<TodoModel> todos) {
    // 完成即删的始终显示
    if (_filter == '按日期') {
      return todos.where((t) {
        if (t.todoType == TodoType.disposable) return true;
        if (t.dueDate != null) return isSameDay(t.dueDate!, _selectedDay);
        return isSameDay(t.createdAt, _selectedDay);
      }).toList();
    }
    switch (_filter) {
      case '今日': return todos.where((t) {
        if (t.todoType == TodoType.disposable || t.todoType == TodoType.daily) return true;
        if (t.dueDate == null) return false;
        final now = DateTime.now(); final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return t.dueDate!.isAfter(start) && t.dueDate!.isBefore(end);
      }).toList();
      case '待完成': return todos.where((t) => !t.isCompleted).toList();
      case '已完成': return todos.where((t) => t.isCompleted).toList();
      default: return todos;
    }
  }

  Widget _buildFilterBar(BuildContext context) {
    final filters = ['全部', '今日', '待完成', '已完成'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
        children: filters.map((f) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: FilterChip(label: Text(f), selected: _filter == f, onSelected: (_) => setState(() { _filter = f; _calendarExpanded = false; }),
            backgroundColor: Colors.grey.shade100, selectedColor: Theme.of(context).colorScheme.primaryContainer,
            side: BorderSide(color: _filter == f ? Theme.of(context).colorScheme.primary : Colors.grey.shade300)),
        )).toList(),
      )),
    );
  }

  Widget _buildStatsBar(BuildContext context, TodoProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary.withOpacity(0.8), Theme.of(context).colorScheme.primary]), borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _statItem('总待办', '${provider.todos.length}'), _statItem('待完成', '${provider.pendingCount}'), _statItem('今日完成', '${provider.completedToday}'),
      ]),
    );
  }

  Widget _statItem(String label, String value) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
    Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
  ]);

  void _confirmDelete(BuildContext context, TodoProvider provider, TodoModel todo) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('删除待办'), content: Text('确定删除「${todo.title}」？'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        TextButton(onPressed: () { provider.deleteTodo(todo.id!); Navigator.pop(ctx); },
          style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('删除')),
      ],
    ));
  }
}
