import '../../../domain/task.dart';
import '../../../domain/task_status.dart';
import '../../../domain/task_priority.dart';
import '../task_repository.dart';

class TaskRepositoryFake implements TaskRepository {
  // Lista en memoria que simula la base de datos
  final List<Task> _items = [];

  @override
  Future<List<Task>> getAll() async {
    // Retornamos una copia para evitar modificaciones accidentales desde fuera
    return List.unmodifiable(_items);
  }

  @override
  Future<void> saveAll(List<Task> tasks) async {
    _items.clear();
    _items.addAll(tasks);
  }

  @override
  Future<void> add(Task task) async {
    _items.add(task);
  }

  @override
  Future<void> update(Task updated) async {
    final index = _items.indexWhere((t) => t.id == updated.id);
    if (index != -1) {
      _items[index] = updated;
    }
  }

  @override
  Future<void> remove(String id) async {
    _items.removeWhere((t) => t.id == id);
  }

  // ---------------------------------------------------------
  // Métodos granulares (Implementación de la interfaz)
  // ---------------------------------------------------------

  /// Helper privado para editar campos sin repetir código
  void _edit(String id, Task Function(Task old) transform) {
    final index = _items.indexWhere((t) => t.id == id);
    if (index != -1) {
      _items[index] = transform(_items[index]);
    }
  }

  @override
  Future<void> updateStatus(String id, TaskStatus status) async =>
      _edit(id, (old) => old.copyWith(status: status));

  @override
  Future<void> updatePriority(String id, TaskPriority priority) async =>
      _edit(id, (old) => old.copyWith(priority: priority));

  @override
  Future<void> updateCategory(String id, String category) async =>
      _edit(id, (old) => old.copyWith(category: category));

  @override
  Future<void> assignTo(String id, String? assignedTo) async =>
      _edit(id, (old) => old.copyWith(assignedTo: assignedTo));

  @override
  Future<void> updateDueDate(String id, DateTime? date) async =>
      _edit(id, (old) => old.copyWith(dueDate: date));

  @override
  Future<void> updateEstimatedMinutes(String id, int? minutes) async =>
      _edit(id, (old) => old.copyWith(estimatedMinutes: minutes));

  @override
  Future<void> updateTags(String id, List<String> tags) async =>
      _edit(id, (old) => old.copyWith(tags: tags));

  @override
  Future<void> updateAttachments(String id, List<String> attachments) async =>
      _edit(id, (old) => old.copyWith(attachments: attachments));
}