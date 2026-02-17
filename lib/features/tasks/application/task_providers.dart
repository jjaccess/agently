import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/repositories/task_repository.dart';
import '../domain/task.dart';
import 'task_controller.dart';
import '../data/repositories/meeting_repository.dart';
import '../data/repositories/sqlite_task_repository.dart';
import '../data/repositories/meeting_repository_impl.dart';

/// 1. Proveedor de SharedPreferences
/// Lo cambiamos a un Provider síncrono porque el valor se inyecta desde el main.
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'Debe ser inicializado mediante un override en el main.dart',
  );
});

/// 2. Repositorio de Tareas
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return SqliteTaskRepository(); // <--- Aquí inyectamos la persistencia real
});

/// 3. Controlador de Tareas (AsyncNotifier)
/// Usamos la sintaxis moderna para Riverpod 3.x
final taskControllerProvider =
    AsyncNotifierProvider<TaskController, List<Task>>(TaskController.new);

final meetingRepositoryProvider = Provider<MeetingRepository>((ref) {
  return SqliteMeetingRepository();
});

final tasksByMeetingProvider = Provider.family<List<Task>, String>((
  ref,
  meetingId,
) {
  final allTasks = ref.watch(taskControllerProvider).value ?? [];
  return allTasks.where((task) => task.meetingId == meetingId).toList();
});
