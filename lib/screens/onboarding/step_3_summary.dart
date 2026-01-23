import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Step3Summary extends StatelessWidget {
  final int totalStages;
  final int stageADays;
  final int stageBDays;
  final int dailyWearingHours;
  final DateTime startDate;
  final String userName;
  final String? notes;

  const Step3Summary({
    Key? key,
    required this.totalStages,
    required this.stageADays,
    required this.stageBDays,
    required this.dailyWearingHours,
    required this.startDate,
    required this.userName,
    this.notes,
  }) : super(key: key);

  /// Calcola la data di fine
  DateTime get endDate {
    final totalDays = totalStages * (stageADays + stageBDays);
    return startDate.add(Duration(days: totalDays));
  }

  /// Calcola il numero totale di giorni
  int get totalDays => totalStages * (stageADays + stageBDays);

  /// Calcola le ore totali
  int get totalHours => totalDays * dailyWearingHours;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titolo
          _buildTitle(
            'Verifica i Tuoi Dati',
            'Controlla che tutto sia corretto prima di iniziare',
          ),
          const SizedBox(height: 32),

          // Sezione Utente
          _buildSection(
            title: '👤 Dati Personali',
            children: [
              _buildSummaryRow('Nome:', userName),
              if (notes != null && notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildSummaryRow('Note:', notes!),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // Sezione Trattamento
          _buildSection(
            title: '📋 Piano di Trattamento',
            children: [
              _buildSummaryRow('Stage Totali:', '$totalStages stage'),
              const SizedBox(height: 12),
              _buildSummaryRow('Giorni Stage A:', '$stageADays giorni'),
              const SizedBox(height: 12),
              _buildSummaryRow('Giorni Stage B:', '$stageBDays giorni'),
              const SizedBox(height: 12),
              _buildSummaryRow('Ore Giornaliere:', '$dailyWearingHours ore'),
            ],
          ),
          const SizedBox(height: 24),

          // Sezione Timeline
          _buildSection(
            title: '📅 Timeline Trattamento',
            children: [
              _buildSummaryRow(
                'Data Inizio:',
                DateFormat('dd MMMM yyyy', 'it_IT').format(startDate),
              ),
              const SizedBox(height: 12),
              _buildSummaryRow(
                'Data Fine Prevista:',
                DateFormat('dd MMMM yyyy', 'it_IT').format(endDate),
              ),
              const SizedBox(height: 12),
              _buildSummaryRow(
                'Durata:',
                '$totalDays giorni (${(totalDays / 30).toStringAsFixed(1)} mesi)',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Sezione Statistiche
          _buildStatisticsCard(),
          const SizedBox(height: 24),

          // Sezione Feature
          _buildFeaturesSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Costruisce una sezione
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  /// Costruisce una riga di riepilogo
  Widget _buildSummaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  /// Costruisce il titolo
  Widget _buildTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Costruisce card statistiche
  Widget _buildStatisticsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1ABC9C).withOpacity(0.1),
            const Color(0xFFF39C12).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1ABC9C).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Statistiche',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1ABC9C),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatBox(
                value: '$totalDays',
                label: 'Giorni',
              ),
              const SizedBox(width: 16),
              _buildStatBox(
                value: '$totalHours',
                label: 'Ore Totali',
              ),
              const SizedBox(width: 16),
              _buildStatBox(
                value: '${(totalDays / 7).toStringAsFixed(0)}',
                label: 'Settimane',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Costruisce un box statistico
  Widget _buildStatBox({
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1ABC9C),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Costruisce la sezione feature
  Widget _buildFeaturesSection() {
    final features = [
      'Tracker giornaliero del tempo di utilizzo',
      'Notifiche promemoria personalizzate',
      'Visualizzazione progresso stage',
      'Statistiche dettagliate di conformità',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '✨ Funzionalità Disponibili',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              for (int i = 0; i < features.length; i++) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF1ABC9C),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        features[i],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                if (i < features.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}