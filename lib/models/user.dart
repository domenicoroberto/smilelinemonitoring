import 'package:uuid/uuid.dart';

class User {
  final String id;
  final String name;
  final String? surname;
  final String? email;
  final String? phone;
  final String? profileImageUrl;
  final DateTime? dateOfBirth;
  final String? currentTreatmentPlanId;
  final int totalCompletedStages;
  final int totalStagesPlanned;
  final bool notificationsEnabled;
  final bool dailyReminderEnabled;
  final int dailyReminderHour;
  final String language;
  final String theme; // 'light', 'dark', 'auto'
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final bool isActive;

  User({
    String? id,
    required this.name,
    this.surname,
    this.email,
    this.phone,
    this.profileImageUrl,
    this.dateOfBirth,
    this.currentTreatmentPlanId,
    this.totalCompletedStages = 0,
    this.totalStagesPlanned = 0,
    this.notificationsEnabled = true,
    this.dailyReminderEnabled = true,
    this.dailyReminderHour = 20,
    this.language = 'it',
    this.theme = 'light',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastLoginAt,
    this.isActive = true,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Calcola il nome completo
  String get fullName {
    if (surname != null && surname!.isNotEmpty) {
      return '$name $surname';
    }
    return name;
  }

  /// Calcola l'età in base alla data di nascita
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month &&
            now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  /// Calcola la percentuale di completamento
  double get completionPercentage {
    if (totalStagesPlanned == 0) return 0.0;
    return (totalCompletedStages / totalStagesPlanned * 100)
        .clamp(0.0, 100.0);
  }

  /// Verifica se è un nuovo utente (creato meno di 7 giorni fa)
  bool get isNewUser {
    final daysSinceCreation = DateTime.now().difference(createdAt).inDays;
    return daysSinceCreation < 7;
  }

  /// Verifica se l'utente è attivo (loggato negli ultimi 30 giorni)
  bool get isRecentlyActive {
    if (lastLoginAt == null) return false;
    final daysSinceLastLogin =
        DateTime.now().difference(lastLoginAt!).inDays;
    return daysSinceLastLogin < 30;
  }

  /// Calcola i giorni da quando è registrato
  int get daysSinceRegistration =>
      DateTime.now().difference(createdAt).inDays;

  /// Calcola i giorni da ultimo accesso
  int? get daysSinceLastLogin {
    if (lastLoginAt == null) return null;
    return DateTime.now().difference(lastLoginAt!).inDays;
  }

  /// Crea una copia con alcuni campi modificati
  User copyWith({
    String? id,
    String? name,
    String? surname,
    String? email,
    String? phone,
    String? profileImageUrl,
    DateTime? dateOfBirth,
    String? currentTreatmentPlanId,
    int? totalCompletedStages,
    int? totalStagesPlanned,
    bool? notificationsEnabled,
    bool? dailyReminderEnabled,
    int? dailyReminderHour,
    String? language,
    String? theme,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      currentTreatmentPlanId:
      currentTreatmentPlanId ?? this.currentTreatmentPlanId,
      totalCompletedStages: totalCompletedStages ?? this.totalCompletedStages,
      totalStagesPlanned: totalStagesPlanned ?? this.totalStagesPlanned,
      notificationsEnabled:
      notificationsEnabled ?? this.notificationsEnabled,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderHour: dailyReminderHour ?? this.dailyReminderHour,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Aggiorna l'ultimo accesso
  User updateLastLogin() {
    return copyWith(lastLoginAt: DateTime.now());
  }

  /// Aggiorna i stage completati
  User incrementCompletedStages() {
    return copyWith(totalCompletedStages: totalCompletedStages + 1);
  }

  /// Imposta il piano di trattamento corrente
  User setCurrentTreatmentPlan(String planId) {
    return copyWith(currentTreatmentPlanId: planId);
  }

  /// Attiva/disattiva le notifiche
  User toggleNotifications(bool enabled) {
    return copyWith(notificationsEnabled: enabled);
  }

  /// Attiva/disattiva il promemoria giornaliero
  User toggleDailyReminder(bool enabled) {
    return copyWith(dailyReminderEnabled: enabled);
  }

  /// Imposta l'ora del promemoria giornaliero
  User setDailyReminderHour(int hour) {
    if (hour < 0 || hour > 23) {
      throw ArgumentError('Hour must be between 0 and 23');
    }
    return copyWith(dailyReminderHour: hour);
  }

  /// Cambia la lingua
  User setLanguage(String languageCode) {
    return copyWith(language: languageCode);
  }

  /// Cambia il tema
  User setTheme(String themeMode) {
    if (!['light', 'dark', 'auto'].contains(themeMode)) {
      throw ArgumentError('Theme must be light, dark, or auto');
    }
    return copyWith(theme: themeMode);
  }

  /// Converte in JSON per il database
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'surname': surname,
    'email': email,
    'phone': phone,
    'profileImageUrl': profileImageUrl,
    'dateOfBirth': dateOfBirth?.toIso8601String(),
    'currentTreatmentPlanId': currentTreatmentPlanId,
    'totalCompletedStages': totalCompletedStages,
    'totalStagesPlanned': totalStagesPlanned,
    'notificationsEnabled': notificationsEnabled,
    'dailyReminderEnabled': dailyReminderEnabled,
    'dailyReminderHour': dailyReminderHour,
    'language': language,
    'theme': theme,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'lastLoginAt': lastLoginAt?.toIso8601String(),
    'isActive': isActive,
  };

  /// Crea da JSON
  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String?,
    name: json['name'] as String,
    surname: json['surname'] as String?,
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    profileImageUrl: json['profileImageUrl'] as String?,
    dateOfBirth: json['dateOfBirth'] != null
        ? DateTime.parse(json['dateOfBirth'] as String)
        : null,
    currentTreatmentPlanId: json['currentTreatmentPlanId'] as String?,
    totalCompletedStages: json['totalCompletedStages'] as int? ?? 0,
    totalStagesPlanned: json['totalStagesPlanned'] as int? ?? 0,
    notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    dailyReminderEnabled: json['dailyReminderEnabled'] as bool? ?? true,
    dailyReminderHour: json['dailyReminderHour'] as int? ?? 20,
    language: json['language'] as String? ?? 'it',
    theme: json['theme'] as String? ?? 'light',
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null,
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null,
    lastLoginAt: json['lastLoginAt'] != null
        ? DateTime.parse(json['lastLoginAt'] as String)
        : null,
    isActive: json['isActive'] as bool? ?? true,
  );

  @override
  String toString() => '''User(
    id: $id,
    name: $name,
    surname: $surname,
    email: $email,
    phone: $phone,
    profileImageUrl: $profileImageUrl,
    dateOfBirth: $dateOfBirth,
    currentTreatmentPlanId: $currentTreatmentPlanId,
    totalCompletedStages: $totalCompletedStages,
    totalStagesPlanned: $totalStagesPlanned,
    notificationsEnabled: $notificationsEnabled,
    dailyReminderEnabled: $dailyReminderEnabled,
    dailyReminderHour: $dailyReminderHour,
    language: $language,
    theme: $theme,
    createdAt: $createdAt,
    updatedAt: $updatedAt,
    lastLoginAt: $lastLoginAt,
    isActive: $isActive,
  )''';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}