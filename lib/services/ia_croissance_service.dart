import '../models/croissance_model.dart';
import 'gemini_service.dart';
import 'percentile_service.dart';

class AnalyseCroissanceIA {
  final List<AlerteCroissance> alertes;
  final String analyseGemini;
  final bool geminiDisponible;
  final double? dernierPctPoids;
  final double? dernierPctTaille;
  final double? dernierIMC;
  final String tendancePoids;   // 'stable', 'hausse', 'baisse'
  final String tendanceTaille;

  const AnalyseCroissanceIA({
    required this.alertes,
    required this.analyseGemini,
    required this.geminiDisponible,
    this.dernierPctPoids,
    this.dernierPctTaille,
    this.dernierIMC,
    required this.tendancePoids,
    required this.tendanceTaille,
  });

  bool get estNormal => alertes.isEmpty;
  bool get aAlerteElevee => alertes.any((a) => a.gravite == GraviteAlerte.elevee);
}

class IACroissanceService {
  static Future<AnalyseCroissanceIA> analyser({
    required List<CroissanceModel> mesures,
    required String prenomEnfant,
    required String sexe,
    required DateTime dateNaissance,
  }) async {
    if (mesures.isEmpty) {
      return const AnalyseCroissanceIA(
        alertes: [],
        analyseGemini: 'Aucune mesure enregistrée. Ajoutez des mesures pour obtenir une analyse.',
        geminiDisponible: false,
        tendancePoids: 'stable',
        tendanceTaille: 'stable',
      );
    }

    final sorted = List<CroissanceModel>.from(mesures)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Alertes locales via PercentileService
    final alertes = mesures.length >= 2
        ? PercentileService.detecterAnomalies(mesures: mesures, sexe: sexe)
        : <AlerteCroissance>[];

    // Percentiles de la dernière mesure
    final derniere = sorted.last;
    final ageMois = _ageMois(dateNaissance, derniere.date);
    final pctPoids = PercentileService.calculerPercentile(
        valeur: derniere.poids, ageMois: ageMois, sexe: sexe, estPoids: true);
    final pctTaille = PercentileService.calculerPercentile(
        valeur: derniere.taille, ageMois: ageMois, sexe: sexe, estPoids: false);

    // Tendances
    final tendancePoids = _calculerTendance(sorted.map((m) => m.poids).toList());
    final tendanceTaille = _calculerTendance(sorted.map((m) => m.taille).toList());

    // Appel Gemini
    final result = await _appelGemini(
      prenom: prenomEnfant,
      sexe: sexe,
      ageMois: ageMois,
      mesures: sorted,
      alertes: alertes,
      pctPoids: pctPoids,
      pctTaille: pctTaille,
      tendancePoids: tendancePoids,
      tendanceTaille: tendanceTaille,
    );

    return AnalyseCroissanceIA(
      alertes: alertes,
      analyseGemini: result.$1,
      geminiDisponible: result.$2,
      dernierPctPoids: pctPoids,
      dernierPctTaille: pctTaille,
      dernierIMC: derniere.imc,
      tendancePoids: tendancePoids,
      tendanceTaille: tendanceTaille,
    );
  }

  static Future<(String, bool)> _appelGemini({
    required String prenom,
    required String sexe,
    required int ageMois,
    required List<CroissanceModel> mesures,
    required List<AlerteCroissance> alertes,
    required double pctPoids,
    required double pctTaille,
    required String tendancePoids,
    required String tendanceTaille,
  }) async {
    if (!GeminiService.configuree) {
      return (_fallback(prenom, sexe, ageMois, alertes, pctPoids, pctTaille), false);
    }

    final ageStr = ageMois < 24 ? '$ageMois mois' : '${(ageMois / 12).floor()} ans';
    final il = sexe == 'F' ? 'elle' : 'il';
    final derniere = mesures.last;

    final historiqueStr = mesures.take(5).map((m) =>
      '${_fmtDate(m.date)}: poids=${m.poids}kg, taille=${m.taille}cm, IMC=${m.imc.toStringAsFixed(1)}'
    ).join(' | ');

    final alertesStr = alertes.isEmpty
        ? 'aucune anomalie détectée'
        : alertes.map((a) => a.message).join('; ');

    final prompt = '''
Tu es un assistant pédiatrique IA de l'application PediCare spécialisé en croissance infantile.
Analyse les données de croissance de $prenom et génère un rapport médical personnalisé en français pour les parents.

Données de l'enfant :
- Prénom : $prenom
- Sexe : ${sexe == 'F' ? 'Fille' : 'Garçon'}
- Âge : $ageStr
- Dernière mesure : poids=${derniere.poids}kg, taille=${derniere.taille}cm, IMC=${derniere.imc.toStringAsFixed(1)}
- Percentile poids : P${pctPoids.round()} (${_interpretePct(pctPoids)})
- Percentile taille : P${pctTaille.round()} (${_interpretePct(pctTaille)})
- Tendance poids : $tendancePoids
- Tendance taille : $tendanceTaille
- Historique récent : $historiqueStr
- Anomalies détectées : $alertesStr

Instructions :
- Rédige 4 à 6 phrases en langage clair et bienveillant pour les parents
- Commence par une évaluation globale de la croissance de $prenom
- Explique ce que signifient les percentiles de façon simple
- Si anomalie : explique la cause possible et quand consulter
- Si tout va bien : rassure les parents
- Donne un conseil nutritionnel ou de suivi adapté à l'âge
- Utilise "$il" selon le sexe, et le prénom $prenom
- Texte pur, sans markdown, sans listes
''';

    final text = await GeminiService.generer(
      prompt: prompt,
      temperature: 0.6,
      maxOutputTokens: 1024,
    );
    if (text == null) {
      return (_fallback(prenom, sexe, ageMois, alertes, pctPoids, pctTaille), false);
    }
    return (text, true);
  }

  static String _fallback(String prenom, String sexe, int ageMois,
      List<AlerteCroissance> alertes, double pctPoids, double pctTaille) {
    final il = sexe == 'F' ? 'Elle' : 'Il';
    final ageStr = ageMois < 24 ? '$ageMois mois' : '${(ageMois / 12).floor()} ans';

    if (alertes.isEmpty) {
      return '$prenom ($ageStr) présente une croissance normale. '
          '$il se situe au ${pctPoids.round()}ème percentile pour le poids et au ${pctTaille.round()}ème pour la taille. '
          'Aucune anomalie détectée. Continuez le suivi régulier avec votre pédiatre.';
    }
    final nbElevees = alertes.where((a) => a.gravite == GraviteAlerte.elevee).length;
    return '$prenom ($ageStr) présente ${alertes.length} anomalie(s) de croissance détectée(s)${nbElevees > 0 ? ', dont $nbElevees critique(s)' : ''}. '
        'Percentile poids : P${pctPoids.round()}, taille : P${pctTaille.round()}. '
        'Une consultation pédiatrique est recommandée.';
  }

  static String _calculerTendance(List<double> valeurs) {
    if (valeurs.length < 2) return 'stable';
    final diff = valeurs.last - valeurs.first;
    if (diff > 0.5) return 'hausse';
    if (diff < -0.2) return 'baisse';
    return 'stable';
  }

  static String _interpretePct(double p) {
    if (p < 3) return 'très faible';
    if (p < 15) return 'faible';
    if (p < 85) return 'normal';
    if (p < 97) return 'élevé';
    return 'très élevé';
  }

  static int _ageMois(DateTime naissance, DateTime date) =>
      (date.year - naissance.year) * 12 + (date.month - naissance.month);

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
