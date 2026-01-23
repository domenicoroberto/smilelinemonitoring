import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/database_service.dart';

/// Notifier per la gestione dello stato dell'utente
class UserNotifier extends StateNotifier<User?> {
  final DatabaseService _db = DatabaseService();

  UserNotifier() : super(null);

  /// Carica l'utente corrente
  Future<void> loadCurrentUser() async {
    try {
      final user = _db.getCurrentUser();
      state = user;
      print('✅ Utente caricato: ${user?.fullName}');
    } catch (e) {
      print('❌ Errore nel caricamento dell\'utente: $e');
      state = null;
    }
  }

  /// Crea un nuovo utente
  Future<void> createUser({
    required String name,
    String? surname,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
  }) async {
    try {
      final newUser = User(
        name: name,
        surname: surname,
        email: email,
        phone: phone,
        dateOfBirth: dateOfBirth,
      );

      await _db.saveUser(newUser);
      state = newUser;
      print('✅ Nuovo utente creato: ${newUser.fullName}');
    } catch (e) {
      print('❌ Errore nella creazione dell\'utente: $e');
      rethrow;
    }
  }

  /// Aggiorna i dati dell'utente
  Future<void> updateUser({
    String? name,
    String? surname,
    String? email,
    String? phone,
    String? profileImageUrl,
    DateTime? dateOfBirth,
  }) async {
    try {
      if (state == null) throw Exception('Nessun utente caricato');

      final updatedUser = state!.copyWith(
        name: name ?? state!.name,
        surname: surname ?? state!.surname,
        email: email ?? state!.email,
        phone: phone ?? state!.phone,
        profileImageUrl: profileImageUrl ?? state!.profileImageUrl,
        dateOfBirth: dateOfBirth ?? state!.dateOfBirth,
      );

      await _db.updateUser(updatedUser);
      state = updatedUser;
      print('✅ Utente aggiornato: ${updatedUser.fullName}');
    } catch (e) {
      print('❌ Errore nell\'aggiornamento dell\'utente: $e');
      rethrow;
    }
  }

  /// Aggiorna l'ultimo accesso
  Future<void> updateLastLogin() async {
    try {
      if (state == null) throw Exception('Nessun utente caricato');

      final updatedUser = state!.updateLastLogin();
      await _db.updateUser(updatedUser);
      state = updatedUser;
      print('✅ Ultimo accesso aggiornato');
    } catch (e) {
      print('❌ Errore nell\'aggiornamento del login: $e');
    }
  }

  /// Incrementa i stage completati
  Future<void> incrementCompletedStages() async {
    try {
      if (state == null) throw Exception('Nessun utente caricato');

      final updatedUser = state!.incrementCompletedStages();
      await _db.updateUser(updatedUser);
      state = updatedUser;
      print('✅ Stage completati incrementati');
    } catch (e) {
      print('❌ Errore nell\'incremento degli stage: $e');
      rethrow;
    }
  }

  /// Imposta il piano di trattamento corrente
  Future<void> setCurrentTreatmentPlan(String planId) async {
    try {
      if (state == null) throw Exception('Nessun utente caricato');

      final updatedUser = state!.setCurrentTreatmentPlan(planId);
      await _db.updateUser(updatedUser);
      state = updatedUser;
      print('✅ Piano di trattamento impostato: $planId');
    } catch (e) {
      print('❌ Errore nell\'impostazione del piano: $e');
      rethrow;
    }
  }

  /// Abilita/disabilita le notifiche
  Future<void> toggleNotifications(bool enabled) async {
    try {
      if (state == null) throw Exception('Nessun utente caricato');

      final updatedUser = state!.toggleNotifications(enabled);
      await _db.updateUser(updatedUser);
      state = updatedUser;
      print('✅ Notifiche ${enabled ? 'abilitate' : 'disabilitate'}');
    } catch (e) {
      print('❌ Errore nel toggle delle notifiche: $e');
      rethrow;
    }
  }

  /// Abilita/disabilita il promemoria giornaliero
  Future<void> toggleDailyReminder(bool enabled) async {
    try {
      if (state == null) throw Exception('Nessun utente caricato');

      final updatedUser = state!.toggleDailyReminder(enabled);
      await _db.updateUser(updatedUser);
      state = updatedUser;
      print('✅ Promemoria giornaliero ${enabled ? 'abilitato' : 'disabilitato'}');
    } catch (e) {
      print('❌ Errore nel toggle del promemoria: $e');
      rethrow;
    }
  }

  /// Imposta l'ora del promemoria giornaliero
  Future<void> setDailyReminderHour(int hour) async {
    try {
      if (state == null) throw Exception('Nessun utente caricato');

      final updatedUser = state!.setDailyReminderHour(hour);
      await _db.updateUser(updatedUser);
      state = updatedUser;
      print('✅ Ora promemoria impostata: $hour:00');
    } catch (e) {
      print('❌ Errore nell\'impostazione dell\'ora: $e');
      rethrow;
    }
  }

  /// Cambia la lingua
  Future<void> setLanguage(String languageCode) async {
    try {
      if (state == null) throw Exception('Nessun utente caricato');

      final updatedUser = state!.setLanguage(languageCode);
      await _db.updateUser(updatedUser);
      state = updatedUser;
      print('✅ Lingua impostata: $languageCode');
    } catch (e) {
      print('❌ Errore nell\'impostazione della lingua: $e');
      rethrow;
    }
  }

