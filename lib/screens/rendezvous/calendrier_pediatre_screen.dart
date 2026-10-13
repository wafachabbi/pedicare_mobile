import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/rendezvous_model.dart';
import '../../services/rendezvous_service.dart';
import '../../theme/app_colors.dart';

class CalendrierPediatreScreen extends StatefulWidget {
  final String pediatreId;
  final String pediatreNom;

  const CalendrierPediatreScreen({
    super.key,
    required this.pediatreId,
    required this.pediatreNom,
  });

  @override
  State<CalendrierPediatreScreen> createState() =>
      _CalendrierPediatreScreenState();
}

class _CalendrierPediatreScreenState
    extends State<CalendrierPediatreScreen> {
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
    final rdvs =
        await RendezVousService.getRendezVousPediatre(widget.pediatreId);
    if (mounted) setState(() { _rdvs = rdvs; _loading = false; });
  }

  List<RendezVousModel> _rdvsDuJour(DateTime day) =>
      _rdvs.where((r) => isSameDay(r.dateHeure, day)).toList();

  List<RendezVousModel> get _rdvsSelectionnes =>
      _selectedDay == null ? [] : _rdvsDuJour(_selectedDay!);

  Color _couleurStatut(StatutRDV s) {
    switch (s) {
      case StatutRDV.confirme:  return const Color(0xFF00C9A7);
      case StatutRDV.enAttente: return const Color(0xFFE67E22);
      case StatutRDV.annule:    return AppColors.danger;
      case StatutRDV.termine:   return AppColors.textSecondary;
    }
  }

  Future<void> _updateStatut(RendezVousModel rdv, StatutRDV statut) async {
    await RendezVousService.updateRendezVous(rdv.copyWith(statut: statut));
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A1628), Color(0xFF0A2340), Color(0xFF0D3B6E)],
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
                    ? const Center(child: CircularProgressIndicator(
                        color: Color(0xFF00C9A7)))
                    : Column(
                        children: [
                          const SizedBox(height: 12),
                          SizedBox(
                            height: _calendarFormat == CalendarFormat.month ? 370 : 200,
                            child: _buildCalendar(),
                          ),
                          const SizedBox(height: 8),
                          _buildDayHeader(),
                          Expanded(child: _buildList()),
                        ],
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mon calendrier',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              Text('Dr. ${widget.pediatreNom}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00C9A7).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF00C9A7).withOpacity(0.3)),
            ),
            child: Text(
              '${_rdvs.where((r) => r.dateHeure.isAfter(DateTime.now()) && r.statut != StatutRDV.annule).length} à venir',
              style: const TextStyle(
                  color: Color(0xFF00C9A7),
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
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
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          selectedDecoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF00855A), Color(0xFF00C9A7)]),
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700),
          todayDecoration: BoxDecoration(
            color: const Color(0xFF00C9A7).withOpacity(0.25),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
              color: Color(0xFF00C9A7), fontWeight: FontWeight.w700),
          defaultTextStyle:
              const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          weekendTextStyle:
              const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          markersMaxCount: 3,
          markerSize: 5,
          markerMargin: const EdgeInsets.only(top: 1),
          cellMargin: const EdgeInsets.all(4),
        ),
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
            color: Color(0xFF0D3B6E),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          formatButtonTextStyle:
              TextStyle(color: Color(0xFF00C9A7), fontSize: 11),
          headerPadding:
              EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
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
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) =>
            setState(() => _calendarFormat = format),
        onPageChanged: (focusedDay) => _focusedDay = focusedDay,
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return null;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: events.take(3).map((rdv) => Container(
                width: 5, height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: _couleurStatut(rdv.statut),
                  shape: BoxShape.circle,
                ),
              )).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDayHeader() {
    if (_selectedDay == null) return const SizedBox.shrink();
    final count = _rdvsSelectionnes.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          Text(
            _formatDateFr(_selectedDay!),
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
                color: const Color(0xFF00C9A7).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$count patient${count > 1 ? 's' : ''}',
                  style: const TextStyle(
                      color: Color(0xFF00C9A7),
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final rdvs = _rdvsSelectionnes;

    if (rdvs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📭', style: TextStyle(fontSize: 40)),
            SizedBox(height: 10),
            Text('Aucune consultation ce jour',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: rdvs.length,
      itemBuilder: (context, i) => _ConsultationCard(
        rdv: rdvs[i],
        onConfirm: () => _updateStatut(rdvs[i], StatutRDV.confirme),
        onTermine: () => _updateStatut(rdvs[i], StatutRDV.termine),
        onAnnule: () => _updateStatut(rdvs[i], StatutRDV.annule),
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

// ── Carte consultation ─────────────────────────────────────────────────────────
class _ConsultationCard extends StatelessWidget {
  final RendezVousModel rdv;
  final VoidCallback onConfirm;
  final VoidCallback onTermine;
  final VoidCallback onAnnule;

  const _ConsultationCard({
    required this.rdv,
    required this.onConfirm,
    required this.onTermine,
    required this.onAnnule,
  });

  Color get _statutColor {
    switch (rdv.statut) {
      case StatutRDV.confirme:  return const Color(0xFF00C9A7);
      case StatutRDV.enAttente: return const Color(0xFFE67E22);
      case StatutRDV.annule:    return AppColors.danger;
      case StatutRDV.termine:   return AppColors.textSecondary;
    }
  }

  String get _statutLabel {
    switch (rdv.statut) {
      case StatutRDV.confirme:  return 'Confirmé';
      case StatutRDV.enAttente: return 'En attente';
      case StatutRDV.annule:    return 'Annulé';
      case StatutRDV.termine:   return 'Terminé';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statutColor.withOpacity(0.35), width: 1.2),
      ),
      child: Column(
        children: [
          // Bande heure
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _statutColor.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_rounded,
                    color: _statutColor, size: 14),
                const SizedBox(width: 6),
                Text(
                  '${rdv.dateHeure.hour.toString().padLeft(2, '0')}h${rdv.dateHeure.minute.toString().padLeft(2, '0')}',
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
          // Corps
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C9A7).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                          child: Text(rdv.type == 'video' ? '🎥' : '👶',
                              style: const TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rdv.enfantNomComplet ?? rdv.titre,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14),
                          ),
                          Text(rdv.titre,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                          if (rdv.parentNom != null)
                            Text('Parent : ${rdv.parentNom}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (rdv.lieu.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(children: [
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
                  ]),
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
                Row(children: [
                  if (rdv.statut == StatutRDV.enAttente)
                    _Btn('Confirmer', Icons.check_circle_outline,
                        const Color(0xFF00C9A7), onConfirm),
                  if (rdv.statut == StatutRDV.confirme) ...[
                    _Btn('Terminé', Icons.done_all_rounded,
                        const Color(0xFF1E6FDB), onTermine),
                    const SizedBox(width: 8),
                  ],
                  if (rdv.statut != StatutRDV.annule &&
                      rdv.statut != StatutRDV.termine) ...[
                    const SizedBox(width: 8),
                    _Btn('Annuler', Icons.cancel_outlined,
                        AppColors.danger, onAnnule),
                  ],
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _Btn(this.label, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
