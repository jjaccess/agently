import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/task.dart';
import '../../domain/task_status.dart';
import '../../domain/task_priority.dart';
import 'task_repository.dart';

class TaskRepositoryPrefs implements TaskRepository {
  final SharedPreferences _prefs;
  static const _key = 'tasks_data';

  TaskRepositoryPrefs(this._prefs);

  @override
  Future<List<Task>> getAll() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((item) => Task.fromJson(item)).toList();
    } catch (_) {
      return []; // Si el JSON está corrupto, devolvemos lista vacía
    }
  }

  Future<void> _saveToDisk(List<Task> tasks) async {
    final raw = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await _prefs.setString(_key, raw);
  }

  @override
  Future<void> add(Task task) async {
    final tasks = await getAll();
    tasks.add(task);
    await _saveToDisk(tasks);
  }

  @override
  Future<void> remove(String id) async {
    final tasks = await getAll();
    tasks.removeWhere((t) => t.id == id);
    await _saveToDisk(tasks);
  }

  // Helper para no repetir código en actualizaciones granulares
  Future<void> _updateField(String id, Task Function(Task task) transform) async {
    final tasks = await getAll();
    final index = tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      tasks[index] = transform(tasks[index]).copyWith(updatedAt: DateTime.now());
      await _saveToDisk(tasks);
    }
  }

  @override
  Future<void> updateStatus(String id, TaskStatus status) async => 
    _updateField(id, (t) => t.copyWith(status: status));

  @override
  Future<void> updatePriority(String id, TaskPriority priority) async => 
    _updateField(id, (t) => t.copyWith(priority: priority));

  @override
  Future<void> updateCategory(String id, String category) async => 
    _updateField(id, (t) => t.copyWith(category: category));

  @override
  Future<void> assignTo(String id, String? assignedTo) async => 
    _updateField(id, (t) => t.copyWith(assignedTo: assignedTo));

  @override
  Future<void> updateDueDate(String id, DateTime? date) async => 
    _updateField(id, (t) => t.copyWith(dueDate: date));

  // Métodos requeridos por la interfaz pero menos usados
  @override Future<void> saveAll(List<Task> tasks) async => _saveToDisk(tasks);
  @override Future<void> update(Task updated) async => _updateField(updated.id, (t) => updated);
  @override Future<void> updateTags(String id, List<String> tags) async {}
  @override Future<void> updateAttachments(String id, List<String> att) async {}
  @override Future<void> updateEstimatedMinutes(String id, int? min) async {}
}