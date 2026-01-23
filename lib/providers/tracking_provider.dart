import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_tracking.dart';
import '../models/treatment_plan.dart';
import '../services/database_service.dart';

/// Notifier per la gestione del tracking giornaliero
class TrackingNotifier extends StateNotifier<List<DailyTracking>> {
  final DatabaseService _db = DatabaseService();

  TrackingNotifier() : super([]);

  /// Carica il tracking per un piano di trattamento
  Future<void> loadTrackingByPlan(String treatmentPlanId) async {
    try {
      final tracking = _db.getTrackingByTreatmentPlan(treatmentPlanId);
      state = tracking;
      print('✅ Tracking caricato: ${tracking.length} giorni');
    } catch (e) {
      print('❌ Errore nel caricamento del tracking: $e');
      state = [];
    }
  }

  /// Carica il tracking tra due date
  Future<void> loadTrackingBetweenDates(DateTime startDate, DateTime endDate) async {
    try {
      final tracking = _db.getTrackingBetweenDates(startDate, endDate);
      state = tracking;
      print('✅ Tracking caricato: ${tracking.length} giorni');
    } catch (e) {
      print('❌ Errore nel caricamento del tracking: $e');
      state = [];
    }
  }

  /// Carica il tracking per una data specifica
  Future<DailyTracking?> loadTrackingByDate(DateTime date) async {
    try {
      final tracking = _db.getDailyTrackingByDate(date);
      return tracking;
    } catch (e) {
      print('❌ Errore nel caricamento del tracking: $e');
      return null;
    }
  }

  /// Crea un nuovo tracking giornaliero
  Future<void> createDailyTracking({
    required String treatmentPlanId,
    required String currentStageId,
    required DateTime date,
    required int targetHours,
    required String currentStageNumber,
    required String currentStageType,
    String? notes,
  }) async {
    try {
      final tracking = DailyTracking(
        treatmentPlanId: treatmentPlanId,
        currentStageId: currentStageId,
        date: date,
        targetHours: targetHours,
        currentStageNumber: currentStageNumber,
        currentStageType: currentStageType,
        notes: notes,
      );

      await _db.saveDailyTracking(tracking);
      _addToState(tracking);
      print('✅ Nuovo tracking creato: ${tracking.id}');
    } catch (e) {
      print('❌ Errore nella creazione del tracking: $e');
      rethrow;
    }
  }

  /// Aggiorna il tracking giornaliero
  Future<void> updateDailyTracking({
    required String trackingId,
    int? wearingHours,
    int? wearingMinutes,
    String? notes,
  }) async {
    try {
      final index = state.indexWhere((t) => t.id == trackingId);
      if (index == -1) throw Exception('Tracking non trovato');

      final updated = state[index].copyWith(
        wearingHours: wearingHours ?? state[index].wearingHours,
        wearingMinutes: wearingMinutes ?? state[index].wearingMinutes,
        notes: notes ?? state[index].notes,
      );

      await _db.updateDailyTracking(updated);
      state = [
        ...state.sublist(0, index),
        updated,
        ...state.sublist(index + 1),
      ];
      print('✅ Tracking aggiornato: $trackingId');
    } catch (e) {
      print('❌ Errore nell\'aggiornamento del tracking: $e');
      rethrow;
    }
  }

  /// Aggiunge una sessione di timer al tracking
  Future<void> addSessionToTracking({
    required String trackingId,
    required TimerSession session,
  }) async {
    try {
      final index = state.indexWhere((t) => t.id == trackingId);
      if (index == -1) throw Exception('Tracking non trovato');

      final updated = state[index].addSession(session);
      await _db.updateDailyTracking(updated);
      state = [
        ...state.sublist(0, index),
        updated,
        ...state.sublist(index + 1),
      ];
      print('✅ Sessione aggiunta al tracking');
    } catch (e) {
      print('❌ Errore nell\'aggiunta della sessione: $e');
      rethrow;
    }
  }

  /// Elimina il tracking
  Future<void> deleteTracking(String trackingId) async {
    try {
      await _db.deleteDailyTracking(trackingId);
      state = state.where((t) => t.id != trackingId).toList();
      print('✅ Tracking eliminato: $trackingId');
    } catch (e) {
      print('❌ Errore nell\'eliminazione del tracking: $e');
      rethrow;
    }
  }

  /// Aggiorna manualmente le ore di utilizzo
  Future<void> updateWearingHours({
    required String trackingId,
    required int hours,
    required int minutes,
  }) async {
    try {
      final index = state.indexWhere((t) => t.id == trackingId);
      if (index == -1) throw Exception('Tracking non trovato');

      final updated = state[index].updateWearingTime(
        hours: hours,
        minutes: minutes,
      );

      await _db.updateDailyTracking(updated);
      state = [
        ...state.sublist(0, index),
        updated,
        ...state.sublist(index + 1),
      ];
      print('✅ Ore di utilizzo aggiornate');
    } catch (e) {
      print('❌ Errore nell\'aggiornamento delle ore: $e');
      rethrow;
    }
  }

