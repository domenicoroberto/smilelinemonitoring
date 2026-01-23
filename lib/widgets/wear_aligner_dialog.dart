import 'package:flutter/material.dart';
import '../../config/theme.dart';

class WearAlignerDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const WearAlignerDialog({
    Key? key,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 380;
    final screenHeight = MediaQuery.of(context).size.height;
    final isShortScreen = screenHeight < 700;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Card principale
            Container(
              margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 24),
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Emoji grande
                  Text(
                    '🦷',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 40 : 56,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),

                  // Titolo
                  Text(
                    'Prima di indossare',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.graphite,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isSmallScreen ? 6 : 8),

                  // Sottotitolo
                  Text(
                    'Assicurati di completare questi passaggi',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),

                  // Checklist
                  _buildCheckItem(
                    context,
                    icon: '🪥',
                    title: 'Lavati i denti',
                    subtitle: 'Spazzola accuratamente i denti',
                    isSmallScreen: isSmallScreen,
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  _buildCheckItem(
                    context,
                    icon: '💧',
                    title: 'Igienizza l\'allineatore',
                    subtitle: 'Risciacqua con acqua fredda o tiepida',
                    isSmallScreen: isSmallScreen,
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  _buildCheckItem(
                    context,
                    icon: '✋',
                    title: 'Mani pulite',
                    subtitle: 'Assicurati che le mani siano pulite',
                    isSmallScreen: isSmallScreen,
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 32),

                  // Info card
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.lightBlue.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.blue,
                          size: isSmallScreen ? 16 : 20,
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        Expanded(
                          child: Text(
                            'Indossa l\'allineatore delicatamente dalle estremità',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: AppColors.graphite,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),

                  // Bottoni
                  Row(
                    children: [
                      // Annulla
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 10 : 14,
                            ),
                            side: const BorderSide(
                              color: AppColors.blue,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            'Annulla',
                            style: TextStyle(
                              color: AppColors.blue,
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      // Conferma
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            onConfirm();
                            Navigator.pop(context);
                          },
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
                            'Indossa',
                            style: TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Costruisce un item della checklist
  Widget _buildCheckItem(
      BuildContext context, {
        required String icon,
        required String title,
        required String subtitle,
        required bool isSmallScreen,
      }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Emoji
          Text(
            icon,
            style: TextStyle(fontSize: isSmallScreen ? 18 : 24),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          // Testo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.graphite,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 1 : 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Checkmark
          Container(
            width: isSmallScreen ? 20 : 24,
            height: isSmallScreen ? 20 : 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.blue,
            ),
            child: Center(
              child: Icon(
                Icons.check,
                color: AppColors.white,
                size: isSmallScreen ? 12 : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}