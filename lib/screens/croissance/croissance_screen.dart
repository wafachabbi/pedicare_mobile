import 'package:flutter/material.dart';
import '../../models/croissance_model.dart';
import '../../services/croissance_service.dart';
import '../../services/croissance_pdf_service.dart';
import '../../services/percentile_service.dart';
import '../../theme/app_colors.dart';
import 'add_mesure_screen.dart';
import 'courbes_croissance_screen.dart';
import 'ia_croissance_screen.dart';

class CroissanceScreen extends StatefulWidget {
  final String enfantId;
  final String enfantNom;
  final String enfantSexe;
  final String enfantAge;
  final DateTime? dateNaissance;

  const CroissanceScreen({
    super.key,
    required this.enfantId,
    required this.enfantNom,
    this.enfantSexe = 'M',
    this.enfantAge = '',
    this.dateNaissance,
  });

  @override
  State<CroissanceScreen> createState() => _CroissanceScreenState();
}

class _CroissanceScreenState extends State<CroissanceScreen> {
  List<CroissanceModel> _mesures = [];
  List<AlerteCroissance> _alertes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final mesures = await CroissanceService.getMesures(widget.enfantId);
    final alertes = mesures.length >= 2
        ? PercentileService.detecterAnomalies(mesures: mesures, sexe: widget.enfantSexe)
        : <AlerteCroissance>[];
    if (mounted) setState(() { _mesures = mesures; _alertes = alertes; _loading = false; });
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
              if (!_loading && _mesures.isNotEmpty) _buildLastMesure(),
              if (!_loading && _alertes.isNotEmpty) _buildAlertes(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
                    : _mesures.isEmpty
                        ? _buildEmpty()
                        : _buildList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Suivi de croissance',
                    style: TextStyle(color: AppColors.textPrimary,
                        fontSize: 20, fontWeight: FontWeight.w700)),
                Text(widget.enfantNom,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          // Bouton IA analyse croissance
          if (_mesures.isNotEmpty)
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => IACroissanceScreen(
                  mesures: _mesures,
                  enfantNom: widget.enfantNom,
                  sexe: widget.enfantSexe,
                  dateNaissance: widget.dateNaissance ?? DateTime.now().subtract(const Duration(days: 365)),
                ),
              )),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF4285F4), Color(0xFF0F9D58)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🤖', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
          const SizedBox(width: 8),
          // Bouton courbes interactives
          if (_mesures.isNotEmpty)
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => CourbesCroissanceScreen(
                  mesures: _mesures,
                  enfantNom: widget.enfantNom,
                  sexe: widget.enfantSexe,
                  dateNaissance: widget.dateNaissance ?? DateTime.now().subtract(const Duration(days: 365)),
                ),
              )),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF9B59B6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF9B59B6).withOpacity(0.4)),
                ),
                child: const Icon(Icons.show_chart_rounded, color: Color(0xFF9B59B6), size: 18),
              ),
            ),
          const SizedBox(width: 8),
          // Bouton partager PDF
          if (_mesures.isNotEmpty)
            GestureDetector(
              onTap: () => _partager(context),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF9B59B6), Color(0xFFAD7EC1)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _partager(BuildContext context) async {
    try {
      await CroissancePdfService.partagerCourbes(
        enfantNom: widget.enfantNom,
        enfantAge: widget.enfantAge,
        enfantSexe: widget.enfantSexe,
        mesures: _mesures,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du partage : $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildAlertes() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                '${_alertes.length} alerte${_alertes.length > 1 ? 's' : ''} détectée${_alertes.length > 1 ? 's' : ''}',
                style: const TextStyle(
                    color: AppColors.danger, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._alertes.take(2).map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  a.gravite == GraviteAlerte.elevee
                      ? Icons.error_outline_rounded
                      : Icons.warning_amber_rounded,
                  color: a.gravite == GraviteAlerte.elevee
                      ? AppColors.danger
                      : const Color(0xFFE67E22),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(a.message,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ),
              ],
            ),
          )),
          if (_alertes.length > 2)
            Text('+ ${_alertes.length - 2} autre(s)...',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildLastMesure() {    final m = _mesures.first;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9B59B6), Color(0xFFAD7EC1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x449B59B6), blurRadius: 16, offset: Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dernière mesure', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniStat(label: 'Poids', value: '${m.poids} kg', emoji: '⚖️'),
              const SizedBox(width: 12),
              _MiniStat(label: 'Taille', value: '${m.taille} cm', emoji: '📏'),
              const SizedBox(width: 12),
              _MiniStat(label: 'IMC', value: m.imc.toStringAsFixed(1), emoji: '📊'),
            ],
          ),
          const SizedBox(height: 8),
          Text(_formatDate(m.date),
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _mesures.length,
      itemBuilder: (context, index) => _MesureTile(
        mesure: _mesures[index],
        onEdit: () async {
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => AddMesureScreen(
              enfantId: widget.enfantId,
              mesure: _mesures[index],
            ),
          ));
          _loadData();
        },
        onDelete: () async {
          await CroissanceService.deleteMesure(
              _mesures[index].enfantId, _mesures[index].id);
          _loadData();
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📏', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text('Aucune mesure enregistrée',
              style: TextStyle(color: AppColors.textPrimary,
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Ajoutez la première mesure de ${widget.enfantNom}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => AddMesureScreen(enfantId: widget.enfantId),
        ));
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF9B59B6), Color(0xFFAD7EC1)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x449B59B6), blurRadius: 16, offset: Offset(0, 6))
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Ajouter une mesure',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;
  const _MiniStat({required this.label, required this.value, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }
}

class _MesureTile extends StatelessWidget {
  final CroissanceModel mesure;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MesureTile({required this.mesure, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF9B59B6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('📏', style: TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_formatDate(mesure.date),
                        style: const TextStyle(color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    Text('IMC : ${mesure.imc.toStringAsFixed(1)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatBadge(label: 'Poids', value: '${mesure.poids} kg', color: const Color(0xFF9B59B6)),
              const SizedBox(width: 8),
              _StatBadge(label: 'Taille', value: '${mesure.taille} cm', color: const Color(0xFF1E6FDB)),
              if (mesure.perimeterCranien != null) ...[
                const SizedBox(width: 8),
                _StatBadge(label: 'Périm.', value: '${mesure.perimeterCranien} cm', color: const Color(0xFF00C9A7)),
              ],
            ],
          ),
          if (mesure.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(mesure.notes,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _ActionBtn(label: 'Modifier', icon: Icons.edit_outlined,
                  color: AppColors.secondary, onTap: onEdit),
              const SizedBox(width: 8),
              _ActionBtn(label: 'Supprimer', icon: Icons.delete_outline_rounded,
                  color: AppColors.danger, onTap: () => _confirmDelete(context)),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D2D5E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text('Supprimer cette mesure ?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () { Navigator.pop(context); onDelete(); },
              child: const Text('Supprimer',
                  style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text('$label: $value',
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