  /// Cambia il tema
  Future<void> setTheme(String themeMode) async {
    try {
      if (state == null) throw Exception('Nessun utente caricato');

      final updatedUser = state!.setTheme(themeMode);
      await _db.updateUser(updatedUser);
      state = updatedUser;
      print('✅ Tema impostato: $themeMode');
    } catch (e) {
      print('❌ Errore nell\'impostazione del tema: $e');
      rethrow;
    }
  }

  /// Aggiorna il numero totale di stage pianificati
  Future<void> setTotalStagesPlanned(int total) async {
    try {
      if (state == null) throw Exception('Nessun utente caricato');

      final updatedUser = state!.copyWith(totalStagesPlanned: total);
      await _db.updateUser(updatedUser);
      state = updatedUser;
      print('✅ Stage pianificati impostati: $total');
    } catch (e) {
      print('❌ Errore nell\'impostazione degli stage: $e');
      rethrow;
    }
  }

  /// Cancella l'utente
  Future<void> deleteUser() async {
    try {
      await _db.deleteUser();
      state = null;
      print('✅ Utente eliminato');
    } catch (e) {
      print('❌ Errore nell\'eliminazione dell\'utente: $e');
      rethrow;
    }
  }
}

/// Provider per l'utente corrente
final userProvider = StateNotifierProvider<UserNotifier, User?>((ref) {
  return UserNotifier();
});

/// Provider per il nome completo dell'utente
final userFullNameProvider = Provider<String?>((ref) {
  final user = ref.watch(userProvider);
  return user?.fullName;
});

/// Provider per l'età dell'utente
final userAgeProvider = Provider<int?>((ref) {
  final user = ref.watch(userProvider);
  return user?.age;
});

/// Provider per la percentuale di completamento
final userCompletionPercentageProvider = Provider<double>((ref) {
  final user = ref.watch(userProvider);
  return user?.completionPercentage ?? 0.0;
});

/// Provider per verificare se è un nuovo utente
final isNewUserProvider = Provider<bool>((ref) {
  final user = ref.watch(userProvider);
  return user?.isNewUser ?? false;
});

/// Provider per verificare se l'utente è attivo di recente
final isRecentlyActiveProvider = Provider<bool>((ref) {
  final user = ref.watch(userProvider);
  return user?.isRecentlyActive ?? false;
});

/// Provider per i giorni da registrazione
final daysSinceRegistrationProvider = Provider<int?>((ref) {
  final user = ref.watch(userProvider);
  return user?.daysSinceRegistration;
});

/// Provider per i giorni dall'ultimo accesso
final daysSinceLastLoginProvider = Provider<int?>((ref) {
  final user = ref.watch(userProvider);
  return user?.daysSinceLastLogin;
});

/// Provider per le preferenze dell'utente
final userPreferencesProvider = Provider<UserPreferences?>((ref) {
  final user = ref.watch(userProvider);
  if (user == null) return null;

  return UserPreferences(
    notificationsEnabled: user.notificationsEnabled,
    dailyReminderEnabled: user.dailyReminderEnabled,
    dailyReminderHour: user.dailyReminderHour,
    language: user.language,
    theme: user.theme,
  );
});

/// Provider per le statistiche dell'utente
final userStatsProvider = Provider<UserStats?>((ref) {
  final user = ref.watch(userProvider);
  if (user == null) return null;

  return UserStats(
    totalCompletedStages: user.totalCompletedStages,
    totalStagesPlanned: user.totalStagesPlanned,
    completionPercentage: user.completionPercentage,
    daysSinceRegistration: user.daysSinceRegistration,
    daysSinceLastLogin: user.daysSinceLastLogin,
    isRecentlyActive: user.isRecentlyActive,
  );
});

// ============ MODELS HELPER ============

/// Modello per le preferenze dell'utente
class UserPreferences {
  final bool notificationsEnabled;
  final bool dailyReminderEnabled;
  final int dailyReminderHour;
  final String language;
  final String theme;

  UserPreferences({
    required this.notificationsEnabled,
    required this.dailyReminderEnabled,
    required this.dailyReminderHour,
    required this.language,
    required this.theme,
  });

  @override
  String toString() => '''UserPreferences(
    notificationsEnabled: $notificationsEnabled,
    dailyReminderEnabled: $dailyReminderEnabled,
    dailyReminderHour: $dailyReminderHour,
    language: $language,
    theme: $theme,
  )''';
}

/// Modello per le statistiche dell'utente
class UserStats {
  final int totalCompletedStages;
  final int totalStagesPlanned;
  final double completionPercentage;
  final int daysSinceRegistration;
  final int? daysSinceLastLogin;
  final bool isRecentlyActive;

  UserStats({
    required this.totalCompletedStages,
    required this.totalStagesPlanned,
    required this.completionPercentage,
    required this.daysSinceRegistration,
    required this.daysSinceLastLogin,
    required this.isRecentlyActive,
  });

  @override
  String toString() => '''UserStats(
    totalCompletedStages: $totalCompletedStages,
    totalStagesPlanned: $totalStagesPlanned,
    completionPercentage: $completionPercentage,
    daysSinceRegistration: $daysSinceRegistration,
    daysSinceLastLogin: $daysSinceLastLogin,
    isRecentlyActive: $isRecentlyActive,
  )''';
}