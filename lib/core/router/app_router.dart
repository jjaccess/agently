import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/tasks/presentation/screens/meeting_list_screen.dart';
import '../../features/tasks/presentation/screens/tasks_list_screen.dart';
import '../../features/tasks/presentation/screens/task_form_screen.dart';
import '../../features/tasks/presentation/screens/task_detail_screen.dart';
import '../../features/tasks/presentation/screens/meeting_detail_screen.dart';
import '../../features/tasks/presentation/screens/settings_screen.dart';

enum AppRoute { meetings, tasks, taskNew, taskDetail }

// AGREGAR ESTE PROVIDER:
final appRouterProvider = Provider<GoRouter>((ref) {
  return createRouter();
});

GoRouter createRouter() {
  return GoRouter(
    // 2. CAMBIA ESTO: Ahora inicia en /meetings
    initialLocation: '/meetings',
    debugLogDiagnostics: true,
    routes: [
      // 3. AGREGA LA RUTA DE COMITÉS
      GoRoute(
        path: '/meetings',
        name: AppRoute.meetings.name,
        builder: (context, state) => const MeetingListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return MeetingDetailScreen(meetingId: id);
            },
          ),
        ],
      ),

      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      // Tus rutas de tareas se mantienen igual
      GoRoute(
        path: '/tasks',
        name: AppRoute.tasks.name,
        builder: (context, state) => const TasksListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            name: AppRoute.taskNew.name,
            builder: (context, state) {
              // Captura el meetingId de la URL (ej: /tasks/new?meetingId=123)
              final meetingId = state.uri.queryParameters['meetingId'];
              return TaskFormScreen(meetingId: meetingId);
            },
          ),
          GoRoute(
            path: ':id',
            name: AppRoute.taskDetail.name,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TaskDetailScreen(id: id);
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          "Error de navegación: ${state.error}",
          style: const TextStyle(color: Colors.red),
        ),
      ),
    ),
  );
}
