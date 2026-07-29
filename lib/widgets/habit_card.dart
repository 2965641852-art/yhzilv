import 'package:flutter/material.dart';
import '../models/habit_model.dart';

class HabitCard extends StatelessWidget {
  final HabitModel habit;
  final int todayCount;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const HabitCard({
    super.key,
    required this.habit,
    required this.todayCount,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final done = todayCount >= habit.targetCount;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: done ? Colors.green.shade50 : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: done ? Colors.green.shade300 : Colors.grey.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(habit.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(habit.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(
              '$todayCount/${habit.targetCount} ${habit.unit}',
              style: TextStyle(fontSize: 11, color: done ? Colors.green : Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