  /// Aggiunge al state
  void _addToState(DailyTracking tracking) {
    state = [...state, tracking];
  }
}

/// Provider per il tracking giornaliero
final trackingProvider =
StateNotifierProvider<TrackingNotifier, List<DailyTracking>>((ref) {
  return TrackingNotifier();
});

/// Provider per il tracking di oggi
final todayTrackingProvider = FutureProvider<DailyTracking?>((ref) async {
  final notifier = ref.read(trackingProvider.notifier);
  return notifier.loadTrackingByDate(DateTime.now());
});

/// Provider per il numero totale di sessioni
final totalSessionsProvider = Provider<int>((ref) {
  final trackingList = ref.watch(trackingProvider);
  return trackingList.fold<int>(0, (sum, t) => sum + t.totalSessions);
});

/// Provider per le ore totali registrate
final totalHoursProvider = Provider<int>((ref) {
  final trackingList = ref.watch(trackingProvider);
  return trackingList.fold<int>(
    0,
        (sum, t) => sum + t.wearingHours,
  );
});

/// Provider per i minuti totali registrati
final totalMinutesProvider = Provider<int>((ref) {
  final trackingList = ref.watch(trackingProvider);
  return trackingList.fold<int>(
    0,
        (sum, t) => sum + t.totalMinutes,
  );
});

/// Provider per la conformità media
final averageComplianceProvider = Provider<double>((ref) {
  final trackingList = ref.watch(trackingProvider);
  if (trackingList.isEmpty) return 0.0;

  final totalCompliance = trackingList.fold<double>(
    0.0,
        (sum, t) => sum + t.compliancePercentage,
  );

  return totalCompliance / trackingList.length;
});

/// Provider per i giorni con target raggiunto
final daysWithTargetReachedProvider = Provider<int>((ref) {
  final trackingList = ref.watch(trackingProvider);
  return trackingList.where((t) => t.isMeetingTarget).length;
});

/// Provider per la sessione più lunga
final longestSessionProvider = Provider<int?>((ref) {
  final trackingList = ref.watch(trackingProvider);
  if (trackingList.isEmpty) return null;

  int? longest;
  for (var tracking in trackingList) {
    final trackingLongest = tracking.longestSessionDuration;
    if (trackingLongest != null) {
      if (longest == null || trackingLongest > longest) {
        longest = trackingLongest;
      }
    }
  }
  return longest;
});

/// Provider per la sessione più breve
final shortestSessionProvider = Provider<int?>((ref) {
  final trackingList = ref.watch(trackingProvider);
  if (trackingList.isEmpty) return null;

  int? shortest;
  for (var tracking in trackingList) {
    final trackingShortest = tracking.shortestSessionDuration;
    if (trackingShortest != null) {
      if (shortest == null || trackingShortest < shortest) {
        shortest = trackingShortest;
      }
    }
  }
  return shortest;
});

/// Provider per la durata media sessione
final averageSessionDurationProvider = Provider<double>((ref) {
  final trackingList = ref.watch(trackingProvider);
  if (trackingList.isEmpty) return 0.0;

  final totalAverage = trackingList.fold<double>(
    0.0,
        (sum, t) => sum + t.averageSessionDuration,
  );

  return totalAverage / trackingList.length;
});

/// Provider per le statistiche di tracking
final trackingStatsProvider = Provider<TrackingStats>((ref) {
  final trackingList = ref.watch(trackingProvider);

  return TrackingStats(
    totalDays: trackingList.length,
    totalSessions: ref.watch(totalSessionsProvider),
    totalHours: ref.watch(totalHoursProvider),
    totalMinutes: ref.watch(totalMinutesProvider),
    averageCompliance: ref.watch(averageComplianceProvider),
    daysWithTargetReached: ref.watch(daysWithTargetReachedProvider),
    averageSessionDuration: ref.watch(averageSessionDurationProvider),
  );
});

/// Provider per il tracking di una settimana
final weeklyTrackingProvider = FutureProvider.family<List<DailyTracking>, DateTime>((ref, startDate) async {
  final notifier = ref.read(trackingProvider.notifier);
  final endDate = startDate.add(const Duration(days: 7));
  await notifier.loadTrackingBetweenDates(startDate, endDate);
  return ref.watch(trackingProvider);
});

/// Provider per il tracking di un mese
final monthlyTrackingProvider = FutureProvider.family<List<DailyTracking>, DateTime>((ref, startDate) async {
  final notifier = ref.read(trackingProvider.notifier);
  final endDate = startDate.add(const Duration(days: 30));
  await notifier.loadTrackingBetweenDates(startDate, endDate);
  return ref.watch(trackingProvider);
});

