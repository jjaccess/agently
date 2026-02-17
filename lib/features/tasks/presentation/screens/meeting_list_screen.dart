import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/meeting_controller.dart';
import '../../application/task_providers.dart';
import '../../domain/task_status.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'dart:convert';

final hideCompletedFilterProvider =
    NotifierProvider<HideCompletedNotifier, bool>(() {
      return HideCompletedNotifier();
    });

class HideCompletedNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
}

class MeetingListScreen extends ConsumerWidget {
  const MeetingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingsAsync = ref.watch(meetingControllerProvider);
    final allTasksAsync = ref.watch(taskControllerProvider);
    final hideCompleted = ref.watch(hideCompletedFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comités y Reuniones'),
        actions: [
          // BOTÓN DE FILTRO
          IconButton(
            icon: Icon(
              hideCompleted ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: hideCompleted ? Colors.orange : null,
            ),
            onPressed: () {
              // Llamas al método que creaste, no al .state directamente
              ref.read(hideCompletedFilterProvider.notifier).toggle();
            },
          ),
          IconButton(
            icon: const Icon(Icons.assignment_outlined),
            onPressed: () => context.push('/tasks'),
            tooltip: 'Ver todas las tareas',
          ),
        ],
      ),

      drawer: _buildDrawer(context, ref),

