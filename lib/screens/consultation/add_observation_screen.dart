import 'package:flutter/material.dart';
import '../../models/acteur.dart';
import '../../models/enfant_model.dart';
import '../../models/observation_consultation_model.dart';
import '../../services/observation_consultation_service.dart';
import '../../widgets/pc_ui.dart';

/// Module 3 — saisie par le pédiatre pendant la consultation :
/// motif, mesures, observations, diagnostic, traitement, recommandations.
class AddObservationScreen extends StatefulWidget {
  final EnfantModel enfant;
  final Acteur pediatre;

  /// Non null : modification d'une consultation existante.
  final ObservationConsultationModel? existante;

  const AddObservationScreen({
    super.key,
    required this.enfant,
    required this.pediatre,
    this.existante,
  });

  @override
  State<AddObservationScreen> createState() => _AddObservationScreenState();
}

class _AddObservationScreenState extends State<AddObservationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _motif;
  late final TextEditingController _poids;
  late final TextEditingController _taille;
  late final TextEditingController _temperature;
  late final TextEditingController _observations;
  late final TextEditingController _diagnostic;
  late final TextEditingController _traitement;
  late final TextEditingController _recommandations;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existante;
    String n(double? v) => v == null ? '' : v.toString();
    _motif = TextEditingController(text: e?.motif ?? '');
    _poids = TextEditingController(text: n(e?.poids));
    _taille = TextEditingController(text: n(e?.taille));
    _temperature = TextEditingController(text: n(e?.temperature));
    _observations = TextEditingController(text: e?.observations ?? '');
    _diagnostic = TextEditingController(text: e?.diagnostic ?? '');
    _traitement = TextEditingController(text: e?.traitement ?? '');
    _recommandations = TextEditingController(text: e?.recommandations ?? '');
    _date = e?.dateConsultation ?? DateTime.now();
  }

  @override
  void dispose() {
    for (final c in [
      _motif,
      _poids,
      _taille,
      _temperature,
      _observations,
      _diagnostic,
      _traitement,
      _recommandations,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _nombre(String s) =>
      s.trim().isEmpty ? null : double.tryParse(s.trim().replaceAll(',', '.'));

  String? _validerNombre(String? v, double min, double max) {
    if (v == null || v.trim().isEmpty) return null;
    final x = _nombre(v);
    if (x == null || x < min || x > max) return 'Valeur entre $min et $max';
    return null;
  }

  Future<void> _choisirDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: widget.enfant.dateNaissance,
      lastDate: DateTime.now(),
      builder: pcPickerTheme,
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final model = ObservationConsultationModel(
      id: widget.existante?.id ?? '',
      enfantId: widget.enfant.id,
      pediatreId: widget.pediatre.id,
      pediatreNom: widget.pediatre.nom,
      dateConsultation: _date,
      motif: _motif.text.trim(),
      poids: _nombre(_poids.text),
      taille: _nombre(_taille.text),
      temperature: _nombre(_temperature.text),
      observations: _observations.text.trim(),
      diagnostic: _diagnostic.text.trim(),
      traitement: _traitement.text.trim(),
      recommandations: _recommandations.text.trim(),
      createdAt: widget.existante?.createdAt,
    );

    final ok = widget.existante == null
        ? await ObservationConsultationService.addObservation(model) != null
        : await ObservationConsultationService.updateObservation(model);

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      pcSnack(context, 'Consultation enregistrée. Le parent peut générer le résumé IA.');
      Navigator.pop(context, true);
    } else {
      pcSnack(context, 'Enregistrement impossible.', erreur: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PcPage(
      titre: widget.existante == null
          ? 'Nouvelle consultation'
          : 'Modifier la consultation',
      sousTitre: '${widget.enfant.nomComplet} · ${widget.pediatre.signature}',
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            PcCard(
              onTap: _choisirDate,
              child: Row(
                children: [
                  const Icon(Icons.event_rounded, color: Colors.white70),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Date de la consultation : ${pcDate(_date)}',
                        style: const TextStyle(color: Colors.white)),
                  ),
                  const Icon(Icons.edit_calendar_rounded,
                      color: Colors.white54, size: 18),
                ],
              ),
            ),
            PcTextField(
              controller: _motif,
              label: 'Motif de la consultation *',
              icon: Icons.help_outline_rounded,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Motif obligatoire' : null,
            ),
            const PcSectionTitle('Mesures'),
            Row(
              children: [
                Expanded(
                  child: PcTextField(
                    controller: _poids,
                    label: 'Poids (kg)',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => _validerNombre(v, 0.5, 150),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PcTextField(
                    controller: _taille,
                    label: 'Taille (cm)',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => _validerNombre(v, 20, 220),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PcTextField(
                    controller: _temperature,
                    label: 'Temp. (°C)',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => _validerNombre(v, 34, 43),
                  ),
                ),
              ],
            ),
            const PcSectionTitle('Examen'),
            PcTextField(
              controller: _observations,
              label: 'Observations cliniques',
              icon: Icons.visibility_outlined,
              maxLines: 4,
            ),
            PcTextField(
              controller: _diagnostic,
              label: 'Diagnostic / conclusion',
              icon: Icons.medical_information_outlined,
              maxLines: 2,
            ),
            PcTextField(
              controller: _traitement,
              label: 'Traitement prescrit',
              icon: Icons.medication_outlined,
              maxLines: 2,
            ),
            PcTextField(
              controller: _recommandations,
              label: 'Recommandations au parent (une par ligne)',
              icon: Icons.checklist_rounded,
              maxLines: 4,
            ),
            const SizedBox(height: 8),
            PcPrimaryButton(
              label: _saving ? 'Enregistrement…' : 'Enregistrer la consultation',
              onPressed: _saving ? null : _enregistrer,
            ),
          ],
        ),
      ),
    );
  }
}
