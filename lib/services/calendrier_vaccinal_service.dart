import '../models/vaccin_model.dart';

// ── Entrée du calendrier vaccinal ─────────────────────────────────────────────
class VaccinProgramme {
  final String nom;
  final String maladie;
  final String ageLabel;    // "Naissance", "2 mois", "12 mois"...
  final int ageMoisMin;     // âge min en mois pour ce vaccin
  final int ageMoisMax;     // âge max toléré (retard acceptable)
  final String description;

  const VaccinProgramme({
    required this.nom,
    required this.maladie,
    required this.ageLabel,
    required this.ageMoisMin,
    required this.ageMoisMax,
    required this.description,
  });
}

// ── Statut d'un vaccin dans le calendrier ─────────────────────────────────────
enum StatutVaccin { fait, enRetard, aVenir, nonConcerne }

class VaccinStatut {
  final VaccinProgramme programme;
  final StatutVaccin statut;
  final VaccinModel? vaccinAdministre;

  const VaccinStatut({
    required this.programme,
    required this.statut,
    this.vaccinAdministre,
  });
}

// ── Service calendrier vaccinal (Programme National Tunisien + OMS) ───────────
class CalendrierVaccinalService {

  // Calendrier vaccinal tunisien officiel
  static const List<VaccinProgramme> _calendrier = [
    VaccinProgramme(
      nom: 'BCG',
      maladie: 'Tuberculose',
      ageLabel: 'Naissance',
      ageMoisMin: 0,
      ageMoisMax: 1,
      description: 'Vaccin contre la tuberculose, administré à la naissance',
    ),
    VaccinProgramme(
      nom: 'Hépatite B (1)',
      maladie: 'Hépatite B',
      ageLabel: 'Naissance',
      ageMoisMin: 0,
      ageMoisMax: 1,
      description: '1ère dose du vaccin contre l\'hépatite B',
    ),
    VaccinProgramme(
      nom: 'DTCoq-Hib-HB-Polio (1)',
      maladie: 'Diphtérie, Tétanos, Coqueluche, Polio, Hib',
      ageLabel: '2 mois',
      ageMoisMin: 2,
      ageMoisMax: 4,
      description: '1ère dose du vaccin pentavalent',
    ),
    VaccinProgramme(
      nom: 'VPC13 (1)',
      maladie: 'Pneumocoque',
      ageLabel: '2 mois',
      ageMoisMin: 2,
      ageMoisMax: 4,
      description: '1ère dose vaccin anti-pneumococcique',
    ),
    VaccinProgramme(
      nom: 'DTCoq-Hib-HB-Polio (2)',
      maladie: 'Diphtérie, Tétanos, Coqueluche, Polio, Hib',
      ageLabel: '3 mois',
      ageMoisMin: 3,
      ageMoisMax: 5,
      description: '2ème dose du vaccin pentavalent',
    ),
    VaccinProgramme(
      nom: 'VPC13 (2)',
      maladie: 'Pneumocoque',
      ageLabel: '3 mois',
      ageMoisMin: 3,
      ageMoisMax: 5,
      description: '2ème dose vaccin anti-pneumococcique',
    ),
    VaccinProgramme(
      nom: 'DTCoq-Hib-HB-Polio (3)',
      maladie: 'Diphtérie, Tétanos, Coqueluche, Polio, Hib',
      ageLabel: '4 mois',
      ageMoisMin: 4,
      ageMoisMax: 6,
      description: '3ème dose du vaccin pentavalent',
    ),
    VaccinProgramme(
      nom: 'VPC13 (3)',
      maladie: 'Pneumocoque',
      ageLabel: '4 mois',
      ageMoisMin: 4,
      ageMoisMax: 6,
      description: '3ème dose vaccin anti-pneumococcique',
    ),
    VaccinProgramme(
      nom: 'ROR (1)',
      maladie: 'Rougeole, Oreillons, Rubéole',
      ageLabel: '12 mois',
      ageMoisMin: 12,
      ageMoisMax: 15,
      description: '1ère dose du vaccin ROR',
    ),
    VaccinProgramme(
      nom: 'VPC13 (rappel)',
      maladie: 'Pneumocoque',
      ageLabel: '12 mois',
      ageMoisMin: 12,
      ageMoisMax: 15,
      description: 'Rappel vaccin anti-pneumococcique',
    ),
    VaccinProgramme(
      nom: 'Méningocoque A+C',
      maladie: 'Méningite',
      ageLabel: '12 mois',
      ageMoisMin: 12,
      ageMoisMax: 18,
      description: 'Vaccin anti-méningococcique',
    ),
    VaccinProgramme(
      nom: 'Varicelle (1)',
      maladie: 'Varicelle',
      ageLabel: '12 mois',
      ageMoisMin: 12,
      ageMoisMax: 18,
      description: '1ère dose vaccin varicelle',
    ),
    VaccinProgramme(
      nom: 'ROR (2)',
      maladie: 'Rougeole, Oreillons, Rubéole',
      ageLabel: '18 mois',
      ageMoisMin: 18,
      ageMoisMax: 24,
      description: '2ème dose du vaccin ROR (rappel)',
    ),
    VaccinProgramme(
      nom: 'Varicelle (2)',
      maladie: 'Varicelle',
      ageLabel: '18 mois',
      ageMoisMin: 18,
      ageMoisMax: 24,
      description: '2ème dose vaccin varicelle',
    ),
    VaccinProgramme(
      nom: 'DTCoq-Polio (rappel)',
      maladie: 'Diphtérie, Tétanos, Coqueluche, Polio',
      ageLabel: '6 ans',
      ageMoisMin: 72,
      ageMoisMax: 84,
      description: 'Rappel DTC-Polio à 6 ans',
    ),
    VaccinProgramme(
      nom: 'dT-Polio (rappel)',
      maladie: 'Diphtérie, Tétanos, Polio',
      ageLabel: '11-13 ans',
      ageMoisMin: 132,
      ageMoisMax: 156,
      description: 'Rappel dT-Polio adolescent',
    ),
  ];

