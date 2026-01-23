import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/treatment_provider.dart';
import '../../providers/user_provider.dart';
import 'step_1_treatment_data.dart';
import 'step_2_initial_data.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late PageController _pageController;
  int _currentStep = 0;

  int upperAlignersCount = 0;
  int lowerAlignersCount = 0;
  String changeFrequency = '';

  DateTime startDate = DateTime.now();
  String userName = '';
  String? notes;

  int totalStages = 0;              // ✅ CAMBIA QUESTO
  int dailyWearingHours = 22;       // ✅ CAMBIA QUESTO

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _calculateTreatment() {
    if (upperAlignersCount > 0 && lowerAlignersCount > 0 && changeFrequency.isNotEmpty) {
      totalStages = upperAlignersCount > lowerAlignersCount
          ? upperAlignersCount
          : lowerAlignersCount;
      dailyWearingHours = 22;
    }
  }

  int _extractDays(String frequency) {
    RegExp regExp = RegExp(r'\d+');
    Match? match = regExp.firstMatch(frequency);

    if (match != null) {
      return int.parse(match.group(0)!);
    }

    if (frequency.toLowerCase().contains('settimana') ||
        frequency.toLowerCase().contains('weekly')) {
      return 7;
    }
    if (frequency.toLowerCase().contains('giorno') ||
        frequency.toLowerCase().contains('daily')) {
      return 1;
    }
    if (frequency.toLowerCase().contains('mese') ||
        frequency.toLowerCase().contains('monthly')) {
      return 30;
    }

    return 7;
  }

  void _goToNextStep() {
    // Controlla se step 1 è valido
    if (upperAlignersCount == 0 || lowerAlignersCount == 0 || changeFrequency.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Compila tutti i campi per continuare'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_currentStep < 1) {
      _calculateTreatment();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      _calculateTreatment();

      int changeFrequencyDays = _extractDays(changeFrequency);

      await ref.read(userProvider.notifier).createUser(
        name: userName,
      );

      await ref.read(treatmentPlanProvider.notifier).createTreatmentPlan(
        totalStages: totalStages,
        stageADays: changeFrequencyDays,
        stageBDays: changeFrequencyDays,
        dailyWearingHours: dailyWearingHours,
        startDate: startDate,
        notes: 'Allineatori sup: $upperAlignersCount, Inferiori: $lowerAlignersCount',
      );

      final plan = ref.read(treatmentPlanProvider);
      if (plan != null) {
        await ref.read(userProvider.notifier).setCurrentTreatmentPlan(plan.id);
        await ref.read(userProvider.notifier).setTotalStagesPlanned(totalStages);
      }

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 380;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          // HEADER BLU GRADIENTE con LOGO (come HomeScreen)
          _buildBlueHeader(context, isSmallScreen),

          // Contenuto principale
          Expanded(
            child: Column(
              children: [
                _buildProgressHeader(isSmallScreen),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentStep = index;
                      });
                    },
                    children: [
                      Step1TreatmentData(
                        onDataChanged: (data) {
                          upperAlignersCount = data['upperAlignersCount'] as int;
                          lowerAlignersCount = data['lowerAlignersCount'] as int;
                          changeFrequency = data['changeFrequency'] as String;
                        },
                      ),
                      Step2InitialData(
                        onDataChanged: (data) {
                          startDate = data['startDate'] as DateTime;
                          userName = data['userName'] as String;
                          notes = data['notes'] as String?;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          _buildFooter(isSmallScreen),
        ],
      ),
    );
  }

  /// HEADER BLU GRADIENTE - Identico a HomeScreen
  Widget _buildBlueHeader(BuildContext context, bool isSmallScreen) {
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
          // Logo a sinistra
          Image.asset(
            'assets/images/logo2.png',
            width: isSmallScreen ? 126 : 140,
            height: isSmallScreen ? 45 : 60,
            fit: BoxFit.contain,
          ),

          // Spazio a destra (dove sarebbe l'avatar in HomeScreen)
          SizedBox(width: isSmallScreen ? 18 : 22),
        ],
      ),
    );
  }

  /// PROGRESS HEADER - Barra di progresso + numero step
  Widget _buildProgressHeader(bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Passo ${_currentStep + 1} di 2',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 2,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _goToPreviousStep,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 10 : 14,
                  ),
                  side: const BorderSide(color: AppColors.blue, width: 2),
                ),
                child: Text(
                  'Indietro',
                  style: TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) SizedBox(width: isSmallScreen ? 8 : 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _currentStep < 1 ? _goToNextStep : _completeOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 10 : 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentStep < 1 ? 'Avanti' : 'Inizia Ora',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
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
}