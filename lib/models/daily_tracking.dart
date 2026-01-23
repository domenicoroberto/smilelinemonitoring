import 'package:uuid/uuid.dart';

class DailyTracking {
  final String id;
  final String treatmentPlanId;
  final String currentStageId;
  final DateTime date;
  final int wearingHours;
  final int wearingMinutes;
  final int targetHours;
  final String currentStageNumber;
  final String currentStageType;
  final List<TimerSession> sessions;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyTracking({
    String? id,
    required this.treatmentPlanId,
    required this.currentStageId,
    required this.date,
    this.wearingHours = 0,
    this.wearingMinutes = 0,
    required this.targetHours,
    required this.currentStageNumber,
    required this.currentStageType,
    List<TimerSession>? sessions,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        sessions = sessions ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Calcola il totale dei minuti di utilizzo
  int get totalMinutes => wearingHours * 60 + wearingMinutes;

  /// Calcola il totale dei minuti target
  int get targetMinutes => targetHours * 60;

  /// Calcola la percentuale di conformità
  double get compliancePercentage {
    if (targetMinutes == 0) return 0.0;
    return (totalMinutes / targetMinutes * 100).clamp(0.0, 100.0);
  }

  /// Verifica se l'obiettivo giornaliero è stato raggiunto
  bool get isMeetingTarget => totalMinutes >= targetMinutes;

  /// Calcola i minuti rimanenti per raggiungere l'obiettivo
  int get remainingMinutes {
    final remaining = targetMinutes - totalMinutes;
    return remaining > 0 ? remaining : 0;
  }

  /// Calcola il numero totale di sessioni
  int get totalSessions => sessions.length;

  /// Calcola il tempo della sessione più lunga
  int? get longestSessionDuration {
    if (sessions.isEmpty) return null;
    return sessions
        .map((s) => s.durationMinutes)
        .reduce((a, b) => a > b ? a : b);
  }

  /// Calcola il tempo della sessione più breve
  int? get shortestSessionDuration {
    if (sessions.isEmpty) return null;
    return sessions
        .map((s) => s.durationMinutes)
        .reduce((a, b) => a < b ? a : b);
  }

  /// Calcola il tempo medio per sessione
  double get averageSessionDuration {
    if (sessions.isEmpty) return 0.0;
    final total = sessions.fold<int>(
        0, (sum, session) => sum + session.durationMinutes);
    return total / sessions.length;
  }

  /// Crea una copia con alcuni campi modificati
  DailyTracking copyWith({
    String? id,
    String? treatmentPlanId,
    String? currentStageId,
    DateTime? date,
    int? wearingHours,
    int? wearingMinutes,
    int? targetHours,
    String? currentStageNumber,
    String? currentStageType,
    List<TimerSession>? sessions,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyTracking(
      id: id ?? this.id,
      treatmentPlanId: treatmentPlanId ?? this.treatmentPlanId,
      currentStageId: currentStageId ?? this.currentStageId,
      date: date ?? this.date,
      wearingHours: wearingHours ?? this.wearingHours,
      wearingMinutes: wearingMinutes ?? this.wearingMinutes,
      targetHours: targetHours ?? this.targetHours,
      currentStageNumber: currentStageNumber ?? this.currentStageNumber,
      currentStageType: currentStageType ?? this.currentStageType,
      sessions: sessions ?? this.sessions,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Aggiunge una nuova sessione di timer
  DailyTracking addSession(TimerSession session) {
    final newSessions = [...sessions, session];
    final totalMinutesFromSessions =
    newSessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
    final hours = totalMinutesFromSessions ~/ 60;
    final minutes = totalMinutesFromSessions % 60;

    return copyWith(
      sessions: newSessions,
      wearingHours: hours,
      wearingMinutes: minutes,
    );
  }

  /// Aggiorna le ore di utilizzo manualmente
  DailyTracking updateWearingTime({
    required int hours,
    required int minutes,
  }) {
    return copyWith(
      wearingHours: hours,
      wearingMinutes: minutes,
    );
  }

  /// Converte in JSON per il database
  Map<String, dynamic> toJson() => {
    'id': id,
    'treatmentPlanId': treatmentPlanId,
    'currentStageId': currentStageId,
    'date': date.toIso8601String(),
    'wearingHours': wearingHours,
    'wearingMinutes': wearingMinutes,
    'targetHours': targetHours,
    'currentStageNumber': currentStageNumber,
    'currentStageType': currentStageType,
    'sessions': sessions.map((s) => s.toJson()).toList(),
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// Crea da JSON
  factory DailyTracking.fromJson(Map<String, dynamic> json) => DailyTracking(
    id: json['id'] as String?,
    treatmentPlanId: json['treatmentPlanId'] as String,
    currentStageId: json['currentStageId'] as String,
    date: DateTime.parse(json['date'] as String),
    wearingHours: json['wearingHours'] as int? ?? 0,
    wearingMinutes: json['wearingMinutes'] as int? ?? 0,
    targetHours: json['targetHours'] as int,
    currentStageNumber: json['currentStageNumber'] as String,
    currentStageType: json['currentStageType'] as String,
    sessions: (json['sessions'] as List<dynamic>?)
        ?.map((s) => TimerSession.fromJson(s as Map<String, dynamic>))
        .toList() ??
        [],
    notes: json['notes'] as String?,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null,
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null,
  );

  @override
  String toString() => '''DailyTracking(
    id: $id,
    treatmentPlanId: $treatmentPlanId,
    currentStageId: $currentStageId,
    date: $date,
    wearingHours: $wearingHours,
    wearingMinutes: $wearingMinutes,
    targetHours: $targetHours,
    currentStageNumber: $currentStageNumber,
    currentStageType: $currentStageType,
    sessions: $sessions,
    notes: $notes,
    createdAt: $createdAt,
    updatedAt: $updatedAt,
  )''';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is DailyTracking &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Model per una singola sessione del timer
class TimerSession {
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;

  TimerSession({
    required this.startTime,
    required this.endTime,
    int? durationMinutes,
  }) : durationMinutes =
      durationMinutes ?? endTime.difference(startTime).inMinutes;

  /// Crea una copia con alcuni campi modificati
  TimerSession copyWith({
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
  }) {
    return TimerSession(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  /// Converte in JSON
  Map<String, dynamic> toJson() => {
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'durationMinutes': durationMinutes,
  };

  /// Crea da JSON
  factory TimerSession.fromJson(Map<String, dynamic> json) => TimerSession(
    startTime: DateTime.parse(json['startTime'] as String),
    endTime: DateTime.parse(json['endTime'] as String),
    durationMinutes: json['durationMinutes'] as int?,
  );

  @override
  String toString() => '''TimerSession(
    startTime: $startTime,
    endTime: $endTime,
    durationMinutes: $durationMinutes,
  )''';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is TimerSession &&
              runtimeType == other.runtimeType &&
              startTime == other.startTime &&
              endTime == other.endTime;

  @override
  int get hashCode => startTime.hashCode ^ endTime.hashCode;
}