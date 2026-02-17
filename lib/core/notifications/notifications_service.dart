import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationsService {
  NotificationsService._();
  static final instance = NotificationsService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();

    // 1. Configurar Zona Horaria de forma dinámica y limpia
    try {
      final dynamic locationData = await FlutterTimezone.getLocalTimezone();
      String timeZoneName = locationData.toString();

      // Limpieza: Si el sistema devuelve un objeto complejo, extraemos solo el ID (ej: America/Bogota)
      if (timeZoneName.contains('(')) {
        timeZoneName = timeZoneName.split('(').last.split(',').first.trim();
      }

      tz.setLocalLocation(tz.getLocation(timeZoneName));
      print("🌎 ZONA HORARIA CONFIGURADA: ${tz.local.name}");
    } catch (e) {
      print("⚠️ Error detectando zona, usando UTC por defecto: $e");
      tz.setLocalLocation(
        tz.UTC,
      ); // UTC es el estándar global si falla la detección
    }

    // 2. Configuración de inicialización
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOSInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iOSInit),
      onDidReceiveNotificationResponse: (details) {
        print("Notificación abierta con ID: ${details.id}");
      },
    );

    // 3. Configuración específica para Android (Canales de alta prioridad)
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // ID del canal
        'Alarmas de Tareas', // Nombre en ajustes del cel
        description: 'Canal para recordatorios urgentes de tareas.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      // Solicitar permisos de Android 13+
      await Permission.notification.request();
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    }

    _initialized = true;
  }

  Future<void> scheduleTaskReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAtLocal,
  }) async {
    if (!_initialized) await init();

    // Convertir la hora local a la zona horaria configurada
    final tzTime = tz.TZDateTime.from(scheduledAtLocal, tz.local);

    // Evitar programar en el pasado
    if (tzTime.isBefore(tz.TZDateTime.now(tz.local))) {
      print("❌ Error: Intentaste programar para una hora que ya pasó: $tzTime");
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      'high_importance_channel', // DEBE coincidir con el ID del canal en init()
      'Alarmas de Tareas',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBanner: true,
        interruptionLevel: InterruptionLevel.critical,
      ),
    );

    print("--- 🔬 DIAGNÓSTICO DE TIEMPO ---");
    print("1. Recibido (DateTime): $scheduledAtLocal");
    print("2. Detectado como Local: ${scheduledAtLocal.toLocal()}");
    print("3. Convertido a TZ (Programado): $tzTime");
    print("4. Zona actual del servicio: ${tz.local.name}");
    print("-------------------------------");

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: id.toString(),
      );
      print(
        "🔔 Alarma programada con éxito para: $tzTime (Zona: ${tz.local.name})",
      );
    } catch (e) {
      print("❌ Error al programar: $e");
    }
  }

  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
    print("🗑️ Recordatorio $id eliminado.");
  }
}
