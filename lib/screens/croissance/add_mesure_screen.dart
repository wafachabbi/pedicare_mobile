import 'package:flutter/material.dart';
import '../../models/croissance_model.dart';
import '../../services/croissance_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/gradient_button.dart';

class AddMesureScreen extends StatefulWidget {
  final String enfantId;
  final CroissanceModel? mesure;

  const AddMesureScreen({super.key, required this.enfantId, this.mesure});

  @override
  State<AddMesureScreen> createState() => _AddMesureScreenState();
}

class _AddMesureScreenState extends State<AddMesureScreen> {
  final _poidsController = TextEditingController();
  final _tailleController = TextEditingController();
  final _pcController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.mesure != null) {
      _poidsController.text = widget.mesure!.poids.toString();
      _tailleController.text = widget.mesure!.taille.toString();
      _pcController.text = widget.mesure!.perimeterCranien?.toString() ?? '';
      _notesController.text = widget.mesure!.notes;
      _date = widget.mesure!.date;
    }
  }

  @override
  void dispose() {
    _poidsController.dispose();
    _tailleController.dispose();
    _pcController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double? get _imc {
    final p = double.tryParse(_poidsController.text);
    final t = double.tryParse(_tailleController.text);
    if (p == null || t == null || t == 0) return null;
    return p / ((t / 100) * (t / 100));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF9B59B6),
            surface: Color(0xFF0D2D5E),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final poids = double.tryParse(_poidsController.text);
    final taille = double.tryParse(_tailleController.text);

    if (poids == null || taille == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Poids et taille obligatoires.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final mesure = CroissanceModel(
      id: widget.mesure?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      enfantId: widget.enfantId,
      date: _date,
      poids: poids,
      taille: taille,
      perimeterCranien: double.tryParse(_pcController.text),
      notes: _notesController.text.trim(),
    );

    if (widget.mesure != null) {
      await CroissanceService.updateMesure(mesure);
    } else {
      await CroissanceService.addMesure(mesure);
    }

    if (mounted) {
      setState(() => _loading = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.backgroundGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDatePicker(),
                      const SizedBox(height: 20),
                      _buildSectionLabel('Mesures *'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _NumberField(
                              hint: 'Poids (kg)',
                              controller: _poidsController,
                              emoji: '⚖️',
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _NumberField(
                              hint: 'Taille (cm)',
                              controller: _tailleController,
                              emoji: '📐',
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _NumberField(
                        hint: 'Périmètre crânien (cm) — optionnel',
                        controller: _pcController,
                        emoji: '🧠',
                      ),
                      if (_imc != null) ...[
                        const SizedBox(height: 16),
                        _buildImcPreview(),
                      ],
                      const SizedBox(height: 20),
                      _buildSectionLabel('Notes'),
                      const SizedBox(height: 12),
                      _buildNotesField(),
                      const SizedBox(height: 32),
                      GradientButton(
                        label: widget.mesure != null
                            ? 'Modifier la mesure'
                            : 'Enregistrer la mesure',
                        onTap: _save,
                        loading: _loading,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            widget.mesure != null ? 'Modifier la mesure' : 'Nouvelle mesure',
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
        'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            const Text('📅', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${_date.day} ${months[_date.month - 1]} ${_date.year}',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15),
              ),
            ),
            const Icon(Icons.edit_calendar_outlined,
                color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildImcPreview() {
    final imc = _imc!;
    String label;
    Color color;
    if (imc < 18.5) { label = 'Insuffisance pondérale'; color = const Color(0xFF1E6FDB); }
    else if (imc < 25) { label = 'Normal ✓'; color = const Color(0xFF00C9A7); }
    else if (imc < 30) { label = 'Surpoids'; color = const Color(0xFFE67E22); }
    else { label = 'Obésité'; color = AppColors.danger; }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Text('🔢', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text('IMC : ${imc.toStringAsFixed(1)}',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          const SizedBox(width: 8),
          Text('— $label', style: TextStyle(color: color, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: TextField(
        controller: _notesController,
        maxLines: 3,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Observations, contexte...',
          hintStyle: TextStyle(color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label,
        style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700));
  }
}

class _NumberField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final String emoji;
  final Function(String)? onChanged;

  const _NumberField(
      {required this.hint,
      required this.controller,
      required this.emoji,
      this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: onChanged,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
