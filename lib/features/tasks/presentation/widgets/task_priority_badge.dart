
import 'package:flutter/material.dart';
import '../../domain/task_priority.dart';

class TaskPriorityBadge extends StatelessWidget {
  final TaskPriority priority;
  const TaskPriorityBadge({super.key, required this.priority});

  Color get _color {
    switch (priority) {
      case TaskPriority.critical: return const Color(0xFFD32F2F); // rojo
      case TaskPriority.high:     return const Color(0xFFF57C00); // naranja
      case TaskPriority.medium:   return const Color(0xFF1976D2); // azul
      case TaskPriority.low:      return const Color(0xFFFBC02D); // amarillo
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withOpacity(0.2)),
      ),
      child: Text(
        priority.label, // asegúrate de importar task_priority.dart para .label
        style: TextStyle(
          fontSize: 12,
          color: _color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
