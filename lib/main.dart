import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'config/theme.dart';
import 'config/constants.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/timer_service.dart';
import 'services/background_timer_service.dart';
import 'services/background_work_service.dart';
import 'services/midnight_service.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/main_screens/home_screen.dart';
import 'screens/main_screens/timer_screen.dart';
import 'screens/main_screens/history_screen.dart';
import 'screens/main_screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('\n' + '='*70);
  print('🚀 AVVIO APP - INIZIALIZZAZIONE SERVIZI');
  print('='*70);

  // ⭐ STEP 1: Richiedi permessi notifiche (PRIMA di tutto!)
  await _requestNotificationPermission();

  // ⭐ STEP 2: Inizializza Hive
  await Hive.initFlutter();
  print('✅ Hive inizializzato');

  // ⭐ STEP 3: Inizializza Database
  final databaseService = DatabaseService();
  await databaseService.initialize();
  print('✅ DatabaseService inizializzato');

  // ✅ DEBUG: Verifica cosa c'è nel database
  _debugDatabaseContent(databaseService);

  // ⭐ STEP 4: Inizializza Background Timer
  final bgTimer = BackgroundTimerService();
  await bgTimer.initialize();
  print('✅ BackgroundTimerService inizializzato');

  // ✅ DEBUG: Verifica lo stato del timer
  _debugTimerState(bgTimer);

  // ⭐ STEP 5: Inizializza NotificationService (DOPO permessi!)
  final notificationService = NotificationService();
  await notificationService.initialize();
  print('✅ NotificationService inizializzato');

  // ⭐ STEP 6: Inizializza Background Work
  final backgroundWork = BackgroundWorkService();
  await backgroundWork.initialize();
  await backgroundWork.schedulePeriodicTask();
  print('✅ BackgroundWorkService inizializzato (task ogni 1 minuto)');

  // ⭐ STEP 7: Inizializza MidnightService
  final midnightService = MidnightService();
  await midnightService.initialize();
  print('✅ MidnightService inizializzato - Sistema mezzanotte attivo');

  print('\n' + '='*70);
  print('✅ INIZIALIZZAZIONE COMPLETATA');
  print('='*70 + '\n');

  runApp(const ProviderScope(child: SmileLineMonitoringApp()));
}

/// ✅ Richiedi permessi notifiche per Android e iOS
Future<void> _requestNotificationPermission() async {
  if (Platform.isAndroid) {
    try {
      print('📱 Richiedendo permessi notifiche Android...');

      final status = await Permission.notification.request();

      if (status.isDenied) {
        print('❌ Permesso notifiche Android NEGATO');
      } else if (status.isGranted) {
        print('✅ Permesso notifiche Android CONCESSO');
      } else if (status.isPermanentlyDenied) {
        print('⚠️ Permesso notifiche Android NEGATO PERMANENTEMENTE');
        openAppSettings();
      }
    } catch (e) {
      print('❌ Errore nella richiesta del permesso notifiche Android: $e');
    }
  } else if (Platform.isIOS) {
    try {
      print('📱 Richiedendo permessi notifiche iOS via plugin...');

      // ⭐ Skip permission_handler su iOS
      // Usa direttamente il plugin che mostra il popup nativo
      await _requestIOSNotificationPermissions();

    } catch (e) {
      print('❌ Errore iOS: $e');
    }
  }
}

/// ✅ Richiedi esplicitamente i permessi iOS al plugin (MOSTRA IL POPUP NATIVO)
Future<void> _requestIOSNotificationPermissions() async {
  try {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    print('🔔 Mostro popup nativo iOS per notifiche...');

    final iOSPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    if (iOSPlugin != null) {
      final result = await iOSPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      if (result ?? false) {
        print('✅ Permessi iOS plugin CONCESSI - Notifiche abilitate!');
      } else {
        print('⚠️ Permessi iOS plugin NEGATI - Notifiche disabilitate');
      }
    } else {
      print('❌ Plugin iOS non trovato');
    }
  } catch (e) {
    print('❌ Errore nel richiedere permessi iOS plugin: $e');
  }
}

