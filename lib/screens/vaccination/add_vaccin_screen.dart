import 'package:flutter/material.dart';
import '../../models/vaccin_model.dart';
import '../../models/pediatre_model.dart';
import '../../services/vaccin_service.dart';
import '../../services/pediatre_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_text_field.dart';
import '../../widgets/gradient_button.dart';

class AddVaccinScreen extends StatefulWidget {
  final String enfantId;
  final VaccinModel? vaccin;

  const AddVaccinScreen({super.key, required this.enfantId, this.vaccin});

  @override
  State<AddVaccinScreen> createState() => _AddVaccinScreenState();
}

class _AddVaccinScreenState extends State<AddVaccinScreen> {
  final _nomController = TextEditingController();
  final _maladieController = TextEditingController();
  final _lieuController = TextEditingController();
  final _lotController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _dateAdministre = DateTime.now();
  DateTime? _prochaineDate;
  bool _loading = false;

  List<PediatreModel> _pediatres = [];
  PediatreModel? _selectedPediatre;
  bool _loadingPediatres = true;

  final List<Map<String, String>> _suggestions = [
    {'nom': 'BCG', 'maladie': 'Tuberculose'},
    {'nom': 'DTCoq-Hib-HB-Polio', 'maladie': 'Diphtérie, Tétanos, Coqueluche'},
    {'nom': 'ROR', 'maladie': 'Rougeole, Oreillons, Rubéole'},
    {'nom': 'VPC13', 'maladie': 'Pneumocoque'},
    {'nom': 'Méningocoque', 'maladie': 'Méningite'},
    {'nom': 'Varicelle', 'maladie': 'Varicelle'},
    {'nom': 'Hépatite A', 'maladie': 'Hépatite A'},
    {'nom': 'Hépatite B', 'maladie': 'Hépatite B'},
    {'nom': 'Rotavirus', 'maladie': 'Gastro-entérite'},
    {'nom': 'Grippe', 'maladie': 'Influenza'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPediatres();
    if (widget.vaccin != null) {
      _nomController.text = widget.vaccin!.nom;
      _maladieController.text = widget.vaccin!.maladie;
      _lieuController.text = widget.vaccin!.lieu;
      _lotController.text = widget.vaccin!.lotNumero;
      _notesController.text = widget.vaccin!.notes;
      _dateAdministre = widget.vaccin!.dateAdministre;
      _prochaineDate = widget.vaccin!.prochaineDate;
    }
  }

  Future<void> _loadPediatres() async {
    final list = await PediatreService.getPediatres();
    if (mounted) {
      setState(() {
        _pediatres = list;
        _loadingPediatres = false;
        if (widget.vaccin != null && list.isNotEmpty) {
          try {
            _selectedPediatre = list.firstWhere(
                (p) => p.name == widget.vaccin!.medecin);
          } catch (_) {}
        }
      });
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _maladieController.dispose();
    _lieuController.dispose();
    _lotController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isProchaine) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isProchaine
          ? (_prochaineDate ?? DateTime.now().add(const Duration(days: 30)))
          : _dateAdministre,
      firstDate: isProchaine ? DateTime.now() : DateTime(2000),
      lastDate: isProchaine
          ? DateTime.now().add(const Duration(days: 365 * 5))
          : DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: Color(0xFF0D2D5E),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isProchaine) {
          _prochaineDate = picked;
        } else {
          _dateAdministre = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_nomController.text.isEmpty || _selectedPediatre == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nom du vaccin et médecin obligatoires.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final vaccin = VaccinModel(
      id: widget.vaccin?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      nom: _nomController.text.trim(),
      maladie: _maladieController.text.trim(),
      dateAdministre: _dateAdministre,
      medecin: _selectedPediatre!.name,
      lieu: _lieuController.text.trim(),
      lotNumero: _lotController.text.trim(),
      prochaineDate: _prochaineDate,
      enfantId: widget.enfantId,
      notes: _notesController.text.trim(),
    );

    if (widget.vaccin != null) {
      await VaccinService.updateVaccin(vaccin);
    } else {
      await VaccinService.addVaccin(vaccin);
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
                      _buildSuggestions(),
                      const SizedBox(height: 24),
                      _buildSectionLabel('Informations du vaccin'),
                      const SizedBox(height: 12),
                      GlassTextField(
                        hint: 'Nom du vaccin *',
                        icon: Icons.vaccines_outlined,
                        controller: _nomController,
                      ),
                      const SizedBox(height: 12),
                      GlassTextField(
                        hint: 'Maladie ciblée',
                        icon: Icons.coronavirus_outlined,
                        controller: _maladieController,
                      ),
                      const SizedBox(height: 12),
                      GlassTextField(
                        hint: 'N° de lot',
                        icon: Icons.tag_rounded,
                        controller: _lotController,
                      ),
                      const SizedBox(height: 20),
                      _buildSectionLabel('Administration'),
                      const SizedBox(height: 12),
                      _buildPediatreSelector(),
                      const SizedBox(height: 12),
                      GlassTextField(
                        hint: 'Lieu (hôpital, cabinet...)',
                        icon: Icons.location_on_outlined,
                        controller: _lieuController,
                      ),
                      const SizedBox(height: 12),
                      _buildDatePicker(
                        label: 'Date d\'administration',
                        date: _dateAdministre,
                        onTap: () => _pickDate(false),
                        emoji: '💉',
                      ),
                      const SizedBox(height: 20),
                      _buildSectionLabel('Rappel (optionnel)'),
                      const SizedBox(height: 12),
                      _buildDatePicker(
                        label: _prochaineDate != null
                            ? 'Prochain rappel : ${_formatDate(_prochaineDate!)}'
                            : 'Définir la prochaine échéance',
                        date: _prochaineDate,
                        onTap: () => _pickDate(true),
                        emoji: '📅',
                        optional: true,
                      ),
                      const SizedBox(height: 20),
                      _buildSectionLabel('Notes'),
                      const SizedBox(height: 12),
                      GlassTextField(
                        hint: 'Notes et observations...',
                        icon: Icons.notes_rounded,
                        controller: _notesController,
                      ),
                      const SizedBox(height: 32),
                      GradientButton(
                        label: widget.vaccin != null
                            ? 'Modifier le vaccin'
                            : 'Enregistrer le vaccin',
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
              width: 40,
              height: 40,
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
            widget.vaccin != null ? 'Modifier le vaccin' : 'Ajouter un vaccin',
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Vaccins courants',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestions
              .map((s) => GestureDetector(
                    onTap: () {
                      setState(() {
                        _nomController.text = s['nom']!;
                        _maladieController.text = s['maladie']!;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Text(s['nom']!,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label,
        style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700));
  }

  Widget _buildPediatreSelector() {
    if (_loadingPediatres) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: const Row(children: [
          SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary)),
          SizedBox(width: 12),
          Text('Chargement des pédiatres...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ]),
      );
    }
    if (_pediatres.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: const Row(children: [
          Text('👨‍⚕️', style: TextStyle(fontSize: 18)),
          SizedBox(width: 10),
          Text('Aucun pédiatre disponible',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ]),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _pediatres.map((p) {
        final selected = _selectedPediatre?.id == p.id;
        return GestureDetector(
          onTap: () => setState(() => _selectedPediatre = p),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF00C9A7).withOpacity(0.1)
                  : AppColors.inputFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? const Color(0xFF00C9A7) : AppColors.glassBorder,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF00C9A7).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('👨‍⚕️', style: TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dr. ${p.name}',
                      style: const TextStyle(color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(p.email,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              )),
              if (selected)
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF00C9A7), size: 20),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required String emoji,
    bool optional = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                date != null && !optional
                    ? _formatDate(date)
                    : label,
                style: TextStyle(
                    color: date != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 15),
              ),
            ),
            const Icon(Icons.calendar_today_outlined,
                color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
