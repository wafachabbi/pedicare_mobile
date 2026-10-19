import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/rendezvous_model.dart';
import '../../services/rendezvous_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import 'add_rendezvous_screen.dart';

class CalendrierRdvScreen extends StatefulWidget {
  final String enfantId;
  final String enfantNom;

  const CalendrierRdvScreen({
    super.key,
    required this.enfantId,
    required this.enfantNom,
  });

  @override
  State<CalendrierRdvScreen> createState() => _CalendrierRdvScreenState();
}

class _CalendrierRdvScreenState extends State<CalendrierRdvScreen> {
  List<RendezVousModel> _rdvs = [];
  bool _loading = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final rdvs = await RendezVousService.getRendezVous(widget.enfantId);
    if (mounted) {
      setState(() {
        _rdvs = rdvs;
        _loading = false;
      });
      final prochains = rdvs
          .where((r) =>
              r.dateHeure.isAfter(DateTime.now()) &&
              r.statut != StatutRDV.annule)
          .toList();
      await NotificationService.planifierRappelsRDV(prochains, widget.enfantNom);
    }
  }

  // Retourne les RDV d'un jour donné
  List<RendezVousModel> _rdvsDuJour(DateTime day) {
    return _rdvs.where((r) => isSameDay(r.dateHeure, day)).toList();
  }

  // Retourne les RDV du jour sélectionné
  List<RendezVousModel> get _rdvsSelectionnes {
    if (_selectedDay == null) return [];
    return _rdvsDuJour(_selectedDay!);
  }

  // Couleur du marqueur selon le statut
  Color _couleurStatut(StatutRDV statut) {
    switch (statut) {
      case StatutRDV.confirme:
        return const Color(0xFF00C9A7);
      case StatutRDV.enAttente:
        return const Color(0xFFE67E22);
      case StatutRDV.annule:
        return AppColors.danger;
      case StatutRDV.termine:
        return AppColors.textSecondary;
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
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.secondary))
                    : _buildBody(),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Calendrier',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              Text(widget.enfantNom,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          const Spacer(),
          // Compteur total RDV à venir
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E6FDB).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF1E6FDB).withOpacity(0.3)),
            ),
            child: Text(
              '${_rdvs.where((r) => r.dateHeure.isAfter(DateTime.now()) && r.statut != StatutRDV.annule).length} à venir',
              style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        const SizedBox(height: 12),
        // Calendrier à hauteur fixe pour éviter l'overflow
        SizedBox(
          height: _calendarFormat == CalendarFormat.month ? 370 : 200,
          child: _buildCalendar(),
        ),
        const SizedBox(height: 8),
        _buildSelectedDayHeader(),
        Expanded(child: _buildRdvList()),
      ],
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: TableCalendar<RendezVousModel>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        eventLoader: _rdvsDuJour,
        startingDayOfWeek: StartingDayOfWeek.monday,
        locale: 'fr_FR',
        // ── Style ─────────────────────────────────────────────────────────
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          // Jour sélectionné
          selectedDecoration: const BoxDecoration(
            gradient: LinearGradient(colors: AppColors.buttonGradient),
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700),
          // Aujourd'hui
          todayDecoration: BoxDecoration(
            color: const Color(0xFF1E6FDB).withOpacity(0.25),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
              color: AppColors.secondary, fontWeight: FontWeight.w700),
          // Textes
          defaultTextStyle:
              const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          weekendTextStyle:
              const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          outsideTextStyle:
              const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          // Marqueurs d'événements
          markerDecoration: const BoxDecoration(
            color: Color(0xFF1E6FDB),
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
          markerSize: 5,
          markerMargin: const EdgeInsets.only(top: 1),
          cellMargin: const EdgeInsets.all(4),
        ),
        // ── En-tête ───────────────────────────────────────────────────────
        headerStyle: const HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonShowsNext: false,
          titleTextStyle: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15),
          leftChevronIcon: Icon(Icons.chevron_left_rounded,
              color: AppColors.textPrimary),
          rightChevronIcon: Icon(Icons.chevron_right_rounded,
              color: AppColors.textPrimary),
          formatButtonDecoration: BoxDecoration(
            color: Color(0xFF1E3A6E),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          formatButtonTextStyle:
              TextStyle(color: AppColors.secondary, fontSize: 11),
          headerPadding:
              EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        // ── Jours de la semaine ───────────────────────────────────────────
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600),
          weekendStyle: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600),
        ),
        // ── Callbacks ────────────────────────────────────────────────────
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() => _calendarFormat = format);
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        // Marqueurs personnalisés par statut
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return null;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: events.take(3).map((rdv) {
                return Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: _couleurStatut(rdv.statut),
                    shape: BoxShape.circle,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSelectedDayHeader() {
    if (_selectedDay == null) return const SizedBox.shrink();
    final count = _rdvsSelectionnes.length;
    final label = _formatDateFr(_selectedDay!);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14),
          ),
          const Spacer(),
          if (count > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E6FDB).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count RDV',
                style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRdvList() {
    final rdvs = _rdvsSelectionnes;

    if (rdvs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📭', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 10),
            const Text('Aucun rendez-vous ce jour',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddRendezVousScreen(
                      enfantId: widget.enfantId,
                      initialDate: _selectedDay,
                    ),
                  ),
                );
                _loadData();
              },
              child: const Text('+ Ajouter un RDV pour ce jour',
                  style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: rdvs.length,
      itemBuilder: (context, i) => _RdvCard(
        rdv: rdvs[i],
        onStatusChange: (statut) async {
          await RendezVousService.updateRendezVous(
              rdvs[i].copyWith(statut: statut));
          if (statut == StatutRDV.annule) {
            await NotificationService.annulerRappelsRDV(rdvs[i].id);
          }
          _loadData();
        },
        onDelete: () async {
          await RendezVousService.deleteRendezVous(
              rdvs[i].enfantId, rdvs[i].id);
          await NotificationService.annulerRappelsRDV(rdvs[i].id);
          _loadData();
        },
        onEdit: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddRendezVousScreen(
                  enfantId: widget.enfantId, rdv: rdvs[i]),
            ),
          );
          _loadData();
        },
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddRendezVousScreen(
              enfantId: widget.enfantId,
              initialDate: _selectedDay,
            ),
          ),
        );
        _loadData();
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient:
              const LinearGradient(colors: AppColors.buttonGradient),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x441E6FDB),
                blurRadius: 16,
                offset: Offset(0, 6))
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Nouveau RDV',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  String _formatDateFr(DateTime d) {
    const jours = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi',
      'Vendredi', 'Samedi', 'Dimanche'
    ];
    const mois = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${jours[d.weekday - 1]} ${d.day} ${mois[d.month - 1]} ${d.year}';
  }
}

