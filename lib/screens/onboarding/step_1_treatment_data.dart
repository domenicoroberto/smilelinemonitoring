import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';

class Step1TreatmentData extends StatefulWidget {
  final Function(Map<String, dynamic>) onDataChanged;

  const Step1TreatmentData({
    Key? key,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<Step1TreatmentData> createState() => _Step1TreatmentDataState();
}

class _Step1TreatmentDataState extends State<Step1TreatmentData> {
  late TextEditingController _upperAlignerController;
  late TextEditingController _lowerAlignerController;
  late TextEditingController _changeFrequencyController;

  int upperAlignersCount = 0;
  int lowerAlignersCount = 0;
  String changeFrequency = '';

  @override
  void initState() {
    super.initState();
    _upperAlignerController = TextEditingController();
    _lowerAlignerController = TextEditingController();
    _changeFrequencyController = TextEditingController();
  }

  @override
  void dispose() {
    _upperAlignerController.dispose();
    _lowerAlignerController.dispose();
    _changeFrequencyController.dispose();
    super.dispose();
  }

  void _notifyChanges() {
    widget.onDataChanged({
      'upperAlignersCount': upperAlignersCount,
      'lowerAlignersCount': lowerAlignersCount,
      'changeFrequency': changeFrequency,
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 380;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(
            'Dati del Trattamento',
            'Rispondi alle domande sul tuo piano di allineamento',
            isSmallScreen,
          ),
          SizedBox(height: isSmallScreen ? 20 : 32),

          /// ✅ DOMANDA 1 - SOLO NUMERI
          _buildQuestion(
            number: '1',
            question: 'Quanti allineatori hai per l\'arcata superiore?',
            controller: _upperAlignerController,
            onChanged: (value) {
              try {
                setState(() {
                  upperAlignersCount = int.tryParse(value) ?? 0;
                });
                _notifyChanges();
              } catch (e) {
                print('❌ Errore parsing numero superiore: $e');
              }
            },
            isSmallScreen: isSmallScreen,
            isNumeric: true,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 28),

          /// ✅ DOMANDA 2 - SOLO NUMERI
          _buildQuestion(
            number: '2',
            question: 'Quanti allineatori hai per l\'arcata inferiore?',
            controller: _lowerAlignerController,
            onChanged: (value) {
              try {
                setState(() {
                  lowerAlignersCount = int.tryParse(value) ?? 0;
                });
                _notifyChanges();
              } catch (e) {
                print('❌ Errore parsing numero inferiore: $e');
              }
            },
            isSmallScreen: isSmallScreen,
            isNumeric: true,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 28),

          /// ✅ DOMANDA 3 - SOLO NUMERI (CORRETTO!)
          _buildQuestion(
            number: '3',
            question: 'Ogni quanti giorni devi cambiare gli allineatori?',
            hint: 'Es: 7, 14, 21',
            controller: _changeFrequencyController,
            isNumeric: true,
            onChanged: (value) {
              try {
                setState(() {
                  changeFrequency = value;
                });
                _notifyChanges();
              } catch (e) {
                print('❌ Errore parsing frequenza: $e');
              }
            },
            isSmallScreen: isSmallScreen,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3), // Max 999 giorni
            ],
          ),
          SizedBox(height: isSmallScreen ? 24 : 40),
        ],
      ),
    );
  }

  Widget _buildQuestion({
    required String number,
    required String question,
    required TextEditingController controller,
    required Function(String) onChanged,
    required bool isSmallScreen,
    String hint = '',
    bool isNumeric = true,
    List<TextInputFormatter> inputFormatters = const [],
  }) {
    String? errorText;

    if (number == '1' && upperAlignersCount == 0 && controller.text.isNotEmpty) {
      errorText = null; // Solo se l'utente ha scritto ma è 0
    }
    if (number == '2' && lowerAlignersCount == 0 && controller.text.isNotEmpty) {
      errorText = null;
    }
    if (number == '3' && changeFrequency.isEmpty && controller.text.isNotEmpty) {
      errorText = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Domanda $number',
          style: TextStyle(
            fontSize: isSmallScreen ? 10 : 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        Text(
          question,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w600,
            color: AppColors.graphite,
          ),
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        TextField(
          controller: controller,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          onChanged: onChanged,
          inputFormatters: isNumeric
              ? [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ]
              : inputFormatters,
          decoration: InputDecoration(
            hintText: hint.isNotEmpty ? hint : 'Scrivi la risposta...',
            hintStyle: TextStyle(
              color: AppColors.textHint,
              fontSize: isSmallScreen ? 12 : 14,
            ),
            errorText: errorText,
            filled: true,
            fillColor: AppColors.lightBlue.withOpacity(0.15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.blue,
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isSmallScreen ? 10 : 14,
            ),
          ),
          style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
        ),
      ],
    );
  }

  Widget _buildTitle(String title, String subtitle, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isSmallScreen ? 22 : 28,
            fontWeight: FontWeight.bold,
            color: AppColors.graphite,
          ),
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}