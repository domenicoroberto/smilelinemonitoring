import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/treatment_plan.dart';
import '../models/aligner_stage.dart';
import '../services/database_service.dart';
import '../services/database_service.dart';

/// Notifier per la gestione dello stato del piano di trattamento
class TreatmentPlanNotifier extends StateNotifier<TreatmentPlan?> {
  final DatabaseService _db = DatabaseService();

  TreatmentPlanNotifier() : super(null);

  /// Carica il piano di trattamento corrente
  Future<void> loadTreatmentPlan(String planId) async {
    try {
      final plan = _db.getTreatmentPlan(planId);
      state = plan;
      print('✅ Piano di trattamento caricato: ${plan?.id}');
    } catch (e) {
      print('❌ Errore nel caricamento del piano: $e');
      state = null;
    }
  }

  /// Crea un nuovo piano di trattamento
  Future<void> createTreatmentPlan({
    required int totalStages,
    required int stageADays,
    required int stageBDays,
    required int dailyWearingHours,
    required DateTime startDate,
    String? notes,
  }) async {
    try {
      final newPlan = TreatmentPlan(
        totalStages: totalStages,
        stageADays: stageADays,
        stageBDays: stageBDays,
        dailyWearingHours: dailyWearingHours,
        startDate: startDate,
        notes: notes,
      );

      await _db.saveTreatmentPlan(newPlan);
      state = newPlan;
      print('✅ Nuovo piano creato: ${newPlan.id}');
    } catch (e) {
      print('❌ Errore nella creazione del piano: $e');
      rethrow;
    }
  }

  /// Aggiorna il piano di trattamento
  Future<void> updateTreatmentPlan({
    String? notes,
    bool? isActive,
  }) async {
    try {
      if (state == null) throw Exception('Nessun piano di trattamento caricato');

      final updatedPlan = state!.copyWith(
        notes: notes ?? state!.notes,
        isActive: isActive ?? state!.isActive,
      );

      await _db.updateTreatmentPlan(updatedPlan);
      state = updatedPlan;
      print('✅ Piano aggiornato: ${updatedPlan.id}');
    } catch (e) {
      print('❌ Errore nell\'aggiornamento del piano: $e');
      rethrow;
    }
  }

  /// Elimina il piano di trattamento
  Future<void> deleteTreatmentPlan(String planId) async {
    try {
      await _db.deleteTreatmentPlan(planId);
      state = null;
      print('✅ Piano eliminato: $planId');
    } catch (e) {
      print('❌ Errore nell\'eliminazione del piano: $e');
      rethrow;
    }
  }

  /// Aggiorna le note del piano
  Future<void> updateNotes(String notes) async {
    try {
      if (state == null) throw Exception('Nessun piano caricato');

      final updated = state!.copyWith(notes: notes);
      await _db.updateTreatmentPlan(updated);
      state = updated;
      print('✅ Note aggiornate');
    } catch (e) {
      print('❌ Errore nell\'aggiornamento delle note: $e');
      rethrow;
    }
  }

  /// Disattiva il piano (fine trattamento)
  Future<void> deactivatePlan() async {
    try {
      if (state == null) throw Exception('Nessun piano caricato');

      final deactivated = state!.copyWith(isActive: false);
      await _db.updateTreatmentPlan(deactivated);
      state = deactivated;
      print('✅ Piano disattivato');
    } catch (e) {
      print('❌ Errore nella disattivazione: $e');
      rethrow;
    }
  }

  /// Riattiva il piano
  Future<void> reactivatePlan() async {
    try {
      if (state == null) throw Exception('Nessun piano caricato');

      final reactivated = state!.copyWith(isActive: true);
      await _db.updateTreatmentPlan(reactivated);
      state = reactivated;
      print('✅ Piano riattivato');
    } catch (e) {
      print('❌ Errore nella riattivazione: $e');
      rethrow;
    }
  }

