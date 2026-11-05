import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';

/// Gère des rappels hebdomadaires récurrents : une notification par
/// (routine, jour de la semaine sélectionné), qui se répète chaque semaine
/// à la même heure — même si l'application est fermée.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'skincare_reminders';
  static const _channelName = 'Rappels routine skincare';
  static const _channelDesc = 'Rappels programmés pour tes routines skincare';

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Fuseau par défaut si la détection échoue.
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(initSettings);

    try {
      await ph.Permission.notification.request();
    } catch (_) {
      // Ignoré : sur certaines versions d'Android, cette permission n'existe pas.
    }
    try {
      await ph.Permission.scheduleExactAlarm.request();
    } catch (_) {
      // Idem — selon l'OS/le plugin, peut ne pas s'appliquer.
    }

    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  /// Statut actuel de la permission notification (utilise permission_handler,
  /// plus fiable que le plugin de notifications pour connaître l'état réel).
  Future<ph.PermissionStatus> notificationPermissionStatus() async {
    try {
      return await ph.Permission.notification.status;
    } catch (_) {
      return ph.PermissionStatus.denied;
    }
  }

  /// Redemande la permission notification. Si Android a déjà définitivement
  /// refusé (l'utilisateur a coché "Ne plus demander" ou a refusé une
  /// première fois), cet appel ne réaffichera PAS de popup : il faut alors
  /// passer par [openAppSettings].
  Future<ph.PermissionStatus> requestNotificationPermission() async {
    try {
      return await ph.Permission.notification.request();
    } catch (_) {
      return ph.PermissionStatus.denied;
    }
  }

  /// Statut de la permission "alarmes exactes" (Android 12+).
  Future<ph.PermissionStatus> exactAlarmPermissionStatus() async {
    try {
      return await ph.Permission.scheduleExactAlarm.status;
    } catch (_) {
      return ph.PermissionStatus.denied;
    }
  }

  /// Demande la permission "alarmes exactes". Sur Android 12+, ceci ouvre
  /// directement l'écran système correspondant (comportement normal, ce
  /// n'est pas une popup in-app).
  Future<ph.PermissionStatus> requestExactAlarmPermission() async {
    try {
      return await ph.Permission.scheduleExactAlarm.request();
    } catch (_) {
      return ph.PermissionStatus.denied;
    }
  }

  /// Ouvre la page de réglages de l'application dans les paramètres système.
  /// C'est le seul moyen fiable d'activer une permission déjà refusée
  /// définitivement — aucun appel "request" ne rouvrira le popup dans ce cas.
  Future<bool> openAppSettings() async {
    try {
      return await ph.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  Future<List<PendingNotificationRequest>> pendingRequests() async {
    try {
      return await _plugin.pendingNotificationRequests();
    } catch (_) {
      return [];
    }
  }

  /// Identifiant stable par (routine, jour). weekday va de 1 (lundi) à 7 (dimanche).
  int _idFor(String routineId, int weekday) =>
      ((routineId.hashCode.abs() % 100000) * 10) + weekday;

  tz.TZDateTime _nextInstanceOfWeekdayTime(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// (Re)programme les rappels hebdomadaires d'une routine pour tous ses
  /// jours actifs. Annule d'abord les 7 créneaux possibles pour repartir propre.
  Future<void> scheduleRoutineReminders({
    required String routineId,
    required String routineName,
    required Set<int> days,
    required int hour,
    required int minute,
  }) async {
    await cancelRoutineReminders(routineId);
    for (final day in days) {
      final scheduled = _nextInstanceOfWeekdayTime(day, hour, minute);
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );
      try {
        await _plugin.zonedSchedule(
          _idFor(routineId, day),
          'Routine skincare ✨',
          'C\'est l\'heure de ta routine "$routineName"',
          scheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {
        // La permission "alarmes exactes" a probablement été refusée :
        // on retombe sur un mode approximatif plutôt que de ne rien programmer.
        await _plugin.zonedSchedule(
          _idFor(routineId, day),
          'Routine skincare ✨',
          'C\'est l\'heure de ta routine "$routineName"',
          scheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  /// Notification de test immédiate (dans 5 secondes).
  Future<void> scheduleTestNotification() async {
    final scheduled = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    try {
      await _plugin.zonedSchedule(
        999999,
        'Test skincare ✅',
        'Si tu vois ça, les notifications fonctionnent !',
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      await _plugin.zonedSchedule(
        999999,
        'Test skincare ✅',
        'Si tu vois ça, les notifications fonctionnent !',
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelRoutineReminders(String routineId) async {
    for (var day = 1; day <= 7; day++) {
      await _plugin.cancel(_idFor(routineId, day));
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
