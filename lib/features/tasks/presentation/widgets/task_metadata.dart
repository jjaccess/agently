
import 'package:flutter/material.dart';
import '../../domain/task.dart';

class TaskMetadata extends StatelessWidget {
  final Task task;

  const TaskMetadata({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final due = task.dueDate != null
        ? task.dueDate!.toLocal().toString().split(" ")[0]
        : "Sin fecha";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Asignado a: ${task.assignedTo ?? 'Nadie'}",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 6),
        Text(
          "Categoría: ${task.category}",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 6),
        Text(
          "Vence: $due",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (task.tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: task.tags
                .map(
                  (tag) => Chip(
                    label: Text(tag),
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}
