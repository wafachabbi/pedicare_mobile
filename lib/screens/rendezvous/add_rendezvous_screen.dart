import 'package:flutter/material.dart';
import '../../models/rendezvous_model.dart';
import '../../services/rendezvous_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_text_field.dart';
import '../../widgets/gradient_button.dart';

class AddRendezVousScreen extends StatefulWidget {
  final String enfantId;
  final RendezVousModel? rdv;

  const AddRendezVousScreen({super.key, required this.enfantId, this.rdv});

  @override
  State<AddRendezVousScreen> createState() => _AddRendezVousScreenState();
}

class _AddRendezVousScreenState extends State<AddRendezVousScreen> {
  final _titreController = TextEditingController();
  final _medecinController = TextEditingController();
  final _specialiteController = TextEditingController();
  final _lieuController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _dateHeure = DateTime.now().add(const Duration(days: 1));
  String _type = 'presentiel';
  bool _loading = false;

  final List<String> _specialites = [
    'Pédiatre', 'Généraliste', 'Ophtalmologue', 'Dentiste',
    'ORL', 'Dermatologue', 'Orthopédiste', 'Neurologue', 'Cardiologue',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.rdv != null) {
      _titreController.text = widget.rdv!.titre;
      _medecinController.text = widget.rdv!.medecin;
      _specialiteController.text = widget.rdv!.specialite;
      _lieuController.text = widget.rdv!.lieu;
      _notesController.text = widget.rdv!.notes;
      _dateHeure = widget.rdv!.dateHeure;
      _type = widget.rdv!.type;
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _medecinController.dispose();
    _specialiteController.dispose();
    _lieuController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateHeure,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
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
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateHeure),
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
    if (time == null) return;

    setState(() {
      _dateHeure = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (_titreController.text.isEmpty || _medecinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Titre et médecin obligatoires.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final rdv = RendezVousModel(
      id: widget.rdv?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      titre: _titreController.text.trim(),
      medecin: _medecinController.text.trim(),
      specialite: _specialiteController.text.trim(),
      lieu: _lieuController.text.trim(),
      dateHeure: _dateHeure,
      statut: widget.rdv?.statut ?? StatutRDV.enAttente,
      enfantId: widget.enfantId,
      notes: _notesController.text.trim(),
      type: _type,
    );

    if (widget.rdv != null) {
      await RendezVousService.updateRendezVous(rdv);
    } else {
      await RendezVousService.addRendezVous(rdv);
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
                      _buildTypeSelector(),
                      const SizedBox(height: 20),
                      _buildSectionLabel('Informations'),
                      const SizedBox(height: 12),
                      GlassTextField(
                        hint: 'Titre du rendez-vous *',
                        icon: Icons.title_rounded,
                        controller: _titreController,
                      ),
                      const SizedBox(height: 12),
                      GlassTextField(
                        hint: 'Médecin *',
                        icon: Icons.medical_services_outlined,
                        controller: _medecinController,
                      ),
                      const SizedBox(height: 12),
                      _buildSpecialiteDropdown(),
                      const SizedBox(height: 20),
                      _buildSectionLabel('Date et heure'),
                      const SizedBox(height: 12),
                      _buildDateTimePicker(),
                      const SizedBox(height: 20),
                      _buildSectionLabel('Lieu'),
                      const SizedBox(height: 12),
                      GlassTextField(
                        hint: _type == 'video' ? 'Lien de visioconférence' : 'Adresse / Hôpital / Cabinet',
                        icon: _type == 'video' ? Icons.videocam_outlined : Icons.location_on_outlined,
                        controller: _lieuController,
                      ),
                      const SizedBox(height: 20),
                      _buildSectionLabel('Notes'),
                      const SizedBox(height: 12),
                      GlassTextField(
                        hint: 'Motif de la consultation, préparations...',
                        icon: Icons.notes_rounded,
                        controller: _notesController,
                      ),
                      const SizedBox(height: 32),
                      GradientButton(
                        label: widget.rdv != null
                            ? 'Modifier le rendez-vous'
                            : 'Enregistrer le rendez-vous',
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
            widget.rdv != null ? 'Modifier le RDV' : 'Nouveau rendez-vous',
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(child: _TypeBtn(label: 'Présentiel', emoji: '🏥',
            selected: _type == 'presentiel',
            onTap: () => setState(() => _type = 'presentiel'))),
        const SizedBox(width: 12),
        Expanded(child: _TypeBtn(label: 'Vidéo', emoji: '🎥',
            selected: _type == 'video',
            onTap: () => setState(() => _type = 'video'))),
      ],
    );
  }

  Widget _buildSpecialiteDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _specialites.contains(_specialiteController.text)
              ? _specialiteController.text
              : null,
          hint: const Text('Spécialité',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          dropdownColor: const Color(0xFF0D2D5E),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          isExpanded: true,
          items: _specialites.map((s) => DropdownMenuItem(
            value: s,
            child: Text(s),
          )).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _specialiteController.text = val);
          },
        ),
      ),
    );
  }

  Widget _buildDateTimePicker() {
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
        'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return GestureDetector(
      onTap: _pickDateTime,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_dateHeure.day} ${months[_dateHeure.month - 1]} ${_dateHeure.year}',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                  ),
                  Text(
                    '${_dateHeure.hour.toString().padLeft(2, '0')}h${_dateHeure.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_calendar_outlined,
                color: AppColors.textSecondary, size: 18),
          ],
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

class _TypeBtn extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _TypeBtn({required this.label, required this.emoji,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0x221E6FDB)
              : AppColors.inputFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.secondary : AppColors.glassBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: selected ? AppColors.secondary : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
