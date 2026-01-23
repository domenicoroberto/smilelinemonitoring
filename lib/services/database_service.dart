import 'package:hive_flutter/hive_flutter.dart';
import '../models/treatment_plan.dart';
import '../models/daily_tracking.dart';
import '../models/user.dart';

class DatabaseService {
  static const String treatmentPlanBoxKey = 'treatment_plans';
  static const String dailyTrackingBoxKey = 'daily_tracking';
  static const String userBoxKey = 'user';

  static final DatabaseService _instance = DatabaseService._internal();

  late Box<Map> _treatmentPlanBox;
  late Box<Map> _dailyTrackingBox;
  late Box<Map> _userBox;

  bool _isInitialized = false;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  /// Inizializza il database
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();

      _treatmentPlanBox = await Hive.openBox<Map>(treatmentPlanBoxKey);
      _dailyTrackingBox = await Hive.openBox<Map>(dailyTrackingBoxKey);
      _userBox = await Hive.openBox<Map>(userBoxKey);

      _isInitialized = true;
      print('✅ Database inizializzato con successo');
    } catch (e) {
      print('❌ Errore nell\'inizializzazione del database: $e');
      rethrow;
    }
  }

  /// Verifica se il database è inizializzato
  bool get isInitialized => _isInitialized;

  // ============ TREATMENT PLAN OPERATIONS ============

  /// Salva un piano di trattamento
  Future<void> saveTreatmentPlan(TreatmentPlan plan) async {
    try {
      await _treatmentPlanBox.put(plan.id, plan.toJson());
      print('✅ Piano di trattamento salvato: ${plan.id}');
    } catch (e) {
      print('❌ Errore nel salvataggio del piano: $e');
      rethrow;
    }
  }

  /// Recupera un piano di trattamento per ID
  TreatmentPlan? getTreatmentPlan(String id) {
    try {
      final data = _treatmentPlanBox.get(id);
      if (data != null) {
        return TreatmentPlan.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } catch (e) {
      print('❌ Errore nel recupero del piano: $e');
      return null;
    }
  }

  /// Recupera tutti i piani di trattamento
  List<TreatmentPlan> getAllTreatmentPlans() {
    try {
      return _treatmentPlanBox.values
          .map((e) => TreatmentPlan.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print('❌ Errore nel recupero dei piani: $e');
      return [];
    }
  }

  /// Cancella un piano di trattamento
  Future<void> deleteTreatmentPlan(String id) async {
    try {
      await _treatmentPlanBox.delete(id);
      print('✅ Piano di trattamento eliminato: $id');
    } catch (e) {
      print('❌ Errore nell\'eliminazione del piano: $e');
      rethrow;
    }
  }

  /// Aggiorna un piano di trattamento
  Future<void> updateTreatmentPlan(TreatmentPlan plan) async {
    try {
      await _treatmentPlanBox.put(plan.id, plan.toJson());
      print('✅ Piano di trattamento aggiornato: ${plan.id}');
    } catch (e) {
      print('❌ Errore nell\'aggiornamento del piano: $e');
      rethrow;
    }
  }

  // ============ DAILY TRACKING OPERATIONS ============

  /// Salva il tracking giornaliero
  Future<void> saveDailyTracking(DailyTracking tracking) async {
    try {
      await _dailyTrackingBox.put(tracking.id, tracking.toJson());
      print('✅ Tracking giornaliero salvato: ${tracking.id}');
    } catch (e) {
      print('❌ Errore nel salvataggio del tracking: $e');
      rethrow;
    }
  }

  /// ✅ NUOVO: Salva l'utilizzo giornaliero a mezzanotte
  // ✅ Aggiungi questo metodo al DatabaseService

  /// ✅ NUOVO: Salva l'utilizzo giornaliero a mezzanotte
  Future<void> saveDailyUsage({
    required DateTime date,
    required int totalSeconds,
    required String treatmentPlanId,
    String? currentStageId,
    String? currentStageNumber,
    String? currentStageType,
    int? targetHours,
  }) async {
    try {
      // Converti secondi in ore e minuti
      final totalMinutes = totalSeconds ~/ 60;
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;

      // Crea il tracking giornaliero
      final tracking = DailyTracking(
        treatmentPlanId: treatmentPlanId,
        currentStageId: currentStageId ?? '',
        date: date,
        wearingHours: hours,
        wearingMinutes: minutes,
        targetHours: targetHours ?? 22,
        currentStageNumber: currentStageNumber ?? '0',
        currentStageType: currentStageType ?? 'A',
        sessions: [],  // Vuoto, solo statistiche giornaliere
        createdAt: date,
        updatedAt: DateTime.now(),
      );

      // Salva nel database
      await saveDailyTracking(tracking);

      print('🌙 STATISTICHE SALVATE PER ${date.day}/${date.month}/${date.year}');
      print('   ✅ Utilizzo: $hours ore e $minutes minuti ($totalSeconds secondi)');
      print('   ✅ Target: ${tracking.targetHours}h');
      print('   ✅ Compliance: ${tracking.compliancePercentage.toStringAsFixed(1)}%');
      print('   ✅ Stage: ${tracking.currentStageNumber}-${tracking.currentStageType}');
    } catch (e) {
      print('❌ Errore nel salvataggio dell\'utilizzo giornaliero: $e');
      rethrow;
    }
  }

  /// Recupera il tracking per una data specifica
  DailyTracking? getDailyTrackingByDate(DateTime date) {
    try {
      final targetDate =
      DateTime(date.year, date.month, date.day); // Normalizza la data

      for (var value in _dailyTrackingBox.values) {
        final tracking =
        DailyTracking.fromJson(Map<String, dynamic>.from(value));
        final trackingDate =
        DateTime(tracking.date.year, tracking.date.month, tracking.date.day);

        if (trackingDate == targetDate) {
          return tracking;
        }
      }
      return null;
    } catch (e) {
      print('❌ Errore nel recupero del tracking: $e');
      return null;
    }
  }

  /// Recupera il tracking per un piano di trattamento
  List<DailyTracking> getTrackingByTreatmentPlan(String treatmentPlanId) {
    try {
      return _dailyTrackingBox.values
          .where((e) =>
      Map<String, dynamic>.from(e)['treatmentPlanId'] ==
          treatmentPlanId)
          .map((e) => DailyTracking.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print('❌ Errore nel recupero del tracking: $e');
      return [];
    }
  }

  /// Recupera il tracking tra due date
  List<DailyTracking> getTrackingBetweenDates(
      DateTime startDate, DateTime endDate) {
    try {
      return _dailyTrackingBox.values
          .map((e) => DailyTracking.fromJson(Map<String, dynamic>.from(e)))
          .where((t) =>
      t.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          t.date.isBefore(endDate.add(const Duration(days: 1))))
          .toList();
    } catch (e) {
      print('❌ Errore nel recupero del tracking: $e');
      return [];
    }
  }

  /// Cancella il tracking
  Future<void> deleteDailyTracking(String id) async {
    try {
      await _dailyTrackingBox.delete(id);
      print('✅ Tracking eliminato: $id');
    } catch (e) {
      print('❌ Errore nell\'eliminazione del tracking: $e');
      rethrow;
    }
  }

  /// Aggiorna il tracking
  Future<void> updateDailyTracking(DailyTracking tracking) async {
    try {
      await _dailyTrackingBox.put(tracking.id, tracking.toJson());
      print('✅ Tracking aggiornato: ${tracking.id}');
    } catch (e) {
      print('❌ Errore nell\'aggiornamento del tracking: $e');
      rethrow;
    }
  }

  // ============ USER OPERATIONS ============

  /// Salva l'utente
  Future<void> saveUser(User user) async {
    try {
      await _userBox.put('current_user', user.toJson());
      print('✅ Utente salvato: ${user.id}');
    } catch (e) {
      print('❌ Errore nel salvataggio dell\'utente: $e');
      rethrow;
    }
  }

  /// Recupera l'utente corrente
  User? getCurrentUser() {
    try {
      final data = _userBox.get('current_user');
      if (data != null) {
        return User.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } catch (e) {
      print('❌ Errore nel recupero dell\'utente: $e');
      return null;
    }
  }

  /// Aggiorna l'utente
  Future<void> updateUser(User user) async {
    try {
      await _userBox.put('current_user', user.toJson());
      print('✅ Utente aggiornato: ${user.id}');
    } catch (e) {
      print('❌ Errore nell\'aggiornamento dell\'utente: $e');
      rethrow;
    }
  }

  /// Cancella l'utente
  Future<void> deleteUser() async {
    try {
      await _userBox.delete('current_user');
      print('✅ Utente eliminato');
    } catch (e) {
      print('❌ Errore nell\'eliminazione dell\'utente: $e');
      rethrow;
    }
  }

  // ============ UTILITY OPERATIONS ============

  /// Conta i piani di trattamento
  int countTreatmentPlans() => _treatmentPlanBox.length;

  /// Conta il tracking
  int countDailyTracking() => _dailyTrackingBox.length;

  /// Ottiene lo spazio occupato dal database
  Map<String, int> getDatabaseSize() {
    return {
      'treatment_plans': _treatmentPlanBox.length,
      'daily_tracking': _dailyTrackingBox.length,
      'user': _userBox.length,
      'total': _treatmentPlanBox.length +
          _dailyTrackingBox.length +
          _userBox.length,
    };
  }

  /// Pulisce tutti i dati
  Future<void> clearAll() async {
    try {
      await Future.wait([
        _treatmentPlanBox.clear(),
        _dailyTrackingBox.clear(),
        _userBox.clear(),
      ]);
      print('✅ Database pulito completamente');
    } catch (e) {
      print('❌ Errore nella pulizia del database: $e');
      rethrow;
    }
  }

  /// Chiude tutti i box
  Future<void> close() async {
    try {
      await Hive.close();
      _isInitialized = false;
      print('✅ Database chiuso');
    } catch (e) {
      print('❌ Errore nella chiusura del database: $e');
      rethrow;
    }
  }

  @override
  String toString() => 'DatabaseService($_isInitialized)';
}