// ✅ NUOVO: Provider per le statistiche settimanali (ultimi 7 giorni)
class DailyHours {
  final int dayNumber;
  final DateTime date;
  final double hours;

  DailyHours({
    required this.dayNumber,
    required this.date,
    required this.hours,
  });
}

final weeklyStatisticsProvider =
FutureProvider.family<List<DailyHours>, String?>((ref, treatmentPlanId) async {

  if (treatmentPlanId == null || treatmentPlanId.isEmpty) {
    return [];
  }

  final db = DatabaseService();

  final treatment = db.getTreatmentPlan(treatmentPlanId);
  if (treatment == null) {
    return [];
  }

  final List<DailyHours> weeklyData = [];
  final now = DateTime.now();
  final startDate = treatment.startDate;

  // ✅ LEGGI GLI ULTIMI 7 GIORNI DAL DATABASE
  for (int i = 6; i >= 0; i--) {
    final date = now.subtract(Duration(days: i));
    final dayNum = 7 - i; // 1, 2, 3, 4, 5, 6, 7

    double hours = 0.0;

    if (date.isBefore(startDate)) {
      hours = 0.0;
    } else {
      // ✅ LEGGI DAL DATABASE
      final dateOnly = DateTime(date.year, date.month, date.day);
      final tracking = db.getDailyTrackingByDate(dateOnly);

      if (tracking != null) {
        hours = (tracking.wearingHours + tracking.wearingMinutes / 60.0);

        print('📊 Dati per ${date.toIso8601String()}: $hours ore');
      } else {
        print('📭 Nessun dato per ${date.toIso8601String()}');
        hours = 0.0;
      }
    }

    weeklyData.add(DailyHours(
      dayNumber: dayNum,
      date: date,
      hours: hours,
    ));
  }

  return weeklyData;
});

// ✅ NUOVO: Provider per le statistiche aggregate della settimana
class WeeklyStatistics {
  final double totalHours;
  final double averageHours;
  final double maxHours;
  final double minHours;
  final int daysWithData;

  WeeklyStatistics({
    required this.totalHours,
    required this.averageHours,
    required this.maxHours,
    required this.minHours,
    required this.daysWithData,
  });
}

final aggregatedStatisticsProvider =
FutureProvider.family<WeeklyStatistics, String?>((ref, treatmentPlanId) async {

  final weeklyData = await ref.watch(weeklyStatisticsProvider(treatmentPlanId).future);

  if (weeklyData.isEmpty) {
    return WeeklyStatistics(
      totalHours: 0.0,
      averageHours: 0.0,
      maxHours: 0.0,
      minHours: 0.0,
      daysWithData: 0,
    );
  }

  final hours = weeklyData.map((d) => d.hours).toList();
  final totalHours = hours.isEmpty ? 0.0 : hours.reduce((a, b) => a + b);

  // ✅ Conta solo i giorni CON DATI
  final daysWithData = hours.where((h) => h > 0).length;
  final averageHours = daysWithData == 0 ? 0.0 : totalHours / daysWithData;

  final maxHours = hours.isEmpty ? 0.0 : hours.reduce((a, b) => a > b ? a : b);
  final minHours = hours.isEmpty ? 0.0 : hours.reduce((a, b) => a < b ? a : b);

  return WeeklyStatistics(
    totalHours: totalHours,
    averageHours: averageHours,
    maxHours: maxHours,
    minHours: minHours,
    daysWithData: daysWithData,
  );
});

// ============ MODELS HELPER ============

/// Modello per le statistiche di tracking
class TrackingStats {
  final int totalDays;
  final int totalSessions;
  final int totalHours;
  final int totalMinutes;
  final double averageCompliance;
  final int daysWithTargetReached;
  final double averageSessionDuration;

  TrackingStats({
    required this.totalDays,
    required this.totalSessions,
    required this.totalHours,
    required this.totalMinutes,
    required this.averageCompliance,
    required this.daysWithTargetReached,
    required this.averageSessionDuration,
  });

  double get compliancePercentage => averageCompliance;

  double get daysWithTargetPercentage {
    if (totalDays == 0) return 0.0;
    return (daysWithTargetReached / totalDays * 100).clamp(0.0, 100.0);
  }

  @override
  String toString() => '''TrackingStats(
    totalDays: $totalDays,
    totalSessions: $totalSessions,
    totalHours: $totalHours,
    totalMinutes: $totalMinutes,
    averageCompliance: ${averageCompliance.toStringAsFixed(2)}%,
    daysWithTargetReached: $daysWithTargetReached,
    averageSessionDuration: ${averageSessionDuration.toStringAsFixed(2)}min,
  )''';
}