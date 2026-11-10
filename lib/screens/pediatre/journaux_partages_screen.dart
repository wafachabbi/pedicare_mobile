import 'package:flutter/material.dart';
import '../../models/enfant_model.dart';
import '../../models/journal_symptome_model.dart';
import '../../services/enfant_service.dart';
import '../../services/journal_symptome_service.dart';
import '../../theme/app_colors.dart';
import '../../models/acteur.dart';
import 'dossier_enfant_screen.dart';

/// Espace pédiatre : enfants dont le parent a partagé le dossier avec CE
/// pédiatre. Chaque enfant ouvre son [DossierEnfantScreen].
class JournauxPartagesScreen extends StatefulWidget {
  /// users.id du pédiatre connecté : seuls les journaux qui lui sont partagés
  /// sont affichés.
  final String pediatreId;
  final String pediatreNom;
  const JournauxPartagesScreen(
      {super.key, required this.pediatreId, this.pediatreNom = ''});

  @override
  State<JournauxPartagesScreen> createState() => _JournauxPartagesScreenState();
}

class _JournauxPartagesScreenState extends State<JournauxPartagesScreen> {
  List<EnfantModel> _enfants = [];
  final Map<String, JournalSymptomeModel?> _dernieres = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final enfants = await EnfantService.getEnfantsPartages(widget.pediatreId);
      final dernieres = <String, JournalSymptomeModel?>{};
      for (final e in enfants) {
        dernieres[e.id] = await JournalSymptomeService.getDerniere(e.id);
      }
      if (!mounted) return;
      setState(() {
        _enfants = enfants;
        _dernieres
          ..clear()
          ..addAll(dernieres);
        _loading = false;
      });
    } catch (e) {
      debugPrint('_load error: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du chargement des dossiers partagés'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
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
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF00C9A7)))
                    : RefreshIndicator(
                        color: const Color(0xFF00C9A7),
                        backgroundColor: const Color(0xFF0D2D5E),
                        onRefresh: _load,
                        child: _buildBody(),
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dossiers partagés',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                Text('Enfants suivis',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _load,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Icon(Icons.refresh_rounded,
                  color: AppColors.textPrimary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_enfants.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 60),
          const Center(
            child: Text('📭', style: TextStyle(fontSize: 56)),
          ),
          const SizedBox(height: 14),
          const Text('Aucun dossier partagé',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text(
            'Les parents peuvent partager le dossier de leur enfant avec vous depuis sa fiche.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 12, height: 1.4),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF00C9A7).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF00C9A7).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: Color(0xFF00C9A7), size: 18),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  '${_enfants.length} enfant${_enfants.length > 1 ? 's' : ''} '
                  '${_enfants.length > 1 ? 'partagent' : 'partage'} son dossier avec vous. '
                  'Vous pouvez prescrire et gérer la nutrition.',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11.5,
                      height: 1.35),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._enfants.map(_buildEnfantCard),
      ],
    );
  }

  Widget _buildEnfantCard(EnfantModel enfant) {
    final derniere = _dernieres[enfant.id];
    final isFille = enfant.sexe == 'F';
    final color = isFille ? const Color(0xFFE91E8C) : const Color(0xFF4DAAFF);

    return GestureDetector(
      onTap: () => _ouvrir(enfant),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(isFille ? '👧' : '👦',
                    style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(enfant.nomComplet,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    '${enfant.age} an${enfant.age > 1 ? 's' : ''} · '
                    '${isFille ? 'Fille' : 'Garçon'}'
                    '${enfant.parentNom != null ? ' · Parent : ${enfant.parentNom}' : ''}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    derniere == null
                        ? 'Aucune entrée dans le journal'
                        : 'Dernière saisie : ${_fmtDate(derniere.date)}'
                            '${derniere.temperature != null ? ' · ${derniere.temperature!.toStringAsFixed(1)} °C' : ''}',
                    style: TextStyle(
                        color: derniere == null
                            ? AppColors.textSecondary
                            : const Color(0xFF00C9A7),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _ouvrir(EnfantModel enfant) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DossierEnfantScreen(
          enfant: enfant,
          pediatre: Acteur.pediatre(
              id: widget.pediatreId, nom: widget.pediatreNom),
        ),
      ),
    );
    if (mounted) _load();
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';
}