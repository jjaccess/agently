import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/tasks/domain/task.dart';
import '../../features/tasks/application/task_providers.dart';
import '../../features/tasks/application/meeting_controller.dart';
import '../../features/tasks/domain/task_status.dart'; // Asegúrate de importar esto

class BackupService {
  /// EXPORTAR: Ahora recibe tareas y reuniones
  static Future<void> exportFullBackup({
    required List<Task> tasks,
    required List<dynamic>
    meetings, // Usamos dynamic para evitar conflictos de tipo
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final Map<String, dynamic> fullData = {
        'metadata': {
          'version': '1.1.0',
          'export_date': DateTime.now().toIso8601String(),
        },
        'settings': {},
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'meetings': meetings.map((m) => m.toJson()).toList(),
      };

      // Guardar preferencias adicionales
      for (String key in prefs.getKeys()) {
        fullData['settings'][key] = prefs.get(key);
      }

      String jsonString = const JsonEncoder.withIndent('  ').convert(fullData);

      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/agently_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString(jsonString);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Backup Completo Agently (Tareas y Comités)');
    } catch (e) {
      print("Error exportando: $e");
    }
  }

  /// IMPORTAR: Lee y restaura
  static Future<bool> importFullBackup(WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return false;

      File file = File(result.files.single.path!);
      String content = await file.readAsString();
      final dynamic decoded = jsonDecode(content);

      final taskController = ref.read(taskControllerProvider.notifier);
      final meetingController = ref.read(meetingControllerProvider.notifier);

      // --- CASO 1: FORMATO ANTIGUO (Como el archivo que subiste) ---
      if (decoded is Map && decoded.containsKey('meetings_storage_key')) {
        // Restaurar Reuniones del formato viejo
        final List<dynamic> oldMeetingsRaw = decoded['meetings_storage_key'];
        for (var meetingStr in oldMeetingsRaw) {
          final Map<String, dynamic> m = jsonDecode(meetingStr);
          await meetingController.addMeeting(
            id: m['id']?.toString(),
            name: m['title'] ?? m['name'] ?? 'Sin título',
            date: DateTime.tryParse(m['date'] ?? '') ?? DateTime.now(),
            description: m['description'] ?? '',
          );
        }
        // Restaurar Tareas del formato viejo
        if (decoded.containsKey('tasks_data')) {
          final List<dynamic> oldTasksList = jsonDecode(decoded['tasks_data']);
          for (var taskJson in oldTasksList) {
            final task = Task.fromJson(taskJson);
            await _processAddTask(taskController, task, taskJson);
          }
        }
        return true;
      }

      // --- CASO 2: FORMATO NUEVO (Estructura limpia) ---
      if (decoded is Map) {
        // 1. Restaurar reuniones primero para que las tareas encuentren sus IDs
        if (decoded.containsKey('meetings')) {
          final List<dynamic> meetingList = decoded['meetings'];
          for (var m in meetingList) {
            await meetingController.addMeeting(
              id: m['id']?.toString(),
              name: m['name'] ?? m['title'] ?? 'Sin título',
              date: DateTime.tryParse(m['date'] ?? '') ?? DateTime.now(),
              description: m['description'] ?? '',
            );
          }
        }

        // 2. Restaurar tareas
        if (decoded.containsKey('tasks')) {
          final List<dynamic> taskList = decoded['tasks'];
          for (var taskJson in taskList) {
            final task = Task.fromJson(taskJson);
            await _processAddTask(taskController, task, taskJson);
          }
        }
        return true;
      }

      return false;
    } catch (e) {
      print("Error en importación: $e");
      return false;
    }
  }

  /// PROCESADOR: Traduce el JSON al controlador respetando el estado
  static Future<void> _processAddTask(
    dynamic taskController,
    Task task,
    Map<String, dynamic> rawJson,
  ) async {
    // Traducción de estados del JSON (String) al Enum de la App
    TaskStatus targetStatus;
    final String? statusStr = rawJson['status']?.toString().toLowerCase();

    switch (statusStr) {
      case 'inprogress':
      case 'in_progress':
        targetStatus = TaskStatus.inProgress;
        break;
      case 'done':
      case 'completed':
        targetStatus = TaskStatus.done;
        break;
      case 'onhold':
      case 'waiting':
        targetStatus = TaskStatus.onHold;
        break;
      default:
        targetStatus = TaskStatus.open;
    }

    await taskController.addTask(
      title: task.title,
      description: task.description,
      priority: task.priority,
      dueDate: task.dueDate,
      category: task.category,
      assignedTo: task.assignedTo,
      status: targetStatus,
      reminderMinutesBefore: task.reminderMinutesBefore,
      meetingId: task.meetingId,
      evidencePaths: task.evidencePaths,
    );
  }
}
