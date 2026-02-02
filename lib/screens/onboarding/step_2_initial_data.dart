import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';

class Step2InitialData extends StatefulWidget {
  final Function(Map<String, dynamic>) onDataChanged;

  const Step2InitialData({
    Key? key,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<Step2InitialData> createState() => _Step2InitialDataState();
}

class _Step2InitialDataState extends State<Step2InitialData> {
  late TextEditingController _nameController;
  late TextEditingController _dateController;
  late TextEditingController _notesController;

  DateTime selectedDate = DateTime.now();
  String userName = '';
  String? notes;
  bool treatmentStartsTodayFlag = true;  // ✅ FLAG: verifica se inizia oggi
  bool treatmentAlreadyStarted = false;  // ✅ FLAG: se il trattamento è già iniziato

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(selectedDate),
    );
    _notesController = TextEditingController();

    // ✅ Imposta il flag correttamente al caricamento
    _updateTreatmentStartsFlag();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _notifyChanges() {
    widget.onDataChanged({
      'userName': userName,
      'startDate': selectedDate,
      'notes': notes,
      'treatmentStartsToday': treatmentStartsTodayFlag,  // ✅ Aggiungi il flag
      'treatmentAlreadyStarted': treatmentAlreadyStarted,  // ✅ Aggiungi il flag
    });
  }

  /// ✅ VERIFICA SE IL TRATTAMENTO INIZIA OGGI
  void _updateTreatmentStartsFlag() {
    final today = DateTime.now();
    final selectedDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final todayDay = DateTime(today.year, today.month, today.day);

    setState(() {
      treatmentStartsTodayFlag = selectedDay.isAtSameMomentAs(todayDay);
    });

    print('📅 Verifica data:');
    print('   Data selezionata: ${DateFormat('dd/MM/yyyy').format(selectedDate)}');
    print('   Oggi: ${DateFormat('dd/MM/yyyy').format(today)}');
    print('   Inizia oggi: $treatmentStartsTodayFlag');
    print('   Già iniziato: $treatmentAlreadyStarted');

    // ✅ Mostra avviso se non inizia oggi
    _showTreatmentStartsWarning();
  }

  /// ✅ MOSTRA AVVISO SE IL TRATTAMENTO NON INIZIA OGGI O SE È GIÀ INIZIATO
  void _showTreatmentStartsWarning() {
    if (treatmentAlreadyStarted) {
      // ⚠️ Alert per "Già iniziato"
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'La progressione del trattamento sarà tracciata a partire da oggi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      });
    } else if (!treatmentStartsTodayFlag) {
      // ℹ️ Alert per data nel passato ma non "già iniziato"
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '⚠️ Data selezionata nel passato - Il conteggio inizierà da oggi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.overlap,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),  // ✅ Ultimi 30 giorni
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.blue,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.graphite,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
      // ✅ Aggiorna il flag quando la data cambia
      _updateTreatmentStartsFlag();
      _notifyChanges();
    }
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
            'Dati Iniziali',
            'Inserisci le tue informazioni personali',
            isSmallScreen,
          ),
          SizedBox(height: isSmallScreen ? 20 : 32),

          _buildInputField(
            label: 'Il Tuo Nome',
            hint: 'Inserisci il Tuo Nome',
            controller: _nameController,
            onChanged: (value) {
              setState(() {
                userName = value;
              });
              _notifyChanges();
            },
            isRequired: true,
            isSmallScreen: isSmallScreen,
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),

          _buildReadOnlyDateField(
            label: 'Data di Inizio',
            controller: _dateController,
            isSmallScreen: isSmallScreen,
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),

          // ✅ NUOVO: Toggle per "Già iniziato"
          _buildTreatmentAlreadyStartedToggle(isSmallScreen),
          SizedBox(height: isSmallScreen ? 16 : 20),

          _buildTextAreaField(
            label: 'Note (Opzionale)',
            hint: 'Es. Allergie, sensibilità particolare...',
            controller: _notesController,
            onChanged: (value) {
              setState(() {
                notes = value.isEmpty ? null : value;
              });
              _notifyChanges();
            },
            isSmallScreen: isSmallScreen,
          ),
          SizedBox(height: isSmallScreen ? 16 : 32),

          _buildInfoCard(isSmallScreen),
          SizedBox(height: isSmallScreen ? 16 : 32),
        ],
      ),
    );
  }

  /// ✅ WIDGET: Toggle per "Già iniziato"
  Widget _buildTreatmentAlreadyStartedToggle(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: treatmentAlreadyStarted
            ? AppColors.error.withOpacity(0.1)
            : Colors.transparent,
        border: Border.all(
          color: treatmentAlreadyStarted
              ? AppColors.error.withOpacity(0.3)
              : AppColors.border,
          width: treatmentAlreadyStarted ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Il trattamento è già iniziato?',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.graphite,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 4 : 6),
                Text(
                  'Seleziona se il trattamento è già in corso',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Switch(
            value: treatmentAlreadyStarted,
            onChanged: (value) {
              setState(() {
                treatmentAlreadyStarted = value;
              });
              _updateTreatmentStartsFlag();
              _notifyChanges();
            },
            activeColor: AppColors.error,
            activeTrackColor: AppColors.error.withOpacity(0.3),
            inactiveThumbColor: AppColors.textHint,
            inactiveTrackColor: AppColors.border,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required Function(String) onChanged,
    required bool isSmallScreen,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.w600,
                color: AppColors.graphite,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: AppColors.error, fontSize: 16),
              ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textHint, fontSize: isSmallScreen ? 12 : 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.blue, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isSmallScreen ? 10 : 12,
            ),
          ),
          style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required VoidCallback onTap,
    required bool isSmallScreen,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: AppColors.graphite,
          ),
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        TextField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textHint, fontSize: isSmallScreen ? 12 : 14),
            prefixIcon: Icon(
              Icons.calendar_today,
              color: AppColors.blue,
              size: isSmallScreen ? 16 : 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.blue, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isSmallScreen ? 10 : 12,
            ),
          ),
          style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
        ),
      ],
    );
  }

  /// ✅ WIDGET: Data in sola lettura (non modificabile)
  Widget _buildReadOnlyDateField({
    required String label,
    required TextEditingController controller,
    required bool isSmallScreen,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: AppColors.graphite,
          ),
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isSmallScreen ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: AppColors.textHint.withOpacity(0.05),
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: AppColors.blue,
                size: isSmallScreen ? 16 : 20,
              ),
              SizedBox(width: isSmallScreen ? 10 : 12),
              Text(
                controller.text,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: AppColors.graphite,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextAreaField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required Function(String) onChanged,
    required bool isSmallScreen,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: AppColors.graphite,
          ),
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: isSmallScreen ? 2 : 3,
          minLines: isSmallScreen ? 2 : 2,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textHint, fontSize: isSmallScreen ? 12 : 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.blue, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isSmallScreen ? 10 : 12,
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

  Widget _buildInfoCard(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.overlap.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.overlap.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.overlap,
            size: isSmallScreen ? 18 : 24,
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Expanded(
            child: Text(
              'I tuoi dati verranno utilizzati solo per personalizzare la tua esperienza',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: AppColors.graphite,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}