import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/task_status.dart';
import '../../application/task_filters.dart';
import '../../application/task_providers.dart';
import '../widgets/task_item.dart';

class TasksListScreen extends ConsumerWidget {
  const TasksListScreen({super.key});

  // Lista de tus categorías
  static const categories = [
    'General',
    'Infraestructura',
    'Seguridad',
    'Desarrollo',
    'Soporte',
    'Plataforma',
    'Telecomunicaciones',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskControllerProvider);
    final filteredTasks = ref.watch(filteredTasksProvider);
    final filters = ref.watch(taskFiltersProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis Tareas',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: false,
        scrolledUnderElevation: 4,
      ),
      body: Column(
        children: [
          // 1. BARRA DE BÚSQUEDA
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              hintText: 'Buscar por título...',
              leading: const Icon(Icons.search),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(
                colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) {
                ref
                    .read(taskFiltersProvider.notifier)
                    .update((state) => state.copyWith(query: value));
              },
            ),
          ),

          // 2. FILTROS DE ESTADO (Fila 1)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todos los Estados'),
                  selected: filters.status == null,
                  onSelected: (_) {
                    ref
                        .read(taskFiltersProvider.notifier)
                        .update((state) => state.copyWith(clearStatus: true));
                  },
                ),
                const SizedBox(width: 8),
                ...TaskStatus.values.map((status) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(status.label),
                      selected: filters.status == status,
                      onSelected: (selected) {
                        ref
                            .read(taskFiltersProvider.notifier)
                            .update(
                              (state) => state.copyWith(
                                status: status,
                                clearStatus: !selected,
                              ),
                            );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          // 3. FILTROS DE CATEGORÍA (Fila 2 - NUEVO)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todas las Categorías'),
                  selected: filters.category == null,
                  selectedColor: colorScheme.primaryContainer,
                  onSelected: (_) {
                    ref
                        .read(taskFiltersProvider.notifier)
                        .update((state) => state.copyWith(clearCategory: true));
                  },
                ),
                const SizedBox(width: 8),
                ...categories.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat),
                      selected: filters.category == cat,
                      onSelected: (selected) {
                        ref
                            .read(taskFiltersProvider.notifier)
                            .update(
                              (state) => state.copyWith(
                                category: cat,
                                clearCategory: !selected,
                              ),
                            );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 0.5),

          // 4. LISTA DE TAREAS
          Expanded(
            child: tasksAsync.when(
              data: (_) {
                if (filteredTasks.isEmpty) {
                  return _buildEmptyState(context, filters.query.isNotEmpty);
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    // TaskItem ya debe tener la lógica del cuadro rojo por dentro
                    return TaskItem(task: filteredTasks[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/tasks/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Tarea'),
        elevation: 3,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isSearching) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.task_alt,
            size: 80,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching
                ? 'No encontramos coincidencias'
                : '¡Todo listo por hoy!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class TaskSourceBadge extends StatelessWidget {
  final String? meetingId;

  const TaskSourceBadge({super.key, this.meetingId});

  @override
  Widget build(BuildContext context) {
    final bool isFromMeeting = meetingId != null && meetingId!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        // Azul para comités (formal), Gris para independientes (operativo)
        color: isFromMeeting
            ? Colors.blue.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isFromMeeting ? Colors.blue.shade300 : Colors.grey.shade400,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFromMeeting ? Icons.groups_rounded : Icons.person_outline_rounded,
            size: 12,
            color: isFromMeeting ? Colors.blue.shade700 : Colors.grey.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            isFromMeeting ? "COMITÉ" : "INDEPENDIENTE",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isFromMeeting
                  ? Colors.blue.shade700
                  : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