/// ✅ DEBUG: Controlla il contenuto del database
void _debugDatabaseContent(DatabaseService db) {
  try {
    print('\n' + '-'*70);
    print('🔍 DEBUG DATABASE CONTENT');
    print('-'*70);

    // Utente
    final user = db.getCurrentUser();
    print('\n👤 UTENTE:');
    print('   Nome: ${user?.name ?? "NESSUNO"}');
    print('   ID: ${user?.id ?? "NULL"}');
    print('   Current Treatment Plan ID: ${user?.currentTreatmentPlanId ?? "NULL"}');

    // Piano di trattamento
    if (user?.currentTreatmentPlanId != null) {
      final plan = db.getTreatmentPlan(user!.currentTreatmentPlanId!);
      print('\n📋 TREATMENT PLAN:');
      print('   ID: ${plan?.id ?? "NULL"}');
      print('   📅 INIZIO: ${plan?.startDate.toIso8601String() ?? "NULL"}');
      print('   📅 FINE PREVISTA: ${plan?.endDate.toIso8601String() ?? "NULL"}');
      print('   Stage A: ${plan?.stageADays}d');
      print('   Stage B: ${plan?.stageBDays}d');
      print('   Total Stages: ${plan?.totalStages}');
      print('   Daily Target: ${plan?.dailyWearingHours}h');
      print('   Giorni rimanenti: ${plan?.daysRemaining ?? "?"}');
      print('   Progresso: ${plan?.progressPercentage.toStringAsFixed(1) ?? "?"}%');
    }

    // Tracking giornaliero
    final today = DateTime.now();
    final todayTracking = db.getDailyTrackingByDate(today);
    print('\n📊 TRACKING OGGI (${today.toIso8601String()}):');
    if (todayTracking != null) {
      print('   ✅ TROVATO!');
      print('   ID: ${todayTracking.id}');
      print('   Ore: ${todayTracking.wearingHours}h ${todayTracking.wearingMinutes}m');
      print('   Target: ${todayTracking.targetHours}h');
      print('   Compliance: ${todayTracking.compliancePercentage.toStringAsFixed(1)}%');
    } else {
      print('   ❌ NESSUN DATO PER OGGI');
    }

    // Ultimi 7 giorni
    print('\n📅 ULTIMI 7 GIORNI:');
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final tracking = db.getDailyTrackingByDate(date);

      if (tracking != null) {
        print('   ${date.toIso8601String()}: ✅ ${tracking.wearingHours}h ${tracking.wearingMinutes}m');
      } else {
        print('   ${date.toIso8601String()}: ❌ NESSUN DATO');
      }
    }

    print('\n' + '-'*70 + '\n');
  } catch (e) {
    print('❌ ERRORE DEBUG DATABASE: $e');
  }
}

/// ✅ DEBUG: Controlla lo stato del timer nel background
void _debugTimerState(BackgroundTimerService bgTimer) {
  try {
    print('\n' + '-'*70);
    print('⏱️ DEBUG BACKGROUND TIMER STATE');
    print('-'*70);

    final state = bgTimer.getTimerState();
    print('\n📊 STATO ATTUALE:');
    print('   isRunning: ${state['isRunning']}');
    print('   totalSeconds: ${state['totalSeconds']}s');
    print('   dailySeconds: ${state['dailySeconds']}s');
    print('   startTime: ${state['startTime'] ?? "NULL"}');

    // Converti in ore:minuti
    final total = state['totalSeconds'] as int;
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final seconds = total % 60;
    print('\n⏱️ FORMATO LEGGIBILE:');
    print('   Tempo totale: ${hours}h ${minutes}m ${seconds}s');

    print('\n' + '-'*70 + '\n');
  } catch (e) {
    print('❌ ERRORE DEBUG TIMER: $e');
  }
}

class SmileLineMonitoringApp extends ConsumerWidget {
  const SmileLineMonitoringApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timerService = TimerService();
      timerService.setRef(ref);
      print('✅ TimerService inizializzato con ref');
    });

    return MaterialApp(
      title: 'SmileLine Monitoring',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const HomeScreen(),
        '/timer': (context) => const TimerScreen(),
        '/history': (context) => const HistoryScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}