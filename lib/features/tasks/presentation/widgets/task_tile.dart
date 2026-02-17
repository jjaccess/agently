
import 'package:flutter/material.dart';
import '../../domain/task.dart';
import '../../domain/task_status.dart';
import '../../domain/task_priority.dart';
import 'task_priority_badge.dart'; // 👈

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  const TaskTile({super.key, required this.task, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == TaskStatus.done;

    return ListTile(
      onTap: onTap,
      title: Text(
        task.title,
        style: isDone
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: Row(
        children: [
          Flexible(child: Text('${task.category} • ${task.priority.label}', maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          TaskPriorityBadge(priority: task.priority), // 👈 badge de color
        ],
      ),
      trailing: Icon(
        isDone ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isDone ? Colors.green : Theme.of(context).colorScheme.outline,
      ),
    );
  }
}
