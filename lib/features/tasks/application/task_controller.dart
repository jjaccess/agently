import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/task.dart';
import '../domain/task_priority.dart';
import '../domain/task_status.dart';
import '../data/repositories/task_repository.dart';
import 'task_providers.dart';
import '../../../core/notifications/notifications_service.dart';

class TaskController extends AsyncNotifier<List<Task>> {
  late TaskRepository _repo;
  final _uuid = const Uuid();

  @override
  Future<List<Task>> build() async {
    // Al usar ref.read, nos aseguramos de tener la instancia del repositorio
    _repo = ref.read(taskRepositoryProvider);
    return _fetchAndProcessTasks();
  }

  /// Método central para obtener y ordenar tareas desde SQLite
  Future<List<Task>> _fetchAndProcessTasks() async {
    final tasks = await _repo.getAll();

    // ORDENAMIENTO: Fechas próximas primero, luego por prioridad
    tasks.sort((a, b) {
      if (a.dueDate != null && b.dueDate != null) {
        int dateCompare = a.dueDate!.compareTo(b.dueDate!);
        if (dateCompare != 0) return dateCompare;
      } else if (a.dueDate != null) {
        return -1;
      } else if (b.dueDate != null) {
        return 1;
      }
      return b.priority.index.compareTo(a.priority.index);
    });

    return tasks;
  }

  // === ACTUALIZACIÓN (PERSISTENTE) ===
  Future<void> updateTask(Task updatedTask) async {
    final previousState = state;
    if (!state.hasValue) return;

    try {
      // 1. Actualización Optimista (UI rápida)
      final currentTasks = state.value!;
      state = AsyncValue.data(
        currentTasks
            .map((t) => t.id.trim() == updatedTask.id.trim() ? updatedTask : t)
            .toList(),
      );

      // 2. Persistencia en SQLite
      await _repo.update(updatedTask);

      // 3. Gestión de Notificaciones
      await NotificationsService.instance.cancelReminder(
        updatedTask.id.hashCode,
      );

      if (updatedTask.status != TaskStatus.done &&
          updatedTask.dueDate != null &&
          updatedTask.reminderMinutesBefore != null) {
        await _scheduleNotification(updatedTask);
      }

      print("✅ SQLite: Tarea ${updatedTask.id} guardada.");
    } catch (e) {
      print("❌ Error en updateTask: $e");
      state = previousState; // Revertir si falla SQLite
    }
  }

  // === CREACIÓN DE TAREA ===
  Future<void> addTask({
    required String title,
    String description = "",
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    String category = "General",
    String? assignedTo,
    int? reminderMinutesBefore,
    String? meetingId,
    List<String>? evidencePaths,
    TaskStatus? status, // Agregado para soportar adjuntos iniciales
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final newTask = Task(
        id: _uuid.v4(),
        title: title,
        description: description,
        priority: priority,
        status: status ?? TaskStatus.open,
        dueDate: dueDate,
        category: category,
        assignedTo: assignedTo,
        reminderMinutesBefore: reminderMinutesBefore,
        meetingId: meetingId,
        evidencePaths: evidencePaths ?? [],
      );

      // Guardar en la base de datos
      await _repo.add(newTask);

      if (dueDate != null && reminderMinutesBefore != null) {
        await _scheduleNotification(newTask);
      }

      return _fetchAndProcessTasks();
    });
  }

  // === ELIMINACIÓN ===
  Future<void> removeTask(String id) async {
    state = await AsyncValue.guard(() async {
      await NotificationsService.instance.cancelReminder(id.hashCode);
      await _repo.remove(id);
      return _fetchAndProcessTasks();
    });
  }

  // === ACTUALIZAR SOLO ESTADO (Ej: Desde el Checkbox) ===
  Future<void> setStatus(String id, TaskStatus status) async {
    state = await AsyncValue.guard(() async {
      final tasks = await _repo.getAll();
      final task = tasks.firstWhere((t) => t.id == id);

      final updatedTask = task.copyWith(status: status);
      await _repo.update(updatedTask); // Usamos update completo para SQLite

      if (status == TaskStatus.done) {
        await NotificationsService.instance.cancelReminder(id.hashCode);
      } else {
        await _scheduleNotification(updatedTask);
      }

      return _fetchAndProcessTasks();
    });
  }

  // === BORRADO MASIVO (Comités) ===
  Future<void> deleteAllTasksFromMeeting(String meetingId) async {
    final allTasks = await _repo.getAll();
    final tasksToDelete = allTasks
        .where((t) => t.meetingId == meetingId)
        .toList();

    for (final task in tasksToDelete) {
      await NotificationsService.instance.cancelReminder(task.id.hashCode);
      await _repo.remove(task.id);
    }

    state = AsyncValue.data(await _fetchAndProcessTasks());
  }

  // --- PRIVADOS ---

  Future<void> _scheduleNotification(Task task) async {
    if (task.dueDate == null || task.reminderMinutesBefore == null) return;

    final scheduledDate = task.dueDate!.subtract(
      Duration(minutes: task.reminderMinutesBefore!),
    );

    if (scheduledDate.isAfter(DateTime.now())) {
      await NotificationsService.instance.scheduleTaskReminder(
        id: task.id.hashCode,
        title: '📌 Tarea: ${task.title}',
        body: 'Vence pronto: ${_formatDateTime(task.dueDate!)}',
        scheduledAtLocal: scheduledDate,
      );
    }
  }

  String _formatDateTime(DateTime dt) =>
      "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
}
