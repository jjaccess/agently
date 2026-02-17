
import '../../domain/task.dart';
import '../../domain/task_status.dart';
import '../../domain/task_priority.dart';

/// Contrato del repositorio de tareas.
/// 
/// Permite implementar diferentes backends:
/// - SharedPreferences (local)
/// - SQLite
/// - API REST
/// - Firebase
/// - FakeRepository (tests)
/// 
abstract class TaskRepository {
  /// Obtiene todas las tareas almacenadas.
  Future<List<Task>> getAll();

  /// Guarda TODAS las tareas, sobrescribiendo la data previa.
  Future<void> saveAll(List<Task> tasks);

  /// Agrega una nueva tarea.
  Future<void> add(Task task);

  /// Actualiza una tarea existente.
  Future<void> update(Task task);

  /// Elimina una tarea por ID.
  Future<void> remove(String id);

  // ------------------------------
  // Métodos granulares opcionales
  // ------------------------------

  /// Cambia solo el estado de una tarea (open, done, etc.)
  Future<void> updateStatus(String id, TaskStatus status);

  /// Cambia solo la prioridad.
  Future<void> updatePriority(String id, TaskPriority priority);

  /// Cambia la categoría.
  Future<void> updateCategory(String id, String category);

  /// Asigna un responsable.
  Future<void> assignTo(String id, String? assignedTo);

  /// Modifica las etiquetas asociadas.
  Future<void> updateTags(String id, List<String> tags);

  /// Modifica archivos adjuntos.
  Future<void> updateAttachments(String id, List<String> attachments);

  /// Modifica fecha de vencimiento.
  Future<void> updateDueDate(String id, DateTime? date);

  /// Modifica tiempo estimado.
  Future<void> updateEstimatedMinutes(String id, int? minutes);
}
