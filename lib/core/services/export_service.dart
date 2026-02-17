import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../features/tasks/domain/task.dart';
import 'dart:convert';

class ExportService {
  static Future<void> exportTasksToCSV(List<Task> tasks) async {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('hh:mm a');

    List<List<dynamic>> rows = [];

    // Cabeceras
    rows.add([
      "Fecha Creación",
      "Fecha Vencimiento",
      "Hora",
      "Tarea",
      "Descripción",
      "Relación",
      "Categoría",
      "Responsable",
      "Estado",
      "Comentario de Cierre",
    ]);

    for (var task in tasks) {
      rows.add([
        dateFormat.format(task.createdAt),
        task.dueDate != null ? dateFormat.format(task.dueDate!) : 'Sin fecha',
        task.dueDate != null ? timeFormat.format(task.dueDate!) : 'N/A',
        task.title,
        task.description,
        task.meetingId != null ? "Comité: ${task.meetingId}" : "Independiente",
        task.category,
        task.assignedTo ?? 'Sin asignar',
        task.status.name.toUpperCase(),
        task.closingComment ?? '',
      ]);
    }

    // El convertidor de CSV maneja automáticamente las comas y comillas
    String csv = const ListToCsvConverter().convert(rows);

    final directory = await getTemporaryDirectory();
    final String fileName =
        "Reporte_Agently_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv";
    final path = "${directory.path}/$fileName";

    final file = File(path);
    // IMPORTANTE: Para que Excel reconozca tildes y eñes, usa encoding utf8 con BOM
    await file.writeAsBytes([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);

    await Share.shareXFiles(
      [XFile(path)],
      subject: 'Informe de Tareas',
      text: 'Adjunto envío el reporte de tareas generado desde Agently.',
    );
  }
}
