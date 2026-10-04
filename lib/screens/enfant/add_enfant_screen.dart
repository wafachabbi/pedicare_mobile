import 'package:flutter/material.dart';
import '../../models/enfant_model.dart';
import '../../services/enfant_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/gradient_button.dart';

class AddEnfantScreen extends StatefulWidget {
  final String parentId;

  const AddEnfantScreen({super.key, required this.parentId});

  @override
  State<AddEnfantScreen> createState() => _AddEnfantScreenState();
}

class _AddEnfantScreenState extends State<AddEnfantScreen> {
  final _nomController    = TextEditingController();
  final _prenomController = TextEditingController();
  final _allergiesController = TextEditingController();
  String _sexe = 'M';
  String? _groupeSanguin;
  DateTime _dateNaissance = DateTime.now().subtract(const Duration(days: 365));
  bool _loading = false;

  final _groupes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateNaissance,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF1E6FDB),
            surface: Color(0xFF0D2D5E),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateNaissance = picked);
  }

  Future<void> _save() async {
    final nom    = _nomController.text.trim();
    final prenom = _prenomController.text.trim();

    if (nom.isEmpty || prenom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom et prénom obligatoires.'),
            backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _loading = true);

    final enfant = EnfantModel(
      id: '',
      parentId: widget.parentId,
      nom: nom,
      prenom: prenom,
      dateNaissance: _dateNaissance,
      sexe: _sexe,
      groupeSanguin: _groupeSanguin,
      allergies: _allergiesController.text.trim().isEmpty
          ? null
          : _allergiesController.text.trim(),
    );

    final id = await EnfantService.addEnfant(enfant);

    if (!mounted) return;
    setState(() => _loading = false);

    if (id != null) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur : impossible de joindre le serveur. Vérifiez que XAMPP est démarré.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
        'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];

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
              // Header
              Padding(
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
                    const Text('Nouveau profil enfant',
                        style: TextStyle(color: AppColors.textPrimary,
                            fontSize: 20, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Prénom *'),
                      const SizedBox(height: 8),
                      _field(_prenomController, 'Prénom de l\'enfant', Icons.person_outline),
                      const SizedBox(height: 16),
                      _label('Nom *'),
                      const SizedBox(height: 8),
                      _field(_nomController, 'Nom de famille', Icons.person_outline),
                      const SizedBox(height: 20),
                      _label('Date de naissance'),
                      const SizedBox(height: 8),
                      GestureDetector(
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
                              Text(
                                '${_dateNaissance.day} ${months[_dateNaissance.month - 1]} ${_dateNaissance.year}',
                                style: const TextStyle(color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _label('Sexe'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _SexeBtn(label: 'Garçon', emoji: '👦', value: 'M',
                              selected: _sexe == 'M',
                              onTap: () => setState(() => _sexe = 'M')),
                          const SizedBox(width: 12),
                          _SexeBtn(label: 'Fille', emoji: '👧', value: 'F',
                              selected: _sexe == 'F',
                              onTap: () => setState(() => _sexe = 'F')),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _label('Groupe sanguin (optionnel)'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _groupes.map((g) => GestureDetector(
                          onTap: () => setState(() => _groupeSanguin = g == _groupeSanguin ? null : g),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: _groupeSanguin == g
                                  ? AppColors.primary.withOpacity(0.3)
                                  : AppColors.inputFill,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _groupeSanguin == g
                                    ? AppColors.secondary
                                    : AppColors.glassBorder,
                              ),
                            ),
                            child: Text(g,
                                style: TextStyle(
                                  color: _groupeSanguin == g
                                      ? AppColors.secondary
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                )),
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 20),
                      _label('Allergies connues (optionnel)'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: TextField(
                          controller: _allergiesController,
                          maxLines: 2,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Ex: pénicilline, arachides...',
                            hintStyle: TextStyle(color: AppColors.textSecondary),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      GradientButton(label: 'Enregistrer', onTap: _save, loading: _loading),
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

  Widget _label(String text) => Text(text,
      style: const TextStyle(color: AppColors.textPrimary,
          fontSize: 14, fontWeight: FontWeight.w700));

  Widget _field(TextEditingController ctrl, String hint, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: ctrl,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }
}

class _SexeBtn extends StatelessWidget {
  final String label, emoji, value;
  final bool selected;
  final VoidCallback onTap;

  const _SexeBtn({required this.label, required this.emoji,
      required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = value == 'F' ? const Color(0xFFE91E8C) : const Color(0xFF1E6FDB);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.15) : AppColors.inputFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? color : AppColors.glassBorder,
                width: selected ? 1.5 : 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: selected ? color : AppColors.textPrimary,
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
