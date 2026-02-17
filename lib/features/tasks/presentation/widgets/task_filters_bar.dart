
import 'package:flutter/material.dart';
import '../../domain/task_status.dart';
import '../../domain/task_priority.dart';

class TaskFiltersBar extends StatelessWidget {
  final TaskStatus? selectedStatus;
  final TaskPriority? selectedPriority;
  final String? selectedCategory;

  final void Function(TaskStatus?) onStatusChanged;
  final void Function(TaskPriority?) onPriorityChanged;
  final void Function(String?) onCategoryChanged;

  const TaskFiltersBar({
    super.key,
    this.selectedStatus,
    this.selectedPriority,
    this.selectedCategory,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // FILTRO POR ESTADO
        DropdownButton<TaskStatus?>(
          value: selectedStatus,
          hint: const Text("Estado"),
          items: [
            const DropdownMenuItem(value: null, child: Text("Todos")),
            ...TaskStatus.values.map(
              (s) => DropdownMenuItem(
                value: s,
                child: Text(s.label),
              ),
            )
          ],
          onChanged: onStatusChanged,
        ),

        // FILTRO POR PRIORIDAD
        DropdownButton<TaskPriority?>(
          value: selectedPriority,
          hint: const Text("Prioridad"),
          items: [
            const DropdownMenuItem(value: null, child: Text("Todas")),
            ...TaskPriority.values.map(
              (p) => DropdownMenuItem(
                value: p,
                child: Text(p.label),
              ),
            )
          ],
          onChanged: onPriorityChanged,
        ),

        // FILTRO POR CATEGORÍA
        SizedBox(
          width: 160,
          child: TextField(
            decoration: const InputDecoration(
              labelText: "Categoría",
            ),
            onChanged: (value) => onCategoryChanged(
              value.isEmpty ? null : value,
            ),
          ),
        ),
      ],
    );
  }
}
