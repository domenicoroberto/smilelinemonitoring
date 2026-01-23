/// Servizio di Analytics per tracciare gli eventi dell'app
/// Preparato per Firebase Analytics (TODO)
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();

  final List<AnalyticsEvent> _eventLog = [];
  bool _isInitialized = false;

  factory AnalyticsService() {
    return _instance;
  }

  AnalyticsService._internal();

  /// Inizializza il servizio di analytics
  Future<void> initialize() async {
    try {
      // TODO: Inizializzare Firebase Analytics
      // await Firebase.initializeApp();
      // _firebaseAnalytics = FirebaseAnalytics.instance;

      _isInitialized = true;
      print('✅ Analytics inizializzato');
    } catch (e) {
      print('❌ Errore nell\'inizializzazione di Analytics: $e');
      rethrow;
    }
  }

  bool get isInitialized => _isInitialized;

  // ============ ONBOARDING EVENTS ============

  /// Log: Utente ha completato l'onboarding
  Future<void> logOnboardingComplete({
    required int totalStages,
    required int stageADays,
    required int stageBDays,
    required int dailyWearingHours,
  }) async {
    try {
      final event = AnalyticsEvent(
        name: 'onboarding_complete',
        parameters: {
          'total_stages': totalStages,
          'stage_a_days': stageADays,
          'stage_b_days': stageBDays,
          'daily_wearing_hours': dailyWearingHours,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      _eventLog.add(event);

      // TODO: Inviare a Firebase
      // await _firebaseAnalytics.logEvent(
      //   name: event.name,
      //   parameters: event.parameters.cast<String, Object>(),
      // );

      print('✅ Event logged: ${event.name}');
    } catch (e) {
      print('❌ Errore nel logging dell\'evento: $e');
    }
  }

  /// Log: Utente ha iniziato l'onboarding
  Future<void> logOnboardingStart() async {
    try {
      final event = AnalyticsEvent(
        name: 'onboarding_start',
        parameters: {
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      _eventLog.add(event);

      print('✅ Event logged: onboarding_start');
    } catch (e) {
      print('❌ Errore nel logging: $e');
    }
  }

  /// Log: Utente ha saltato l'onboarding
  Future<void> logOnboardingSkipped() async {
    try {
      final event = AnalyticsEvent(
        name: 'onboarding_skipped',
        parameters: {
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      _eventLog.add(event);
      print('✅ Event logged: onboarding_skipped');
    } catch (e) {
      print('❌ Errore nel logging: $e');
    }
  }

  // ============ TIMER EVENTS ============

  /// Log: Utente ha avviato il timer
  Future<void> logTimerStart({
    String? stageId,
    String? stageNumber,
  }) async {
    try {
      final event = AnalyticsEvent(
        name: 'timer_start',
        parameters: {
          'stage_id': stageId,
          'stage_number': stageNumber,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      _eventLog.add(event);
      print('✅ Event logged: timer_start');
    } catch (e) {
      print('❌ Errore nel logging: $e');
    }
  }

  /// Log: Utente ha messo in pausa il timer
  Future<void> logTimerPause({
    required int elapsedSeconds,
  }) async {
    try {
      final event = AnalyticsEvent(
        name: 'timer_pause',
        parameters: {
          'elapsed_seconds': elapsedSeconds,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      _eventLog.add(event);
      print('✅ Event logged: timer_pause');
    } catch (e) {
      print('❌ Errore nel logging: $e');
    }
  }

  /// Log: Utente ha completato una sessione
  Future<void> logSessionCompleted({
    required int sessionLengthSeconds,
    required String stageNumber,
    required int totalHoursForDay,
  }) async {
    try {
      final event = AnalyticsEvent(
        name: 'session_completed',
        parameters: {
          'session_length_seconds': sessionLengthSeconds,
          'stage_number': stageNumber,
          'total_hours_for_day': totalHoursForDay,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      _eventLog.add(event);
      print('✅ Event logged: session_completed');
    } catch (e) {
      print('❌ Errore nel logging: $e');
    }
  }

  // ============ STAGE EVENTS ============

  /// Log: Utente ha completato uno stage
  Future<void> logStageCompleted({
    required int stageNumber,
    required String stageType,
    required int totalHoursLogged,
    required int plannedHours,
  }) async {
    try {
      final compliancePercentage =
      (totalHoursLogged / plannedHours * 100).toStringAsFixed(2);

      final event = AnalyticsEvent(
        name: 'stage_completed',
        parameters: {
          'stage_number': stageNumber,
          'stage_type': stageType,
          'total_hours_logged': totalHoursLogged,
          'planned_hours': plannedHours,
          'compliance_percentage': compliancePercentage,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      _eventLog.add(event);
      print('✅ Event logged: stage_completed');
    } catch (e) {
      print('❌ Errore nel logging: $e');
    }
  }

  /// Log: Stage cambiato
  Future<void> logStageChanged({
    required int fromStage,
    required int toStage,
  }) async {
    try {
      final event = AnalyticsEvent(
        name: 'stage_changed',
        parameters: {
          'from_stage': fromStage,
          'to_stage': toStage,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      _eventLog.add(event);
      print('✅ Event logged: stage_changed');
    } catch (e) {
      print('❌ Errore nel logging: $e');
    }
  }

  // ============ MILESTONE EVENTS ============

  /// Log: Utente ha raggiunto un milestone
  Future<void> logMilestoneReached({
    required int percentage,
    required int totalStagesCompleted,
  }) async {
    try {
      final event = AnalyticsEvent(
        name: 'milestone_reached',
        parameters: {
          'percentage': percentage,
          'total_stages_completed': totalStagesCompleted,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      _eventLog.add(event);
      print('✅ Event logged: milestone_reached');
    } catch (e) {
      print('❌ Errore nel logging: $e');
    }
  }

  // ============ SETTINGS EVENTS ============

  /// Log: Utente ha cambiato le impostazioni
  Future<void> logSettingsChanged({
    required String setting,
    required dynamic oldValue,
    required dynamic newValue,
  }) async {
    try {
      final event = AnalyticsEvent(
        name: 'settings_changed',
        parameters: {
          'setting': setting,
          'old_value': oldValue.toString(),
          'new_value': newValue.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      _eventLog.add(event);
      print('✅ Event logged: settings_changed');
    } catch (e) {
      print('❌ Errore nel logging: $e');
    }
  }

  // ============ ERROR EVENTS ============

  /// Log: Errore nell'app
  Future<void> logError({
    required String errorType,
    required String message,
    String? stackTrace,
  }) async {
    try {
      final event = AnalyticsEvent(
        name: 'app_error',
        parameters: {
          'error_type': errorType,
          'message': message,
          'stack_trace': stackTrace,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      _eventLog.add(event);
      print('⚠️ Error logged: $message');
    } catch (e) {
      print('❌ Errore nel logging dell\'errore: $e');
    }
  }

  // ============ ENGAGEMENT EVENTS ============

  /// Log: Utente ha aperto l'app
  Future<void> logAppOpen() async {
    try {
      final event = AnalyticsEvent(
        name: 'app_open',
        parameters: {
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      _eventLog.add(event);
      print('✅ Event logged: app_open');
    } catch (e) {
      print('❌ Errore nel logging: $e');
    }
  }

  /// Log: Utente ha chiuso l'app
  Future<void> logAppClose() async {
    try {
      final event = AnalyticsEvent(
        name: 'app_close',
        parameters: {
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      _eventLog.add(event);
      print('✅ Event logged: app_close');
    } catch (e) {
      print('❌ Errore nel logging: $e');
    }
  }

  // ============ UTILITY ============

  /// Ottiene tutti gli eventi registrati
  List<AnalyticsEvent> getEventLog() => List.unmodifiable(_eventLog);

  /// Ottiene il numero di eventi registrati
  int get eventCount => _eventLog.length;

  /// Pulisce il log degli eventi
  void clearEventLog() {
    _eventLog.clear();
    print('✅ Event log pulito');
  }

  /// Esporta il log degli eventi in JSON
  List<Map<String, dynamic>> exportEventLog() {
    return _eventLog.map((e) => e.toJson()).toList();
  }

  /// Stampa il log degli eventi
  void printEventLog() {
    print('\n📊 ANALYTICS EVENT LOG');
    print('━' * 60);
    for (var event in _eventLog) {
      print('${event.name} - ${event.parameters['timestamp']}');
    }
    print('━' * 60);
    print('Total events: ${_eventLog.length}\n');
  }

  @override
  String toString() => 'AnalyticsService($_isInitialized)';
}

// ============ MODELS ============

/// Modello per un evento di analytics
class AnalyticsEvent {
  final String name;
  final Map<String, dynamic> parameters;

  AnalyticsEvent({
    required this.name,
    required this.parameters,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'parameters': parameters,
  };

  @override
  String toString() => 'AnalyticsEvent($name)';
}