import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/treatment_plan.dart';
import '../providers/user_provider.dart';
import '../providers/treatment_provider.dart';

/// ✅ Enum per lo stato dell'app
enum AppState {
  loading,      // SplashScreen
  onboarding,   // Nessun utente/trattamento
  ready,        // Utente + trattamento caricati
  error,        // Errore durante il caricamento
}

/// ✅ Notifier per gestire lo stato dell'app
class AppStateNotifier extends StateNotifier<AppState> {
  final Ref ref;

  AppStateNotifier(this.ref) : super(AppState.loading);

  /// ✅ Inizializza l'app e controlla lo stato
  Future<void> initialize() async {
    try {
      print('🚀 Inizializzando app state...');
      state = AppState.loading;

      // Carica l'utente
      final userNotifier = ref.read(userProvider.notifier);
      await userNotifier.loadCurrentUser();
      final user = ref.read(userProvider);

      print('👤 Utente: ${user?.name ?? "NESSUNO"}');

      if (user == null) {
        print('➡️ Nessun utente, vai a Onboarding');
        state = AppState.onboarding;
        return;
      }

      // Carica il trattamento se esiste
      if (user.currentTreatmentPlanId != null) {
        final treatmentNotifier = ref.read(treatmentPlanProvider.notifier);
        await treatmentNotifier.loadTreatmentPlan(user.currentTreatmentPlanId!);

        final treatment = ref.read(treatmentPlanProvider);

        if (treatment == null) {
          print('⚠️ Piano non trovato, vai a Onboarding');
          state = AppState.onboarding;
          return;
        }

        print('✅ Utente + Trattamento caricati');
        state = AppState.ready;
      } else {
        print('⚠️ Utente senza piano, vai a Onboarding');
        state = AppState.onboarding;
      }
    } catch (e) {
      print('❌ Errore nell\'inizializzazione: $e');
      state = AppState.error;
    }
  }

  /// ✅ Resetta a Onboarding (per logout)
  void resetToOnboarding() {
    state = AppState.onboarding;
    print('🔄 Reset a Onboarding');
  }

  /// ✅ Resetta a Loading
  void resetToLoading() {
    state = AppState.loading;
    print('🔄 Reset a Loading');
  }

  /// ✅ Passa a Ready (quando registrazione completa)
  void markAsReady() {
    state = AppState.ready;
    print('✅ App marked as Ready');
  }
}

/// ✅ Provider per lo stato dell'app
/// DOVE INSERIRLO: lib/providers/app_state_provider.dart
final appStateProvider =
StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier(ref);
});

/// ✅ Provider per verificare se l'app è pronta
final isAppReadyProvider = Provider<bool>((ref) {
  final appState = ref.watch(appStateProvider);
  return appState == AppState.ready;
});

/// ✅ Provider per verificare se siamo in onboarding
final isOnboardingProvider = Provider<bool>((ref) {
  final appState = ref.watch(appStateProvider);
  return appState == AppState.onboarding;
});

/// ✅ Provider per verificare se siamo in loading
final isLoadingProvider = Provider<bool>((ref) {
  final appState = ref.watch(appStateProvider);
  return appState == AppState.loading;
});

/// ✅ Provider per verificare se c'è stato un errore
final isErrorProvider = Provider<bool>((ref) {
  final appState = ref.watch(appStateProvider);
  return appState == AppState.error;
});