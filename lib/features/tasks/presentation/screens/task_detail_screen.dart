import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/utils/file_utils.dart';
import '../../application/task_providers.dart';
import '../../application/meeting_controller.dart';
import '../../domain/task.dart';
import '../../domain/task_status.dart';
import '../../domain/meeting.dart';
import '../widgets/task_priority_badge.dart';
import '../widgets/task_status_badge.dart';

const List<String> taskCategories = [
  'General',
  'Infraestructura',
  'Seguridad',
  'Desarrollo',
  'Soporte',
  'Sogamoso App',
];

const List<Map<String, dynamic>> reminderOptions = [
  {'label': 'Al momento del vencimiento', 'value': 0},
  {'label': '5 minutos antes', 'value': 5},
  {'label': '15 minutos antes', 'value': 15},
  {'label': '30 minutos antes', 'value': 30},
  {'label': '1 hora antes', 'value': 60},
  {'label': '1 día antes', 'value': 1440},
];

class TaskDetailScreen extends ConsumerWidget {
  final String id;
  const TaskDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTasks = ref.watch(taskControllerProvider);
    final asyncMeetings = ref.watch(meetingControllerProvider);
    final controller = ref.read(taskControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de tarea'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                final ok = await _confirmDelete(
                  context,
                  '¿Estás seguro de eliminar esta tarea? Esta acción no se puede deshacer.',
                );
                if (ok == true && context.mounted) {
                  await controller.removeTask(id);
                  if (context.mounted) context.pop();
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Text('Eliminar', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: asyncTasks.when(
        data: (tasks) {
          final task = tasks.where((t) => t.id == id).firstOrNull;
          if (task == null) {
            return const Center(child: Text('Tarea no encontrada'));
          }

          final Meeting? linkedMeeting = asyncMeetings.value
              ?.where((m) => m.id == task.meetingId)
              .firstOrNull;

          final bool isCompleted = task.status == TaskStatus.done;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                task.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TaskStatusBadge(status: task.status),
                  const SizedBox(width: 8),
                  TaskPriorityBadge(priority: task.priority),
                ],
              ),
              const SizedBox(height: 20),

              if (task.description.isNotEmpty) ...[
                Text(
                  task.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
              ],

              // --- BLOQUE DE INFORME DE CIERRE ---
              // CORRECCIÓN: Quitamos el '??' innecesario ya que la lógica del 'if' ya filtra
              if (isCompleted && task.closingComment != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.verified,
                            size: 18,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'INFORME DE CIERRE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.closingComment!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              if (linkedMeeting != null) ...[
                _buildMeetingLink(linkedMeeting),
                _buildCreationDateInfo(task.createdAt),
                const SizedBox(height: 10),
              ],

              if (linkedMeeting == null) _buildCreationDateInfo(task.createdAt),

              const Divider(height: 40),

              if (task.status == TaskStatus.done)
                _buildExecutionTimeCard(
                  task.createdAt,
                  task.completedAt ?? DateTime.now(),
                ),

              // --- EVIDENCIAS ---
              if (task.evidencePaths != null &&
                  task.evidencePaths!.isNotEmpty) ...[
                const Text(
                  'EVIDENCIAS ADJUNTAS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: task.evidencePaths!.length,
                    itemBuilder: (context, index) => _buildEvidenceThumbnail(
                      context,
                      task.evidencePaths![index],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              IgnorePointer(
                ignoring: isCompleted,
                child: Opacity(
                  opacity: isCompleted ? 0.6 : 1.0,
                  child: Column(
                    children: [
                      _editableRow(
                        context,
                        label: 'Categoría',
                        value: task.category,
                        icon: Icons.label_outline,
                        onTap: () =>
                            _showCategoryPicker(context, task, controller),
                      ),
                      _editableRow(
                        context,
                        label: 'Responsable',
                        value: task.assignedTo ?? 'Sin asignar',
                        icon: Icons.person_outline,
                        onTap: () => _showEditDialog(
                          context,
                          'Asignar Responsable',
                          task.assignedTo ?? '',
                          (val) => controller.updateTask(
                            task.copyWith(assignedTo: val),
                          ),
                        ),
                      ),
                      _editableRow(
                        context,
                        label: 'Vencimiento',
                        value: task.dueDate != null
                            ? _fmtDateTime(task.dueDate!)
                            : 'Sin fecha',
                        icon: Icons.calendar_today_outlined,
                        onTap: () => _pickDateTime(context, task, controller),
                      ),
                      _editableRow(
                        context,
                        label: 'Recordatorio',
                        value: task.reminderMinutesBefore != null
                            ? _fmtReminder(task.reminderMinutesBefore!)
                            : 'Sin recordatorio',
                        icon: Icons.notifications_active_outlined,
                        onTap: () =>
                            _showReminderPicker(context, task, controller),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 40),
              const Text(
                'Gestión de estado',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Estado actual"),
                trailing: DropdownButton<TaskStatus>(
                  value: task.status,
                  onChanged: isCompleted
                      ? null
                      : (newStatus) {
                          if (newStatus == TaskStatus.done) {
                            _confirmCompleteTask(context, ref, task);
                          } else if (newStatus != null) {
                            controller.setStatus(task.id, newStatus);
                          }
                        },
                  items: TaskStatus.values
                      .map(
                        (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                      )
                      .toList(),
                ),
              ),

              if (!isCompleted)
                Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 40),
                  child: FilledButton.icon(
                    onPressed: () => _confirmCompleteTask(context, ref, task),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('MARCAR COMO COMPLETADA'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(55),
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  // --- WIDGETS INTERNOS ---
  Widget _buildEvidenceThumbnail(BuildContext context, String path) {
    final isImage = ['.jpg', '.jpeg', '.png'].any(path.toLowerCase().endsWith);
    return GestureDetector(
      onTap: () async {
        if (isImage) {
          _showFullScreenImage(context, path);
        } else {
          // AHORA LLAMAMOS A LA FUNCIÓN PARA QUITAR LA ADVERTENCIA
          await _openExternalFile(path);
        }
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: isImage
              ? Image.file(File(path), fit: BoxFit.cover)
              : const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
        ),
      ),
    );
  }

  Widget _buildExecutionTimeCard(DateTime start, DateTime end) {
    final DateTime sUtc = start.isUtc ? start : start.toUtc();
    final DateTime eUtc = end.isUtc ? end : end.toUtc();
    final duration = eUtc.difference(sUtc);
    final int totalMinutes = duration.inMinutes.abs();
    final int h = totalMinutes ~/ 60;
    final int m = totalMinutes % 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_sharp, color: Colors.blue, size: 28),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "TIEMPO REAL DE EJECUCIÓN",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              Text(
                h > 0 ? "$h h $m min" : "$m min",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingLink(Meeting meeting) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.groups, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Vinculada al comité:",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  meeting.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreationDateInfo(DateTime createdAt) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.history, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Tarea creada el:",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _fmtDateTime(createdAt),
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _editableRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: Colors.blueGrey.shade50,
        child: Icon(icon, color: Colors.blueGrey, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }

  // --- DIÁLOGOS Y LÓGICA ---
  void _showEditDialog(
    BuildContext context,
    String title,
    String initialValue,
    Function(String) onSave, {
    bool isNumeric = false,
  }) {
    final textController = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: textController,
          autofocus: true,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Ingrese el valor",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () {
              onSave(textController.text);
              Navigator.pop(ctx);
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }

  void _showCategoryPicker(
    BuildContext context,
    Task task,
    dynamic controller,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Seleccionar Categoría',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ...taskCategories.map(
              (cat) => ListTile(
                title: Text(cat),
                trailing: task.category == cat
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  controller.updateTask(task.copyWith(category: cat));
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReminderPicker(
    BuildContext context,
    Task task,
    dynamic controller,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Configurar Recordatorio',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              ...reminderOptions.map(
                (opt) => ListTile(
                  title: Text(opt['label']),
                  trailing: task.reminderMinutesBefore == opt['value']
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    controller.updateTask(
                      task.copyWith(reminderMinutesBefore: opt['value']),
                    );
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateTime(
    BuildContext context,
    Task task,
    dynamic controller,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: task.dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2030),
    );
    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(task.dueDate ?? DateTime.now()),
      );
      if (time != null) {
        final fullDate = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        controller.updateTask(task.copyWith(dueDate: fullDate));
      }
    }
  }

  Future<void> _confirmCompleteTask(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final commentController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    List<String> tempPaths = [];

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.verified, color: Colors.green),
              SizedBox(width: 10),
              Text('Cerrar Tarea'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Ingresa el comentario de cierre:'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Nota final',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Debes ingresar una nota'
                        : null,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () async {
                          final p = await ImagePicker().pickImage(
                            source: ImageSource.camera,
                            imageQuality: 50,
                          );
                          if (p != null)
                            setModalState(() => tempPaths.add(p.path));
                        },
                        icon: const Icon(Icons.camera_alt),
                      ),
                      IconButton.filledTonal(
                        onPressed: () async {
                          final r = await FilePicker.platform.pickFiles(
                            allowMultiple: true,
                          );
                          if (r != null)
                            setModalState(
                              () =>
                                  tempPaths.addAll(r.paths.whereType<String>()),
                            );
                        },
                        icon: const Icon(Icons.attach_file),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCELAR'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  List<String> permanentPaths = [];
                  for (var p in tempPaths) {
                    permanentPaths.add(await FileUtils.saveFilePermanently(p));
                  }
                  final now = DateTime.now();
                  final timestamp =
                      "${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}";

                  await ref
                      .read(taskControllerProvider.notifier)
                      .updateTask(
                        task.copyWith(
                          status: TaskStatus.done,
                          closingComment:
                              "Cerrada el $timestamp: ${commentController.text.trim()}",
                          evidencePaths: permanentPaths,
                          completedAt: DateTime.now(),
                        ),
                      );
                  if (context.mounted) Navigator.pop(dialogContext);
                }
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('CONFIRMAR CIERRE'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- FUNCIONES GLOBALES ---

void _showFullScreenImage(BuildContext context, String path) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(path), fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: IconButton.filled(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _openExternalFile(String path) async {
  final uri = Uri.file(path);
  try {
    // Para archivos locales en Android/iOS usamos Share como respaldo si launchUrl falla
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await Share.shareXFiles([XFile(path)], text: 'Visualizando archivo');
    }
  } catch (e) {
    debugPrint("Error al abrir archivo: $e");
    // Fallback final: compartir el archivo
    await Share.shareXFiles([XFile(path)]);
  }
}

String _fmtDateTime(DateTime dt) {
  return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
}

String _fmtReminder(int minutes) {
  if (minutes == 0) return "Al momento del vencimiento";
  if (minutes < 60) return "$minutes minutos antes";
  if (minutes == 60) return "1 hora antes";
  if (minutes >= 1440) return "1 día antes";
  return "${minutes ~/ 60} horas antes";
}

Future<bool?> _confirmDelete(BuildContext context, String message) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirmar'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => ctx.pop(false),
          child: const Text('CANCELAR'),
        ),
        FilledButton(
          onPressed: () => ctx.pop(true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('ELIMINAR'),
        ),
      ],
    ),
  );
}
