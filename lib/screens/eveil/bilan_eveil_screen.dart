import 'package:flutter/material.dart';
import '../../models/enfant_model.dart';
import '../../models/pediatre_model.dart';
import '../../services/eveil_service.dart';
import '../../services/ia_eveil_service.dart';
import '../../services/message_service.dart';
import '../../services/pediatre_service.dart';
import '../../theme/app_colors.dart';

class BilanEveilScreen extends StatefulWidget {
  final EnfantModel enfant;
  const BilanEveilScreen({super.key, required this.enfant});

  @override
  State<BilanEveilScreen> createState() => _BilanEveilScreenState();
}

class _BilanEveilScreenState extends State<BilanEveilScreen> {
  BilanEveil? _bilan;
  bool _loading = true;

  static const Map<String, String> _emojis = {
    'langage': '🗣️',
    'memoire': '🧠',
    'logique': '🧩',
    'motricite': '✋',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final bilan = await IAEveilService.genererBilan(widget.enfant);
    if (!mounted) return;
    setState(() {
      _bilan = bilan;
      _loading = false;
    });
  }

  Color _couleurNiveau(DomaineBilan d) {
    if (d.nbSeances == 0) return AppColors.textSecondary;
    if (d.scoreMoyen >= 80) return AppColors.accent;
    if (d.scoreMoyen >= 50) return AppColors.secondary;
    return const Color(0xFFFFB020);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.backgroundGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.secondary),
                SizedBox(height: 16),
                Text("✨ L'IA analyse les activités…",
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          )
              : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildResume(),
                const SizedBox(height: 20),
                const Text('Domaines de développement',
                    style: TextStyle(color: AppColors.textPrimary,
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ..._bilan!.domaines.map(_buildDomaine),
                const SizedBox(height: 20),
                _buildAnalyseIA(),
                const SizedBox(height: 20),
                _buildBoutonEnvoyer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bilan de développement',
                style: TextStyle(color: AppColors.textPrimary,
                    fontSize: 20, fontWeight: FontWeight.w700)),
            Text(widget.enfant.nomComplet,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildResume() {
    return Row(
      children: [
        Expanded(child: _tuile('🎮', '${_bilan!.totalSeances}', 'Activités')),
        const SizedBox(width: 12),
        Expanded(child: _tuile('⏱️', '${_bilan!.totalMinutes} min', 'Temps de jeu')),
      ],
    );
  }

  Widget _tuile(String emoji, String valeur, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(valeur,
              style: const TextStyle(color: AppColors.textPrimary,
                  fontSize: 20, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDomaine(DomaineBilan d) {
    final couleur = _couleurNiveau(d);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_emojis[d.categorie] ?? '🎲', style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(d.label,
                    style: const TextStyle(color: AppColors.textPrimary,
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: couleur.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: couleur.withOpacity(0.5)),
                ),
                child: Text(d.niveau,
                    style: TextStyle(color: couleur, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: d.scoreMoyen / 100,
              minHeight: 8,
              backgroundColor: AppColors.inputFill,
              color: couleur,
            ),
          ),
          const SizedBox(height: 6),
          Text('${d.nbSeances} séance(s) · score moyen ${d.scoreMoyen.round()} % · ${d.minutes} min',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildAnalyseIA() {
    final bilan = _bilan!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.25),
            AppColors.accent.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Analyse IA',
                    style: TextStyle(color: AppColors.textPrimary,
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              Text(bilan.geminiDisponible ? 'Gemini' : 'Analyse locale',
                  style: const TextStyle(color: AppColors.secondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          Text(bilan.texte,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  // ── Envoyer le bilan au pédiatre (lien Éveil ↔ Messagerie) ─────────────────
  Widget _buildBoutonEnvoyer() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _bilan!.totalSeances == 0 ? null : _choisirPediatre,
        icon: const Icon(Icons.send_rounded, color: Colors.white),
        label: const Text('Envoyer le bilan au pédiatre',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Future<void> _choisirPediatre() async {
    final pediatres = await PediatreService.getPediatres();
    if (!mounted) return;
    final choisi = await showModalBottomSheet<PediatreModel>(
      context: context,
      backgroundColor: const Color(0xFF0D2D5E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Envoyer à quel pédiatre ?',
                  style: TextStyle(color: AppColors.textPrimary,
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              if (pediatres.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text("Aucun pédiatre inscrit dans l'application.",
                      style: TextStyle(color: AppColors.textSecondary)),
                )
              else
                ...pediatres.map((p) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.accent.withOpacity(0.25),
                    child: const Text('👨‍⚕️'),
                  ),
                  title: Text('Dr. ${p.name}',
                      style: const TextStyle(color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                  subtitle: Text(p.email,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  onTap: () => Navigator.pop(sheetContext, p),
                )),
            ],
          ),
        ),
      ),
    );
    if (choisi == null) return;
    await _envoyer(choisi);
  }

  Future<void> _envoyer(PediatreModel pediatre) async {
    final bilan = _bilan!;
    final ageMois = EveilService.ageEnMois(widget.enfant.dateNaissance);
    final lignes = bilan.domaines
        .map((d) => '• ${d.label} : ${d.niveau} (${d.scoreMoyen.round()} %, ${d.nbSeances} séance(s))')
        .join('\n');
    final contenu = '${widget.enfant.nomComplet} – $ageMois mois\n'
        '${bilan.totalSeances} activité(s) · ${bilan.totalMinutes} min de jeu\n\n'
        '$lignes\n\n'
        '${bilan.texte}';

    final erreur = await MessageService.envoyer(
      senderId: widget.enfant.parentId,
      receiverId: pediatre.id,
      content: contenu,
      type: 'bilan',
      enfantId: widget.enfant.id,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: erreur == null ? AppColors.accent : AppColors.danger,
        behavior: SnackBarBehavior.floating,
        content: Text(erreur ?? 'Bilan envoyé au Dr. ${pediatre.name} ✅'),
      ),
    );
  }
}