import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

/// ✅ SERVIZIO BACKGROUND PERSISTENTE - VERSIONE CORRETTA
/// Usa solo metodi che sicuramente esistono in flutter_background_service
class BackgroundTimerService {
  static final BackgroundTimerService _instance = BackgroundTimerService._internal();

  late SharedPreferences _prefs;
  late DatabaseService _db;
  bool _isInitialized = false;

  // ✅ Timer che salva ogni secondo
  Timer? _secondlySaveTimer;

  factory BackgroundTimerService() {
    return _instance;
  }

  BackgroundTimerService._internal();

  bool get isInitialized => _isInitialized;

  /// ✅ Inizializza il servizio di background
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _db = DatabaseService();

      // Assicurati che il database sia inizializzato
      if (!_db.isInitialized) {
        await _db.initialize();
      }

      _isInitialized = true;
      print('✅ BackgroundTimerService inizializzato');
    } catch (e) {
      print('❌ Errore nell\'inizializzazione BackgroundTimerService: $e');
      rethrow;
    }
  }

  /// ✅ QUANDO PREMI START
  /// Salva l'ora e avvia il salvataggio ogni secondo
  Future<void> saveTimerStart() async {
    try {
      final now = DateTime.now();
      await _prefs.setString('timer_start_time', now.toIso8601String());
      await _prefs.setBool('timer_is_running', true);

      print('✅ Timer START: ${now.toIso8601String()}');

      // Avvia il timer che salva ogni secondo
      _startSecondlySave();
    } catch (e) {
      print('❌ Errore nel saveTimerStart: $e');
    }
  }

  /// ✅ TIMER CHE SALVA OGNI SECONDO
  /// ⚠️ CRITICO: Salva il timestamp dell'ultimo save per evitare doppi conteggi
  void _startSecondlySave() {
    _secondlySaveTimer?.cancel();

    // ✅ Tempo dell'ultimo salvataggio (inizia adesso)
    DateTime lastSaveTime = DateTime.now();

    _secondlySaveTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        if (isTimerRunning()) {
          final now = DateTime.now();

          // ✅ CRITICO: Calcola SOLO i secondi dall'ultimo salvataggio
          // NON dal timer_start_time!
          final newSeconds = now.difference(lastSaveTime).inSeconds;

          if (newSeconds > 0) {
            // ✅ Prendi il valore PRECEDENTE
            final previousDaily = getDailySeconds();

            // ✅ Aggiungi SOLO i nuovi secondi
            final newTotal = previousDaily + newSeconds;

            print('💾 Save: previousDaily=$previousDaily + newSeconds=$newSeconds = $newTotal');

            await _prefs.setInt('daily_seconds_today', newTotal);

            // ✅ Aggiorna il tempo dell'ultimo salvataggio
            lastSaveTime = now;
          }
        }
      } catch (e) {
        print('❌ Errore nel salvataggio ogni secondo: $e');
      }
    });

    print('⏱️ Salvataggio ogni secondo AVVIATO');
  }

  /// ✅ QUANDO PREMI PAUSA
  /// Calcola l'ultimo valore, lo salva e ferma il timer
  Future<void> pauseTimer() async {
    try {
      _secondlySaveTimer?.cancel();

      final startTime = getTimerStartTime();
      if (startTime != null) {
        // ✅ Calcola i secondi trascorsi
        final elapsedNow = DateTime.now().difference(startTime).inSeconds;
        final currentDaily = getDailySeconds();

        // ✅ Somma e salva il totale FINALE
        final finalTotal = currentDaily + elapsedNow;
        await _prefs.setInt('daily_seconds_today', finalTotal);

        print('⏸️ PAUSA: Salvati $finalTotal secondi');
      }

      // Pulisci lo state
      await _prefs.remove('timer_start_time');
      await _prefs.setBool('timer_is_running', false);

      print('⏸️ Timer in PAUSA');
    } catch (e) {
      print('❌ Errore nella pausa: $e');
    }
  }

  /// ✅ QUANDO PREMI RESUME
  /// Ricomincia il timer da qui
  Future<void> resumeTimer() async {
    try {
      // I daily_seconds rimangono quelli salvati, non si resettano!
      final now = DateTime.now();
      await _prefs.setString('timer_start_time', now.toIso8601String());
      await _prefs.setBool('timer_is_running', true);

      print('▶️ Timer RESUMED');

      // Riavvia il salvataggio ogni secondo
      _startSecondlySave();
    } catch (e) {
      print('❌ Errore nel resume: $e');
    }
  }

  /// ✅ Recupera i secondi TOTALI per oggi
  int getDailySeconds() {
    try {
      return _prefs.getInt('daily_seconds_today') ?? 0;
    } catch (e) {
      print('❌ Errore getDailySeconds: $e');
      return 0;
    }
  }

  /// ✅ Salva i secondi (usato solo al reset di mezzanotte)
  Future<void> saveDailySeconds(int seconds) async {
    try {
      await _prefs.setInt('daily_seconds_today', seconds);
      print('✅ daily_seconds salvati: $seconds');
    } catch (e) {
      print('❌ Errore nel saveDailySeconds: $e');
    }
  }

  /// ✅ NUOVO: Aggiunge secondi al totale (usato quando l'app si chiude)
  Future<void> addDailySeconds(int seconds) async {
    try {
      final current = getDailySeconds();
      final newTotal = current + seconds;
      await _prefs.setInt('daily_seconds_today', newTotal);
      print('✅ Aggiunti $seconds secondi: $current + $seconds = $newTotal');
    } catch (e) {
      print('❌ Errore nell\'aggiungere daily_seconds: $e');
    }
  }

  /// ✅ Recupera l'ora di inizio del timer
  DateTime? getTimerStartTime() {
    try {
      final startTimeStr = _prefs.getString('timer_start_time');
      if (startTimeStr == null) return null;
      return DateTime.parse(startTimeStr);
    } catch (e) {
      print('❌ Errore nel getTimerStartTime: $e');
      return null;
    }
  }

  /// ✅ Recupera lo stato: il timer è running?
  bool isTimerRunning() {
    try {
      return _prefs.getBool('timer_is_running') ?? false;
    } catch (e) {
      print('❌ Errore nel isTimerRunning: $e');
      return false;
    }
  }

  /// ✅ Recupera i secondi TOTALI attuali (per la UI)
  int getTotalSeconds() {
    try {
      return getDailySeconds();
    } catch (e) {
      print('❌ Errore nel getTotalSeconds: $e');
      return getDailySeconds();
    }
  }

  /// ✅ Verifica il cambio di giorno
  Future<bool> checkDayChanged() async {
    try {
      final lastCheckStr = _prefs.getString('last_day_check');
      final now = DateTime.now();
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      if (lastCheckStr != today) {
        print('🌙 CAMBIO GIORNO: era $lastCheckStr, oggi è $today');

        await _prefs.setString('last_day_check', today);
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Errore nel checkDayChanged: $e');
      return false;
    }
  }

  /// ✅ RESET PER NUOVO GIORNO (chiamato a mezzanotte)
  Future<void> resetForNewDay() async {
    try {
      _secondlySaveTimer?.cancel();

      final totalSeconds = getDailySeconds();
      final wasRunning = isTimerRunning();

      print('🌙 RESET PER NUOVO GIORNO:');
      print('   - daily_seconds: $totalSeconds');
      print('   - timer_is_running: $wasRunning');

      // I dati vengono salvati nel DB PRIMA di questo reset

      await _prefs.remove('timer_start_time');
      await _prefs.setInt('daily_seconds_today', 0);
      await _prefs.setBool('timer_is_running', false);

      print('✅ Timer azzerato per nuovo giorno');
    } catch (e) {
      print('❌ Errore nel resetForNewDay: $e');
    }
  }

  /// ✅ Se il timer era RUNNING prima di mezzanotte, lo riavvia
  Future<void> restartTimerForNewDay(bool wasRunning) async {
    try {
      if (wasRunning) {
        print('↪️ Timer era RUNNING, lo riavvio per il nuovo giorno');
        await saveTimerStart();
      }
    } catch (e) {
      print('❌ Errore nel restartTimerForNewDay: $e');
    }
  }

  /// ✅ Salva lo stato del reminder countdown
  Future<void> saveReminderState({
    required int minutesRemaining,
    required bool isActive,
  }) async {
    try {
      if (isActive) {
        await _prefs.setInt('reminder_start_time_ms', DateTime.now().millisecondsSinceEpoch);
        await _prefs.setInt('reminder_duration_minutes', minutesRemaining);
        await _prefs.setBool('reminder_active', true);
        print('⏰ Reminder salvato: $minutesRemaining minuti');
      } else {
        await _prefs.setBool('reminder_active', false);
        print('⏰ Reminder disattivato');
      }
    } catch (e) {
      print('❌ Errore nel saveReminderState: $e');
    }
  }

  /// ✅ Recupera i minuti rimanenti del reminder
  int? getReminderMinutesRemaining() {
    try {
      if (!(_prefs.getBool('reminder_active') ?? false)) {
        return null;
      }

      final startTimeMs = _prefs.getInt('reminder_start_time_ms');
      final durationMinutes = _prefs.getInt('reminder_duration_minutes');

      if (startTimeMs == null || durationMinutes == null) return null;

      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsedMs = now - startTimeMs;
      final elapsedMinutes = elapsedMs ~/ (60 * 1000);
      final remainingMinutes = durationMinutes - elapsedMinutes;

      if (remainingMinutes <= 0) {
        return null;
      }

      return remainingMinutes;
    } catch (e) {
      print('❌ Errore nel getReminderMinutesRemaining: $e');
      return null;
    }
  }

  /// ✅ Recupera lo stato del timer
  Map<String, dynamic> getTimerState() {
    try {
      return {
        'isRunning': isTimerRunning(),
        'totalSeconds': getTotalSeconds(),
        'dailySeconds': getDailySeconds(),
        'startTime': isTimerRunning() ? getTimerStartTime()?.toIso8601String() : null,
      };
    } catch (e) {
      print('❌ Errore nel getTimerState: $e');
      return {
        'isRunning': false,
        'totalSeconds': 0,
        'dailySeconds': 0,
        'startTime': null,
      };
    }
  }

  /// ✅ Pulisci
  Future<void> clearAll() async {
    try {
      _secondlySaveTimer?.cancel();
      await _prefs.clear();
      print('✅ BackgroundTimerService clearAll()');
    } catch (e) {
      print('❌ Errore nel clearAll: $e');
    }
  }

  void dispose() {
    _secondlySaveTimer?.cancel();
    print('✅ BackgroundTimerService disposed');
  }

  @override
  String toString() => 'BackgroundTimerService(initialized: $_isInitialized)';
}