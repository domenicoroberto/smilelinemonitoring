import 'package:uuid/uuid.dart';

class TreatmentPlan {
  final String id;
  final int totalStages;
  final int stageADays;
  final int stageBDays;
  final int dailyWearingHours;
  final DateTime startDate;
  final int currentStage; // ✅ NUOVO: Stage attuale PERSISTENTE (non calcolato)
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  TreatmentPlan({
    String? id,
    required this.totalStages,
    required this.stageADays,
    required this.stageBDays,
    required this.dailyWearingHours,
    required this.startDate,
    this.currentStage = 1, // ✅ NUOVO: Default a stage 1
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // ============ PROPRIETÀ CALCOLATE ============

  /// Calcola la durata totale del trattamento in giorni
  int get totalDays => totalStages * (stageADays + stageBDays);

  /// Calcola la data di fine prevista
  DateTime get endDate => startDate.add(Duration(days: totalDays));

  /// Calcola i giorni rimanenti dal today
  int get daysRemaining {
    final today = DateTime.now();
    if (today.isAfter(endDate)) return 0;
    return endDate.difference(today).inDays;
  }

  /// Calcola la percentuale di progresso
  double get progressPercentage {
    final today = DateTime.now();
    if (today.isBefore(startDate)) return 0.0;
    if (today.isAfter(endDate)) return 100.0;

    final elapsed = today.difference(startDate).inDays;
    return (elapsed / totalDays * 100).clamp(0.0, 100.0);
  }

  /// Verifica se il trattamento è completato
  bool get isCompleted => currentStage > totalStages;

  // ============ METODI PER STAGE ✅ NUOVO ============

  /// ✅ Calcola il numero del giorno corrente nello stage (1-indexed)
  /// Esempio: Se sono passati 6 giorni e la fase dura 5 giorni:
  /// (6 % 5) + 1 = 2 (siamo al 2° giorno della fase 2)
  int getStageCurrentDayNumber() {
    final now = DateTime.now();
    final daysPassed = now.difference(startDate).inDays;
    final stageDayLength = stageADays + stageBDays;
    final daysInCurrentStage = daysPassed % stageDayLength;

    return (daysInCurrentStage + 1).clamp(1, stageDayLength);
  }

  /// ✅ Calcola i giorni rimanenti fino al cambio dello stage
  /// Se siamo al giorno 5 di 5: 5 - 5 = 0 (cambio oggi!)
  /// Se siamo al giorno 2 di 5: 5 - 2 = 3 (3 giorni rimanenti)
  int getStageRemainingDays() {
    final currentDay = getStageCurrentDayNumber();
    final stageDayLength = stageADays + stageBDays;

    final daysRemaining = stageDayLength - currentDay;
    return daysRemaining.clamp(0, stageDayLength);
  }

  /// ✅ Verifica se lo stage attuale è completato
  /// Ritorna true quando daysRemaining == 0
  bool isCurrentStageDue() {
    return getStageRemainingDays() == 0;
  }

  /// ✅ Passa al prossimo stage
  /// Incrementa currentStage di 1, rispettando il massimo (totalStages)
  TreatmentPlan moveToNextStage() {
    final nextStage = (currentStage + 1).clamp(1, totalStages + 1);

    return copyWith(
      currentStage: nextStage,
    );
  }

  /// ✅ Calcola la percentuale di progresso del trattamento
  /// Esempio: Stage 2 di 4 = (2 / 4) * 100 = 50%
  double getProgressPercentage() {
    if (totalStages == 0) return 0.0;
    return ((currentStage - 1) / totalStages * 100).clamp(0.0, 100.0);
  }

  /// ✅ Calcola i giorni totali del trattamento
  int getTotalDays() {
    return totalStages * (stageADays + stageBDays);
  }

  /// ✅ Calcola i giorni passati dal inizio del trattamento
  int getDaysPassed() {
    return DateTime.now().difference(startDate).inDays;
  }

  /// ✅ Calcola i giorni rimanenti per il trattamento completo
  int getDaysRemaining() {
    final totalDays = getTotalDays();
    final daysPassed = getDaysPassed();
    return (totalDays - daysPassed).clamp(0, totalDays);
  }

  /// ✅ Calcola la lunghezza di uno stage (giorni A + giorni B)
  int getStageDayLength() {
    return stageADays + stageBDays;
  }

  /// ✅ Debug: Stampa tutte le info dello stage
  void printStageInfo() {
    print('\n📊 STAGE INFO:');
    print('   Stage attuale: $currentStage / $totalStages');
    print('   Giorni passati: ${getDaysPassed()}');
    print('   Giorni totali: ${getTotalDays()}');
    print('   Giorni rimanenti: ${getDaysRemaining()}');
    print('   Giorno corrente dello stage: ${getStageCurrentDayNumber()} / ${stageADays + stageBDays}');
    print('   Giorni al cambio: ${getStageRemainingDays()}');
    print('   Progress: ${getProgressPercentage().toStringAsFixed(1)}%');
    print('   Completato: $isCompleted');
  }

  // ============ METODI ORIGINALI ============

  /// Crea una copia con alcuni campi modificati
  TreatmentPlan copyWith({
    String? id,
    int? totalStages,
    int? stageADays,
    int? stageBDays,
    int? dailyWearingHours,
    DateTime? startDate,
    int? currentStage, // ✅ NUOVO: Aggiunto
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return TreatmentPlan(
      id: id ?? this.id,
      totalStages: totalStages ?? this.totalStages,
      stageADays: stageADays ?? this.stageADays,
      stageBDays: stageBDays ?? this.stageBDays,
      dailyWearingHours: dailyWearingHours ?? this.dailyWearingHours,
      startDate: startDate ?? this.startDate,
      currentStage: currentStage ?? this.currentStage, // ✅ NUOVO
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isActive: isActive ?? this.isActive,
    );
  }

  /// Converte in JSON per il database
  Map<String, dynamic> toJson() => {
    'id': id,
    'totalStages': totalStages,
    'stageADays': stageADays,
    'stageBDays': stageBDays,
    'dailyWearingHours': dailyWearingHours,
    'startDate': startDate.toIso8601String(),
    'currentStage': currentStage, // ✅ NUOVO: Salva nel DB
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isActive': isActive,
  };

  /// Crea da JSON
  factory TreatmentPlan.fromJson(Map<String, dynamic> json) => TreatmentPlan(
    id: json['id'] as String?,
    totalStages: json['totalStages'] as int,
    stageADays: json['stageADays'] as int,
    stageBDays: json['stageBDays'] as int,
    dailyWearingHours: json['dailyWearingHours'] as int,
    startDate: DateTime.parse(json['startDate'] as String),
    currentStage: json['currentStage'] as int? ?? 1, // ✅ NUOVO: Leggi dal DB
    notes: json['notes'] as String?,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null,
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null,
    isActive: json['isActive'] as bool? ?? true,
  );

  @override
  String toString() => '''TreatmentPlan(
    id: $id,
    totalStages: $totalStages,
    currentStage: $currentStage,
    stageADays: $stageADays,
    stageBDays: $stageBDays,
    dailyWearingHours: $dailyWearingHours,
    startDate: $startDate,
    notes: $notes,
    createdAt: $createdAt,
    updatedAt: $updatedAt,
    isActive: $isActive,
  )''';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is TreatmentPlan &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}