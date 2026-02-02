import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../services/notification_service.dart';
import '../../services/background_timer_service.dart';

// Stato del reminder timer
class ReminderTimerState {
  final int remainingSeconds;
  final bool isActive;
  final int totalSeconds;

  ReminderTimerState({
    required this.remainingSeconds,
    required this.isActive,
    required this.totalSeconds,
  });

  String get formattedTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get progress {
    if (totalSeconds == 0) return 0;
    return remainingSeconds / totalSeconds;
  }
}

// Notifier per il reminder timer
class ReminderTimerNotifier extends StateNotifier<ReminderTimerState> {
  // ✅ NON usiamo Timer.periodic() - lasciamo che BackgroundTimerService lo faccia!
  // Usiamo solo un Timer per aggiornare la UI ogni secondo
  Timer? _uiUpdateTimer;

  final NotificationService _notificationService = NotificationService();
  final BackgroundTimerService _backgroundTimerService = BackgroundTimerService();

  int _totalSecondsSet = 0;  // ✅ Traccia la durata totale
  DateTime? _reminderStartTime;  // ✅ Quando è stato avviato
  bool _wasRunning = false;  // ✅ Era running prima della pausa

  ReminderTimerNotifier()
      : super(ReminderTimerState(
    remainingSeconds: 0,
    isActive: false,
    totalSeconds: 0,
  )) {
    // ✅ SYNC dal background all'avvio
    _syncFromBackground();
  }

  /// ✅ NUOVO: Sincronizza il reminder dal background
  Future<void> _syncFromBackground() async {
    try {
      await _backgroundTimerService.initialize();

      final minutesRemaining = _backgroundTimerService.getReminderMinutesRemaining();

      if (minutesRemaining == null || minutesRemaining <= 0) {
        print('⏰ Nessun reminder attivo nel background');
        return;
      }

      print('🔄 SYNC REMINDER FROM BACKGROUND: $minutesRemaining minuti rimanenti');

      final totalSeconds = minutesRemaining * 60;
      _totalSecondsSet = totalSeconds;
      _reminderStartTime = DateTime.now();

      state = ReminderTimerState(
        remainingSeconds: totalSeconds,
        isActive: true,
        totalSeconds: totalSeconds,
      );

      // ✅ Avvia l'aggiornamento UI ogni secondo
      _startUIUpdate();

      print('✅ Reminder sincronizzato');
    } catch (e) {
      print('❌ Errore sincronizzazione reminder: $e');
    }
  }

  /// ✅ CRITICO: Avvia il reminder
  /// NON usiamo Timer.periodic() per il timer!
  /// Usiamo BackgroundTimerService che lo gestisce
  Future<void> startCountdown(int minutes) async {
    print('\n' + '='*70);
    print('📍 AVVIO COUNTDOWN REMINDER: $minutes minuti');
    print('='*70);

    final totalSeconds = minutes * 60;
    _totalSecondsSet = totalSeconds;
    _reminderStartTime = DateTime.now();  // ✅ SALVA L'ORA DI INIZIO

    // ✅ Salva nel background
    try {
      await _backgroundTimerService.initialize();
      await _backgroundTimerService.saveReminderState(
        minutesRemaining: minutes,
        isActive: true,
      );
      print('✅ Reminder salvato nel background');
    } catch (e) {
      print('❌ Errore salvataggio: $e');
      return;
    }

    // ✅ ORA aggiorna state
    state = ReminderTimerState(
      remainingSeconds: totalSeconds,
      isActive: true,
      totalSeconds: totalSeconds,
    );

    print('⏱️ Timer reminder avviato: $minutes minuti');

    // ✅ Avvia l'aggiornamento della UI ogni secondo
    _startUIUpdate();

    print('='*70 + '\n');
  }

