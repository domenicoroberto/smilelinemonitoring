import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/background_timer_foreground_service.dart';
import '../services/timer_service.dart';

// ============ ENUM EVENTI TIMER ============

enum TimerEvent {
  started,
  paused,
  resumed,
  stopped,
  reset,
  ticking,
}

// ============ MODELS ============

class TimerState {
  final bool isRunning;
  final int totalSeconds;      // ✅ Unico contatore
  final TimerEvent event;
  final String formattedTime;

  const TimerState({
    required this.isRunning,
    required this.totalSeconds,
    required this.event,
    required this.formattedTime,
  });

  @override
  String toString() => '''TimerState(
    isRunning: $isRunning,
    totalSeconds: $totalSeconds,
    event: $event,
    formattedTime: $formattedTime,
  )''';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is TimerState &&
              runtimeType == other.runtimeType &&
              isRunning == other.isRunning &&
              totalSeconds == other.totalSeconds &&
              event == other.event;

  @override
  int get hashCode =>
      isRunning.hashCode ^ totalSeconds.hashCode ^ event.hashCode;
}

class TimerInfo {
  final bool isRunning;
  final int totalSeconds;
  final int minutesPassed;
  final int hoursPassed;
  final String formattedTime;
  final TimerEvent event;

  TimerInfo({
    required this.isRunning,
    required this.totalSeconds,
    required this.minutesPassed,
    required this.hoursPassed,
    required this.formattedTime,
    required this.event,
  });

  @override
  String toString() => '''TimerInfo(
    isRunning: $isRunning,
    totalSeconds: $totalSeconds,
    minutesPassed: $minutesPassed,
    hoursPassed: $hoursPassed,
    formattedTime: $formattedTime,
    event: $event,
  )''';
}

// ============ NOTIFIER ============

class TimerNotifier extends StateNotifier<TimerState> {
  final TimerService _timerService = TimerService();

  TimerNotifier()
      : super(const TimerState(
    isRunning: false,
    totalSeconds: 0,
    event: TimerEvent.reset,
    formattedTime: '00:00:00',
  )) {
    _initializeTimerCallbacks();
  }

  void _initializeTimerCallbacks() {
    _timerService.addCallback((timerState) {
      final mappedEvent = _mapServiceEventToProviderEvent(timerState.event);

      state = TimerState(
        isRunning: timerState.isRunning,
        totalSeconds: timerState.elapsedSeconds,  // ← Usa elapsedSeconds del TimerService (locale)
        event: mappedEvent,
        formattedTime: timerState.formattedTime,
      );
    });
  }

  TimerEvent _mapServiceEventToProviderEvent(dynamic serviceEvent) {
    final eventString = serviceEvent.toString();

    if (eventString.contains('started')) return TimerEvent.started;
    if (eventString.contains('paused')) return TimerEvent.paused;
    if (eventString.contains('resumed')) return TimerEvent.resumed;
    if (eventString.contains('stopped')) return TimerEvent.stopped;
    if (eventString.contains('reset')) return TimerEvent.reset;
    if (eventString.contains('ticking')) return TimerEvent.ticking;

    return TimerEvent.ticking;
  }

  void start() {
    _timerService.start();
    //BackgroundTimerService().saveTimerStart();
    print('▶️ Timer avviato');
  }

  void pause() {
    _timerService.pause();
    //BackgroundTimerService().pauseTimer();
    print('⏸️ Timer in pausa');
  }

  void resume() {
    _timerService.resume();
    //BackgroundTimerService().resumeTimer();
    print('▶️ Timer ripreso');
  }

  void reset() {
    _timerService.reset();
    //BackgroundTimerService().resetForNewDay();
    print('🔄 Timer resettato');
  }

  void stop() {
    _timerService.stop();
    //BackgroundTimerService().resetForNewDay();
    print('⏹️ Timer fermato');
  }

  void addSeconds(int seconds) {
    _timerService.addSeconds(seconds);
  }

  void subtractSeconds(int seconds) {
    _timerService.subtractSeconds(seconds);
  }

  void setElapsedSeconds(int seconds) {
    _timerService.setElapsedSeconds(seconds);
  }

