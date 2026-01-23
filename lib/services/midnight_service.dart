import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import 'background_timer_service.dart';
import 'notification_service.dart';
import 'timer_service.dart';

/// 🌙 SERVIZIO CENTRALIZZATO PER MEZZANOTTE - VERSIONE SEMPLIFICATA
/// Gestisce TUTTE le operazioni che devono succedere a mezzanotte:
/// 1. Salva i dati giornalieri nel DB
/// 2. Resetta il timer
/// 3. Incrementa lo stage se necessario
/// 4. Invalida i provider Riverpod
/// 5. Invia notifica
class MidnightService {
  static final MidnightService _instance = MidnightService._internal();

  late SharedPreferences _prefs;
  late DatabaseService _db;
  late BackgroundTimerService _bgTimer;
  late NotificationService _notificationService;
  late TimerService _timerService;

  bool _isInitialized = false;
  Timer? _midnightCheckTimer;

  factory MidnightService() {
    return _instance;
  }

  MidnightService._internal();

  bool get isInitialized => _isInitialized;

  /// ✅ Inizializza il servizio
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _db = DatabaseService();
      _bgTimer = BackgroundTimerService();
      _notificationService = NotificationService();
      _timerService = TimerService();

      if (!_db.isInitialized) {
        await _db.initialize();
      }

      if (!_bgTimer.isInitialized) {
        await _bgTimer.initialize();
      }

      _isInitialized = true;
      print('✅ MidnightService inizializzato');

