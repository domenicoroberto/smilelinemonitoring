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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(selectedDate),
    );
    _notesController = TextEditingController();
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
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
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

          _buildDateField(
            label: 'Data di Inizio',
            hint: 'Seleziona una data',
            controller: _dateController,
            onTap: () => _selectDate(context),
            isSmallScreen: isSmallScreen,
          ),
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