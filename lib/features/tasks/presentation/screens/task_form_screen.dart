import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Para usar context.pop()

import '../../application/task_providers.dart';
import '../../domain/task_priority.dart';
import '../widgets/primary_button.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  final String? meetingId;
  const TaskFormScreen({super.key, this.meetingId});

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _responsable = TextEditingController();

  TaskPriority _priority = TaskPriority.medium;
  String _category = 'General';
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  bool _enableReminder = false;
  int _reminderMinutes = 30;

  final _categories = const [
    'General',
    'Infraestructura',
    'Seguridad',
    'Desarrollo',
    'Soporte',
    'Plataforma',
    'Telecomunicaciones',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _responsable.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(taskControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.meetingId != null ? 'Nueva Tarea de Comité' : 'Nueva tarea',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Banner informativo si la tarea pertenece a un comité
              if (widget.meetingId != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.link, color: Colors.blue, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Esta tarea se vinculará automáticamente a este comité.",
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              TextFormField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _responsable,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Responsable',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<TaskPriority>(
                value: _priority,
                decoration: const InputDecoration(
                  labelText: 'Prioridad',
                  border: OutlineInputBorder(),
                ),
                items: TaskPriority.values
                    .map(
                      (p) => DropdownMenuItem(value: p, child: Text(p.label)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _priority = v ?? _priority),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 16),

              // Fecha + hora
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha de vencimiento',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _dueDate != null
                              ? "${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}"
                              : 'Sin fecha',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Hora',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _dueTime != null
                              ? _dueTime!.format(context)
                              : 'Sin hora',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SwitchListTile(
                value: _enableReminder,
                title: const Text('Activar recordatorio'),
                onChanged: (v) => setState(() => _enableReminder = v),
              ),

              if (_enableReminder) ...[
                DropdownButtonFormField<int>(
                  value: _reminderMinutes,
                  decoration: const InputDecoration(
                    labelText: 'Tiempo de anticipación',
                    prefixIcon: Icon(Icons.notifications_active_outlined),
                  ),
                  items: const [0, 5, 10, 15, 30, 60, 120, 1440]
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(_fmtReminder(m)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _reminderMinutes = v ?? 30),
                ),
              ],

              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Guardar Tarea',
                onPressed: () async {
                  print(
                    "DEBUG: Vinculando tarea al comité: ${widget.meetingId}",
                  ); // <-- Verifica esto en consola
                  if (_formKey.currentState!.validate()) {
                    DateTime? due;
                    if (_dueDate != null) {
                      due = DateTime(
                        _dueDate!.year,
                        _dueDate!.month,
                        _dueDate!.day,
                        _dueTime?.hour ?? 9,
                        _dueTime?.minute ?? 0,
                      );
                    }

                    await controller.addTask(
                      title: _titleCtrl.text.trim(),
                      description: _descCtrl.text.trim(),
                      priority: _priority,
                      dueDate: due,
                      category: _category,
                      assignedTo: _responsable.text.trim(),
                      meetingId:
                          widget.meetingId, // <--- AQUÍ SE VINCULA EL COMITÉ
                      reminderMinutesBefore: _enableReminder
                          ? _reminderMinutes
                          : null,
                    );

                    if (context.mounted) {
                      context.pop(); // Usamos go_router para volver atrás
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      initialDate: _dueDate ?? now,
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _dueTime = picked);
  }
}

String _fmtReminder(int minutes) {
  if (minutes == 0) return "Al momento del vencimiento";
  if (minutes < 60) return "$minutes minutos antes";
  if (minutes == 60) return "1 hora antes";
  if (minutes >= 1440) return "1 día antes";
  return "${minutes ~/ 60} horas antes";
}
