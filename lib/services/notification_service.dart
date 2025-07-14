import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();

  factory NotificationService() => _notificationService;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
  
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(settings);
  }

  Future<void> showNotification(int id, String title, String body) async {
    final details = _androidDetails(
      channelId: 'instant_channel',
      channelName: 'Notificações Imediatas',
      channelDescription: 'Alertas instantâneos do app',
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(android: details),
    );
  }

  Future<void> scheduleDailyNotification(
    int id,
    String title,
    String body,
    Time time,
  ) async {
    final details = _androidDetails(
      channelId: 'daily_channel',
      channelName: 'Lembretes Diários',
      channelDescription: 'Lembretes diários do app',
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(time),
      NotificationDetails(android: details),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> agendarNotificacoesParaHabito(
    String id,
    String nome,
    Map<String, bool> diasSelecionados,
  ) async {
    for (final entry in diasSelecionados.entries) {
      if (entry.value) {
        final int weekday = _diaSemanaParaNumero(entry.key);
        final notificationId = '$id-${entry.key}'.hashCode;

        await agendarNotificacaoSemanal(
          id: notificationId,
          titulo: 'Lembrete de Hábito',
          corpo: 'Hora de praticar: $nome',
          diaSemana: weekday,
          hora: const Time(8, 0),
        );
      }
    }
  }

  Future<void> agendarNotificacaoSemanal({
    required int id,
    required String titulo,
    required String corpo,
    required int diaSemana,
    required Time hora,
  }) async {
    final details = _androidDetails(
      channelId: 'weekly_channel',
      channelName: 'Lembretes Semanais',
      channelDescription: 'Lembretes semanais do app',
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      titulo,
      corpo,
      _nextInstanceOfWeekdayAndTime(diaSemana, hora),
      NotificationDetails(android: details),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> cancelarNotificacoesDoHabito(String habitoId) async {
    for (final dia in ['seg', 'ter', 'qua', 'qui', 'sex', 'sab', 'dom']) {
      final id = '$habitoId-$dia'.hashCode;
      await flutterLocalNotificationsPlugin.cancel(id);
    }
  }

  AndroidNotificationDetails _androidDetails({
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) {
    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(Time time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfWeekdayAndTime(int weekday, Time time) {
    var now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
      scheduled = tz.TZDateTime(
        tz.local,
        scheduled.year,
        scheduled.month,
        scheduled.day,
        time.hour,
        time.minute,
      );
    }
    return scheduled;
  }

  int _diaSemanaParaNumero(String dia) {
    const dias = {
      'seg': DateTime.monday,
      'ter': DateTime.tuesday,
      'qua': DateTime.wednesday,
      'qui': DateTime.thursday,
      'sex': DateTime.friday,
      'sab': DateTime.saturday,
      'dom': DateTime.sunday,
    };
    return dias[dia] ?? (throw ArgumentError('Dia inválido: $dia'));
  }
}
