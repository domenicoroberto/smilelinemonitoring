import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/treatment_plan.dart';
import '../../providers/treatment_provider.dart';
import '../../providers/timer_provider.dart';
import '../../services/database_service.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  /// ✅ Legge i dati reali degli ultimi 7 giorni dal database
  List<DailyHours> _getWeeklyHours(TreatmentPlan treatment) {
    final List<DailyHours> weeklyData = [];
    final db = DatabaseService();

    final startDate = treatment.startDate;
    final now = DateTime.now();

    print('\n' + '='*70);
    print('🔍 _getWeeklyHours() - DEBUG DETTAGLIATO');
    print('='*70);

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayNum = 7 - i;

      double hours = 0.0;

      if (date.isBefore(startDate)) {
        print('🔴 Giorno $dayNum: PRIMA dell\'inizio');
        hours = 0.0;
      } else {
        final dateOnly = DateTime(date.year, date.month, date.day);

        final tracking = db.getDailyTrackingByDate(dateOnly);

        if (tracking != null) {
          final wearingHours = tracking.wearingHours;
          final wearingMinutes = tracking.wearingMinutes;
          hours = wearingHours + (wearingMinutes / 60.0);

          print('🟢 Giorno $dayNum: ${hours}h');
        } else {
          print('⭕ Giorno $dayNum: NON TROVATO');
          hours = 0.0;
        }
      }

      weeklyData.add(DailyHours(
        dayNumber: dayNum,
        date: date,
        hours: hours,
      ));
    }

    print('='*70 + '\n');
    return weeklyData;
  }

  /// ✅ CALCOLO CONTATORI - FORMULA CORRETTA CON MAX(A, B)!
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
      final daysPassedRaw = nowMidnight.difference(startDateMidnight).inDays;

      final daysPassed = daysPassedRaw + 1;

      final currentStepNumber = (daysPassedRaw ~/ daysPerChange) + 1;
      final clampedStep = currentStepNumber.clamp(1, totalStages);

      final dayInCurrentStep = (daysPassedRaw % daysPerChange) + 1;

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
        'daysPassed': daysPassed,
        'totalDays': totalDays,
      };
    } catch (e) {
      print('❌ ERRORE nel calcolo contatori: $e');
      return {
        'currentStepNumber': 1,
        'dayInCurrentStep': 1,
        'daysPerChange': 3,
        'daysToSwitch': 0,
        'progressPercentage': 0.0,
        'daysRemaining': 0,
        'daysPassed': 0,
        'totalDays': 36,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final treatment = ref.watch(treatmentPlanProvider);
    final timerState = ref.watch(timerProvider);

    if (treatment == null) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.white,
          title: const Text('Dashboard', style: TextStyle(color: AppColors.graphite)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.graphite),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text('Nessun piano di trattamento')),
      );
    }

    final counters = _calculateStepCounters(treatment);
    final daysPassed = counters['daysPassed'] as int;
    final currentStepNumber = counters['currentStepNumber'] as int;
    final dayInCurrentStep = counters['dayInCurrentStep'] as int;
    final daysPerChange = counters['daysPerChange'] as int;
    final totalDays = counters['totalDays'] as int;

    final weeklyData = _getWeeklyHours(treatment);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.white,
        title: const Text(
          'Dashboard',
          style: TextStyle(color: AppColors.graphite, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.graphite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCards(treatment, daysPassed, totalDays, weeklyData),
              const SizedBox(height: 24),

              _buildWeeklyHistogram(weeklyData),
              const SizedBox(height: 24),

              _buildStageProgress(treatment, currentStepNumber, dayInCurrentStep, daysPerChange),
              const SizedBox(height: 24),

              _buildDailyStats(treatment, timerState),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(TreatmentPlan treatment, int daysPassed, int totalDays, List<DailyHours> weeklyData) {
    final totalHours = weeklyData.isEmpty ? 0.0 : weeklyData.map((d) => d.hours).reduce((a, b) => a + b);

    final daysWithData = weeklyData.where((d) => d.hours > 0).length;
    final averageHours = daysWithData == 0 ? 0.0 : totalHours / daysWithData;

    return Row(
      children: [
        Expanded(
          child: _buildCard(
            icon: '📅',
            title: 'Giorni Passati',
            value: '$daysPassed',
            subtitle: 'di $totalDays',
            color: AppColors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCard(
            icon: '⏱️',
            title: 'Tempo Medio',
            value: '${averageHours.toStringAsFixed(1)}h',
            subtitle: 'ultimi 7 giorni',
            color: AppColors.overlap,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required String icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyHistogram(List<DailyHours> weeklyData) {
    final hours = weeklyData.map((d) => d.hours).toList();
    final totalHours = hours.isEmpty ? 0.0 : hours.reduce((a, b) => a + b);

    final daysWithData = hours.where((h) => h > 0).length;
    final average = daysWithData == 0 ? 0.0 : totalHours / daysWithData;
    final maxValue = hours.isEmpty || hours.reduce((a, b) => a > b ? a : b) == 0
        ? 24.0
        : hours.reduce((a, b) => a > b ? a : b);
    final minValue = hours.isEmpty ? 0.0 : hours.reduce((a, b) => a < b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Utilizzo Giornaliero (ultimi 7 giorni)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.graphite),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: HistogramChart(data: weeklyData, maxValue: maxValue),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatBadge('Media', '${average.toStringAsFixed(1)}h', AppColors.blue),
              _buildStatBadge('Max', '${maxValue.toStringAsFixed(1)}h', AppColors.overlap),
              _buildStatBadge('Min', '${minValue.toStringAsFixed(1)}h', AppColors.lightBlue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStageProgress(
      TreatmentPlan treatment,
      int currentStepNumber,
      int dayInCurrentStep,
      int daysPerChange,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stato Step Attuale',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.graphite),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step $currentStepNumber',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.blue),
                  ),
                  Text(
                    'di ${treatment.totalStages}',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$dayInCurrentStep/$daysPerChange',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.overlap),
                  ),
                  Text(
                    'giorni',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: dayInCurrentStep / daysPerChange,
              minHeight: 10,
              backgroundColor: AppColors.lightBlue.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.overlap),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ IMPORTANTE: Mostra il totale GIORNALIERO dal database (TODAY)
  Widget _buildDailyStats(TreatmentPlan treatment, TimerState timerState) {
    final targetHours = treatment.dailyWearingHours;
    final db = DatabaseService();

    // ✅ LEGGI IL TOTALE DI OGGI DAL DATABASE
    final tracking = db.getDailyTrackingByDate(DateTime.now());
    final currentHours = tracking != null
        ? tracking.wearingHours + (tracking.wearingMinutes / 60.0)
        : 0.0;

    final compliance = (currentHours / targetHours * 100).clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Target Giornaliero',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.graphite),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (currentHours / targetHours).clamp(0, 1),
              minHeight: 12,
              backgroundColor: AppColors.lightBlue.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blue),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${currentHours.toStringAsFixed(1)}h',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.blue),
                  ),
                  Text(
                    'Registrato oggi',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${targetHours}h',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  Text(
                    'Target',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Conformità: ${compliance.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: compliance >= 100 ? Colors.green : AppColors.overlap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class DailyHours {
  final int dayNumber;
  final DateTime date;
  final double hours;

  DailyHours({
    required this.dayNumber,
    required this.date,
    required this.hours,
  });
}

class HistogramChart extends StatelessWidget {
  final List<DailyHours> data;
  final double maxValue;

  const HistogramChart({
    Key? key,
    required this.data,
    required this.maxValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    return CustomPaint(
      painter: HistogramChartPainter(data, maxValue),
      size: Size.infinite,
    );
  }
}

class HistogramChartPainter extends CustomPainter {
  final List<DailyHours> data;
  final double maxValue;

  HistogramChartPainter(this.data, this.maxValue);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final barWidth = (width - 60) / data.length;
    final margin = 10.0;

    final baselineY = height - 30;
    canvas.drawLine(
      const Offset(30, 0),
      Offset(30, baselineY),
      Paint()
        ..color = const Color(0xFFEEEEEE)
        ..strokeWidth = 2,
    );

    for (int i = 0; i < data.length; i++) {
      final d = data[i];
      final x = 30 + i * barWidth + margin;
      final barHeight = (d.hours / maxValue) * (baselineY - 20);
      final barY = baselineY - barHeight;

      if (d.hours > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, barY, barWidth - margin * 2, barHeight),
            const Radius.circular(4),
          ),
          Paint()
            ..color = AppColors.blue
            ..style = PaintingStyle.fill,
        );

        final valueText = TextPainter(
          text: TextSpan(
            text: '${d.hours.toStringAsFixed(1)}',
            style: const TextStyle(
              color: AppColors.graphite,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        valueText.layout();
        canvas.save();
        canvas.translate(x + (barWidth - margin * 2) / 2 - valueText.width / 2, barY - 15);
        valueText.paint(canvas, Offset.zero);
        canvas.restore();
      }

      final dayText = TextPainter(
        text: TextSpan(
          text: 'G${d.dayNumber}',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      dayText.layout();
      canvas.save();
      canvas.translate(x + (barWidth - margin * 2) / 2 - dayText.width / 2, baselineY + 5);
      dayText.paint(canvas, Offset.zero);
      canvas.restore();
    }

    final yLabel = TextPainter(
      text: const TextSpan(
        text: 'Ore',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    );
    yLabel.layout();
    canvas.save();
    canvas.translate(2, 5);
    yLabel.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(HistogramChartPainter oldDelegate) => true;
}