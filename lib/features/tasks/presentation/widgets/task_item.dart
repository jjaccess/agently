import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/task.dart';
import '../../domain/task_priority.dart';
import '../../domain/task_status.dart';

class TaskItem extends StatelessWidget {
  final Task task;

  const TaskItem({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isDone = task.status == TaskStatus.done;
    final isOverdue =
        task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        !isDone;

    Color cardBgColor = colorScheme.surface;
    Color borderColor = colorScheme.outlineVariant.withOpacity(0.5);
    double borderWidth = 1.0;

    if (isDone) {
      cardBgColor = colorScheme.surfaceContainerHighest.withOpacity(0.3);
      borderColor = Colors.transparent;
    } else if (isOverdue) {
      cardBgColor = Colors.red.shade50;
      borderColor = Colors.red.shade400;
      borderWidth = 2.0;
    }

    return Card(
      elevation: isOverdue ? 2 : 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor, width: borderWidth),
      ),
      color: cardBgColor,
      child: ListTile(
        onTap: () => context.push('/tasks/${task.id}'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: _getPriorityColor(task.priority),
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        // --- TÍTULO CON BADGE DE ORIGEN ---
        title: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8, // Espacio entre el texto y el badge
          children: [
            Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                decoration: isDone ? TextDecoration.lineThrough : null,
                color: isDone
                    ? colorScheme.outline
                    : (isOverdue ? Colors.red.shade900 : colorScheme.onSurface),
              ),
            ),
            // Widget del Badge de origen
            TaskSourceBadge(meetingId: task.meetingId),
          ],
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.label_outline,
                    size: 14,
                    color: isOverdue
                        ? Colors.red.shade700
                        : colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    task.category,
                    style: TextStyle(
                      color: isOverdue
                          ? Colors.red.shade700
                          : colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  if (task.dueDate != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      isOverdue ? Icons.history : Icons.calendar_today,
                      size: 14,
                      color: isOverdue ? Colors.red : colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${task.dueDate!.day}/${task.dueDate!.month} ${task.dueDate!.hour}:${task.dueDate!.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: isOverdue ? Colors.red : colorScheme.outline,
                        fontSize: 12,
                        fontWeight: isOverdue
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        trailing: isOverdue
            ? const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 28,
              )
            : Icon(
                isDone ? Icons.check_circle : Icons.arrow_forward_ios,
                color: isDone ? Colors.green : colorScheme.outlineVariant,
                size: isDone ? 28 : 16,
              ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.critical:
        return Colors.purple;
      case TaskPriority.high:
        return Colors.redAccent;
      case TaskPriority.medium:
        return Colors.orangeAccent;
      case TaskPriority.low:
        return Colors.blueAccent;
    }
  }
}

// --- WIDGET DEL BADGE (Puede ir aquí mismo) ---
class TaskSourceBadge extends StatelessWidget {
  final String? meetingId;
  const TaskSourceBadge({super.key, this.meetingId});

  @override
  Widget build(BuildContext context) {
    final bool isFromMeeting = meetingId != null && meetingId!.isNotEmpty;

    // Asignación explícita de colores para evitar errores de compilación
    final Color backgroundColor = isFromMeeting
        ? Colors.blue.withOpacity(0.1)
        : Colors.blueGrey.withOpacity(0.1);

    final Color borderColor = isFromMeeting
        ? Colors.blue.withOpacity(0.4)
        : Colors.blueGrey.withOpacity(0.4);

    final Color contentColor = isFromMeeting
        ? Colors.blue.shade800
        : Colors.blueGrey.shade800;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFromMeeting ? Icons.groups_rounded : Icons.person_rounded,
            size: 10,
            color: contentColor,
          ),
          const SizedBox(width: 3),
          Text(
            isFromMeeting ? "COMITÉ" : "IND",
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: contentColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
