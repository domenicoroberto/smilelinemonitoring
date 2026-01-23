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
  Timer? _timer;
  final NotificationService _notificationService = NotificationService();
  final BackgroundTimerService _backgroundTimerService = BackgroundTimerService();

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

      // ✅ Riavvia il countdown con i minuti rimanenti
      final totalSeconds = minutesRemaining * 60;
      state = ReminderTimerState(
        remainingSeconds: totalSeconds,
        isActive: true,
        totalSeconds: totalSeconds,
      );

      // ✅ Riavvia il timer tick
      _startTimerTick();

      print('✅ Reminder sincronizzato e riavviato');
    } catch (e) {
      print('❌ Errore nella sincronizzazione reminder: $e');
    }
  }

  /// ✅ NUOVO: Avvia il timer tick separato
  void _startTimerTick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        state = ReminderTimerState(
          remainingSeconds: state.remainingSeconds - 1,
          isActive: true,
          totalSeconds: state.totalSeconds,
        );
      } else {
        // Timer finito - invia notifica
        print('⏰ Timer scaduto! Invio notifica...');
        _onTimerComplete();
        timer.cancel();
      }
    });
  }

  /// ✅ Avvia il countdown timer
  Future<void> startCountdown(int minutes) async {
    // Cancella timer precedente se esiste
    _timer?.cancel();

    final totalSeconds = minutes * 60;
    state = ReminderTimerState(
      remainingSeconds: totalSeconds,
      isActive: true,
      totalSeconds: totalSeconds,
    );

    print('⏱️ Timer reminder avviato: $minutes minuti ($totalSeconds secondi)');

    // ✅ NUOVO: Salva il reminder nel background
    try {
      await _backgroundTimerService.initialize();
      await _backgroundTimerService.saveReminderState(
        minutesRemaining: minutes,
        isActive: true,
      );
      print('✅ Reminder salvato nel background');
    } catch (e) {
      print('❌ Errore nel salvataggio reminder nel background: $e');
    }

    // ✅ Usa il metodo centralizzato per avviare il tick
    _startTimerTick();
  }

  /// Quando il timer finisce
  Future<void> _onTimerComplete() async {
    state = ReminderTimerState(
      remainingSeconds: 0,
      isActive: false,
      totalSeconds: state.totalSeconds,
    );

    // ✅ Disattiva il reminder nel background
    try {
      await _backgroundTimerService.initialize();
      await _backgroundTimerService.saveReminderState(
        minutesRemaining: 0,
        isActive: false,
      );
      print('✅ Reminder disattivato nel background');
    } catch (e) {
      print('❌ Errore nel disattivare reminder dal background: $e');
    }

    // Invia notifica istantanea
    _notificationService.sendInstantReminder(
        title: '🦷 SmileLine Reminder',
        body: 'Tempo scaduto! ⏰ \n '
            'È ora di indossare i tuoi allineatori!'
    );
  }

  /// ✅ Cancella il timer
  Future<void> cancelCountdown() async {
    _timer?.cancel();
    state = ReminderTimerState(
      remainingSeconds: 0,
      isActive: false,
      totalSeconds: 0,
    );

    // ✅ Disattiva nel background
    try {
      await _backgroundTimerService.initialize();
      await _backgroundTimerService.saveReminderState(
        minutesRemaining: 0,
        isActive: false,
      );
      print('✅ Reminder disattivato nel background');
    } catch (e) {
      print('❌ Errore nel disattivare: $e');
    }

    print('❌ Reminder cancellato');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// Provider del reminder timer
final reminderTimerProvider =
StateNotifierProvider<ReminderTimerNotifier, ReminderTimerState>(
      (ref) => ReminderTimerNotifier(),
);