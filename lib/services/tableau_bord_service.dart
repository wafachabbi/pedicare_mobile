import '../models/consultation_model.dart';
import '../models/croissance_model.dart';
import '../models/enfant_model.dart';
import '../models/journal_alimentaire_model.dart';
import '../models/journal_symptome_model.dart';
import '../models/rendezvous_model.dart';
import '../models/tableau_bord_model.dart';
import '../models/traitement_model.dart';
import '../models/vaccin_model.dart';
import 'calendrier_vaccinal_service.dart';
import 'consultation_service.dart';
import 'croissance_service.dart';
import 'ia_consultation_service.dart';
import 'journal_alimentaire_service.dart';
import 'journal_symptome_service.dart';
import 'rendezvous_service.dart';
import 'traitement_service.dart';
import 'vaccin_service.dart';

/// Agrège les données de tous les modules pour le tableau de bord (Module 3).
class TableauBordService {
  static Future<TableauBordData> charger(EnfantModel enfant) async {
    final results = await Future.wait([
      VaccinService.getVaccins(enfant.id),
      VaccinService.getProchainesEcheances(enfant.id),
      RendezVousService.getRendezVous(enfant.id),
      CroissanceService.getMesures(enfant.id),
      JournalSymptomeService.getEntrees(enfant.id),
      ConsultationService.getConsultations(enfant.id),
      TraitementService.getActifs(enfant.id),
      JournalAlimentaireService.getEntrees(enfant.id),
    ]);

    final vaccins = results[0] as List<VaccinModel>;
    final prochainesEcheances = results[1] as List<VaccinModel>;
    final rdvs = results[2] as List<RendezVousModel>;
    final mesures = results[3] as List<CroissanceModel>;
    final journal = results[4] as List<JournalSymptomeModel>;
    final consultations = results[5] as List<ConsultationModel>;
    final traitements = results[6] as List<TraitementModel>;
    final entreesAlimentaires = results[7] as List<JournalAlimentaireModel>;

    final maintenant = DateTime.now();
    final prochainsRdv = rdvs
        .where((r) =>
            r.dateHeure.isAfter(maintenant) && r.statut != StatutRDV.annule)
        .toList()
      ..sort((a, b) => a.dateHeure.compareTo(b.dateHeure));

    final consultationsPassees = rdvs
        .where((r) =>
            r.dateHeure.isBefore(maintenant) || r.statut == StatutRDV.termine)
        .toList()
      ..sort((a, b) => b.dateHeure.compareTo(a.dateHeure));

    final journalRecent = journal.take(30).toList(growable: false);
    final stats = await JournalSymptomeService.getStatistiques(
      enfant.id,
      entrees: journal,
    );
    final serie = await JournalSymptomeService.getSerieJournaliere(
      enfant.id,
      jours: 7,
      entrees: journal,
    );
    final analyse = await IAConsultationService.analyserContexte(
      enfant: enfant,
      journal: journalRecent,
    );

    // État vaccinal à partir du calendrier national.
    final evaluation = CalendrierVaccinalService.evaluer(
      ageMois: CalendrierVaccinalService.ageMoisDepuis(enfant.dateNaissance),
      vaccinsAdministres: vaccins,
    );
    final faits = evaluation
        .where((v) => v.statut == StatutVaccin.fait)
        .length;
    final enRetard = evaluation
        .where((v) => v.statut == StatutVaccin.enRetard)
        .length;
    final aVenir = evaluation
        .where((v) => v.statut == StatutVaccin.aVenir)
        .length;
    final prochainsProgrammes = evaluation
        .where((v) => v.statut == StatutVaccin.aVenir)
        .toList()
      ..sort((a, b) =>
          a.programme.ageMoisMin.compareTo(b.programme.ageMoisMin));

    final vaccination = VaccinStats(
      faits: faits,
      enRetard: enRetard,
      aVenir: aVenir,
      total: evaluation.length,
      prochainVaccin: prochainesEcheances.isNotEmpty
          ? prochainesEcheances.first.nom
          : (prochainsProgrammes.isNotEmpty
              ? prochainsProgrammes.first.programme.nom
              : null),
      prochaineEcheance: prochainesEcheances.isNotEmpty
          ? prochainesEcheances.first.prochaineDate
          : null,
    );

    final evenements = _construireEvenements(
      journal: journalRecent,
      vaccins: vaccins,
      mesures: mesures,
      rendezvousPasses: consultationsPassees,
      consultations: consultations,
    );

    return TableauBordData(
      enfant: enfant,
      vaccins: vaccins,
      prochainsRdv: prochainsRdv,
      consultationsPassees: consultationsPassees,
      mesures: mesures,
      journalRecent: journalRecent,
      journalStats: stats,
      serieJournaliere: serie,
      consultations: consultations,
      traitementsActifs: traitements,
      vaccination: vaccination,
      analyse: analyse,
      evenements: evenements,
      entreesAlimentaires: entreesAlimentaires,
      chargement: maintenant,
    );
  }

  static List<EvenementDashboard> _construireEvenements({
    required List<JournalSymptomeModel> journal,
    required List<VaccinModel> vaccins,
    required List<CroissanceModel> mesures,
    required List<RendezVousModel> rendezvousPasses,
    required List<ConsultationModel> consultations,
  }) {
    final events = <EvenementDashboard>[];

    for (final e in journal.take(8)) {
      final details = <String>[];
      if (e.temperature != null) {
        details.add('${e.temperature!.toStringAsFixed(1)} °C');
      }
      if (e.notes.trim().isNotEmpty) details.add(e.notes.trim());
      events.add(EvenementDashboard(
        type: 'journal',
        titre: e.resumeCourt,
        sousTitre: details.isEmpty ? 'Journal de santé' : details.join(' · '),
        emoji: e.fievre ? '🌡️' : '📝',
        date: e.date,
      ));
    }

    for (final v in vaccins.take(8)) {
      events.add(EvenementDashboard(
        type: 'vaccin',
        titre: 'Vaccin : ${v.nom}',
        sousTitre: v.maladie,
        emoji: '💉',
        date: v.dateAdministre,
      ));
    }

    for (final m in mesures.take(5)) {
      events.add(EvenementDashboard(
        type: 'croissance',
        titre: 'Mesure de croissance',
        sousTitre:
            '${m.poids} kg · ${m.taille} cm · IMC ${m.imc.toStringAsFixed(1)}',
        emoji: '📏',
        date: m.date,
      ));
    }

    for (final r in rendezvousPasses.take(6)) {
      events.add(EvenementDashboard(
        type: 'rdv',
        titre: 'Consultation : ${r.titre}',
        sousTitre: r.medecin.isEmpty ? r.specialite : 'Dr. ${r.medecin}',
        emoji: '🏥',
        date: r.dateHeure,
      ));
    }

    for (final c in consultations.take(4)) {
      events.add(EvenementDashboard(
        type: 'consultation',
        titre: 'Résumé de consultation généré',
        sousTitre: c.titre,
        emoji: '🤖',
        date: c.createdAt,
      ));
    }

    events.sort((a, b) => b.date.compareTo(a.date));
    return events.take(15).toList(growable: false);
  }
}