// ── Carte RDV ──────────────────────────────────────────────────────────────────
class _RdvCard extends StatelessWidget {
  final RendezVousModel rdv;
  final Function(StatutRDV) onStatusChange;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _RdvCard({
    required this.rdv,
    required this.onStatusChange,
    required this.onDelete,
    required this.onEdit,
  });

  Color get _statutColor {
    switch (rdv.statut) {
      case StatutRDV.confirme:
        return const Color(0xFF00C9A7);
      case StatutRDV.enAttente:
        return const Color(0xFFE67E22);
      case StatutRDV.annule:
        return AppColors.danger;
      case StatutRDV.termine:
        return AppColors.textSecondary;
    }
  }

  String get _statutLabel {
    switch (rdv.statut) {
      case StatutRDV.confirme:
        return 'Confirmé';
      case StatutRDV.enAttente:
        return 'En attente';
      case StatutRDV.annule:
        return 'Annulé';
      case StatutRDV.termine:
        return 'Terminé';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _statutColor.withOpacity(0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          // ── Bande heure + statut ────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _statutColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_rounded,
                    color: _statutColor, size: 14),
                const SizedBox(width: 6),
                Text(
                  _heure(rdv.dateHeure),
                  style: TextStyle(
                      color: _statutColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statutColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _statutColor.withOpacity(0.4)),
                  ),
                  child: Text(_statutLabel,
                      style: TextStyle(
                          color: _statutColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          // ── Corps ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(rdv.type == 'video' ? '🎥' : '🏥',
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rdv.titre,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                          Text(
                              'Dr. ${rdv.medecin} • ${rdv.specialite}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (rdv.lieu.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: AppColors.textSecondary, size: 13),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(rdv.lieu,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
                if (rdv.notes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(rdv.notes,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 10),
                // ── Actions ─────────────────────────────────────────────
                Row(
                  children: [
                    _Btn(
                        label: 'Modifier',
                        icon: Icons.edit_outlined,
                        color: AppColors.secondary,
                        onTap: onEdit),
                    const SizedBox(width: 8),
                    if (rdv.statut != StatutRDV.annule)
                      _Btn(
                          label: 'Annuler',
                          icon: Icons.cancel_outlined,
                          color: AppColors.danger,
                          onTap: () =>
                              onStatusChange(StatutRDV.annule)),
                    if (rdv.statut == StatutRDV.enAttente) ...[
                      const SizedBox(width: 8),
                      _Btn(
                          label: 'Confirmer',
                          icon: Icons.check_circle_outline,
                          color: const Color(0xFF00C9A7),
                          onTap: () =>
                              onStatusChange(StatutRDV.confirme)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _heure(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';
}

class _Btn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _Btn(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
