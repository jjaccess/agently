import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/backup_service.dart';
import '../../application/task_providers.dart';
import '../../application/meeting_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildSectionHeader(context, "Seguridad y Datos"),
          const SizedBox(height: 10),

          // --- TARJETA: CREAR COPIA DE SEGURIDAD ---
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: const Icon(
                  Icons.cloud_upload_rounded,
                  color: Colors.blue,
                ),
              ),
              title: const Text(
                "Crear copia de seguridad",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                "Exporta tus tareas y comités a un archivo para mantenerlos a salvo.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                final tasks = ref.read(taskControllerProvider).value ?? [];
                final meetings =
                    ref.read(meetingControllerProvider).value ?? [];

                BackupService.exportFullBackup(
                  tasks: tasks,
                  meetings: meetings,
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // --- TARJETA: RESTAURAR DATOS ---
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: Colors.orange.withOpacity(0.1),
                child: const Icon(
                  Icons.settings_backup_restore_rounded,
                  color: Colors.orange,
                ),
              ),
              title: const Text(
                "Restaurar datos",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                "Recupera tu información desde un archivo de respaldo anterior.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () async {
                final confirm = await _showConfirmDialog(context);

                if (confirm == true) {
                  final success = await BackupService.importFullBackup(ref);

                  if (context.mounted) {
                    _showSnackBar(context, success);
                  }
                }
              },
            ),
          ),

          const Divider(height: 40),
          _buildSectionHeader(context, "Acerca de"),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text("Versión de la aplicación"),
            trailing: Text(
              "1.0.0",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES PARA LIMPIAR EL CÓDIGO ---

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text("¿Restaurar datos?"),
          ],
        ),
        content: const Text(
          "Esta acción importará las tareas y comités del archivo seleccionado. Los datos se sumarán a los que ya tienes.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("SÍ, IMPORTAR"),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Text(
              success
                  ? "¡Restauración exitosa!"
                  : "Error al restaurar los datos",
            ),
          ],
        ),
        backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }
}
