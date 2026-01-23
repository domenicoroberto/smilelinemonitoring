import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import 'background_timer_service.dart';
import 'midnight_service.dart';
import 'notification_service.dart';

/// ✅ Callback dispatcher per il background task
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      print('📡 [$taskName] Task eseguito in background');

      final prefs = await SharedPreferences.getInstance();
      final bgTimer = BackgroundTimerService();
      await bgTimer.initialize();

      final notificationService = NotificationService();
      await notificationService.initialize();

      // ✅ CONTROLLA SE È CAMBIATO IL GIORNO
      final dayChanged = await bgTimer.checkDayChanged();
      if (dayChanged) {
        print('🌙 CAMBIO GIORNO RILEVATO IN BACKGROUND!');

        try {
          final midnightService = MidnightService();
          await midnightService.initialize();
          await midnightService.executeMidnightOperations();
          print('✅ Operazioni di mezzanotte completate in background');
          return true;
        } catch (e) {
          print('❌ Errore operazioni mezzanotte: $e');
        }
      }

      // ✅ MOSTRA NOTIFICA SE TIMER È RUNNING
      final isTimerRunning = bgTimer.isTimerRunning();

      if (isTimerRunning) {
        print('⏱️ Timer in esecuzione in background');

        final totalSeconds = bgTimer.getTotalSeconds();

        print('📊 Secondi totali: $totalSeconds');

        await notificationService.showPersistentNotification(
          title: 'SmileLine Timer',
          body: '⏱️ ${_formatSeconds(totalSeconds)}',
          progress: (totalSeconds % 3600) ~/ 60,
        );
      }

      // ✅ CONTROLLA REMINDER
      final reminderMinutesRemaining = bgTimer.getReminderMinutesRemaining();

      if (reminderMinutesRemaining == null) {
        print('⏰ Reminder non attivo');
      } else if (reminderMinutesRemaining <= 0) {
        print('⏰⏰⏰ REMINDER FINITO! Invio notifica...');

        try {
          await notificationService.sendInstantReminder(
            title: '🦷 Ricordati gli allineatori!',
            body: 'È ora di rimettere i tuoi allineatori',
          );
          print('✅ Notifica reminder inviata con successo');
        } catch (e) {
          print('❌ Errore nell\'invio notifica reminder: $e');
        }

        try {
          await bgTimer.saveReminderState(minutesRemaining: 0, isActive: false);
          print('✅ Reminder disattivato');
        } catch (e) {
          print('❌ Errore nel disattivare il reminder: $e');
        }
      } else {
        print('⏰ Reminder attivo: $reminderMinutesRemaining minuti rimanenti');
      }

      return true;
    } catch (e) {
      print('❌ Errore in background task: $e');
      return false;
    }
  });
}

/// ✅ Servizio che schedula i task background
class BackgroundWorkService {
  static final BackgroundWorkService _instance = BackgroundWorkService._internal();

  bool _isInitialized = false;

  factory BackgroundWorkService() {
    return _instance;
  }

  BackgroundWorkService._internal();

  /// ✅ Inizializza il workmanager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: true, // Metti false in produzione
      );

      _isInitialized = true;
      print('✅ BackgroundWorkService inizializzato');
    } catch (e) {
      print('❌ Errore nell\'inizializzazione BackgroundWorkService: $e');
      rethrow;
    }
  }

  /// ✅ Schedula il task periodico OGNI 1 MINUTO
  Future<void> schedulePeriodicTask() async {
    try {
      await Workmanager().registerPeriodicTask(
        'smile_line_timer_task',
        'syncTimerData',
        frequency: const Duration(minutes: 1),
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        backoffPolicy: BackoffPolicy.exponential,
        initialDelay: const Duration(minutes: 1),
      );

      print('✅ Task periodico schedulato (ogni 1 MINUTO)');
    } catch (e) {
      print('❌ Errore nello scheduling del task: $e');
    }
  }

  /// ✅ Schedula il task una sola volta (per testing)
  Future<void> scheduleOneTimeTask() async {
    try {
      await Workmanager().registerOneOffTask(
        'smile_line_timer_once',
        'syncTimerData',
        initialDelay: const Duration(seconds: 30),
      );

      print('✅ Task una volta schedulato (fra 30 secondi)');
    } catch (e) {
      print('❌ Errore nello scheduling del task una volta: $e');
    }
  }

  /// ✅ Cancella il task per identificatore
  Future<void> cancelTask() async {
    try {
      await Workmanager().cancelByUniqueName('smile_line_timer_task');
      print('✅ Task cancellato');
    } catch (e) {
      print('❌ Errore nella cancellazione del task: $e');
    }
  }

  /// ✅ Cancella tutti i task
  Future<void> cancelAllTasks() async {
    try {
      await Workmanager().cancelAll();
      print('✅ Tutti i task cancellati');
    } catch (e) {
      print('❌ Errore nella cancellazione di tutti i task: $e');
    }
  }
}

/// ✅ Helper: Formatta i secondi in HH:MM:SS
String _formatSeconds(int seconds) {
  final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
  final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
  final secs = (seconds % 60).toString().padLeft(2, '0');
  return '$hours:$minutes:$secs';
}