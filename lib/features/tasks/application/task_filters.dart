import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'task_providers.dart';
import '../domain/task.dart';
import '../domain/task_status.dart';
import '../domain/task_priority.dart';

/// 1. Modelo de filtros extendido con Categoría
class TaskFilters {
  final String query;
  final TaskStatus? status;
  final TaskPriority? priority;
  final String? category; // Añadido

  const TaskFilters({
    this.query = '',
    this.status,
    this.priority,
    this.category,
  });

  TaskFilters copyWith({
    String? query,
    TaskStatus? status,
    TaskPriority? priority,
    String? category,
    bool clearStatus = false,
    bool clearCategory = false, // Útil para resetear filtros
  }) {
    return TaskFilters(
      query: query ?? this.query,
      status: clearStatus ? null : (status ?? this.status),
      priority: priority ?? this.priority,
      category: clearCategory ? null : (category ?? this.category),
    );
  }
}

/// 2. El Notifier de Filtros
class TaskFiltersNotifier extends Notifier<TaskFilters> {
  @override
  TaskFilters build() => const TaskFilters();

  void update(TaskFilters Function(TaskFilters state) callback) {
    state = callback(state);
  }
  void setQuery(String q) => state = state.copyWith(query: q);
  void setStatus(TaskStatus? s) => state = state.copyWith(status: s, clearStatus: s == null);
  void setCategory(String? c) => state = state.copyWith(category: c, clearCategory: c == null);
  
  void reset() => state = const TaskFilters();
}

final taskFiltersProvider = NotifierProvider<TaskFiltersNotifier, TaskFilters>(() {
  return TaskFiltersNotifier();
});

/// 3. El Provider de lista filtrada (Compatible con Riverpod v3)
final filteredTasksProvider = Provider<List<Task>>((ref) {
  final tasksAsync = ref.watch(taskControllerProvider);
  final filters = ref.watch(taskFiltersProvider);
  
  // Obtenemos la lista base (que ya viene ordenada por el Controller)
  final List<Task> tasks = tasksAsync.value ?? [];

  return tasks.where((t) {
    // A. Filtro por búsqueda
    final q = filters.query.toLowerCase().trim();
    final matchesQuery = q.isEmpty || 
                         t.title.toLowerCase().contains(q) || 
                         t.description.toLowerCase().contains(q);
    
    // B. Filtro por Estado
    final matchesStatus = filters.status == null || t.status == filters.status;

    // C. Filtro por Categoría (NUEVO)
    final matchesCategory = filters.category == null || 
                            filters.category == 'Todas' || 
                            t.category == filters.category;

    return matchesQuery && matchesStatus && matchesCategory;
  }).toList();
});