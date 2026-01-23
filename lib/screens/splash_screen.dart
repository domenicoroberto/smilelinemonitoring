import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/app_state_provider.dart';
import '../services/background_timer_service.dart';
import '../providers/timer_provider.dart';
import '../services/timer_service.dart' hide TimerState;

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// ✅ SINCRONIZZA IL TIMER DAL BACKGROUND E INIZIALIZZA
  Future<void> _initializeApp() async {
    try {
      print('🔄 SplashScreen: Inizio inizializzazione...');

      // ✅ 1️⃣ SINCRONIZZA IL TIMER DAL BACKGROUND
      await _syncTimerFromBackground();

      // ✅ 2️⃣ Avvia l'inizializzazione dello stato dell'app
      final appStateNotifier = ref.read(appStateProvider.notifier);
      await appStateNotifier.initialize();

      // ✅ 3️⃣ Controlla lo stato e naviga
      if (!mounted) return;

      final appState = ref.read(appStateProvider);

      switch (appState) {
        case AppState.ready:
          print('✅ App pronta! Vai a Home');
          Navigator.of(context).pushReplacementNamed('/home');
          break;

        case AppState.onboarding:
          print('➡️ Vai a Onboarding');
          Navigator.of(context).pushReplacementNamed('/onboarding');
          break;

        case AppState.loading:
          print('⚠️ Ancora in loading?');
          break;

        case AppState.error:
          print('❌ Errore, vai a Onboarding');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Errore nell\'inizializzazione, ricomincia'),
            ),
          );
          Navigator.of(context).pushReplacementNamed('/onboarding');
          break;
      }
    } catch (e) {
      print('❌ Errore nell\'inizializzazione: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    }
  }

  /// ✅ SINCRONIZZA IL TIMER DAL BACKGROUND
  /// Supporta sia RUNNING che PAUSED
  Future<void> _syncTimerFromBackground() async {
    try {
      print('🔄 Sincronizzazione timer dal background...');

      // Inizializza BackgroundTimerService
      final bgTimer = BackgroundTimerService();
      await bgTimer.initialize();

      // ✅ Recupera TUTTI i dati
      final isRunning = bgTimer.isTimerRunning();
      final totalSeconds = bgTimer.getTotalSeconds();  // ← Usa getTotalSeconds()!

      print('📊 Stato background:');
      print('   - isRunning: $isRunning');
      print('   - totalSeconds: $totalSeconds');

      // ✅ Se totalSeconds è 0, skip
      if (totalSeconds == 0) {
        print('⭕ Timer a zero - Skip sync');
        return;
      }

      // ✅ Se il timer era RUNNING, sincronizza in modalità running
      if (isRunning) {
        print('⏱️ Timer ERA in esecuzione - Sincronizzazione running mode...');
        ref.read(timerProvider.notifier).syncRunningTimerFromBackground(totalSeconds);
        print('✅ Timer sincronizzato (running mode)');
      }
      // ✅ Se il timer era PAUSED, sincronizza in modalità paused
      else {
        print('⏸️ Timer ERA in PAUSA con $totalSeconds secondi');
        ref.read(timerProvider.notifier).setSyncedTimeWhilePaused(totalSeconds);
        print('✅ Timer sincronizzato (paused mode)');
      }
    } catch (e) {
      print('❌ Errore in _syncTimerFromBackground: $e');
      // Non bloccare l'app se c'è errore nella sincronizzazione
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 200,
              height: 200,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.sentiment_very_satisfied,
                      size: 100,
                      color: AppColors.blue,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'SmileLine Monitoring',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.graphite,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Monitora il tuo trattamento',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.blue),
            ),
          ],
        ),
      ),
    );
  }
}