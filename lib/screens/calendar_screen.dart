import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/todo_provider.dart';
import '../models/todo_model.dart';
import 'add_todo_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日历'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<TodoProvider>(
        builder: (context, provider, _) {
          final todos = provider.todos;
          final events = _buildEvents(todos);

          return Column(
            children: [
              // 日历
              TableCalendar(
                firstDay: DateTime(2020),
                lastDay: DateTime(2030),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
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
                  markerDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                ),
                eventLoader: (day) => events[day] ?? [],
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return null;
                    return Positioned(
                      bottom: 2,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              // 选中日期的待办
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      DateFormat('M月d日 EEEE', 'zh_CN').format(_selectedDay),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text('${_dayTodos(todos, _selectedDay).length} 项'),
                  ],
                ),
              ),
              Expanded(
                child: _dayTodos(todos, _selectedDay).isEmpty
                    ? Center(child: Text('这天没有待办', style: TextStyle(color: Colors.grey.shade400)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _dayTodos(todos, _selectedDay).length,
                        itemBuilder: (context, i) {
                          final t = _dayTodos(todos, _selectedDay)[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              leading: Icon(
                                t.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: t.isCompleted ? Colors.green : Colors.grey,
                              ),
                              title: Text(t.title,
                                style: TextStyle(
                                  decoration: t.isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              subtitle: t.durationText.isNotEmpty ? Text(t.durationText, style: const TextStyle(fontSize: 12)) : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (t.isDaily) const Text('每日 ', style: TextStyle(fontSize: 11, color: Colors.blue)),
                                  Text(t.priorityText, style: TextStyle(fontSize: 11, color: t.priority == TodoPriority.high ? Colors.red : Colors.grey)),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => AddTodoScreen(existingTodo: t)));
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTodoScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }

  Map<DateTime, List<bool>> _buildEvents(List<TodoModel> todos) {
    final map = <DateTime, List<bool>>{};
    for (final t in todos) {
      if (t.createdAt != null) {
        final d = DateTime(t.createdAt.year, t.createdAt.month, t.createdAt.day);
        map.putIfAbsent(d, () => []).add(t.isCompleted);
      }
      if (t.dueDate != null) {
        final d = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
        map.putIfAbsent(d, () => []).add(t.isCompleted);
      }
    }
    return map;
  }

  List<TodoModel> _dayTodos(List<TodoModel> todos, DateTime day) {
    return todos.where((t) {
      if (t.dueDate != null) {
        return isSameDay(t.dueDate!, day);
      }
      return isSameDay(t.createdAt, day);
    }).toList();
  }
}
