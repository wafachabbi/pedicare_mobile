import 'package:flutter/material.dart';
import '../../data/symptomes_catalogue.dart';
import '../../models/journal_symptome_model.dart';
import '../../services/journal_symptome_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/gradient_button.dart';

class AddSymptomeScreen extends StatefulWidget {
  final String enfantId;
  final JournalSymptomeModel? entree;

  const AddSymptomeScreen({
    super.key,
    required this.enfantId,
    this.entree,
  });

  @override
  State<AddSymptomeScreen> createState() => _AddSymptomeScreenState();
}

class _AddSymptomeScreenState extends State<AddSymptomeScreen> {
  final _temperatureController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _date;
  late Set<String> _symptomes;
  NiveauToux _toux = NiveauToux.aucune;
  EtatComportement _comportement = EtatComportement.normal;
  QualiteSommeil _sommeil = QualiteSommeil.bon;
  NiveauAppetit _appetit = NiveauAppetit.normal;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final entree = widget.entree;
    _date = entree?.date ?? DateTime.now();
    _symptomes = {...?entree?.symptomes};
    _toux = entree?.toux ?? NiveauToux.aucune;
    _comportement = entree?.comportement ?? EtatComportement.normal;
    _sommeil = entree?.sommeil ?? QualiteSommeil.bon;
    _appetit = entree?.appetit ?? NiveauAppetit.normal;
    if (entree?.temperature != null) {
      _temperatureController.text =
          entree!.temperature!.toStringAsFixed(1).replaceAll('.0', '');
    }
    _notesController.text = entree?.notes ?? '';
  }

  @override
  void dispose() {
    _temperatureController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
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
      initialTime: TimeOfDay.fromDateTime(_date),
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
      _date =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    final raw = _temperatureController.text.trim().replaceAll(',', '.');
    final temperature = raw.isEmpty ? null : double.tryParse(raw);

    if (raw.isNotEmpty && temperature == null) {
      _erreur('Température invalide.');
      return;
    }
    if (temperature != null && (temperature < 34 || temperature > 43)) {
      _erreur('La température doit être comprise entre 34 et 43 °C.');
      return;
    }

    setState(() => _loading = true);

    final entree = JournalSymptomeModel(
      id: widget.entree?.id ?? '',
      enfantId: widget.enfantId,
      date: _date,
      temperature: temperature,
      toux: _toux,
      comportement: _comportement,
      sommeil: _sommeil,
      appetit: _appetit,
      symptomes: _symptomes.toList(),
      notes: _notesController.text.trim(),
      createdAt: widget.entree?.createdAt,
    );

    final ok = widget.entree == null
        ? await JournalSymptomeService.addEntree(entree) != null
        : await JournalSymptomeService.updateEntree(entree);

    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.pop(context, true);
    } else {
      _erreur('Impossible d\'enregistrer l\'entrée. Réessayez.');
    }
  }

  void _erreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fievre = (double.tryParse(
                _temperatureController.text.replaceAll(',', '.')) ??
            0) >=
        38;

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
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateHeure(),
                      const SizedBox(height: 22),
                      _buildSectionLabel('Température'),
                      const SizedBox(height: 10),
                      _buildTemperatureField(fievre),
                      const SizedBox(height: 22),
                      _buildSectionLabel('Symptômes (saisie rapide)'),
                      const SizedBox(height: 10),
                      _buildSymptomesGrid(),
                      const SizedBox(height: 22),
                      _buildSectionLabel('Toux'),
                      const SizedBox(height: 10),
                      _ChoiceSelector<NiveauToux>(
                        selected: _toux,
                        onChanged: (v) => setState(() => _toux = v),
                        options: const [
                          _ChoiceOption(NiveauToux.aucune, 'Aucune', '✅'),
                          _ChoiceOption(NiveauToux.legere, 'Légère', '🙂'),
                          _ChoiceOption(NiveauToux.moderee, 'Modérée', '😷'),
                          _ChoiceOption(NiveauToux.forte, 'Forte', '😮‍💨'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSectionLabel('Comportement'),
                      const SizedBox(height: 10),
                      _ChoiceSelector<EtatComportement>(
                        selected: _comportement,
                        onChanged: (v) => setState(() => _comportement = v),
                        options: const [
                          _ChoiceOption(EtatComportement.normal, 'Normal', '😊'),
                          _ChoiceOption(EtatComportement.calme, 'Calme', '🙂'),
                          _ChoiceOption(EtatComportement.fatigue, 'Fatigué', '😴'),
                          _ChoiceOption(
                              EtatComportement.irritable, 'Irritable', '😤'),
                          _ChoiceOption(
                              EtatComportement.lethargique, 'Très somnolent', '🚨'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSectionLabel('Sommeil'),
                      const SizedBox(height: 10),
                      _ChoiceSelector<QualiteSommeil>(
                        selected: _sommeil,
                        onChanged: (v) => setState(() => _sommeil = v),
                        options: const [
                          _ChoiceOption(QualiteSommeil.bon, 'Bon', '😴'),
                          _ChoiceOption(QualiteSommeil.moyen, 'Moyen', '😐'),
                          _ChoiceOption(QualiteSommeil.agite, 'Agité', '😣'),
                          _ChoiceOption(QualiteSommeil.mauvais, 'Mauvais', '😫'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSectionLabel('Appétit'),
                      const SizedBox(height: 10),
                      _ChoiceSelector<NiveauAppetit>(
                        selected: _appetit,
                        onChanged: (v) => setState(() => _appetit = v),
                        options: const [
                          _ChoiceOption(NiveauAppetit.normal, 'Normal', '🍽️'),
                          _ChoiceOption(NiveauAppetit.diminue, 'Diminué', '🥄'),
                          _ChoiceOption(NiveauAppetit.faible, 'Faible', '🚫'),
                          _ChoiceOption(NiveauAppetit.excessif, 'Excessif', '🍼'),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _buildSectionLabel('Notes'),
                      const SizedBox(height: 10),
                      _buildNotesField(),
                      const SizedBox(height: 30),
                      GradientButton(
                        label: widget.entree != null
                            ? 'Modifier l\'entrée'
                            : 'Enregistrer dans le journal',
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
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.entree != null ? 'Modifier l\'entrée' : 'Journal du jour',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                ),
                const Text('Fièvre, toux, comportement, sommeil, appétit',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeure() {
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
              child: Text(
                '${_date.day} ${months[_date.month - 1]} ${_date.year} · '
                '${_date.hour.toString().padLeft(2, '0')}h${_date.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
            ),
            const Icon(Icons.edit_calendar_outlined,
                color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureField(bool fievre) {
    final color = fievre ? AppColors.danger : const Color(0xFF00C9A7);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: fievre ? AppColors.danger.withValues(alpha: 0.5) : AppColors.glassBorder),
          ),
          child: Row(
            children: [
              const Text('🌡️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _temperatureController,
                  onChanged: (_) => setState(() {}),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: 'Température en °C (ex. 38.2)',
                    hintStyle: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              if (_temperatureController.text.trim().isNotEmpty)
                Text(
                  fievre ? 'Fièvre' : 'Normal',
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [36.5, 37.0, 37.5, 38.0, 38.5, 39.0, 39.5]
              .map((t) => GestureDetector(
                    onTap: () => setState(() {
                      _temperatureController.text = t.toStringAsFixed(1);
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(
                        color: t >= 38
                            ? AppColors.danger.withValues(alpha: 0.12)
                            : AppColors.inputFill,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: t >= 38
                              ? AppColors.danger.withValues(alpha: 0.35)
                              : AppColors.glassBorder,
                        ),
                      ),
                      child: Text(
                        '${t.toStringAsFixed(1)}°',
                        style: TextStyle(
                          color: t >= 38
                              ? AppColors.danger
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSymptomesGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SymptomesCatalogue.tous.map((s) {
        final selected = _symptomes.contains(s.id);
        final color = s.alerte
            ? AppColors.danger
            : selected
                ? AppColors.secondary
                : AppColors.textSecondary;
        return GestureDetector(
          onTap: () => setState(() {
            if (selected) {
              _symptomes.remove(s.id);
            } else {
              _symptomes.add(s.id);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.16)
                  : AppColors.inputFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? color : AppColors.glassBorder,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  s.label,
                  style: TextStyle(
                    color: selected ? AppColors.textPrimary : color,
                    fontSize: 12,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
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
          hintText: 'Contexte, remarques, médicament donné...',
          hintStyle: TextStyle(color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
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

// ── Sélecteur générique ──────────────────────────────────────────────────────
class _ChoiceOption<T> {
  final T value;
  final String label;
  final String emoji;
  const _ChoiceOption(this.value, this.label, this.emoji);
}

class _ChoiceSelector<T> extends StatelessWidget {
  final List<_ChoiceOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  const _ChoiceSelector({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = option.value == selected;
        return GestureDetector(
          onTap: () => onChanged(option.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : AppColors.inputFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppColors.secondary : AppColors.glassBorder,
                width: isSelected ? 1.4 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(option.emoji, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 6),
                Text(
                  option.label,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
