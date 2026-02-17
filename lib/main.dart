import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/notifications/notifications_service.dart';
import 'features/tasks/application/task_providers.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final results = await Future.wait([
    SharedPreferences.getInstance(),
    NotificationsService.instance.init(),
  ]);

  final SharedPreferences prefs = results[0] as SharedPreferences;

  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Agently', // Cambiado a tu nuevo nombre
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed:
            Colors.blueAccent, // Color más acorde al logo tecnológico
        brightness: Brightness.light,
      ),
      routerConfig: router,
    );
  }
}