  void _startUIUpdate() {
    _uiUpdateTimer?.cancel();

    print('🎬 Inizio aggiornamento UI ogni secondo');

    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        // ✅ NON LEGGERE DAL BACKGROUND!
        // Calcola direttamente da _reminderStartTime che è l'ora di inizio

        if (_reminderStartTime == null) {
          timer.cancel();
          return;
        }

        final now = DateTime.now();
        final elapsedSeconds = now.difference(_reminderStartTime!).inSeconds;
        final remainingSeconds = _totalSecondsSet - elapsedSeconds;

        // ✅ Se scaduto
        if (remainingSeconds <= 0) {
          print('⏰⏰⏰ REMINDER SCADUTO!');
          timer.cancel();
          _uiUpdateTimer = null;

          state = ReminderTimerState(
            remainingSeconds: 0,
            isActive: false,
            totalSeconds: state.totalSeconds,
          );

          await _sendNotificationAndCleanup();
          return;
        }

        // ✅ Aggiorna UI
        state = ReminderTimerState(
          remainingSeconds: remainingSeconds,
          isActive: true,
          totalSeconds: state.totalSeconds,
        );

        print('⏱️ Reminder UI update: ${remainingSeconds}s rimasti');

      } catch (e) {
        print('❌ Errore update UI: $e');
        timer.cancel();
        _uiUpdateTimer = null;
      }
    });
  }

  /// ✅ Quando il timer scade (CALLBACK CRITICA)
  Future<void> _sendNotificationAndCleanup() async {
    print('\n' + '='*70);
    print('🔔 TIMER COMPLETATO - Notifica');
    print('='*70);

    // ✅ PRIMA: Invia notifica istantanea CORRETTA
    try {
      print('📢 Invio notifica istantanea...');
      await _notificationService.sendInstantReminder(
        title: '🦷 SmileLine Reminder',
        body: 'Tempo scaduto! ⏰\nÈ ora di indossare i tuoi allineatori!',
      );
      print('✅ Notifica inviata!');
    } catch (e) {
      print('❌ Errore notifica: $e');
    }

    // ✅ POI: Disattiva nel background
    try {
      await _backgroundTimerService.saveReminderState(
        minutesRemaining: 0,
        isActive: false,
      );
      print('✅ Reminder disattivato nel background');
    } catch (e) {
      print('❌ Errore disattivazione: $e');
    }

    print('='*70 + '\n');
  }

  /// ✅ Cancella il countdown
  Future<void> cancelCountdown() async {
    print('❌ CANCELLAZIONE REMINDER');

    _uiUpdateTimer?.cancel();
    _uiUpdateTimer = null;

    state = ReminderTimerState(
      remainingSeconds: 0,
      isActive: false,
      totalSeconds: 0,
    );

    try {
      await _backgroundTimerService.initialize();
      await _backgroundTimerService.saveReminderState(
        minutesRemaining: 0,
        isActive: false,
      );
      print('✅ Reminder disattivato');
    } catch (e) {
      print('❌ Errore: $e');
    }
  }

  /// ✅ NUOVO: Quando app va in pausa
  /// Non serve fare niente - BackgroundTimerService continua!
  Future<void> pauseReminder() async {
    print('⏸️ APP PAUSED - Pausa timer UI');
    _uiUpdateTimer?.cancel();
    _uiUpdateTimer = null;
    _wasRunning = state.isActive;
    print('✅ UI timer pausato, BackgroundTimerService continua in background');
  }

  /// ✅ NUOVO: Quando app torna in foreground
  /// Riprendi l'aggiornamento UI dal background
  Future<void> resumeReminder() async {
    print('▶️ APP RESUMED - Riprendi timer UI');

    // ✅ Sincronizza con il valore attuale dal background
    if (state.isActive) {
      _startUIUpdate();
      print('✅ UI timer riavviato, sincronizzato col background');
    }
  }

  @override
  void dispose() {
    print('🗑️ Dispose ReminderTimerNotifier');
    _uiUpdateTimer?.cancel();
    super.dispose();
  }
}

// Provider del reminder timer
final reminderTimerProvider =
StateNotifierProvider<ReminderTimerNotifier, ReminderTimerState>(
      (ref) => ReminderTimerNotifier(),
);