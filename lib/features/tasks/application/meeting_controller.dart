import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/meeting.dart';
import '../data/repositories/meeting_repository.dart';
import 'task_providers.dart'; // Asegúrate de tener aquí el meetingRepositoryProvider y taskControllerProvider

class MeetingController extends AsyncNotifier<List<Meeting>> {
  late MeetingRepository _repo;
  final _uuid = const Uuid();

  @override
  Future<List<Meeting>> build() async {
    // 1. Inicializamos el repositorio
    _repo = ref.read(meetingRepositoryProvider);
    // 2. Cargamos y ordenamos (el build de AsyncNotifier ya maneja el estado de carga)
    return _fetchAndProcessMeetings();
  }

  /// Método privado para centralizar la carga y el ordenamiento
  Future<List<Meeting>> _fetchAndProcessMeetings() async {
    final meetings = await _repo.getMeetings();
    // Ordenar: Las reuniones más recientes primero
    meetings.sort((a, b) => b.date.compareTo(a.date));
    return meetings;
  }

  Future<void> addMeeting({
    String? id,
    required String name,
    required DateTime date,
    String description = '',
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final newMeeting = Meeting(
        id: id ?? _uuid.v4(),
        name: name,
        date: date,
        description: description,
      );

      await _repo.saveMeeting(newMeeting);
      return _fetchAndProcessMeetings();
    });
  }

  Future<void> deleteMeeting(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // 1. ELIMINACIÓN EN CASCADA
      // Llamamos al controlador de tareas para limpiar notificaciones y datos
      await ref
          .read(taskControllerProvider.notifier)
          .deleteAllTasksFromMeeting(id);

      // 2. Borrar el comité de la base de datos
      await _repo.deleteMeeting(id);

      // 3. Refrescar la lista
      return _fetchAndProcessMeetings();
    });
  }

  // Bonus: Método para actualizar (útil si quieres editar el nombre del comité)
  Future<void> updateMeeting(Meeting updatedMeeting) async {
    state = await AsyncValue.guard(() async {
      await _repo.updateMeeting(updatedMeeting);
      return _fetchAndProcessMeetings();
    });
  }
}

// DEFINICIÓN DEL PROVIDER
final meetingControllerProvider =
    AsyncNotifierProvider<MeetingController, List<Meeting>>(() {
      return MeetingController();
    });