  /// Retourne le calendrier complet avec le statut de chaque vaccin
  /// pour un enfant de [ageMois] mois, en comparant avec [vaccinsAdministres]
  static List<VaccinStatut> evaluer({
    required int ageMois,
    required List<VaccinModel> vaccinsAdministres,
  }) {
    return _calendrier.map((programme) {
      // Cherche si ce vaccin a été administré (correspondance par nom partiel)
      final administre = _trouverVaccin(programme, vaccinsAdministres);

      StatutVaccin statut;

      if (administre != null) {
        // Vaccin trouvé dans l'historique
        statut = StatutVaccin.fait;
      } else if (ageMois < programme.ageMoisMin) {
        // Enfant pas encore à l'âge requis
        statut = StatutVaccin.aVenir;
      } else if (ageMois <= programme.ageMoisMax + 6) {
        // Dans la fenêtre ou légèrement dépassé → en retard
        statut = StatutVaccin.enRetard;
      } else {
        // Trop vieux pour ce vaccin (> max + 6 mois de grâce)
        // Si l'enfant n'a pas eu le vaccin et est trop vieux,
        // on marque quand même en retard pour alerter
        statut = ageMois > programme.ageMoisMax + 12
            ? StatutVaccin.enRetard
            : StatutVaccin.enRetard;
      }

      return VaccinStatut(
        programme: programme,
        statut: statut,
        vaccinAdministre: administre,
      );
    }).toList();
  }

  /// Retourne uniquement les vaccins en retard ou à faire bientôt
  static List<VaccinStatut> getAlertes({
    required int ageMois,
    required List<VaccinModel> vaccinsAdministres,
  }) {
    return evaluer(ageMois: ageMois, vaccinsAdministres: vaccinsAdministres)
        .where((v) => v.statut == StatutVaccin.enRetard ||
            (v.statut == StatutVaccin.aVenir &&
                v.programme.ageMoisMin <= ageMois + 2))
        .toList();
  }

  /// Cherche un vaccin administré correspondant au programme
  static VaccinModel? _trouverVaccin(
      VaccinProgramme programme, List<VaccinModel> administres) {
    final nomProg = _normaliser(programme.nom);
    final maladieProg = _normaliser(programme.maladie);

    for (final v in administres) {
      final nomV = _normaliser(v.nom);
      final maladieV = _normaliser(v.maladie);

      // Correspondance exacte ou partielle
      if (nomV.contains(nomProg) ||
          nomProg.contains(nomV) ||
          maladieV.contains(maladieProg) ||
          maladieProg.contains(maladieV)) {
        return v;
      }
    }
    return null;
  }

  static String _normaliser(String s) =>
      s.toLowerCase()
          .replaceAll(RegExp(r'\s+'), '')
          .replaceAll(RegExp(r'[()0-9]'), '')
          .replaceAll('é', 'e')
          .replaceAll('è', 'e')
          .replaceAll('ê', 'e')
          .replaceAll('à', 'a')
          .replaceAll('ô', 'o');

  /// Calcule l'âge en mois depuis la date de naissance
  static int ageMoisDepuis(DateTime dateNaissance) {
    final now = DateTime.now();
    return (now.year - dateNaissance.year) * 12 +
        (now.month - dateNaissance.month);
  }
}
