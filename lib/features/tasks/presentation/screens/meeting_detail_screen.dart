import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/meeting_controller.dart';
import '../../application/task_providers.dart';
import '../../domain/task_status.dart'; // Asegúrate de importar tus Enums
import '../widgets/task_item.dart';

class MeetingDetailScreen extends ConsumerWidget {
  final String meetingId;
  const MeetingDetailScreen({super.key, required this.meetingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingsAsync = ref.watch(meetingControllerProvider);
    final tasks = ref.watch(tasksByMeetingProvider(meetingId));

    return meetingsAsync.when(
      data: (meetings) {
        final meeting = meetings.where((m) => m.id == meetingId).firstOrNull;

        if (meeting == null) {
          return const Scaffold(body: Center(child: Text("Cerrando...")));
        }

        // --- LÓGICA DE CONTADORES ---
        final abiertas = tasks.where((t) => t.status == TaskStatus.open).length;
        final enProceso = tasks
            .where((t) => t.status == TaskStatus.inProgress)
            .length;
        final enEspera = tasks
            .where((t) => t.status == TaskStatus.onHold)
            .length;

        return Scaffold(
          appBar: AppBar(
            title: Text(meeting.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('¿Eliminar comité?'),
                      content: const Text(
                        'Se eliminará el comité y todas sus tareas asociadas permanentemente.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('CANCELAR'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('SÍ, ELIMINAR'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    context.pop(); // Volver a la lista antes de borrar
                    await ref
                        .read(meetingControllerProvider.notifier)
                        .deleteMeeting(meetingId);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Comité y tareas eliminados'),
                          backgroundColor: Colors.black87,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Cabecera con descripción
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Acta / Descripción:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(meeting.description),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. FILA DE CONTADORES
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _buildStatCard("Abiertas", abiertas, Colors.blue),
                    _buildStatCard("En Proceso", enProceso, Colors.orange),
                    _buildStatCard("En Espera", enEspera, Colors.grey),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  "Tareas del Comité",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              // 3. Lista de tareas filtradas
              Expanded(
                child: tasks.isEmpty
                    ? const Center(
                        child: Text("No hay tareas para este comité"),
                      )
                    : ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) =>
                            TaskItem(task: tasks[index]),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/tasks/new?meetingId=$meetingId'),
            label: const Text("Nueva Tarea"),
            icon: const Icon(Icons.add_task),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text("Error: $e"))),
    );
  }

  // WIDGET AUXILIAR PARA LOS CONTADORES
  Widget _buildStatCard(String label, int count, Color color) {
    return Expanded(
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
