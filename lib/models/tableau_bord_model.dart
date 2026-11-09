import 'journal_alimentaire_model.dart';
import 'analyse_symptomes_model.dart';
import 'consultation_model.dart';
import 'croissance_model.dart';
import 'enfant_model.dart';
import 'journal_symptome_model.dart';
import 'rendezvous_model.dart';
import 'traitement_model.dart';
import 'vaccin_model.dart';
import '../services/journal_symptome_service.dart';

class EvenementDashboard {
  final String type; // journal | vaccin | rdv | croissance | consultation
  final String titre;
  final String sousTitre;
  final String emoji;
  final DateTime date;

  const EvenementDashboard({
    required this.type,
    required this.titre,
    required this.sousTitre,
    required this.emoji,
    required this.date,
  });
}

class VaccinStats {
  final int faits;
  final int enRetard;
  final int aVenir;
  final int total;
  final String? prochainVaccin;
  final DateTime? prochaineEcheance;

  const VaccinStats({
    required this.faits,
    required this.enRetard,
    required this.aVenir,
    required this.total,
    this.prochainVaccin,
    this.prochaineEcheance,
  });

  double get couverture => total == 0 ? 0 : (faits / total).clamp(0.0, 1.0);

  static const empty = VaccinStats(
    faits: 0,
    enRetard: 0,
    aVenir: 0,
    total: 0,
  );
}

class TableauBordData {
  final EnfantModel enfant;
  final List<VaccinModel> vaccins;
  final List<RendezVousModel> prochainsRdv;
  final List<RendezVousModel> consultationsPassees;
  final List<CroissanceModel> mesures;
  final List<JournalSymptomeModel> journalRecent;
  final JournalStats journalStats;
  final List<JourJournal> serieJournaliere;
  final List<ConsultationModel> consultations;
  final List<TraitementModel> traitementsActifs;
  final VaccinStats vaccination;
  final AnalyseSymptomes analyse;
  final List<EvenementDashboard> evenements;
  final List<JournalAlimentaireModel> entreesAlimentaires;
  final DateTime chargement;

  const TableauBordData({
    required this.enfant,
    required this.vaccins,
    required this.prochainsRdv,
    required this.consultationsPassees,
    required this.mesures,
    required this.journalRecent,
    required this.journalStats,
    required this.serieJournaliere,
    required this.consultations,
    required this.traitementsActifs,
    required this.vaccination,
    required this.analyse,
    required this.evenements,
    required this.entreesAlimentaires,
    required this.chargement,
  });

  CroissanceModel? get derniereMesure => mesures.isEmpty ? null : mesures.first;

  ConsultationModel? get dernierResume =>
      consultations.isEmpty ? null : consultations.first;
}