      _startMidnightCheck();
    } catch (e) {
      print('❌ Errore nell\'inizializzazione MidnightService: $e');
      rethrow;
    }
  }

  /// ✅ Avvia il monitoraggio di mezzanotte
  void _startMidnightCheck() {
    _midnightCheckTimer?.cancel();

    _midnightCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      try {
        final dayChanged = await _bgTimer.checkDayChanged();
        if (dayChanged) {
          print('🌙 CAMBIO GIORNO RILEVATO! Esecuzione operazioni mezzanotte...');
          await executeMidnightOperations();
        }
      } catch (e) {
        print('❌ Errore nel check di mezzanotte: $e');
      }
    });

    print('⏰ Monitoraggio mezzanotte avviato (check ogni minuto)');
  }

  /// 🌙 OPERAZIONI CRITICHE A MEZZANOTTE
  /// FLUSSO LOGICO:
  /// 1. LEGGI daily_seconds PRIMA di qualsiasi reset!
  /// 2. Salva dati della giornata nel DB
  /// 3. Resetta il timer
  /// 4. Incrementa stage se necessario
  /// 5. Invalida i provider Riverpod
  /// 6. Invia notifica
  Future<void> executeMidnightOperations() async {
    try {
      print('\n' + '='*70);
      print('🌙 MEZZANOTTE - OPERAZIONI CRITICHE');
      print('='*70);

      // ✅ FIX CRITICO: Leggi daily_seconds PRIMA di resettare il timer!
      final dailySecondsBeforeReset = _bgTimer.getDailySeconds();
      final timerWasRunning = _bgTimer.isTimerRunning();

      print('\n⚠️ BACKUP DATI PRIMA DI RESET:');
      print('   - daily_seconds: $dailySecondsBeforeReset');
      print('   - timer_is_running: $timerWasRunning');

      // ✅ STEP 1: Salva i dati giornalieri nel database
      await _saveDailyDataToDatabase(dailySecondsBeforeReset);
      print('\n📊 STEP 1: Salvataggio dati giornalieri nel DB... ✅');

      // ✅ STEP 2: Resetta il timer
      await _resetTimer(timerWasRunning);
      print('\n⏱️ STEP 2: Reset timer... ✅');

      // ✅ STEP 3: Incrementa stage se è ora
      await _checkAndIncrementStage();
      print('\n📅 STEP 3: Controllo stage... ✅');

      // ✅ STEP 4: Aggiorna i contatori
      await _updateCounters();
      print('\n📱 STEP 4: Aggiornamento contatori... ✅');

      // ✅ STEP 5: Aggiorna le statistiche
      await _updateStatistics();
      print('\n📈 STEP 5: Aggiornamento statistiche... ✅');

      // ✅ STEP 6: Invalida i provider Riverpod
      await _invalidateProviders();
      print('\n🔄 STEP 6: Invalidazione provider... ✅');

      // ✅ STEP 7: Invia notifica
      await _sendMidnightNotification(dailySecondsBeforeReset);
      print('\n📢 STEP 7: Notifica inviata... ✅');

      print('\n' + '='*70);
      print('✅ MEZZANOTTE - OPERAZIONI COMPLETATE!');
      print('='*70 + '\n');
    } catch (e) {
      print('❌ ERRORE CRITICO nelle operazioni di mezzanotte: $e');
      await _notificationService.sendInstantReminder(
        title: '⚠️ SmileLine Avviso',
        body: 'Errore nel salvataggio dati di oggi. Per favore contatta il supporto.',
      );
      rethrow;
    }
  }

  /// ✅ STEP 1: Salva i dati giornalieri nel database
  Future<void> _saveDailyDataToDatabase(int dailySeconds) async {
    try {
      print('\n💾 Salvataggio dati in database...');

      final user = _db.getCurrentUser();
      if (user == null) {
        print('⚠️ Nessun utente trovato - Skip');
        return;
      }

      final treatmentPlanId = user.currentTreatmentPlanId;
      if (treatmentPlanId == null || treatmentPlanId.isEmpty) {
        print('⚠️ Nessun treatment plan ID trovato - Skip');
        return;
      }

      final treatmentPlan = _db.getTreatmentPlan(treatmentPlanId);
      if (treatmentPlan == null) {
        print('⚠️ Nessun piano di trattamento trovato - Skip');
        return;
      }

      final targetHours = treatmentPlan.dailyWearingHours;
      final hours = dailySeconds ~/ 3600;
      final minutes = (dailySeconds % 3600) ~/ 60;
      final compliance = ((dailySeconds / (targetHours * 3600)) * 100).clamp(0.0, 100.0);

      // ✅ Calcola la data del GIORNO PRECEDENTE
      final now = DateTime.now();
      final yesterdayDate = DateTime(now.year, now.month, now.day - 1);

      await _db.saveDailyUsage(
        date: yesterdayDate,
        totalSeconds: dailySeconds,
        treatmentPlanId: treatmentPlanId,
        currentStageId: '',
        currentStageNumber: treatmentPlan.currentStage.toString(),
        currentStageType: _getStageType(treatmentPlan.currentStage, treatmentPlan.stageADays),
        targetHours: targetHours,
      );

      final savedTracking = _db.getDailyTrackingByDate(yesterdayDate);

      if (savedTracking != null) {
        print('✅ Dati salvati nel DB con successo!');
        print('   📊 Utilizzo: $hours ore e $minutes minuti ($dailySeconds secondi)');
        print('   🎯 Target: ${targetHours}h');
        print('   📈 Compliance: ${compliance.toStringAsFixed(1)}%');
        print('   📅 Data: ${savedTracking.date.toIso8601String()}');
        print('   🏷️ Stage: ${savedTracking.currentStageNumber}-${savedTracking.currentStageType}');
      } else {
        print('❌ ATTENZIONE: Dati non trovati dopo il salvataggio!');
      }
    } catch (e) {
      print('❌ Errore nel salvataggio dati giornalieri: $e');
      rethrow;
    }
  }

  /// ✅ STEP 2: Resetta il timer per il nuovo giorno
  Future<void> _resetTimer(bool wasRunning) async {
    try {
      print('\n🔄 Azzeramento timer...');

      await _bgTimer.resetForNewDay();

      print('✅ Timer azzerato');
      print('   - daily_seconds: 0 ✅');
      print('   - timer_is_running: false ✅');
      print('   - timer_start_time: removed ✅');

      // Se il timer era RUNNING prima di mezzanotte, riavvialo
      if (wasRunning) {
        print('\n   ⚠️ Il timer era RUNNING prima di mezzanotte');
        print('   ↪ Riavviandolo per il nuovo giorno...');

        await _bgTimer.restartTimerForNewDay(true);
        print('   ✅ Timer riavviato per nuovo giorno');
      }
    } catch (e) {
      print('❌ Errore nell\'azzeramento del timer: $e');
      rethrow;
    }
  }

  /// ✅ STEP 3: Incrementa lo stage se "giorni al cambio" = 0
  Future<void> _checkAndIncrementStage() async {
    try {
      print('\n📅 Verifica se incrementare stage...');

      final user = _db.getCurrentUser();
      if (user == null) {
        print('⚠️ Nessun utente trovato - Skip');
        return;
      }

      final treatmentPlanId = user.currentTreatmentPlanId;
      if (treatmentPlanId == null || treatmentPlanId.isEmpty) {
        print('⚠️ Nessun treatment plan ID trovato - Skip');
        return;
      }

      final treatment = _db.getTreatmentPlan(treatmentPlanId);
      if (treatment == null) {
        print('⚠️ Nessun piano di trattamento trovato - Skip');
        return;
      }

      final daysRemaining = treatment.getStageRemainingDays();

      print('   📅 Stage attuale: ${treatment.currentStage}');
      print('   📅 Giorni rimanenti nello stage: $daysRemaining');

      if (daysRemaining == 0) {
        print('   ✅ STAGE COMPLETATO! È ora di cambiare gli allineatori!');

        final nextStage = treatment.currentStage + 1;
        print('   ↪ Stage: ${treatment.currentStage} → $nextStage');

        if (nextStage > treatment.totalStages) {
          print('   🎉 TRATTAMENTO COMPLETATO!');
          print('   - Stage attuali: $nextStage');
          print('   - Stage totali: ${treatment.totalStages}');

          final inactiveTreatment = treatment.copyWith(
            isActive: false,
            currentStage: nextStage,
          );
          await _db.updateTreatmentPlan(inactiveTreatment);

          await _notificationService.sendInstantReminder(
            title: '🎉 Trattamento Completato!',
            body: 'Complimenti! Hai completato tutto il tuo trattamento!\n'
                'Contatta il tuo ortodontista per i prossimi passi.',
          );

          print('✅ Trattamento disattivato e marcato come completato');
        } else {
          final updatedTreatment = treatment.copyWith(
            currentStage: nextStage,
          );
          await _db.updateTreatmentPlan(updatedTreatment);

          print('✅ Stage aggiornato nel database');

          await _notificationService.sendInstantReminder(
            title: '🦷 È ora di cambiare gli allineatori!',
            body: 'Lo stage ${treatment.currentStage} è completato.\n'
                'Cambia gli allineatori per il stage $nextStage.\n'
                'Ricorda: Massaggia le gengive durante il cambio!',
          );
        }
      } else {
        print('   ℹ️ Stage non ancora completato');
        print('      Rimanenti: $daysRemaining giorni');
      }
    } catch (e) {
      print('❌ Errore nel controllo dello stage: $e');
      rethrow;
    }
  }

  /// ✅ STEP 4: Aggiorna i contatori
  Future<void> _updateCounters() async {
    try {
      print('\n📱 Aggiornamento contatori (home screen)...');

      final user = _db.getCurrentUser();
      if (user == null) {
        print('⚠️ Nessun utente trovato - Skip aggiornamento contatori');
        return;
      }

      final treatmentPlanId = user.currentTreatmentPlanId;
      if (treatmentPlanId == null) {
        print('⚠️ Nessun treatment plan ID - Skip aggiornamento contatori');
        return;
      }

      final treatment = _db.getTreatmentPlan(treatmentPlanId);
      if (treatment == null) {
        print('⚠️ Nessun piano trovato - Skip aggiornamento contatori');
        return;
      }

      final currentStageDay = treatment.getStageCurrentDayNumber();
      final stageDayLength = treatment.getStageDayLength();
      final daysToSwitch = treatment.getStageRemainingDays();

      print('   📊 Nuovi valori calcolati:');
      print('      - Step attuale: ${treatment.currentStage}');
      print('      - Giorno dello step: $currentStageDay / $stageDayLength');
      print('      - Giorni al cambio: $daysToSwitch');

      await _prefs.setBool('new_day_flag', true);

      Future.delayed(const Duration(seconds: 1), () {
        _prefs.setBool('new_day_flag', false);
      });

      print('✅ Contatori segnalati per aggiornamento');
    } catch (e) {
      print('❌ Errore nell\'aggiornamento contatori: $e');
      rethrow;
    }
  }

  /// ✅ STEP 5: Aggiorna le statistiche
  Future<void> _updateStatistics() async {
    try {
      print('\n📈 Aggiornamento statistiche (dashboard)...');

      final user = _db.getCurrentUser();
      if (user == null) {
        print('⚠️ Nessun utente trovato - Skip aggiornamento statistiche');
        return;
      }

      final treatmentPlanId = user.currentTreatmentPlanId;
      if (treatmentPlanId == null) {
        print('⚠️ Nessun treatment plan ID - Skip aggiornamento statistiche');
        return;
      }

      final allTracking = _db.getTrackingByTreatmentPlan(treatmentPlanId);

      int totalSessions = 0;
      int totalHours = 0;
      int totalMinutes = 0;
      double totalCompliance = 0.0;
      int daysWithTargetReached = 0;

      for (var tracking in allTracking) {
        totalSessions += tracking.totalSessions;
        totalHours += tracking.wearingHours;
        totalMinutes += tracking.wearingMinutes;
        totalCompliance += tracking.compliancePercentage;
        if (tracking.isMeetingTarget) {
          daysWithTargetReached++;
        }
      }

      final averageCompliance = allTracking.isEmpty
          ? 0.0
          : totalCompliance / allTracking.length;

      print('✅ Statistiche ricalcolate');
      print('   📊 Sessioni totali: $totalSessions');
      print('   ⏱️ Ore totali: $totalHours');
      print('   📈 Conformità media: ${averageCompliance.toStringAsFixed(1)}%');
      print('   🎯 Giorni con target raggiunto: $daysWithTargetReached');

      await _prefs.setInt('stats_total_sessions', totalSessions);
      await _prefs.setInt('stats_total_hours', totalHours);
      await _prefs.setDouble('stats_avg_compliance', averageCompliance);
    } catch (e) {
      print('❌ Errore nell\'aggiornamento statistiche: $e');
      rethrow;
    }
  }

  /// ✅ STEP 6: Invalida i provider Riverpod
  Future<void> _invalidateProviders() async {
    try {
      print('\n🔄 Invalidazione provider Riverpod via SharedPreferences...');

      // Setta il flag per notificare HomeScreen
      await _prefs.setInt('midnight_update_timestamp', DateTime.now().millisecondsSinceEpoch);
      await _prefs.setBool('midnight_data_updated', true);

      print('   ✅ SharedPreferences aggiornate con signal di update');
      print('   ✅ HomeScreen riceverà il segnale tra pochi secondi');

      // Reset il flag dopo 2 secondi
      await Future.delayed(const Duration(seconds: 2));
      await _prefs.setBool('midnight_data_updated', false);

      print('✅ Invalidazione provider completata');
    } catch (e) {
      print('⚠️ Errore nell\'invalidazione provider (non critico): $e');
    }
  }

  /// ✅ STEP 7: Invia notifica di mezzanotte
  Future<void> _sendMidnightNotification(int yesterdayUsage) async {
    try {
      print('\n📢 Invio notifica...');

      final yesterdayHours = yesterdayUsage ~/ 3600;
      final yesterdayMinutes = (yesterdayUsage % 3600) ~/ 60;

      final user = _db.getCurrentUser();
      final treatmentPlanId = user?.currentTreatmentPlanId;
      final treatment = treatmentPlanId != null
          ? _db.getTreatmentPlan(treatmentPlanId)
          : null;

      final targetHours = treatment?.dailyWearingHours ?? 22;

      String body = '';

      if (yesterdayUsage == 0) {
        body = '⚠️ Nessun utilizzo registrato ieri. Ricordati di indossare i tuoi allineatori!';
      } else if (yesterdayHours >= targetHours) {
        body = '🎉 Perfetto! Ieri hai indossato gli allineatori per $yesterdayHours ore!';
      } else {
        body = '💪 Ieri: ${yesterdayHours}h ${yesterdayMinutes}m (target: ${targetHours}h)';
      }

      print('   📬 Messaggio: $body');

      await _notificationService.sendInstantReminder(
        title: '🌙 Buongiorno!',
        body: body,
      );

      print('✅ Notifica inviata con successo');
    } catch (e) {
      print('⚠️ Errore nell\'invio notifica (non critico): $e');
    }
  }

  /// ✅ Determina il tipo di stage (A o B)
  String _getStageType(int currentStage, int stageADays) {
    final today = DateTime.now();
    final treatment = _db.getAllTreatmentPlans().isNotEmpty
        ? _db.getAllTreatmentPlans().first
        : null;

    if (treatment == null) return 'A';

    final stageDayStart = treatment.startDate.add(
      Duration(
        days: (currentStage - 1) *
            (treatment.stageADays + treatment.stageBDays),
      ),
    );

    final dayInStage = today.difference(stageDayStart).inDays;

    return dayInStage < stageADays ? 'A' : 'B';
  }

  void dispose() {
    _midnightCheckTimer?.cancel();
    print('✅ MidnightService dispose');
  }

  @override
  String toString() => 'MidnightService(initialized: $_isInitialized)';
}