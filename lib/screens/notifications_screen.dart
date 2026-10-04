import 'package:flutter/material.dart';
import '../models/enfant_model.dart';
import '../models/vaccin_model.dart';
import '../models/rendezvous_model.dart';
import '../services/enfant_service.dart';
import '../services/vaccin_service.dart';
import '../services/rendezvous_service.dart';
import '../theme/app_colors.dart';

class _Notif {
  final String type; // 'vaccin' | 'rdv'
  final String emoji;
  final String titre;
  final String sousTitre;
  final String enfantNom;
  final DateTime date;
  final Color color;

  _Notif({
    required this.type,
    required this.emoji,
    required this.titre,
    required this.sousTitre,
    required this.enfantNom,
    required this.date,
    required this.color,
  });
}

class NotificationsScreen extends StatefulWidget {
  final String parentId;
  const NotificationsScreen({super.key, required this.parentId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<_Notif> _notifs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final List<_Notif> result = [];

    final enfants = await EnfantService.getEnfants(widget.parentId);

    for (final EnfantModel enfant in enfants) {
      // Vaccins à venir
      final echeances = await VaccinService.getProchainesEcheances(enfant.id);
      for (final VaccinModel v in echeances) {
        final jours = v.prochaineDate!.difference(DateTime.now()).inDays;
        result.add(_Notif(
          type: 'vaccin',
          emoji: jours <= 7 ? '⚠️' : '💉',
          titre: 'Rappel vaccin : ${v.nom}',
          sousTitre: v.maladie,
          enfantNom: enfant.prenom,
          date: v.prochaineDate!,
          color: jours <= 7 ? const Color(0xFFE67E22) : const Color(0xFF00C9A7),
        ));
      }

      // Rendez-vous à venir
      final rdvs = await RendezVousService.getProchains(enfant.id);
      for (final RendezVousModel r in rdvs) {
        final jours = r.dateHeure.difference(DateTime.now()).inDays;
        result.add(_Notif(
          type: 'rdv',
          emoji: jours <= 2 ? '🚨' : '📅',
          titre: r.titre,
          sousTitre: 'Dr. ${r.medecin} · ${r.specialite}',
          enfantNom: enfant.prenom,
          date: r.dateHeure,
          color: jours <= 2 ? const Color(0xFFFF6B6B) : const Color(0xFF1E6FDB),
        ));
      }
    }

    // Trier par date la plus proche
    result.sort((a, b) => a.date.compareTo(b.date));

    if (mounted) setState(() { _notifs = result; _loading = false; });
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
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
                    : _notifs.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            color: AppColors.secondary,
                            backgroundColor: const Color(0xFF0D2D5E),
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                              itemCount: _notifs.length,
                              itemBuilder: (context, i) => _NotifTile(notif: _notifs[i]),
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
                const Text('Notifications',
                    style: TextStyle(color: AppColors.textPrimary,
                        fontSize: 20, fontWeight: FontWeight.w700)),
                Text(_loading ? '' : '${_notifs.length} alerte(s)',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (!_loading && _notifs.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.danger.withOpacity(0.4)),
              ),
              child: Text('${_notifs.length}',
                  style: const TextStyle(color: AppColors.danger,
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('✅', style: TextStyle(fontSize: 56)),
          SizedBox(height: 16),
          Text('Tout est à jour !',
              style: TextStyle(color: AppColors.textPrimary,
                  fontSize: 18, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text('Aucune alerte en cours',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final _Notif notif;
  const _NotifTile({required this.notif});

  @override
  Widget build(BuildContext context) {
    final jours = notif.date.difference(DateTime.now()).inDays;
    final label = jours == 0
        ? "Aujourd'hui"
        : jours == 1
            ? 'Demain'
            : 'Dans $jours j.';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notif.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: notif.color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: notif.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(child: Text(notif.emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notif.titre,
                    style: const TextStyle(color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 3),
                Text(notif.sousTitre,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E6FDB).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('👶 ${notif.enfantNom}',
                          style: const TextStyle(color: AppColors.secondary,
                              fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 6),
                    Text(_fmtDate(notif.date),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: notif.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: notif.color.withOpacity(0.4)),
            ),
            child: Text(label,
                style: TextStyle(color: notif.color,
                    fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
