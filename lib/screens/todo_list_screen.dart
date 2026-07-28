import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/todo_model.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_tile.dart';
import 'add_todo_screen.dart';

class TodoListScreen extends StatelessWidget {
  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('待办事项'),
            elevation: 0,
            centerTitle: true,
          ),
          body: Column(
            children: [
              // 筛选标签
              _buildFilterBar(context, todoProvider),
              // 统计概览
              _buildStatsBar(context, todoProvider),
              // 待办列表
              Expanded(
                child: todoProvider.todos.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => todoProvider.loadTodos(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: todoProvider.todos.length,
                          itemBuilder: (context, index) {
                            final todo = todoProvider.todos[index];
                            return TodoTile(
                              todo: todo,
                              onToggle: () =>
                                  todoProvider.toggleComplete(todo.id!),
                              onDelete: () => _confirmDelete(
                                context, todoProvider, todo,
                              ),
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

  Widget _buildFilterBar(BuildContext context, TodoProvider provider) {
    final filters = ['全部', '今日', '待完成', '已完成'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final selected = provider.filter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(f),
                selected: selected,
                onSelected: (_) => provider.setFilter(f),
                backgroundColor: Colors.grey.shade100,
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                checkmarkColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatsBar(BuildContext context, TodoProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
            Theme.of(context).colorScheme.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('总待办', '${provider.todos.length}'),
          _statItem('待完成', '${provider.pendingCount}'),
          _statItem('今日完成', '${provider.completedToday}'),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checklist_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            '还没有待办事项',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            '点击 + 添加第一个目标吧',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  void _addTodo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTodoScreen()),
    );
  }

  void _editTodo(BuildContext context, TodoModel todo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTodoScreen(existingTodo: todo),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    TodoProvider provider,
    TodoModel todo,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除待办'),
        content: Text('确定要删除「${todo.title}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteTodo(todo.id!);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已删除')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
