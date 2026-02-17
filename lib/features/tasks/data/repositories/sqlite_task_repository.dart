import '../../domain/task.dart';
import '../../domain/task_status.dart';
import '../../domain/task_priority.dart';
import '../local/database_helper.dart';
import 'task_repository.dart';
import 'package:sqflite/sqflite.dart';

class SqliteTaskRepository implements TaskRepository {
  final _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<Task>> getAll() async {
    return await _dbHelper.getAllTasks();
  }

  @override
  Future<void> add(Task task) async {
    await _dbHelper.insertTask(task);
  }

  @override
  Future<void> update(Task task) async {
    await _dbHelper.insertTask(task);
  }

  @override
  Future<void> remove(String id) async {
    await _dbHelper.deleteTask(id);
  }

  // --- MÉTODOS GRANULARES OPTIMIZADOS ---
  // En lugar de bajar toda la lista, le pedimos a SQLite que cambie solo un campo.

  @override
  Future<void> updateStatus(String id, TaskStatus status) async {
    final db = await _dbHelper.database;
    await db.update(
      'tasks',
      {'status': status.name, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updateEstimatedMinutes(String id, int? minutes) async {
    final db = await _dbHelper.database;
    await db.update(
      'tasks',
      {'estimatedMinutes': minutes},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updateAttachments(String id, List<String> attachments) async {
    final db = await _dbHelper.database;
    await db.update(
      'tasks',
      {'evidencePaths': attachments.join(',')}, // Vinculamos a evidencePaths
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updatePriority(String id, TaskPriority priority) async {
    final db = await _dbHelper.database;
    await db.update(
      'tasks',
      {'priority': priority.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updateCategory(String id, String category) async {
    final db = await _dbHelper.database;
    await db.update(
      'tasks',
      {'category': category},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> assignTo(String id, String? assignedTo) async {
    final db = await _dbHelper.database;
    await db.update(
      'tasks',
      {'assignedTo': assignedTo},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updateDueDate(String id, DateTime? date) async {
    final db = await _dbHelper.database;
    await db.update(
      'tasks',
      {'dueDate': date?.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updateTags(String id, List<String> tags) async {
    final db = await _dbHelper.database;
    await db.update(
      'tasks',
      {'tags': tags.join(',')},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> saveAll(List<Task> tasks) async {
    final db = await _dbHelper.database;
    Batch batch = db.batch();
    for (var task in tasks) {
      batch.insert(
        'tasks',
        task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
