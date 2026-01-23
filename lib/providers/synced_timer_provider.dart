import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/timer_service.dart';
import '../services/background_timer_service.dart';
import '../models/treatment_plan.dart';
import '../providers/treatment_provider.dart';

// ============ MODELS ============

/// Stato del timer con sincronizzazione background
class SyncedTimerState {
  final bool isRunning;
  final int totalSeconds;      // ✅ Unico contatore: total giornaliero + elapsed da start
  final String formattedTime;
  final bool isSynced;
  final DateTime? lastSyncTime;

  const SyncedTimerState({
    required this.isRunning,
    required this.totalSeconds,
    required this.formattedTime,
    this.isSynced = false,
    this.lastSyncTime,
  });

  /// Formatta il tempo in HH:MM:SS
  static String formatSeconds(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  /// ✅ Copia con alcuni campi modificati
  SyncedTimerState copyWith({
    bool? isRunning,
    int? totalSeconds,
    String? formattedTime,
    bool? isSynced,
    DateTime? lastSyncTime,
  }) {
    return SyncedTimerState(
      isRunning: isRunning ?? this.isRunning,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      formattedTime: formattedTime ?? this.formattedTime,
      isSynced: isSynced ?? this.isSynced,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }

  @override
  String toString() => '''SyncedTimerState(
    isRunning: $isRunning,
    totalSeconds: $totalSeconds,
    formattedTime: $formattedTime,
    isSynced: $isSynced,
    lastSyncTime: $lastSyncTime,
  )''';
}

// ============ NOTIFIER ============

/// Notifier che gestisce il timer con persistenza background
class SyncedTimerNotifier extends StateNotifier<SyncedTimerState> {
  final BackgroundTimerService _bgTimer;
  final TimerService _fgTimer = TimerService();

  SyncedTimerNotifier(this._bgTimer)
      : super(const SyncedTimerState(
    isRunning: false,
    totalSeconds: 0,
    formattedTime: '00:00:00',
  )) {
    _initializeFromBackground();
  }

  /// ✅ Inizializza il timer dai dati salvati in background
  Future<void> _initializeFromBackground() async {
    try {
      print('📡 Inizializzo timer dai dati background...');

      final totalSeconds = _bgTimer.getTotalSeconds();
      final isRunning = _bgTimer.isTimerRunning();

      state = SyncedTimerState(
        isRunning: isRunning,
        totalSeconds: totalSeconds,
        formattedTime: SyncedTimerState.formatSeconds(totalSeconds),
        isSynced: true,
        lastSyncTime: DateTime.now(),
      );

      print('✅ Timer sincronizzato dal background');
      print('   - isRunning: $isRunning');
      print('   - totalSeconds: $totalSeconds');
      print('   - formatted: ${state.formattedTime}');

      // Se il timer era in esecuzione, continua
      if (isRunning) {
        _startLocalTimer();
      }
    } catch (e) {
      print('❌ Errore nell\'inizializzazione dal background: $e');
    }
  }

  /// ✅ Avvia il timer locale (per gli aggiornamenti UI)
  void _startLocalTimer() {
    _fgTimer.addCallback((timerState) {
      _updateTimerState();
    });

    _fgTimer.start();
    print('▶️ Timer locale avviato');
  }

  /// ✅ Aggiorna lo stato del timer
  void _updateTimerState() {
    final totalSeconds = _bgTimer.getTotalSeconds();

    state = state.copyWith(
      isRunning: true,
      totalSeconds: totalSeconds,
      formattedTime: SyncedTimerState.formatSeconds(totalSeconds),
    );
  }

  // ============ TIMER OPERATIONS ============

  /// ✅ Avvia il timer
  Future<void> start() async {
    try {
      await _bgTimer.saveTimerStart();
      _startLocalTimer();

      state = state.copyWith(isRunning: true);
      print('▶️ Timer avviato');
    } catch (e) {
      print('❌ Errore nell\'avvio del timer: $e');
    }
  }

  /// ✅ Pausa il timer
  Future<void> pause() async {
    try {
      _fgTimer.pause();
      await _bgTimer.pauseTimer();

      final totalSeconds = _bgTimer.getTotalSeconds();

      state = state.copyWith(
        isRunning: false,
        totalSeconds: totalSeconds,
        formattedTime: SyncedTimerState.formatSeconds(totalSeconds),
      );

      print('⏸️ Timer in pausa - Salvati: $totalSeconds secondi');
    } catch (e) {
      print('❌ Errore nella pausa del timer: $e');
    }
  }

  /// ✅ Riprende il timer
  Future<void> resume() async {
    try {
      await _bgTimer.resumeTimer();
      _startLocalTimer();

      state = state.copyWith(isRunning: true);
      print('▶️ Timer ripreso');
    } catch (e) {
      print('❌ Errore nella ripresa del timer: $e');
    }
  }

  /// ✅ Resetta il timer per il nuovo giorno (mezzanotte)
  Future<void> resetForNewDay() async {
    try {
      _fgTimer.reset();
      await _bgTimer.resetForNewDay();

      state = const SyncedTimerState(
        isRunning: false,
        totalSeconds: 0,
        formattedTime: '00:00:00',
        isSynced: true,
      );

      print('🌙 Timer resettato per nuovo giorno');
    } catch (e) {
      print('❌ Errore nel reset: $e');
    }
  }

  /// ✅ Sincronizza con il background
  Future<void> syncWithBackground() async {
    try {
      await _initializeFromBackground();
      print('📡 Timer sincronizzato col background');
    } catch (e) {
      print('❌ Errore nella sincronizzazione: $e');
    }
  }

  /// ✅ Cleanup
  @override
  void dispose() {
    _fgTimer.dispose();
    super.dispose();
  }
}

// ============ PROVIDERS ============

/// Provider per il BackgroundTimerService
final backgroundTimerProvider = FutureProvider<BackgroundTimerService>((ref) async {
  final bgTimer = BackgroundTimerService();
  await bgTimer.initialize();
  return bgTimer;
});

/// Provider principale per il timer sincronizzato
final syncedTimerProvider = StateNotifierProvider<SyncedTimerNotifier, SyncedTimerState>((ref) {
  final bgTimer = BackgroundTimerService();
  return SyncedTimerNotifier(bgTimer);
});

/// Provider per verificare se il timer è in esecuzione
final isTimerRunningProvider = Provider<bool>((ref) {
  return ref.watch(syncedTimerProvider).isRunning;
});

/// Provider per i secondi totali
final timerTotalSecondsProvider = Provider<int>((ref) {
  return ref.watch(syncedTimerProvider).totalSeconds;
});

/// Provider per il tempo formattato
final timerFormattedProvider = Provider<String>((ref) {
  return ref.watch(syncedTimerProvider).formattedTime;
});

/// Provider per verificare se il timer è sincronizzato
final timerIsSyncedProvider = Provider<bool>((ref) {
  return ref.watch(syncedTimerProvider).isSynced;
});

/// Provider per l'ultima volta sincronizzato
final timerLastSyncProvider = Provider<DateTime?>((ref) {
  return ref.watch(syncedTimerProvider).lastSyncTime;
});