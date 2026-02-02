import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smileline_monitoring/screens/main_screens/reminder_timer_provider.dart';
import '../../config/theme.dart';
import '../../models/treatment_plan.dart';
import '../../models/user.dart';
import '../../providers/tracking_provider.dart';
import '../../providers/treatment_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/timer_provider.dart';
import '../../services/database_service.dart';
import '../../services/midnight_service.dart';
import '../../services/notification_service.dart';
import '../../services/background_timer_service.dart';
import '../../services/smart_timer_sync.dart';
import '../../services/timer_service.dart' hide TimerState;
import '../../widgets/wear_aligner_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  final BackgroundTimerService _bgTimer = BackgroundTimerService();
  final SmartTimerSync _smartSync = SmartTimerSync();
  bool _smartSyncInitialized = false;
  bool _isFirstBuild = true;  // ✅ Track if this is the first build

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initializeSmartSync();
    _initializeBackgroundTimer();
    _setupEmergencySave();
  }

  Future<void> _initializeSmartSync() async {
    try {
      await _smartSync.initialize();
      _smartSyncInitialized = true;
      print('✅ SmartTimerSync inizializzato');
    } catch (e) {
      print('❌ Errore SmartTimerSync: $e');
      _smartSyncInitialized = false;
    }
  }

  Future<void> _initializeBackgroundTimer() async {
    try {
      await _bgTimer.initialize();
      print('✅ BackgroundTimerService inizializzato');
    } catch (e) {
      print('❌ Errore BackgroundTimerService: $e');
    }
  }

  void _setupEmergencySave() {
    _saveStateToPreferences();
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _saveStateToPreferences();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _saveStateToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isRunning = _bgTimer.isTimerRunning();
      final dailySeconds = _bgTimer.getDailySeconds();
      final startTime = _bgTimer.getTimerStartTime();
      final now = DateTime.now();

      prefs.setString('app_last_state_saved_at', now.toIso8601String());
      prefs.setBool('app_last_timer_was_running', isRunning);
      prefs.setInt('app_last_daily_seconds', dailySeconds);

      if (isRunning && startTime != null) {
        prefs.setString('app_last_timer_start_time', startTime.toIso8601String());
      }

      print('💾 BACKUP: $dailySeconds sec, running: $isRunning');
    } catch (e) {
      print('⚠️ Errore backup: $e');
    }
  }

  /// ✅ Sincronizza il timer
  /// Chiamata OGNI VOLTA che l'app si riavvia o torna da background
  Future<void> _syncTimerOnAppOpen() async {
    try {
      print('\n========================================');
      print('🔄 SINCRONIZZAZIONE AL RIAVVIO');
      print('========================================\n');

      final prefs = await SharedPreferences.getInstance();
      final lastSyncedClosedAt = prefs.getString('last_synced_closed_at');
      final currentClosedAt = prefs.getString('app_closed_at');

      // ✅ Se sono uguali, significa che l'app è tornata dal background
      // e NON da una vera chiusura, quindi skip!
      if (lastSyncedClosedAt == currentClosedAt && currentClosedAt != null) {
        print('⏭️ Già sincronizzato questa chiusura - Skip');
        return;
      }

      // ✅ LEGGI DALLE CHIAVI CORRETTE (come le salva BackgroundTimerService)
      var closedAtStr = prefs.getString('app_closed_at');
      var wasRunning = prefs.getBool('was_running_on_close');
      var wasRunningStr = prefs.getString('was_running_on_close_str') ?? 'false';
      //var currentDaily = prefs.getInt('app_closed_daily_seconds');  // ← Questa chiave
      var timerStartStr = prefs.getString('app_close_timer_start_time');




      print('📊 STATO SALVATO ALLA CHIUSURA:');
      print('   - closedAt: $closedAtStr');
      print('   - wasRunning: $wasRunning');
      //print('   - dailySeconds: $currentDaily');


      // ✅ CRITICO: Leggi il valore ATTUALE da BackgroundTimerService, non dal backup!


      // SE NON ESISTE, usa il BACKUP (da _setupEmergencySave)
      if (closedAtStr == null|| wasRunning == null) {
        print('⚠️ Stato chiusura non trovato, uso BACKUP');

        closedAtStr = prefs.getString('app_last_state_saved_at');
        wasRunning = prefs.getBool('app_last_timer_was_running') ?? false;
        //currentDaily = prefs.getInt('app_last_daily_seconds') ?? 0;  // ← Backup
        timerStartStr = prefs.getString('app_last_timer_start_time');


        print('📊 STATO BACKUP:');
        print('   - closedAt: $closedAtStr');
        print('   - wasRunning: $wasRunning');
        //print('   - dailySeconds: $currentDaily');
      }
      final currentDaily = _bgTimer.getDailySeconds();
      print('   - dailySeconds: $currentDaily');

      if (closedAtStr == null) {
        print('⭕ Nessun stato salvato');
        return;
      }

      final now = DateTime.now();
      final closedAt = DateTime.parse(closedAtStr);

      // Calcola il cambio giorno
      final closedDay = DateTime(closedAt.year, closedAt.month, closedAt.day);
      final nowDay = DateTime(now.year, now.month, now.day);
      final dayChanged = closedDay != nowDay;

      print('\n🌙 ANALISI GIORNO:');
      print('   - Giorno chiusura: ${closedDay.toIso8601String().split('T')[0]}');
      print('   - Giorno adesso: ${nowDay.toIso8601String().split('T')[0]}');
      print('   - Cambiato: $dayChanged');

      if (!mounted) {
        return;
      }

      // ✅ CASO 1: ERA RUNNING E STESSO GIORNO
      /// ✅ In HomeScreen._syncTimerOnAppOpen()
      if (wasRunning == true && !dayChanged && timerStartStr != null && timerStartStr!.isNotEmpty) {
        print('\n✅ CASO 1: ERA RUNNING (STESSO GIORNO)');

        final secondsLost = now.difference(closedAt).inSeconds;
        final currentDailyBefore = currentDaily;  // ← Salva il valore PRIMA
        final newTotal = currentDaily + secondsLost;  // ← Somma correttamente

        print('   - Chiuso alle: ${closedAt.toIso8601String()}');
        print('   - Riaperto alle: ${now.toIso8601String()}');
        print('   - Secondi passati in chiusura: $secondsLost');
        print('   - Daily precedente: $currentDailyBefore');  // ← Stampa il valore prima
        print('   - Totale aggiornato: $newTotal');  // ← Stampa il totale NUOVO

        // ✅ Salva il nuovo totale
        await _bgTimer.saveDailySeconds(newTotal);

        // ✅ Riavvia il timer
        await _bgTimer.saveTimerStart();

        // ✅ Sincronizza con Riverpod
        if (mounted) {
          ref.read(timerProvider.notifier).syncRunningTimerFromBackground(newTotal);
        }
        ref.read(timerProvider.notifier).start();

        print('   ✅ Timer RIPRESO: ${currentDailyBefore}s + ${secondsLost}s = ${newTotal}s\n');
      }

      // ✅ CASO 2: ERA RUNNING E GIORNO CAMBIATO
      else if (wasRunning == true && dayChanged && timerStartStr != null && timerStartStr!.isNotEmpty) {
        print('\n✅ CASO 2: ERA RUNNING (GIORNO CAMBIATO)');

        final timerStart = DateTime.parse(timerStartStr!);
        final midnight = DateTime(closedAt.year, closedAt.month, closedAt.day + 1);
        final secondsUntilMidnight = midnight.difference(timerStart).inSeconds;
        final secondsFromMidnight = now.difference(midnight).inSeconds;
        final totalToPreviousDay = (currentDaily ?? 0) + secondsUntilMidnight;

        print('   - Secondi fino a mezzanotte (giorno precedente): $secondsUntilMidnight');
        print('   - Secondi da mezzanotte: $secondsFromMidnight');
        print('   - Totale giorno precedente: $totalToPreviousDay');

        // ✅ Salva nel DB il giorno PRECEDENTE (closedDay)
        final db = DatabaseService();
        if (!db.isInitialized) {
          await db.initialize();
        }

        final treatmentPlanId = ref.read(treatmentPlanProvider)?.id ?? '';
        await db.saveDailyUsage(
          date: closedDay,  // ← GIORNO PRECEDENTE
          totalSeconds: totalToPreviousDay,
          treatmentPlanId: treatmentPlanId,
          targetHours: 22,
        );
        print('   ✅ Salvato nel DB ${closedDay.toIso8601String().split('T')[0]}: $totalToPreviousDay sec');

        // ✅ Aggiorna last_day_check per il nuovo giorno
        await _bgTimer.checkDayChanged();

        // ✅ Reset per nuovo giorno
        await _bgTimer.saveDailySeconds(secondsFromMidnight);
        await prefs.setString('timer_start_time', midnight.toIso8601String());
        await _bgTimer.saveTimerStart();

        // ✅ Sincronizza con Riverpod
        if (mounted) {
          ref.read(timerProvider.notifier).syncRunningTimerFromBackground(secondsFromMidnight);
        }
        ref.read(timerProvider.notifier).start();

        print('   ✅ Timer RIPRESO da mezzanotte a $secondsFromMidnight secondi\n');
      }

      // ✅ CASO 3: ERA PAUSED E STESSO GIORNO
      else if (wasRunning == false && !dayChanged) {
        print('\n✅ CASO 3: ERA PAUSED (STESSO GIORNO)');
        print('   - Valore: $currentDaily secondi');

        // ✅ Salva nel BackgroundTimer
        await _bgTimer.saveDailySeconds(currentDaily ?? 0);

        // ✅ Sincronizza con Riverpod in modalità PAUSED
        if (mounted) {
          ref.read(timerProvider.notifier).setSyncedTimeWhilePaused(currentDaily ?? 0);
        }

        print('   ✅ Timer sincronizzato (fermo a $currentDaily secondi)\n');
      }

      // ✅ CASO 4: ERA PAUSED E GIORNO CAMBIATO
      // ✅ CASO 4: ERA PAUSED E GIORNO CAMBIATO
      else if (wasRunning == false && dayChanged) {
        print('\n✅ CASO 4: ERA PAUSED (GIORNO CAMBIATO)');
        print('   - Valore giorno precedente: $currentDaily secondi');

        // ✅ Reset per nuovo giorno
        await _bgTimer.saveDailySeconds(0);
        await prefs.remove('timer_start_time');

        // ✅ Sincronizza con Riverpod
        if (mounted) {
          ref.read(timerProvider.notifier).setSyncedTimeWhilePaused(0);
        }

        print('   ✅ Timer resettato per il nuovo giorno\n');
      }


      else {
        print('\n⭕ Nessun caso corrispondente');
      }

      // ✅ NON pulire gli stati di chiusura!
      // Rimangono per la prossima sincronizzazione
      // await prefs.remove('app_closed_at');
      // await prefs.remove('was_running_on_close');
      // await prefs.remove('app_close_timer_start_time');
      // await prefs.remove('app_closed_daily_seconds');
      await prefs.setString('last_synced_closed_at', currentClosedAt ?? '');

      print('========================================');
      print('✅ SINCRONIZZAZIONE COMPLETATA');
      print('========================================\n');

    } catch (e) {
      print('❌ ERRORE sincronizzazione: $e');
      print(e.toString());
    }
  }

  /// ✅ Quando l'app ritorna in foreground
  bool _hasSyncedOnce = false;  // ← Aggiungi questo


  // ❌ TOGLI TUTTO QUESTO DA HomeScreen
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      print('📴 App in background - Salvataggio stato...');
      _saveFinalState();
    }
    else if (state == AppLifecycleState.detached) {
      print('🛑 App chiusura - Salvataggio stato...');
      _saveFinalState();
    }
    // ❌ NON sincronizzare qui
  }

  /// ✅ SALVA LO STATO AL CHIUSURA
  Future<void> _saveFinalState() async {
    try {
      if (!_smartSyncInitialized) {
        await _smartSync.initialize();
        _smartSyncInitialized = true;
      }

      await _smartSync.saveCloseState();
      print('📴 Stato salvato');
    } catch (e) {
      print('⚠️ Errore salvataggio: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _smartSync.dispose();
    super.dispose();
  }

  Map<String, dynamic> _calculateStepCounters(TreatmentPlan treatment) {
    try {
      final now = DateTime.now();
      final startDate = treatment.startDate;

      final stageADays = treatment.stageADays;
      final stageBDays = treatment.stageBDays;
      final totalStages = treatment.totalStages;

      final daysPerChange = (stageADays > stageBDays) ? stageADays : stageBDays;
      final totalDays = daysPerChange * totalStages;

      final startDateMidnight = DateTime(startDate.year, startDate.month, startDate.day);
      final nowMidnight = DateTime(now.year, now.month, now.day);
      final daysPassed = nowMidnight.difference(startDateMidnight).inDays;

      final currentStepNumber = (daysPassed ~/ daysPerChange) + 1;
      final clampedStep = currentStepNumber.clamp(1, totalStages);

      final dayInCurrentStep = (daysPassed % daysPerChange) + 1;
      final daysToSwitch = daysPerChange - dayInCurrentStep;

      final endDate = startDate.add(Duration(days: totalDays));
      final daysRemaining = endDate.difference(now).inDays;

      final progressPercentage = ((daysPassed / totalDays) * 100).clamp(0.0, 100.0);

      return {
        'currentStepNumber': clampedStep,
        'dayInCurrentStep': dayInCurrentStep,
        'daysPerChange': daysPerChange,
        'daysToSwitch': daysToSwitch,
        'progressPercentage': progressPercentage,
        'daysRemaining': daysRemaining,
        'endDate': endDate,
        'totalDays': totalDays,
      };
    } catch (e) {
      print('❌ Errore contatori: $e');
      return {
        'currentStepNumber': 1,
        'dayInCurrentStep': 1,
        'daysPerChange': 3,
        'daysToSwitch': 0,
        'progressPercentage': 0.0,
        'daysRemaining': 0,
        'endDate': DateTime.now(),
        'totalDays': 36,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final treatment = ref.watch(treatmentPlanProvider);
    final user = ref.watch(userProvider);
    final timerState = ref.watch(timerProvider);
    final reminderState = ref.watch(reminderTimerProvider);

    // ✅ Sincronizza al primo build
    if (_isFirstBuild && treatment != null && user != null) {
      _isFirstBuild = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncTimerOnAppOpen();
      });
    }

    final isSmallScreen = MediaQuery.of(context).size.width < 380;
    final screenHeight = MediaQuery.of(context).size.height;
    final isShortScreen = screenHeight < 700;

    if (treatment == null || user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Nessun piano di trattamento'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/onboarding'),
                child: const Text('Inizia'),
              ),
            ],
          ),
        ),
      );
    }

    final counters = _calculateStepCounters(treatment);
    final currentStepNumber = counters['currentStepNumber'] as int;
    final dayInCurrentStep = counters['dayInCurrentStep'] as int;
    final daysPerChange = counters['daysPerChange'] as int;
    final daysToSwitch = counters['daysToSwitch'] as int;

    final targetSeconds = 22 * 3600;
    final totalDailySeconds = _bgTimer.getTotalSeconds();
    final usagePercentage = (totalDailySeconds / targetSeconds) * 100;
    final clampedUsagePercentage = usagePercentage.clamp(0.0, 100.0);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildBlueHeader(context, user, isSmallScreen),
            _buildWhiteCard(
              child: Column(
                children: [
                  if (reminderState.isActive) ...[
                    _buildReminderCountdown(reminderState, ref, isSmallScreen),
                    SizedBox(height: isShortScreen ? 16 : 32),
                  ],
                  _buildCircularProgress(clampedUsagePercentage, isSmallScreen, isShortScreen),
                  SizedBox(height: isShortScreen ? 12 : 24),
                  _buildTimeDisplay(timerState, isSmallScreen),
                  SizedBox(height: isShortScreen ? 16 : 32),
                  _buildMainButton(context, ref, timerState, isSmallScreen),
                  SizedBox(height: isShortScreen ? 16 : 32),
                  _buildStepInfoSection(
                    treatment,
                    currentStepNumber,
                    dayInCurrentStep,
                    daysPerChange,
                    daysToSwitch,
                    isSmallScreen,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildReminderCountdown(ReminderTimerState state, WidgetRef ref, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.overlap.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.overlap.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Riprendi l\'uso degli allineatori',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: AppColors.graphite,
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Text(
            state.formattedTime,
            style: TextStyle(
              fontSize: isSmallScreen ? 28 : 36,
              fontWeight: FontWeight.bold,
              color: AppColors.overlap,
              fontFamily: 'monospace',
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.progress,
              minHeight: 6,
              backgroundColor: AppColors.overlap.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.overlap),
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref.read(reminderTimerProvider.notifier).cancelCountdown();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.overlap,
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 10),
              ),
              child: Text(
                'Annulla reminder',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlueHeader(BuildContext context, User user, bool isSmallScreen) {
    final userInitial = user.name.isNotEmpty
        ? user.name.substring(0, 1).toUpperCase()
        : '?';

    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topPadding + 8,
        left: 16,
        right: 16,
        bottom: 4,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.blue, AppColors.overlap],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo2.png',
            width: isSmallScreen ? 126 : 140,
            height: isSmallScreen ? 45 : 60,
            fit: BoxFit.contain,
          ),
          CircleAvatar(
            backgroundColor: AppColors.white.withOpacity(0.3),
            radius: isSmallScreen ? 18 : 22,
            child: Text(
              userInitial,
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 20,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhiteCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildCircularProgress(double percentage, bool isSmallScreen, bool isShortScreen) {
    final circleSize = isSmallScreen ? 140.0 : isShortScreen ? 160.0 : 200.0;
    final percentageSize = isSmallScreen ? 38.0 : isShortScreen ? 42.0 : 56.0;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.lightBlue.withOpacity(0.5),
                width: 2,
              ),
            ),
          ),
          SizedBox(
            width: circleSize,
            height: circleSize,
            child: CustomPaint(
              painter: CircleProgressPainter(
                percentage: percentage,
                color: AppColors.blue,
                backgroundColor: AppColors.lightBlue.withOpacity(0.2),
              ),
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: percentageSize,
              fontWeight: FontWeight.bold,
              color: AppColors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay(TimerState timerState, bool isSmallScreen) {
    final totalSeconds = _bgTimer.getTotalSeconds();
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    final formattedDailyTime = '$hours:$minutes:$seconds';

    return Column(
      children: [
        Text(
          'Tempo di utilizzo oggi',
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          formattedDailyTime,
          style: TextStyle(
            fontSize: isSmallScreen ? 36 : 48,
            fontWeight: FontWeight.bold,
            color: AppColors.graphite,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildMainButton(
      BuildContext context,
      WidgetRef ref,
      TimerState timerState,
      bool isSmallScreen,
      ) {
    final isRunning = timerState.isRunning;
    final buttonText = isRunning ? 'Rimuovi' : 'Indossa';
    final buttonIcon = isRunning ? Icons.pause : Icons.play_arrow;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          if (isRunning) {
            _showRemovalConfirmation(context, ref);
          } else {
            ref.read(reminderTimerProvider.notifier).cancelCountdown();
            _showWearAlignerDialog(context, ref);
          }
        },
        icon: Icon(buttonIcon),
        label: Text(
          buttonText,
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: AppColors.white,
          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showWearAlignerDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => WearAlignerDialog(
        onConfirm: () {
          ref.read(timerProvider.notifier).start();
        },
      ),
    );
  }

  void _showRemovalConfirmation(BuildContext context, WidgetRef ref) {
    int selectedMinutes = 1;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ricordami di rimettere gli allineatori',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.graphite,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tra quanto tempo vuoi che ti ricordi?',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    /*
                    const SizedBox(height: 24),
                    _buildTimeOption(
                      minutes: 1,
                      selected: selectedMinutes == 1,
                      onTap: () => setState(() => selectedMinutes = 1),
                      label: '1 minuto (TEST)',
                    ),*/
                    const SizedBox(height: 12),
                    _buildTimeOption(
                      minutes: 30,
                      selected: selectedMinutes == 30,
                      onTap: () => setState(() => selectedMinutes = 30),
                      label: '30 minuti',
                    ),
                    const SizedBox(height: 12),
                    _buildTimeOption(
                      minutes: 60,
                      selected: selectedMinutes == 60,
                      onTap: () => setState(() => selectedMinutes = 60),
                      label: '60 minuti (1 ora)',
                    ),
                    const SizedBox(height: 12),
                    _buildTimeOption(
                      minutes: 90,
                      selected: selectedMinutes == 90,
                      onTap: () => setState(() => selectedMinutes = 90),
                      label: '90 minuti (1.5 ore)',
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppColors.blue, width: 2),
                            ),
                            child: const Text(
                              'Annulla',
                              style: TextStyle(
                                color: AppColors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final preferences = ref.read(userPreferencesProvider);

                              if (preferences != null && !preferences.notificationsEnabled) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('⚠️ Le notifiche sono disabilitate nelle impostazioni'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }

                              ref.read(timerProvider.notifier).pause();
                              ref.read(reminderTimerProvider.notifier)
                                  .startCountdown(selectedMinutes);

                              if (preferences != null && preferences.notificationsEnabled) {
                                NotificationService().scheduleReminder(
                                  minutesFromNow: selectedMinutes,
                                  title: 'Ricordati gli allineatori!',
                                  body: 'È ora di rimettere i tuoi allineatori',
                                );
                              }

                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Conferma',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeOption({
    required int minutes,
    required bool selected,
    required VoidCallback onTap,
    required String label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.blue : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.blue : AppColors.border,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.blue,
                  ),
                ),
              )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppColors.blue : AppColors.graphite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepInfoSection(
      TreatmentPlan treatment,
      int currentStepNumber,
      int dayInCurrentStep,
      int daysPerChange,
      int daysToSwitch,
      bool isSmallScreen,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informazioni Utilizzo',
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: AppColors.graphite,
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 20),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                title: 'Step',
                value: '$currentStepNumber',
                subtitle: 'di ${treatment.totalStages}',
                isSmallScreen: isSmallScreen,
              ),
            ),
            SizedBox(width: isSmallScreen ? 10 : 16),
            Expanded(
              child: _buildInfoCard(
                title: 'Giorno Corrente',
                value: '$dayInCurrentStep',
                subtitle: 'di ${daysPerChange}gg',
                isSmallScreen: isSmallScreen,
              ),
            ),
            SizedBox(width: isSmallScreen ? 10 : 16),
            Expanded(
              child: _buildInfoCard(
                title: 'Cambio',
                value: '$daysToSwitch',
                subtitle: 'giorni rimanenti',
                isSmallScreen: isSmallScreen,
                isWarning: daysToSwitch == 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required String subtitle,
    required bool isSmallScreen,
    bool isWarning = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.lightBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.lightBlue.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 24 : 32,
              fontWeight: FontWeight.bold,
              color: isWarning ? Colors.red : AppColors.blue,
            ),
          ),
          SizedBox(height: isSmallScreen ? 4 : 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: isSmallScreen ? 9 : 11,
              color: AppColors.textHint,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.blue,
      unselectedItemColor: AppColors.textSecondary,
      currentIndex: 0,
      onTap: (index) => _navigateToTab(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Impostazioni',
        ),
      ],
    );
  }

  void _navigateToTab(BuildContext context, int index) {
    final routes = ['/home', '/history', '/settings'];
    if (index != 0) {
      Navigator.pushNamed(context, routes[index]);
    }
  }
}

class CircleProgressPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color backgroundColor;

  CircleProgressPainter({
    required this.percentage,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    final sweepAngle = (percentage / 100) * (2 * 3.14159);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      sweepAngle,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(CircleProgressPainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}