  /// ✅ Sincronizza il timer dal background (RUNNING)
  /// Il timer continua a scorrere usando l'ora del sistema
  void setSyncedTime(int totalSeconds) {
    print('📡 Sincronizzazione timer dal background (RUNNING)');
    print('   📊 Secondi totali: $totalSeconds');

    // Calcola l'ora di inizio
    final now = DateTime.now();
    final startTime = now.subtract(Duration(seconds: totalSeconds));

    print('   ⏰ Start time calcolato: ${startTime.toIso8601String()}');

    // Imposta isRunning PRIMA di sincronizzare
    _timerService.setIsRunning(true);
    print('   ✅ Timer state impostato a RUNNING');

    // Comunica al timerservice il nuovo start time
    _timerService.setSyncedStartTime(startTime);

    print('✅ Timer sincronizzato! Continuerà a scorrere automaticamente');
  }

  /// ✅ Sincronizza il timer dal background (PAUSED)
  /// Imposta solo il tempo, ma NON riavvia il timer
  void setSyncedTimeWhilePaused(int totalSeconds) {
    print('📡 Sincronizzazione timer dal background (PAUSED)');
    print('   📊 Secondi totali: $totalSeconds');

    // Imposta solo il tempo senza riavviare il tick
    _timerService.setElapsedSeconds(totalSeconds);

    print('✅ Timer sincronizzato ma rimane in PAUSA!');
  }

  /// ✅ Sincronizza il timer quando l'app si riapre (il timer era RUNNING in background)
  void syncRunningTimerFromBackground(int totalSeconds) {
    print('📡 SYNC RUNNING TIMER FROM BACKGROUND');
    print('   📊 Secondi totali: $totalSeconds');

    final now = DateTime.now();
    final startTime = now.subtract(Duration(seconds: totalSeconds));

    print('   ⏰ Start time calcolato: ${startTime.toIso8601String()}');

    _timerService.setIsRunning(true);
    print('   ✅ Timer state impostato a RUNNING');

    _timerService.setSyncedStartTime(startTime);

    // ✅ CRITICO: Forza il riavvio manuale del tick
    _timerService.resume();  // ← Riavvia il tick!

    print('✅ Timer sincronizzato e RIAVVIATO automaticamente!');
  }

  @override
  void dispose() {
    _timerService.dispose();
    super.dispose();
  }
}

// ============ PROVIDERS ============

final timerProvider =
StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  return TimerNotifier();
});

final isTimerRunningProvider = Provider<bool>((ref) {
  final timerState = ref.watch(timerProvider);
  return timerState.isRunning;
});

final timerTotalSecondsProvider = Provider<int>((ref) {
  final timerState = ref.watch(timerProvider);
  return timerState.totalSeconds;
});

final timerFormattedProvider = Provider<String>((ref) {
  final timerState = ref.watch(timerProvider);
  return timerState.formattedTime;
});

final timerMinutesPassedProvider = Provider<int>((ref) {
  final timerState = ref.watch(timerProvider);
  return timerState.totalSeconds ~/ 60;
});

final timerHoursPassedProvider = Provider<int>((ref) {
  final timerState = ref.watch(timerProvider);
  return timerState.totalSeconds ~/ 3600;
});

final timerHasPassedMinutesProvider = FutureProvider.family<bool, int>((ref, minutes) async {
  final timerState = ref.watch(timerProvider);
  return timerState.totalSeconds >= (minutes * 60);
});

final timerHasPassedHoursProvider = FutureProvider.family<bool, int>((ref, hours) async {
  final timerState = ref.watch(timerProvider);
  return timerState.totalSeconds >= (hours * 3600);
});

final timerEventProvider = Provider<TimerEvent>((ref) {
  final timerState = ref.watch(timerProvider);
  return timerState.event;
});

final timerInfoProvider = Provider<TimerInfo>((ref) {
  final timerState = ref.watch(timerProvider);

  return TimerInfo(
    isRunning: timerState.isRunning,
    totalSeconds: timerState.totalSeconds,
    minutesPassed: timerState.totalSeconds ~/ 60,
    hoursPassed: timerState.totalSeconds ~/ 3600,
    formattedTime: timerState.formattedTime,
    event: timerState.event,
  );
});

final timerStreamProvider = StreamProvider<TimerState>((ref) async* {
  while (true) {
    await Future.delayed(const Duration(milliseconds: 100));
    yield ref.watch(timerProvider);
  }
});