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
  bool _calendarExpanded = true;
  List<TodoModel> _todos = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final provider = context.read<TodoProvider>();
    await provider.loadTodos();
    _filterByDate(provider.todos);
  }

  void _filterByDate(List<TodoModel> all) {
    setState(() => _todos = all.where((t) => t.shouldShowOn(_selectedDay)).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (ctx, provider, _) {
        if (provider.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final dateStr = DateFormat('M月d日 EEEE', 'zh_CN').format(_selectedDay);
        return Scaffold(
          appBar: AppBar(title: Column(children: [const Text('待办', style: TextStyle(fontSize: 18)), Text(dateStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal))]),
            elevation: 0, centerTitle: true,
            actions: [IconButton(icon: Icon(_calendarExpanded ? Icons.calendar_month : Icons.calendar_today), onPressed: () => setState(() => _calendarExpanded = !_calendarExpanded))],
          ),
          body: Column(children: [
            if (_calendarExpanded)
              Container(decoration: BoxDecoration(color: Theme.of(context).cardColor, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                child: TableCalendar(firstDay: DateTime(2020), lastDay: DateTime(2030), focusedDay: _selectedDay,
                  selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
                  onDaySelected: (d, _) { setState(() { _selectedDay = d; _calendarExpanded = false; }); _filterByDate(provider.todos); },
                  calendarStyle: CalendarStyle(selectedDecoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
                    todayDecoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), shape: BoxShape.circle)),
                  headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true), daysOfWeekHeight: 26,
                  availableCalendarFormats: const {CalendarFormat.month: '月'},
                )),
            Expanded(child: _todos.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.event_available, size: 64, color: Colors.grey.shade300), const SizedBox(height: 12), Text('这天没有待办', style: TextStyle(color: Colors.grey.shade400))]))
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: _todos.length,
                  onReorder: (oldIdx, newIdx) {
                    if (newIdx > oldIdx) newIdx--;
                    final item = _todos.removeAt(oldIdx);
                    _todos.insert(newIdx, item);
                    provider.reorderTodos(_todos);
                  },
                  proxyDecorator: (c, i, a) => Material(elevation: 4, borderRadius: BorderRadius.circular(12), child: c),
                  itemBuilder: (ctx, i) => TodoTile(key: ValueKey(_todos[i].id), todo: _todos[i],
                    onToggle: () {
                      if (_todos[i].type == TodoType.disposable) {
                        provider.deleteTodo(_todos[i].id!);
                        _todos.removeAt(i);
                        setState(() {});
                      } else {
                        provider.toggleComplete(_todos[i].id!);
                      }
                    },
                    onDelete: () {
                      showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('删除'), content: Text('确定删除「${_todos[i].title}」？'), actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                        TextButton(onPressed: () { provider.deleteTodo(_todos[i].id!); Navigator.pop(ctx); }, style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('删除')),
                      ]));
                    },
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddTodoScreen(existingTodo: _todos[i]))),
                  ),
                )),
          ]),
          floatingActionButton: FloatingActionButton(onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTodoScreen()));
            _filterByDate(provider.todos);
          }, child: const Icon(Icons.add)),
        );
      },
    );
  }
}
