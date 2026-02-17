
import 'package:flutter/material.dart';
import '../../domain/task_status.dart';

class TaskStatusBadge extends StatelessWidget {
  final TaskStatus status;

  const TaskStatusBadge({
    super.key,
    required this.status,
  });

  Color _color(BuildContext context) {
    switch (status) {
      case TaskStatus.open:
        return Colors.blue;
      case TaskStatus.inProgress:
        return Colors.orange;
      case TaskStatus.onHold:
        return Colors.grey;
      case TaskStatus.done:
        return Colors.green;
      case TaskStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: _color(context).withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          color: _color(context),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