      body: meetingsAsync.when(
        data: (meetings) {
          final allTasks = allTasksAsync.value ?? [];

          // 1. PROCESAMIENTO Y ORDENAMIENTO
          var displayedMeetings = List.of(meetings).map((m) {
            final tasks = allTasks.where((t) => t.meetingId == m.id);
            final pendingCount = tasks
                .where(
                  (t) =>
                      t.status == TaskStatus.open ||
                      t.status == TaskStatus.inProgress ||
                      t.status == TaskStatus.onHold,
                )
                .length;

            return _MeetingWithStats(m, pendingCount, tasks.toList());
          }).toList();

          // 2. APLICAR FILTRO (Si está activo, quitar los que tienen 0 pendientes)
          if (hideCompleted) {
            displayedMeetings = displayedMeetings
                .where((m) => m.pendingCount > 0)
                .toList();
          }

          // 3. ORDENAR: Más pendientes arriba, luego por fecha
          displayedMeetings.sort((a, b) {
            if (b.pendingCount != a.pendingCount) {
              return b.pendingCount.compareTo(a.pendingCount);
            }
            return b.meeting.date.compareTo(a.meeting.date);
          });

          if (displayedMeetings.isEmpty) {
            return _EmptyMeetingsView(isFiltered: hideCompleted);
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80, top: 8),
            itemCount: displayedMeetings.length,
            itemBuilder: (context, index) {
              final item = displayedMeetings[index];
              final meeting = item.meeting;
              final meetingTasks = item.tasks;

              final numAbiertas = meetingTasks
                  .where((t) => t.status == TaskStatus.open)
                  .length;
              final numProceso = meetingTasks
                  .where((t) => t.status == TaskStatus.inProgress)
                  .length;
              final numEspera = meetingTasks
                  .where((t) => t.status == TaskStatus.onHold)
                  .length;

              final bool hasAlert = item.pendingCount > 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: hasAlert ? 2 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(
                    color: hasAlert
                        ? Colors.blue.shade200
                        : Colors.grey.shade200,
                    width: hasAlert ? 1.5 : 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: hasAlert
                        ? Colors.blue.shade50
                        : Colors.grey.shade100,
                    child: Icon(
                      Icons.groups,
                      color: hasAlert ? Colors.blue : Colors.grey,
                    ),
                  ),
                  title: Text(
                    meeting.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: hasAlert ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        meeting.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildMiniBadge(numAbiertas, Colors.blue),
                          const SizedBox(width: 8),
                          _buildMiniBadge(numProceso, Colors.orange),
                          const SizedBox(width: 8),
                          _buildMiniBadge(numEspera, Colors.grey),
                          const Spacer(),
                          Text(
                            "${meeting.date.day}/${meeting.date.month}/${meeting.date.year}",
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey,
                  ),
                  onTap: () => context.push('/meetings/${meeting.id}'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMeetingDialog(context, ref),
        label: const Text('Nuevo Comité'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  // --- COMPONENTES AUXILIARES ---

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    // Añade ref aquí
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(),
          ListTile(
            leading: const Icon(Icons.groups_rounded, color: Colors.blue),
            title: const Text('Comités'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.task_alt_rounded, color: Colors.blue),
            title: const Text('Todas las Tareas'),
            onTap: () {
              Navigator.pop(context);
              context.push('/tasks');
            },
          ),
          // --- NUEVA OPCIÓN DE REPORTE ---
          ListTile(
            leading: const Icon(Icons.analytics_outlined, color: Colors.green),
            title: const Text('Reporte de Gestión'),
            subtitle: const Text('Exportar tareas a CSV'),
            onTap: () {
              Navigator.pop(context);
              _exportTasksReport(context, ref);
            },
          ),
          // ------------------------------
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.settings_suggest_rounded,
              color: Colors.blueGrey,
            ),
            title: const Text('Configuración y Backup'),
            onTap: () {
              Navigator.pop(context);
              context.push('/settings');
            },
          ),
          const Spacer(),
          // ... resto del código
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return const DrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rocket_launch, size: 40, color: Colors.white),
            SizedBox(height: 10),
            Text(
              'AGENTLY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color.darken(),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMeetingDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Nuevo Comité'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty) {
                ref
                    .read(meetingControllerProvider.notifier)
                    .addMeeting(
                      name: titleCtrl.text,
                      date: DateTime.now(),
                      description: descCtrl.text,
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }
}

// Clase de apoyo para el ordenamiento
class _MeetingWithStats {
  final dynamic meeting;
  final int pendingCount;
  final List<dynamic> tasks;
  _MeetingWithStats(this.meeting, this.pendingCount, this.tasks);
}

class _EmptyMeetingsView extends StatelessWidget {
  final bool isFiltered;
  const _EmptyMeetingsView({required this.isFiltered});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Icons.check_circle_outline : Icons.groups_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered
                ? '¡Todo al día! No hay pendientes.'
                : 'No hay comités registrados',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

extension on Color {
  Color darken([double amount = .3]) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}

Future<void> _exportTasksReport(BuildContext context, WidgetRef ref) async {
  // 1. Selección del rango de fechas
  final DateTimeRange? pickedRange = await showDateRangePicker(
    context: context,
    initialDateRange: DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    ),
    firstDate: DateTime(2024),
    lastDate: DateTime(2030),
    helpText: 'Selecciona el periodo del reporte',
    confirmText: 'GENERAR',
    saveText: 'OK',
  );

  if (pickedRange == null) return;

  // 2. Obtener datos de los providers
  final tasks = ref.read(taskControllerProvider).value ?? [];
  final meetings = ref.read(meetingControllerProvider).value ?? [];

  // 3. Filtrar tareas por el rango de fecha de creación
  final filteredTasks = tasks.where((t) {
    final date = t.createdAt;
    return date.isAfter(pickedRange.start) &&
        date.isBefore(pickedRange.end.add(const Duration(days: 1)));
  }).toList();

  if (filteredTasks.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay tareas en el rango seleccionado')),
      );
    }
    return;
  }

  // 4. Construcción del contenido CSV
  // Encabezados
  String csvData =
      'Fecha Creación,Hora,Comité,Tarea,Descripción,Estado,Prioridad,Responsable,Comentario Cierre,Última Actualización\n';

  for (var t in filteredTasks) {
    // Buscar el nombre del comité relacionado
    final meeting = meetings.firstWhereOrNull((m) => m.id == t.meetingId);
    final meetingName = meeting?.name ?? 'Sin Comité';

    // Formatear fechas y horas
    final dateStr = DateFormat('dd/MM/yyyy').format(t.createdAt);
    final hourStr = DateFormat('HH:mm').format(t.createdAt);
    final updateStr = DateFormat('dd/MM/yyyy HH:mm').format(t.updatedAt);

    // Limpiar textos (quitar saltos de línea y comas que rompen el CSV)
    final cleanDesc = t.description.replaceAll('\n', ' ').replaceAll(',', ';');
    final cleanTitle = t.title.replaceAll('\n', ' ').replaceAll(',', ';');
    final cleanComment = (t.closingComment ?? '')
        .replaceAll('\n', ' ')
        .replaceAll(',', ';');

    // Agregar fila
    csvData +=
        '$dateStr,'
        '$hourStr,'
        '"$meetingName",'
        '"$cleanTitle",'
        '"$cleanDesc",'
        '"${t.status.name}",'
        '"${t.priority.name}",'
        '"${t.assignedTo ?? ''}",'
        '"$cleanComment",'
        '$updateStr\n';
  }

  // 5. Guardar y Compartir con soporte para Tildes/Ñ (BOM)
  try {
    final directory = await getTemporaryDirectory();
    final String fileName =
        'Reporte_Agently_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
    final File file = File('${directory.path}/$fileName');

    // Firma BOM para que Excel reconozca UTF-8 (Tildes y Ñ)
    final List<int> bom = [0xEF, 0xBB, 0xBF];
    final List<int> csvBytes = utf8.encode(csvData);

    // Escribir bytes combinados
    await file.writeAsBytes(bom + csvBytes);

    // Abrir el menú de compartir del celular
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Adjunto el reporte de gestión generado desde Agently.');
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
    }
  }
}
