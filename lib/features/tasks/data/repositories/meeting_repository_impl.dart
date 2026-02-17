import 'package:sqflite/sqflite.dart';
import '../../domain/meeting.dart';
import '../local/database_helper.dart';
import 'meeting_repository.dart';

class SqliteMeetingRepository implements MeetingRepository {
  final _db = DatabaseHelper.instance;

  @override
  Future<List<Meeting>> getMeetings() async {
    final db = await _db.database;
    // Consultamos la tabla 'meetings'
    final List<Map<String, dynamic>> maps = await db.query(
      'meetings',
      orderBy: 'date DESC',
    );

    return maps.map((map) => Meeting.fromMap(map)).toList();
  }

  @override
  Future<void> saveMeeting(Meeting meeting) async {
    final db = await _db.database;
    await db.insert(
      'meetings',
      meeting.toMap(),
      // Si por alguna razón el ID ya existe, lo reemplaza
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateMeeting(Meeting meeting) async {
    final db = await _db.database;
    await db.update(
      'meetings',
      meeting.toMap(),
      where: 'id = ?',
      whereArgs: [meeting.id],
    );
  }

  @override
  Future<void> deleteMeeting(String id) async {
    final db = await _db.database;
    // Gracias al ON DELETE CASCADE que pusimos en el DatabaseHelper,
    // al borrar el comité aquí, SQLite borrará solo las tareas vinculadas.
    await db.delete('meetings', where: 'id = ?', whereArgs: [id]);
  }
}
