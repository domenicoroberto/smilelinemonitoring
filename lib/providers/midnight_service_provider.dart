import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/midnight_service.dart';

/// Provider per il MidnightService (singleton)
final midnightServiceProvider = Provider<MidnightService>((ref) {
  return MidnightService();
});

/// Provider asincrono per inizializzare il MidnightService
final midnightInitProvider = FutureProvider<bool>((ref) async {
  try {
    final midnightService = ref.read(midnightServiceProvider);
    await midnightService.initialize();
    print('✅ MidnightService inizializzato tramite provider');
    return true;
  } catch (e) {
    print('❌ Errore nell\'inizializzazione del MidnightService: $e');
    return false;
  }
});