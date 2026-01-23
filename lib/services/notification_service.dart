import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  /// ✅ Inizializza il servizio di notifiche - CON ERROR HANDLING ROBUSTO
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🔧 Inizio inizializzazione NotificationService...');

      // ✅ Inizializza timezone - CON TRY-CATCH
      try {
        tz_data.initializeTimeZones();
        print('✅ Timezone inizializzato');
      } catch (e) {
        print('⚠️ Errore timezone initialization: $e');
        // Continua comunque
      }

      // Configurazione Android
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      // Configurazione iOS - ⭐ I permessi sono già stati richiesti in main.dart
      const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      // Combinazione configurazioni
      const InitializationSettings initializationSettings =
      InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      // ✅ Inizializza il plugin - CON TRY-CATCH SEPARATO
      try {
        await _flutterLocalNotificationsPlugin.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse: _onNotificationTapped,
        );
        _isInitialized = true;
        print('✅ NotificationService completamente inizializzato');
      } catch (e) {
        print('⚠️ Errore nell\'inizializzazione plugin: $e');
        _isInitialized = false;
        // NON bloccare l'app se le notifiche falliscono
        return;
      }
    } catch (e) {
      print('❌ Errore critico NotificationService: $e');
      _isInitialized = false;
      // NON far mai crashare l'app in init
      return;
    }
  }

  /// ✅ Verifica se il servizio è pronto
  bool get isInitialized => _isInitialized;

  /// ✅ Verifica se possiamo inviare notifiche
  bool canSendNotifications() {
    return _isInitialized;
  }

  /// Callback quando l'utente tappa una notifica
  void _onNotificationTapped(NotificationResponse response) {
    try {
      print('📱 Notifica tappata: ${response.payload}');
    } catch (e) {
      print('❌ Errore in _onNotificationTapped: $e');
    }
  }

  /// ✅ Notifica cambio stage
  Future<void> notifyStageChange({
    required int stageNumber,
    required String stageType,
  }) async {
    if (!_isInitialized) {
      print('⚠️ NotificationService non inizializzato, skip notifyStageChange');
      return;
    }

    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'stage_change_channel',
        'Cambio Stage',
        channelDescription: 'Notifiche per il cambio di stage',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
      DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        1,
        '🎉 È il momento di cambiare stage!',
        'Congratulazioni! Passa a Stage $stageNumber-$stageType',
        platformChannelSpecifics,
        payload: 'stage_change_$stageNumber$stageType',
      );

      print('✅ Notifica cambio stage inviata: $stageNumber-$stageType');
    } catch (e) {
      print('❌ Errore nell\'invio notifica cambio stage: $e');
    }
  }

  /// ✅ Programma un promemoria giornaliero ricorrente
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (!_isInitialized) {
      print('⚠️ NotificationService non inizializzato, skip scheduleDailyReminder');
      return;
    }

    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'daily_reminder_channel',
        'Promemoria Giornaliero',
        channelDescription: 'Ricordati di indossare l\'allineatore',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
      DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        2,
        '🦷 Promemoria SmileLine',
        'Non dimenticare di indossare il tuo allineatore!',
        _nextInstanceOfTime(hour, minute),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      print(
          '✅ Promemoria giornaliero programmato per $hour:${minute.toString().padLeft(2, '0')}');
    } catch (e) {
      print('❌ Errore nella programmazione del promemoria giornaliero: $e');
    }
  }

  /// ✅ Programma un reminder per rimettere gli allineatori
  Future<void> scheduleReminder({
    required int minutesFromNow,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) {
      print('⚠️ NotificationService non inizializzato, skip scheduleReminder');
      return;
    }

    try {
      final now = tz.TZDateTime.now(tz.local);
      final scheduledDate = now.add(Duration(minutes: minutesFromNow));

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'reminder_channel',
        'Promemoria Allineatori',
        channelDescription: 'Promemoria per rimettere gli allineatori',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
      DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      // Schedula notifica
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        5,
        title,
        body,
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );

      print('✅ Reminder programmato tra $minutesFromNow minuti');
    } catch (e) {
      print('❌ Errore nella programmazione del reminder: $e');
    }
  }

  /// ✅ Invia notifica istantanea (quando timer app finisce)
  Future<void> sendInstantReminder({
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) {
      print('⚠️ NotificationService non inizializzato, skip sendInstantReminder');
      return;
    }

    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'reminder_channel',
        'Promemoria Allineatori',
        channelDescription: 'Promemoria per rimettere gli allineatori',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
      DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        5,
        title,
        body,
        platformChannelSpecifics,
      );

      print('✅ Notifica istantanea inviata: $title');
    } catch (e) {
      print('❌ Errore nell\'invio della notifica istantanea: $e');
    }
  }

  /// ✅ Notifica raggiungimento milestone
  Future<void> notifyMilestone({
    required int percentage,
    required String treatmentName,
  }) async {
    if (!_isInitialized) {
      print('⚠️ NotificationService non inizializzato, skip notifyMilestone');
      return;
    }

    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'milestone_channel',
        'Milestone',
        channelDescription: 'Notifiche per i traguardi raggiunti',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
      DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        3,
        '🏆 Milestone raggiunto!',
        'Hai completato il $percentage% del tuo trattamento!',
        platformChannelSpecifics,
        payload: 'milestone_$percentage',
      );

      print('✅ Notifica milestone inviata: $percentage%');
    } catch (e) {
      print('❌ Errore nell\'invio della notifica milestone: $e');
    }
  }

  /// ✅ Notifica quando non viene raggiunto l'obiettivo giornaliero
  Future<void> notifyLowCompliance({
    required int currentHours,
    required int targetHours,
  }) async {
    if (!_isInitialized) {
      print('⚠️ NotificationService non inizializzato, skip notifyLowCompliance');
      return;
    }

    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'compliance_channel',
        'Conformità',
        channelDescription: 'Avviso bassa conformità',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
      DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      final remainingHours = targetHours - currentHours;

      await _flutterLocalNotificationsPlugin.show(
        4,
        '⚠️ Ancora ore da raggiungere',
        'Ti mancano ancora $remainingHours ore oggi per raggiungere l\'obiettivo!',
        platformChannelSpecifics,
        payload: 'low_compliance',
      );

      print('✅ Notifica bassa conformità inviata');
    } catch (e) {
      print('❌ Errore nell\'invio della notifica conformità: $e');
    }
  }

  /// ✅ Invia una notifica generica
  Future<void> sendNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      print('⚠️ NotificationService non inizializzato, skip sendNotification');
      return;
    }

    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'generic_channel',
        'Notifiche Generali',
        channelDescription: 'Notifiche generali dell\'app',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
      DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      print('✅ Notifica inviata: $title');
    } catch (e) {
      print('❌ Errore nell\'invio della notifica: $e');
    }
  }

  /// ✅ MOSTRA NOTIFICA PERSISTENTE (per il timer in background)
  Future<void> showPersistentNotification({
    required String title,
    required String body,
    int progress = 0,
  }) async {
    if (!_isInitialized) {
      print('⚠️ NotificationService non inizializzato, skip showPersistentNotification');
      return;
    }

    try {
      final AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'smileline_timer_channel',
        'SmileLine Timer',
        channelDescription: 'Notifiche del timer in background',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        enableVibration: false,
        playSound: false,
        showProgress: true,
        maxProgress: 100,
        progress: progress,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
      DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: true,
        presentSound: false,
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        platformChannelSpecifics,
      );

      print('✅ Notifica persistente aggiornata: $title - Progress: $progress%');
    } catch (e) {
      print('❌ Errore nella notifica persistente: $e');
    }
  }

  /// ✅ Calcola il prossimo istante per l'ora specifica
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    try {
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // Se l'orario è già passato oggi, programma per domani
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      return scheduledDate;
    } catch (e) {
      print('❌ Errore in _nextInstanceOfTime: $e');
      return tz.TZDateTime.now(tz.local).add(const Duration(days: 1));
    }
  }

  /// ✅ Cancella tutte le notifiche programmate
  Future<void> cancelAll() async {
    if (!_isInitialized) {
      print('⚠️ NotificationService non inizializzato, skip cancelAll');
      return;
    }

    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      print('✅ Tutte le notifiche cancellate');
    } catch (e) {
      print('❌ Errore nella cancellazione delle notifiche: $e');
    }
  }

  /// ✅ Cancella una notifica specifica
  Future<void> cancelNotification(int id) async {
    if (!_isInitialized) {
      print('⚠️ NotificationService non inizializzato, skip cancelNotification');
      return;
    }

    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      print('✅ Notifica $id cancellata');
    } catch (e) {
      print('❌ Errore nella cancellazione della notifica: $e');
    }
  }

  @override
  String toString() => 'NotificationService(initialized: $_isInitialized)';
}