import 'package:flutter/material.dart';
import '../../models/vaccin_model.dart';
import '../../theme/app_colors.dart';
import 'add_vaccin_screen.dart';

class VaccinDetailScreen extends StatelessWidget {
  final VaccinModel vaccin;
  final VoidCallback onDelete;

  const VaccinDetailScreen({
    super.key,
    required this.vaccin,
    required this.onDelete,
  });

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
                    children: [
                      _buildHero(),
                      const SizedBox(height: 24),
                      _buildInfoCard(),
                      const SizedBox(height: 16),
                      if (vaccin.prochaineDate != null) _buildRappelCard(),
                      if (vaccin.notes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildNotesCard(),
                      ],
                      const SizedBox(height: 32),
                      _buildActions(context),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          const Text('Détail vaccin',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddVaccinScreen(
                    enfantId: vaccin.enfantId, vaccin: vaccin),
              ),
            ),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Icon(Icons.edit_outlined,
                  color: AppColors.textPrimary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00855A), Color(0xFF00C9A7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x4400C9A7), blurRadius: 20, offset: Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          const Text('💉', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(vaccin.nom,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(vaccin.maladie,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Administré le ${_formatDate(vaccin.dateAdministre)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return _Card(
      title: 'Informations',
      children: [
        _InfoRow(emoji: '👨‍⚕️', label: 'Médecin', value: 'Dr. ${vaccin.medecin}'),
        if (vaccin.lieu.isNotEmpty)
          _InfoRow(emoji: '📍', label: 'Lieu', value: vaccin.lieu),
        if (vaccin.lotNumero.isNotEmpty)
          _InfoRow(emoji: '🔖', label: 'N° de lot', value: vaccin.lotNumero),
      ],
    );
  }

  Widget _buildRappelCard() {
    final jours =
        vaccin.prochaineDate!.difference(DateTime.now()).inDays;
    final urgent = jours <= 7;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: urgent
            ? const Color(0xFFE67E22).withOpacity(0.12)
            : const Color(0xFF1E6FDB).withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: urgent
              ? const Color(0xFFE67E22).withOpacity(0.4)
              : AppColors.glassBorder,
        ),
      ),
      child: Row(
        children: [
          Text(urgent ? '⚠️' : '📅',
              style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Prochain rappel',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              Text(_formatDate(vaccin.prochaineDate!),
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              Text(
                jours >= 0 ? 'Dans $jours jours' : 'En retard de ${-jours} jours',
                style: TextStyle(
                    color: urgent
                        ? const Color(0xFFE67E22)
                        : AppColors.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return _Card(
      title: 'Notes',
      children: [
        Text(vaccin.notes,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5)),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return GestureDetector(
      onTap: () => _confirmDelete(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.danger.withOpacity(0.4)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded,
                color: AppColors.danger, size: 20),
            SizedBox(width: 8),
            Text('Supprimer ce vaccin',
                style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D2D5E),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Supprimer le vaccin "${vaccin.nom}" ?',
            style:
                const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler',
                  style:
                      TextStyle(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                onDelete();
                Navigator.pop(context);
              },
              child: const Text('Supprimer',
                  style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Card({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  const _InfoRow(
      {required this.emoji, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Text('$label : ',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
