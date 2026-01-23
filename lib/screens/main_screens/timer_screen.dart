import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/treatment_plan.dart';
import '../../providers/timer_provider.dart';
import '../../providers/tracking_provider.dart';
import '../../providers/treatment_provider.dart';
import '../../models/daily_tracking.dart';
import '../../services/database_service.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  late DatabaseService _db;

  @override
  void initState() {
    super.initState();
    _db = DatabaseService();
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final treatment = ref.watch(treatmentPlanProvider);
    final todayTracking = ref.watch(todayTrackingProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Timer',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Main timer display
            _buildTimerDisplay(timerState),
            const SizedBox(height: 32),
            // Control buttons
            _buildControlButtons(timerState),
            const SizedBox(height: 32),
            // Daily target section
            if (treatment != null)
              _buildDailyTargetSection(treatment, todayTracking),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Costruisce il display principale del timer
  Widget _buildTimerDisplay(TimerState timerState) {
    return Center(
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1ABC9C),
              const Color(0xFF16A085),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1ABC9C).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: Text(
            timerState.formattedTime,
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  /// Costruisce i bottoni di controllo
  Widget _buildControlButtons(TimerState timerState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Bottone Start/Resume
              ElevatedButton.icon(
                onPressed: timerState.isRunning
                    ? null
                    : () => ref.read(timerProvider.notifier).start(),
                icon: const Icon(Icons.play_arrow),
                label: Text(timerState.isRunning ? 'In Corso' : 'Avvia'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1ABC9C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              // Bottone Pausa
              OutlinedButton.icon(
                onPressed: timerState.isRunning
                    ? () => ref.read(timerProvider.notifier).pause()
                    : null,
                icon: const Icon(Icons.pause),
                label: const Text('Pausa'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1ABC9C),
                  side: const BorderSide(color: Color(0xFF1ABC9C)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Bottone Reset
          OutlinedButton.icon(
            onPressed: () => ref.read(timerProvider.notifier).reset(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reset'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[600],
              side: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ],
      ),
    );
  }

  /// Costruisce la sezione target giornaliero
  Widget _buildDailyTargetSection(
      TreatmentPlan treatment,
      AsyncValue<DailyTracking?> todayTrackingValue,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Target Giornaliero',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: todayTrackingValue.when(
              data: (tracking) {
                final targetHours = treatment.dailyWearingHours;
                final currentHours = tracking?.wearingHours ?? 0;
                final compliance =
                    tracking?.compliancePercentage ?? 0.0;

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ore Target: $targetHours',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          'Ore Registrate: $currentHours',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1ABC9C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (compliance / 100).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: Colors.grey[300],
                        valueColor:
                        const AlwaysStoppedAnimation<Color>(
                          Color(0xFF1ABC9C),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Conformità: ${compliance.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (err, stack) => Text('Errore: $err'),
            ),
          ),
        ],
      ),
    );
  }
}