  /// ✅ NUOVO: Elimina il trattamento e resetta lo stato
  Future<void> deleteTreatment() async {
    try {
      if (state == null) throw Exception('Nessun piano di trattamento caricato');

      final planId = state!.id;
      await _db.deleteTreatmentPlan(planId);
      state = null;
      print('✅ Trattamento eliminato: $planId');
    } catch (e) {
      print('❌ Errore nell\'eliminazione del trattamento: $e');
      rethrow;
    }
  }
}

/// Provider per il piano di trattamento
final treatmentPlanProvider =
StateNotifierProvider<TreatmentPlanNotifier, TreatmentPlan?>((ref) {
  return TreatmentPlanNotifier();
});

/// Provider per tutti i piani di trattamento
final allTreatmentPlansProvider = Provider<List<TreatmentPlan>>((ref) {
  final db = DatabaseService();
  return db.getAllTreatmentPlans();
});

/// Provider per lo stage corrente
final currentStageProvider = Provider<int?>((ref) {
  final plan = ref.watch(treatmentPlanProvider);
  return plan?.currentStage;
});

/// Provider per i giorni rimanenti
final daysRemainingProvider = Provider<int?>((ref) {
  final plan = ref.watch(treatmentPlanProvider);
  return plan?.daysRemaining;
});

/// Provider per la percentuale di progresso
final progressPercentageProvider = Provider<double>((ref) {
  final plan = ref.watch(treatmentPlanProvider);
  return plan?.progressPercentage ?? 0.0;
});

/// Provider per la data di fine prevista
final endDateProvider = Provider<DateTime?>((ref) {
  final plan = ref.watch(treatmentPlanProvider);
  return plan?.endDate;
});

/// Provider per verificare se il trattamento è completato
final isCompletedProvider = Provider<bool>((ref) {
  final plan = ref.watch(treatmentPlanProvider);
  return plan?.isCompleted ?? false;
});

/// Provider per il numero totale di giorni
final totalDaysProvider = Provider<int?>((ref) {
  final plan = ref.watch(treatmentPlanProvider);
  return plan?.totalDays;
});

/// Provider per lo stage tipo (A o B)
final currentStageTypeProvider = Provider<String?>((ref) {
  final plan = ref.watch(treatmentPlanProvider);
  if (plan == null) return null;

  final currentStage = plan.currentStage;
  final stageLength = plan.stageADays + plan.stageBDays;
  final positionInCycle = ((currentStage - 1) * stageLength) % (plan.stageADays + plan.stageBDays);

  return positionInCycle < plan.stageADays ? 'A' : 'B';
});

/// Provider per informazioni sul trattamento
final treatmentInfoProvider = Provider<TreatmentInfo?>((ref) {
  final plan = ref.watch(treatmentPlanProvider);
  if (plan == null) return null;

  return TreatmentInfo(
    id: plan.id,
    totalStages: plan.totalStages,
    currentStage: plan.currentStage,
    stageType: ref.watch(currentStageTypeProvider) ?? 'A',
    progressPercentage: plan.progressPercentage,
    daysRemaining: plan.daysRemaining,
    isCompleted: plan.isCompleted,
    startDate: plan.startDate,
    endDate: plan.endDate,
  );
});

// ============ MODEL HELPER ============

/// Modello per informazioni sintetiche del trattamento
class TreatmentInfo {
  final String id;
  final int totalStages;
  final int currentStage;
  final String stageType;
  final double progressPercentage;
  final int daysRemaining;
  final bool isCompleted;
  final DateTime startDate;
  final DateTime endDate;

  TreatmentInfo({
    required this.id,
    required this.totalStages,
    required this.currentStage,
    required this.stageType,
    required this.progressPercentage,
    required this.daysRemaining,
    required this.isCompleted,
    required this.startDate,
    required this.endDate,
  });

  @override
  String toString() => '''TreatmentInfo(
    id: $id,
    totalStages: $totalStages,
    currentStage: $currentStage,
    stageType: $stageType,
    progressPercentage: $progressPercentage,
    daysRemaining: $daysRemaining,
    isCompleted: $isCompleted,
  )''';
}