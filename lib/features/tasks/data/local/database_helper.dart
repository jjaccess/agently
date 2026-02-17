import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../domain/task.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // ESTA LÍNEA TE DARÁ LA RUTA EXACTA EN TU CONSOLA
    print('-----------------------------------------');
    print('UBICACIÓN DE LA BASE DE DATOS: $path');
    print('-----------------------------------------');

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // 1. Habilitar llaves foráneas (OBLIGATORIO para el CASCADE)
    await db.execute('PRAGMA foreign_keys = ON');

    // 2. Tabla de Comités (Meetings)
    await db.execute('''
    CREATE TABLE meetings (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT,
      date TEXT,                -- Fecha de la reunión
      createdAt TEXT
    )
  ''');

    // 3. Tabla de Tareas (Tasks)
    await db.execute('''
CREATE TABLE tasks (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT,
      status TEXT,
      priority TEXT,
      category TEXT,
      assignedTo TEXT,
      tags TEXT,                -- Se guarda como String separado por comas
      attachments TEXT,         -- Se guarda como String separado por comas
      estimatedMinutes INTEGER,
      createdAt TEXT,           -- ISO8601 String
      updatedAt TEXT,           -- ISO8601 String
      dueDate TEXT,             -- ISO8601 String
      reminderMinutesBefore INTEGER,
      meetingId TEXT,           -- Vínculo con el Comité
      closingComment TEXT,      -- Informe de cierre
      evidencePaths TEXT,        -- Rutas de fotos separadas por comas
      FOREIGN KEY (meetingId) REFERENCES meetings (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- Operaciones CRUD ---

  Future<void> insertTask(Task task) async {
    final db = await instance.database;
    await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Task>> getAllTasks() async {
    final db = await instance.database;
    final result = await db.query('tasks');
    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<void> deleteTask(String id) async {
    final db = await instance.database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}
