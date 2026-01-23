import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

/// ✅ SINCRONIZZAZIONE INTELLIGENTE AL RIAVVIO
/// Traccia quando l'app è stata chiusa e come era lo stato
class SmartTimerSync {
  late SharedPreferences _prefs;
  late DatabaseService _db;
  bool _isInitialized = false;

  SmartTimerSync();

  /// ✅ OBBLIGATORIO: Inizializza il servizio
  /// DEVE essere chiamato in HomeScreen.initState() PRIMA di qualunque altro metodo
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _db = DatabaseService();
      if (!_db.isInitialized) {
        await _db.initialize();
      }
      _isInitialized = true;
      print('✅ SmartTimerSync inizializzato');
    } catch (e) {
      print('❌ Errore nell\'inizializzazione SmartTimerSync: $e');
      rethrow;
    }
  }

  /// ✅ SALVA LO STATO QUANDO L'APP SI CHIUDE
  /// ⚠️ CRITICO: Legge i dati DIRETTAMENTE da SharedPreferences
  /// NON li passa come parametri (potrebbero arrivare non sincronizzati)
  Future<void> saveCloseState() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final now = DateTime.now();
      final timerIsRunningValue = _prefs.getBool('timer_is_running');
      final isRunning = timerIsRunningValue ?? false;
      final currentDaily = _prefs.getInt('daily_seconds_today') ?? 0;
      final timerStartTime = _prefs.getString('timer_start_time');

      print('\n📴 SALVATAGGIO STATO CHIUSURA:');
      print('   - Ora: ${now.toIso8601String()}');
      print('   - Was Running: $isRunning');
      print('   - Daily Seconds: $currentDaily');
      print('   - Timer Start: $timerStartTime');

      // ✅ Salva TUTTO in modo sincrono (senza await)
      _prefs.setString('app_closed_at', now.toIso8601String());
      _prefs.setBool('was_running_on_close', isRunning);
      _prefs.setString('was_running_on_close_str', isRunning ? 'true' : 'false');
      _prefs.setInt('app_closed_daily_seconds', currentDaily);

      if (isRunning && timerStartTime != null && timerStartTime.isNotEmpty) {
        _prefs.setString('app_close_timer_start_time', timerStartTime);
      }

      print('✅ Stato salvato correttamente\n');
    } catch (e) {
      print('❌ Errore salvataggio stato chiusura: $e');
    }
  }

  /// ✅ SINCRONIZZAZIONE INTELLIGENTE AL RIAVVIO
  Future<Map<String, dynamic>> smartSyncOnReopen() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      print('\n' + '='*70);
      print('🔄 SINCRONIZZAZIONE INTELLIGENTE AL RIAVVIO');
      print('='*70);

      final now = DateTime.now();
      final closedAtStr = _prefs.getString('app_closed_at');
      final wasRunning = _prefs.getBool('was_running_on_close') ?? false;
      final currentDaily = _prefs.getInt('daily_seconds_today') ?? 0;

      print('\n📊 STATO ATTUALE:');
      print('   - Ora riavvio: ${now.toIso8601String()}');
      print('   - Era running: $wasRunning');
      print('   - Daily seconds: $currentDaily');

      // Se non c'è stato salvato, skip
      if (closedAtStr == null) {
        print('\n⭕ Nessuno stato salvato precedente');
        print('='*70 + '\n');
        return {'action': 'none'};
      }

      final closedAt = DateTime.parse(closedAtStr);
      print('   - Chiuso alle: ${closedAt.toIso8601String()}');

      // ✅ CALCOLO 1: Verificare se è cambiato il giorno
      final closedDay = DateTime(closedAt.year, closedAt.month, closedAt.day);
      final nowDay = DateTime(now.year, now.month, now.day);
      final dayChanged = closedDay != nowDay;

      print('\n🌙 ANALISI GIORNO:');
      print('   - Giorno chiusura: ${closedDay.toIso8601String().split('T')[0]}');
      print('   - Giorno riavvio: ${nowDay.toIso8601String().split('T')[0]}');
      print('   - È cambiato il giorno: $dayChanged');

      // ✅ CASO 1: ERA RUNNING E NON È CAMBIATO IL GIORNO
      if (wasRunning && !dayChanged) {
        print('\n✅ CASO 1: ERA RUNNING (STESSO GIORNO)');

        final timerStartStr = _prefs.getString('app_close_timer_start_time');
        if (timerStartStr != null && timerStartStr.isNotEmpty) {
          final timerStart = DateTime.parse(timerStartStr);

          // Calcola i secondi persi (da quando è stata chiusa a ora)
          final secondsLost = now.difference(closedAt).inSeconds;

          print('   - Secondi trascorsi in chiusura: $secondsLost');

          // Aggiorna il totale
          final newTotal = currentDaily + secondsLost;
          await _prefs.setInt('daily_seconds_today', newTotal);

          print('   - Daily seconds aggiornato: $currentDaily + $secondsLost = $newTotal');
          print('   - ✅ Timer continuerà a scorrere dal timer_start_time originale');

          print('\n' + '='*70 + '\n');

          return {
            'action': 'continue_running_same_day',
            'secondsLost': secondsLost,
            'totalSeconds': newTotal,
            'timerStartTime': timerStartStr,
          };
        }
      }

      // ✅ CASO 2: ERA RUNNING MA È CAMBIATO IL GIORNO (DOPO MEZZANOTTE)
      if (wasRunning && dayChanged) {
        print('\n✅ CASO 2: ERA RUNNING (GIORNO CAMBIATO - DOPO MEZZANOTTE)');

        final timerStartStr = _prefs.getString('app_close_timer_start_time');
        if (timerStartStr != null && timerStartStr.isNotEmpty) {
          final timerStart = DateTime.parse(timerStartStr);

          // Calcola i secondi fino a mezzanotte (giorno precedente)
          final midnight = DateTime(closedAt.year, closedAt.month, closedAt.day + 1);
          final secondsUntilMidnight = midnight.difference(timerStart).inSeconds;

          // Salva i secondi del giorno precedente
          final totalToPreviousDay = currentDaily + secondsUntilMidnight;

          // Recupera l'ID del piano di trattamento da SharedPreferences
          final treatmentPlanId = _prefs.getString('current_treatment_plan_id') ?? '';

          await _db.saveDailyUsage(
            date: closedDay,
            totalSeconds: totalToPreviousDay,
            treatmentPlanId: treatmentPlanId,
            targetHours: 22,
          );

          print('   - Secondi fino a mezzanotte: $secondsUntilMidnight');
          print('   - Salvati nel DB per ${closedDay.toIso8601String().split('T')[0]}: $totalToPreviousDay sec');

          // Ora calcola i secondi da mezzanotte a ora (nuovo giorno)
          final secondsFromMidnight = now.difference(midnight).inSeconds;
          await _prefs.setInt('daily_seconds_today', secondsFromMidnight);
          await _prefs.setString('timer_start_time', midnight.toIso8601String());

          print('   - Secondi da mezzanotte: $secondsFromMidnight');
          print('   - Daily seconds impostati a: $secondsFromMidnight');
          print('   - ✅ Timer riavviato da mezzanotte');

          print('\n' + '='*70 + '\n');

          return {
            'action': 'midnight_crossed',
            'secondsPreviousDay': totalToPreviousDay,
            'secondsCurrentDay': secondsFromMidnight,
            'timerStartTime': midnight.toIso8601String(),
          };
        }
      }

      // ✅ CASO 3: ERA PAUSED
      if (!wasRunning && !dayChanged) {
        print('\n✅ CASO 3: ERA PAUSED (STESSO GIORNO)');
        print('   - Daily seconds rimane: $currentDaily');
        print('   - Timer rimane FERMO');
        print('\n' + '='*70 + '\n');

        return {
          'action': 'paused_same_day',
          'totalSeconds': currentDaily,
        };
      }

      // ✅ CASO 4: ERA PAUSED MA È CAMBIATO IL GIORNO
      if (!wasRunning && dayChanged) {
        print('\n✅ CASO 4: ERA PAUSED (GIORNO CAMBIATO)');

        // Recupera l'ID del piano di trattamento
        final treatmentPlanId = _prefs.getString('current_treatment_plan_id') ?? '';

        // Salva il giorno precedente
        await _db.saveDailyUsage(
          date: closedDay,
          totalSeconds: currentDaily,
          treatmentPlanId: treatmentPlanId,
          targetHours: 22,
        );

        print('   - Salvati nel DB per ${closedDay.toIso8601String().split('T')[0]}: $currentDaily sec');
        print('   - Daily seconds resettato a: 0');
        print('   - Timer rimane FERMO');

        // Reset per nuovo giorno
        await _prefs.setInt('daily_seconds_today', 0);
        await _prefs.remove('timer_start_time');

        print('\n' + '='*70 + '\n');

        return {
          'action': 'paused_day_changed',
          'totalSecondsPreviousDay': currentDaily,
          'totalSeconds': 0,
        };
      }

      print('\n' + '='*70 + '\n');
      return {'action': 'none'};
    } catch (e) {
      print('❌ Errore sincronizzazione: $e');
      return {'action': 'error', 'error': e.toString()};
    }
  }

  /// ✅ Pulisci i dati di chiusura
  Future<void> clearCloseState() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      await _prefs.remove('app_closed_at');
      await _prefs.remove('was_running_on_close');
      await _prefs.remove('app_close_timer_start_time');
      await _prefs.remove('app_closed_daily_seconds');
      print('✅ Stato di chiusura pulito');
    } catch (e) {
      print('❌ Errore pulizia stato: $e');
    }
  }

  void dispose() {
    print('✅ SmartTimerSync disposed');
  }

  @override
  String toString() => 'SmartTimerSync(initialized: $_isInitialized)';
}