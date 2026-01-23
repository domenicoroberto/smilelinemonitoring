import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../services/background_timer_service.dart';
import '../../providers/treatment_provider.dart';
import '../../providers/tracking_provider.dart';
import '../../models/treatment_plan.dart';
import '../providers/user_provider.dart';

class TimerService {
  static final TimerService _instance = TimerService._internal();

  Timer? _timer;
  Timer? _dailyResetTimer;
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  final List<TimerCallback> _callbacks = [];
  DateTime _currentDay = DateTime.now();
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  final BackgroundTimerService _backgroundTimerService = BackgroundTimerService();

  DateTime? _syncedStartTime;

  WidgetRef? _ref;

  factory TimerService() {
    return _instance;
  }

  TimerService._internal() {
    _initializeDailyReset();
  }

  void setRef(WidgetRef ref) {
    _ref = ref;
    print('✅ TimerService ref impostato');
  }

  void _initializeDailyReset() {
    _dailyResetTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = DateTime.now();

      if (now.day != _currentDay.day ||
          now.month != _currentDay.month ||
          now.year != _currentDay.year) {

        print('\n' + '='*60);
        print('🌙 MEZZANOTTE! Resetting timer dal giorno ${_currentDay.day}');
        print('='*60);

        resetForNewDay(now);
        refreshDashboard();
        _notifyDayChanged();
        refreshHomeScreen();

        print('='*60 + '\n');
      }
    });
  }

  Future<void> refreshHomeScreen() async {
    try {
      if (_ref == null) {
        print('⚠️ WidgetRef non disponibile per refresh HomeScreen');
        return;
      }

      print('🔄 Ricaricando HomeScreen...');

      final userNotifier = _ref!.read(userProvider.notifier);
      await userNotifier.loadCurrentUser();

      final treatmentNotifier = _ref!.read(treatmentPlanProvider.notifier);
      final user = _ref!.read(userProvider);
      if (user?.currentTreatmentPlanId != null) {
        await treatmentNotifier.loadTreatmentPlan(user!.currentTreatmentPlanId!);
      }

      final trackingNotifier = _ref!.read(trackingProvider.notifier);
      await trackingNotifier.loadTrackingByDate(DateTime.now());

      print('✅ HomeScreen completamente ricaricata');
    } catch (e) {
      print('❌ Errore nel refresh del HomeScreen: $e');
    }
  }

  Future<void> refreshDashboard() async {
    try {
      if (_ref == null) {
        print('⚠️ WidgetRef non disponibile per refresh dashboard');
        return;
      }

      print('🔄 Aggiornando dashboard...');

      final trackingNotifier = _ref!.read(trackingProvider.notifier);
      final now = DateTime.now();

      final startDate = now.subtract(const Duration(days: 7));
      await trackingNotifier.loadTrackingBetweenDates(startDate, now);

      print('📊 Tracking caricato per ultimi 7 giorni');
      print('✅ Dashboard completamente aggiornata');
    } catch (e) {
      print('❌ Errore nell\'aggiornamento della dashboard: $e');
    }
  }

  void resetForNewDay(DateTime newDate) {
    final wasRunning = _isRunning;

    _elapsedSeconds = 0;
    _currentDay = newDate;
    _syncedStartTime = null;

    _backgroundTimerService.resetForNewDay().then((_) {
      print('✅ Background resettato per nuovo giorno');

      if (wasRunning) {
        return _backgroundTimerService.restartTimerForNewDay(true);
      }
    }).then((_) {
      if (wasRunning) {
        print('✅ Timer riavviato per nuovo giorno');
      }
    }).catchError((e) {
      print('❌ Errore reset background: $e');
    });

    _notifyListeners(TimerEvent.reset);

    print('🌙 Nuovo giorno! Timer resettato a 0');
    print('   📅 Nuovo giorno: ${newDate.day}/${newDate.month}/${newDate.year}');

    if (wasRunning) {
      print('   ⚙️ Timer continua in esecuzione per il nuovo giorno');
    }
  }

  void _notifyDayChanged() {
    _notifyListeners(TimerEvent.reset);
    print('📱 Notificando UI di refresh...');
  }

  // ============ TIMER OPERATIONS ============

  bool get isRunning => _isRunning;
  int get elapsedSeconds => _elapsedSeconds;
  Duration get elapsed => Duration(seconds: _elapsedSeconds);

  String get formattedTime {
    final hours = (_elapsedSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((_elapsedSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  String get formattedTimeShort {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void start() {
    if (_isRunning) return;

    _isRunning = true;
    _syncedStartTime = null;
    _notifyListeners(TimerEvent.started);

    _backgroundTimerService.saveTimerStart().then((_) {
      print('✅ Timer start salvato nel background');
    }).catchError((e) {
      print('⚠️ Errore nel salvataggio timer nel background: $e');
    });

    _startTimerTick();

    print('✅ Timer avviato');
  }

  void _startTimerTick() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      if (_checkAndHandleNewDay()) {
        return;
      }

      _elapsedSeconds++;
      _notifyListeners(TimerEvent.ticking);
    });

    print('⏱️ Timer tick avviato');
  }

  bool _checkAndHandleNewDay() {
    final now = DateTime.now();
    if (now.day != _currentDay.day ||
        now.month != _currentDay.month ||
        now.year != _currentDay.year) {
      resetForNewDay(now);
      refreshDashboard();
      refreshHomeScreen();
      _notifyDayChanged();
      return true;
    }
    return false;
  }

  void pause() {
    _timer?.cancel();
    _isRunning = false;

    _backgroundTimerService.pauseTimer().then((_) {
      print('✅ Background timer paused');
      print('   - Secondi salvati nel DB');
    }).catchError((e) {
      print('❌ Errore pause: $e');
    });

    _notifyListeners(TimerEvent.paused);
  }

  void resume() {
    if (_isRunning) return;

    _isRunning = true;
    _notifyListeners(TimerEvent.resumed);

    _backgroundTimerService.resumeTimer().then((_) {
      print('✅ Background timer RESUMED');
    }).catchError((e) {
      print('⚠️ Errore nel resume: $e');
    });

    _startTimerTick();

    print('▶️ Timer ripreso');
  }

  void reset() {
    _timer?.cancel();
    _elapsedSeconds = 0;
    _isRunning = false;
    _syncedStartTime = null;

    _backgroundTimerService.resetForNewDay().then((_) {
      print('🔄 Timer reset, background pulito');
    }).catchError((e) {
      print('⚠️ Errore nel reset del background: $e');
    });

    _notifyListeners(TimerEvent.reset);

    print('🔄 Timer resettato');
  }

  void stop() {
    _timer?.cancel();
    _isRunning = false;

    _backgroundTimerService.pauseTimer().then((_) {
      print('⹹️ Timer stopped, stato salvato nel background');
    }).catchError((e) {
      print('⚠️ Errore nel salvataggio stop: $e');
    });

    _notifyListeners(TimerEvent.stopped);

    print('⹹️ Timer fermato');
  }

  void setIsRunning(bool value) {
    _isRunning = value;
    print('🔄 Timer isRunning impostato a: $value');
  }

  /// ✅ CRITICO FIX: Sincronizza il timer quando l'app si riapre (timer era RUNNING)
  /// ⚠️ IMPORTANTE: SEMPRE riavvia il tick se isRunning è true
  void setSyncedStartTime(DateTime startTime) {
    _syncedStartTime = startTime;

    final elapsed = DateTime.now().difference(startTime).inSeconds;
    _elapsedSeconds = elapsed;

    print('🔄 Timer sincronizzato dal background (RUNNING)');
    print('   ⏱️ Start time: ${startTime.toIso8601String()}');
    print('   ⏱️ Secondi trascorsi: $_elapsedSeconds');

    // ✅ CRITICO: Ferma il vecchio timer SEMPRE
    _timer?.cancel();

    // ✅ Se isRunning è true, riavvia il tick SEMPRE
    if (_isRunning) {
      print('   ▶️ Timer ERA in esecuzione, riavvio il conteggio...');
      _startTimerTick();  // ← Questo riavvia il Timer.periodic
      print('   ✅ Timer tick riavviato');
    }

    _notifyListeners(TimerEvent.ticking);
  }

  void setSyncedTimeWhilePaused(int totalSeconds) {
    print('🔄 Timer sincronizzato dal background (PAUSED)');
    print('   📊 Secondi totali: $totalSeconds');

    _elapsedSeconds = totalSeconds;
    _isRunning = false;

    _notifyListeners(TimerEvent.paused);
  }

  void startForDuration(Duration duration) {
    _elapsedSeconds = 0;
    start();
    print('⏱️ Timer avviato per ${duration.inMinutes} minuti');
  }

  Future<void> runForDuration(Duration duration) async {
    start();
    await Future.delayed(duration);
    stop();
  }

  void addCallback(TimerCallback callback) {
    _callbacks.add(callback);
  }

  void removeCallback(TimerCallback callback) {
    _callbacks.remove(callback);
  }

  void _notifyListeners(TimerEvent event) {
    for (var callback in _callbacks) {
      callback(TimerState(
        isRunning: _isRunning,
        elapsedSeconds: _elapsedSeconds,
        event: event,
        formattedTime: formattedTime,
      ));
    }
  }

  void addSeconds(int seconds) {
    _elapsedSeconds += seconds;
    _notifyListeners(TimerEvent.ticking);
    print('➕ Aggiunti $seconds secondi');
  }

  void subtractSeconds(int seconds) {
    if (_elapsedSeconds >= seconds) {
      _elapsedSeconds -= seconds;
    } else {
      _elapsedSeconds = 0;
    }
    _notifyListeners(TimerEvent.ticking);
    print('➖ Tolti $seconds secondi');
  }

  void setElapsedSeconds(int seconds) {
    _elapsedSeconds = seconds;
    _notifyListeners(TimerEvent.ticking);
    print('🎯 Timer impostato a $seconds secondi');
  }

  int get minutesPassed => _elapsedSeconds ~/ 60;
  int get hoursPassed => _elapsedSeconds ~/ 3600;

  bool hasPassedMinutes(int minutes) => _elapsedSeconds >= (minutes * 60);
  bool hasPassedHours(int hours) => _elapsedSeconds >= (hours * 3600);

  void dispose() {
    _timer?.cancel();
    _dailyResetTimer?.cancel();
    _callbacks.clear();
    _isRunning = false;
    _syncedStartTime = null;
    print('🗑️ Timer service disposto');
  }

  @override
  String toString() => 'TimerService($_isRunning, $_elapsedSeconds)';
}

// ============ ENUMS E CLASSES ============

enum TimerEvent {
  started,
  paused,
  resumed,
  stopped,
  reset,
  ticking,
}

class TimerState {
  final bool isRunning;
  final int elapsedSeconds;
  final TimerEvent event;
  final String formattedTime;

  TimerState({
    required this.isRunning,
    required this.elapsedSeconds,
    required this.event,
    required this.formattedTime,
  });

  @override
  String toString() => '''TimerState(
    isRunning: $isRunning,
    elapsedSeconds: $elapsedSeconds,
    event: $event,
    formattedTime: $formattedTime,
  )''';
}

typedef TimerCallback = void Function(TimerState state);