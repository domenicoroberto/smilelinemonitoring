import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../models/treatment_plan.dart';
import '../../models/user.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/treatment_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  /// ✅ Funzione di logout
  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      // Mostra dialog di conferma
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Esci'),
          content: const Text('Sei sicuro di voler uscire? Dovrai registrarti di nuovo.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Esci', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // ✅ Cancella l'utente dal database
      await ref.read(userProvider.notifier).deleteUser();
      print('✅ Utente eliminato');

      // ✅ Cancella il trattamento dal database
      try {
        await ref.read(treatmentPlanProvider.notifier).deleteTreatment();
        print('✅ Trattamento eliminato');
      } catch (e) {
        print('⚠️ Trattamento già eliminato: $e');
      }

      // ✅ Reset lo stato dell'app
      ref.read(appStateProvider.notifier).resetToOnboarding();
      print('✅ App state resettato');

      // ✅ Naviga a Onboarding e rimuovi lo stack di navigazione
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/onboarding',
              (route) => false,
        );
      }
    } catch (e) {
      print('❌ Errore durante il logout: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  /// Dialog di conferma eliminazione trattamento
  void _showDeleteConfirmation(TreatmentPlan treatment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Trattamento?'),
        content: const Text(
          'Questa azione eliminerà il trattamento corrente e dovrai ripetere l\'onboarding. Sei sicuro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => _deleteTreatmentAndResetOnboarding(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  /// Elimina il trattamento e reindirizza all'onboarding
  Future<void> _deleteTreatmentAndResetOnboarding() async {
    try {
      if (mounted) {
        Navigator.pop(context);
      }

      await ref.read(treatmentPlanProvider.notifier).deleteTreatment();

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  /// Apri Privacy Policy in browser
  Future<void> _openPrivacyPolicy() async {
    const url = 'https://husky-marjoram-623.notion.site/Privacy-Policy-Smileline-Monitoring-2d77fa8370588053b135c23bceee5c00';

    try {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.inAppBrowserView,
      );
      print('✅ Privacy Policy aperta');
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
    final user = ref.watch(userProvider);
    final preferences = ref.watch(userPreferencesProvider);
    final treatment = ref.watch(treatmentPlanProvider);

    if (user == null || preferences == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Impostazioni')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.white,
        title: const Text(
          'Impostazioni',
          style: TextStyle(color: AppColors.graphite, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.graphite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profilo section
            _buildSection(
              title: 'Profilo',
              children: [
                _buildProfileTile(user),
              ],
            ),
            // Notifiche section
            _buildSection(
              title: 'Notifiche',
              children: [
                _buildNotificationTiles(user, preferences),
              ],
            ),
            // Trattamento section
            if (treatment != null)
              _buildSection(
                title: 'Trattamento',
                children: [
                  _buildTreatmentInfo(treatment),
                ],
              ),
            // Preferenze
            _buildSection(
              title: 'Preferenze',
              children: [
                _buildFixedPreferences(),
              ],
            ),
            // About section
            _buildSection(
              title: 'Info',
              children: [
                _buildAboutTiles(),
              ],
            ),

            if (treatment != null) ...[
              /*
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showDeleteConfirmation(treatment),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Elimina Trattamento'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),*/
            ],
            // BOTTONE LOGOUT
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _logout(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Esci',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // [Tutti gli altri metodi rimangono uguali...]
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.blue,
            ),
          ),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildProfileTile(User user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.blue,
            child: Text(
              user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : '?',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.graphite,
                  ),
                ),
                if (user.email != null && user.email!.isNotEmpty)
                  Text(
                    user.email!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.edit, color: AppColors.textHint, size: 20),
        ],
      ),
    );
  }

  Widget _buildNotificationTiles(User user, UserPreferences preferences) {
    return Column(
      children: [
        _buildSettingsTile(
          title: 'Promemoria Giornaliero',
          subtitle: preferences.dailyReminderEnabled
              ? 'Attivo alle ${preferences.dailyReminderHour.toString().padLeft(2, '0')}:00'
              : 'Disattivato',
          trailing: Switch(
            value: preferences.dailyReminderEnabled,
            onChanged: (value) {
              ref.read(userProvider.notifier).toggleDailyReminder(value);
            },
            activeColor: AppColors.blue,
          ),
        ),
        if (preferences.dailyReminderEnabled)
          _buildSettingsTile(
            title: 'Ora Promemoria',
            subtitle: 'Scegli l\'ora del promemoria',
            trailing: SizedBox(
              width: 80,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButton<int>(
                  value: preferences.dailyReminderHour,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: List.generate(24, (i) => i)
                      .map((hour) => DropdownMenuItem(
                    value: hour,
                    child: Text(
                      '${hour.toString().padLeft(2, '0')}:00',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ))
                      .toList(),
                  onChanged: (hour) {
                    if (hour != null) {
                      ref
                          .read(userProvider.notifier)
                          .setDailyReminderHour(hour);
                    }
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.graphite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }

  Widget _buildTreatmentInfo(TreatmentPlan treatment) {
    final now = DateTime.now();
    final daysPassed = now.difference(treatment.startDate).inDays + 1;
    final totalDays = treatment.totalStages * treatment.stageADays;
    final progressPercent = ((daysPassed / totalDays) * 100).clamp(0, 100);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            'Stage Corrente:',
            '${(daysPassed ~/ treatment.stageADays) + 1}/${treatment.totalStages}',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Data Inizio:',
            '${treatment.startDate.day}/${treatment.startDate.month}/${treatment.startDate.year}',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Data Fine:',
            '${treatment.startDate.add(Duration(days: totalDays - 1)).day}/${treatment.startDate.add(Duration(days: totalDays - 1)).month}/${treatment.startDate.add(Duration(days: totalDays - 1)).year}',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Progresso:',
            '${progressPercent.toStringAsFixed(1)}%',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.graphite,
          ),
        ),
      ],
    );
  }

  Widget _buildFixedPreferences() {
    return Column(
      children: [
        _buildFixedTile(
          title: 'Lingua',
          value: 'Italiano',
          icon: Icons.language,
        ),
        _buildFixedTile(
          title: 'Tema',
          value: 'Chiaro',
          icon: Icons.palette,
        ),
      ],
    );
  }

  Widget _buildFixedTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.graphite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.lock, color: AppColors.textHint, size: 16),
        ],
      ),
    );
  }

  Widget _buildAboutTiles() {
    return Column(
      children: [
        _buildInfoTile(
          title: 'Versione App',
          subtitle: '1.0.0',
          icon: Icons.info,
          onTap: null,
        ),
        _buildInfoTile(
          title: 'Privacy Policy',
          subtitle: 'Leggi la nostra policy',
          icon: Icons.privacy_tip,
          onTap: _openPrivacyPolicy,
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.blue, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.graphite,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}