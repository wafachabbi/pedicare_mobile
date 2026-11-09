import '../models/analyse_symptomes_model.dart';
import '../models/croissance_model.dart';
import '../models/enfant_model.dart';
import '../models/journal_symptome_model.dart';
import '../models/rendezvous_model.dart';
import '../models/traitement_model.dart';
import '../models/vaccin_model.dart';
import '../services/journal_symptome_service.dart';
import '../services/gemini_service.dart';
import '../data/symptomes_catalogue.dart';

/// Module 3 & 10 — intelligence pré-consultation et analyse contextuelle.
///
/// Le moteur local fonctionne hors connexion. Si une clé Gemini est
/// configurée ([GeminiService.configuree]), les textes sont enrichis par
/// l'API Google Gemini.
class IAConsultationService {

  // ── Analyse contextuelle des symptômes ────────────────────────────────────
  static Future<AnalyseSymptomes> analyserContexte({
    required EnfantModel enfant,
    required List<JournalSymptomeModel> journal,
  }) async {
    if (journal.isEmpty) {
      return const AnalyseSymptomes(
        suggestions: [
          SuggestionSante(
            texte:
                'Aucune entrée dans le journal. Notez les symptômes quotidiens pour obtenir des conseils de suivi personnalisés.',
            emoji: '📝',
          ),
        ],
        message:
            'Le journal est vide. Une saisie régulière permet de mieux préparer la consultation.',
      );
    }

    final sorted = List<JournalSymptomeModel>.from(journal)
      ..sort((a, b) => b.date.compareTo(a.date));
    final latest = sorted.first;
    final ageMois = _ageMois(enfant.dateNaissance);
    final suggestions = <SuggestionSante>[];
    final symptomes = latest.symptomes.toSet();

    // Signes d'alerte prioritaires.
    if (symptomes.contains('respiration')) {
      suggestions.add(const SuggestionSante(
        texte:
            'Difficulté à respirer signalée : contactez immédiatement un médecin ou les urgences.',
        niveau: NiveauSuggestion.urgent,
        emoji: '🚨',
      ));
    }
    if (symptomes.contains('convulsion')) {
      suggestions.add(const SuggestionSante(
        texte:
            'Convulsions signalées : une prise en charge médicale urgente est nécessaire.',
        niveau: NiveauSuggestion.urgent,
        emoji: '🚨',
      ));
    }
    if (symptomes.contains('deshydratation')) {
      suggestions.add(const SuggestionSante(
        texte:
            'Signes de déshydratation : faites évaluer votre enfant rapidement par un professionnel de santé.',
        niveau: NiveauSuggestion.urgent,
        emoji: '💧',
      ));
    }
    if (latest.comportement == EtatComportement.lethargique) {
      suggestions.add(const SuggestionSante(
        texte:
            'Enfant très somnolent ou difficile à réveiller : consultez sans attendre.',
        niveau: NiveauSuggestion.urgent,
        emoji: '🚨',
      ));
    }
    if (latest.fievre && ageMois < 3) {
      suggestions.add(const SuggestionSante(
        texte:
            'Fièvre chez un nourrisson de moins de 3 mois : avis médical rapide recommandé.',
        niveau: NiveauSuggestion.urgent,
        emoji: '👶',
      ));
    }
    if (latest.temperature != null && latest.temperature! >= 39.5) {
      suggestions.add(SuggestionSante(
        texte:
            'Température élevée (${latest.temperature!.toStringAsFixed(1)} °C) : surveillez l\'hydratation et demandez un avis médical rapidement.',
        niveau: NiveauSuggestion.urgent,
        emoji: '🌡️',
      ));
    }

    // Fièvre persistante.
    final joursFievre = _joursConsecutifs(
      sorted,
      (e) => e.fievre,
    );
    if (joursFievre >= 3) {
      suggestions.add(SuggestionSante(
        texte:
            'Fièvre depuis $joursFievre jours : pensez à consulter, surtout si elle persiste ou s\'aggrave.',
        niveau: NiveauSuggestion.attention,
        emoji: '🌡️',
      ));
    } else if (latest.fievre &&
        !suggestions.any((s) => s.niveau == NiveauSuggestion.urgent)) {
      suggestions.add(SuggestionSante(
        texte:
            'Fièvre mesurée à ${latest.temperature!.toStringAsFixed(1)} °C : hydratez régulièrement et surveillez l\'évolution.',
        niveau: NiveauSuggestion.attention,
        emoji: '🌡️',
      ));
    } else if (symptomes.contains('fievre') && latest.temperature == null) {
      suggestions.add(const SuggestionSante(
        texte:
            'Fièvre signalée sans température mesurée : prenez la température pour suivre l\'évolution.',
        niveau: NiveauSuggestion.attention,
        emoji: '🌡️',
      ));
    }

    // Toux persistante.
    final joursToux = _joursConsecutifs(
      sorted,
      (e) => e.toux != NiveauToux.aucune || e.symptomes.contains('toux'),
    );
    if (joursToux >= 5) {
      suggestions.add(SuggestionSante(
        texte:
            'Toux depuis $joursToux jours : une consultation est conseillée si elle persiste ou s\'accompagne d\'essoufflement.',
        niveau: NiveauSuggestion.attention,
        emoji: '😷',
      ));
    }

    // Digestif.
    final digestifsRecents = sorted
        .where((e) => !e.date.isBefore(
            DateTime.now().subtract(const Duration(days: 3))))
        .where((e) =>
            e.symptomes.contains('vomissement') ||
            e.symptomes.contains('diarrhee'))
        .length;
    if (digestifsRecents >= 2 || symptomes.contains('vomissement')) {
      suggestions.add(const SuggestionSante(
        texte:
            'Vomissements ou diarrhée : proposez des petites quantités de liquide et surveillez les signes de déshydratation.',
        niveau: NiveauSuggestion.attention,
        emoji: '💧',
      ));
    }

    if (symptomes.contains('eruption') || symptomes.contains('otite')) {
      suggestions.add(const SuggestionSante(
        texte:
            'Éruption cutanée ou douleur d\'oreille : faites examiner votre enfant si cela persiste ou s\'accompagne de fièvre.',
        niveau: NiveauSuggestion.attention,
        emoji: '🔎',
      ));
    }
    if (latest.appetit == NiveauAppetit.faible && latest.fievre) {
      suggestions.add(const SuggestionSante(
        texte:
            'Appétit très diminué avec fièvre : encouragez l\'hydratation et consultez si votre enfant boit peu.',
        niveau: NiveauSuggestion.attention,
        emoji: '🍽️',
      ));
    }
    if (latest.sommeil != QualiteSommeil.bon ||
        latest.comportement == EtatComportement.irritable ||
        latest.comportement == EtatComportement.fatigue) {
      suggestions.add(const SuggestionSante(
        texte:
            'Sommeil ou comportement modifié : gardez un environnement calme et notez l\'évolution dans le journal.',
        niveau: NiveauSuggestion.info,
        emoji: '😴',
      ));
    }

    // Message synthétique + éventuel enrichissement Gemini.
    String message = _messageLocal(sorted, ageMois);
    bool iaDisponible = false;
    if (GeminiService.configuree) {
      final enrichi = await _enrichirAnalyse(enfant, sorted);
      if (enrichi != null) {
        message = enrichi;
        iaDisponible = true;
      }
    }

    return AnalyseSymptomes(
      suggestions: _dedupliquer(suggestions),
      message: message,
      iaDisponible: iaDisponible,
      derniereEntree: latest.date,
    );
  }

  // ── Génération du résumé pré-consultation ─────────────────────────────────
  static Future<ResumeConsultationIA> genererResumeConsultation({
    required EnfantModel enfant,
    required List<JournalSymptomeModel> journal,
    required List<VaccinModel> vaccins,
    required List<RendezVousModel> rendezvous,
    required CroissanceModel? derniereMesure,
    required List<TraitementModel> traitements,
  }) async {
    final sorted = List<JournalSymptomeModel>.from(journal)
      ..sort((a, b) => b.date.compareTo(a.date));
    final analyse = await analyserContexte(enfant: enfant, journal: sorted);

    final maintenant = DateTime.now();
    final debut = sorted.isEmpty
        ? maintenant
        : sorted.last.date.isBefore(maintenant.subtract(const Duration(days: 30)))
            ? maintenant.subtract(const Duration(days: 30))
            : sorted.last.date;
    final recents = sorted
        .where((e) => !e.date.isBefore(debut))
        .toList(growable: false);

    final local = await _resumeLocal(
      enfant: enfant,
      journal: recents,
      tousLesJournaux: sorted,
      vaccins: vaccins,
      rendezvous: rendezvous,
      derniereMesure: derniereMesure,
      traitements: traitements,
      analyse: analyse,
      periodeDebut: debut,
      periodeFin: maintenant,
    );

    String resume = local.resume;
    bool genereeIA = false;
    if (GeminiService.configuree) {
      final enrichi = await _enrichirResume(
        enfant: enfant,
        journal: recents,
        vaccins: vaccins,
        rendezvous: rendezvous,
        derniereMesure: derniereMesure,
        traitements: traitements,
        analyse: analyse,
      );
      if (enrichi != null) {
        resume = enrichi;
        genereeIA = true;
      }
    }

    return ResumeConsultationIA(
      titre: local.titre,
      resume: resume,
      pointsCles: local.pointsCles,
      suggestions: local.suggestions,
      genereeIA: genereeIA,
      periodeDebut: debut,
      periodeFin: maintenant,
      nbEntrees: recents.length,
    );
  }

  // ── Moteur local : résumé structuré ──────────────────────────────────────
  static Future<ResumeConsultationIA> _resumeLocal({
    required EnfantModel enfant,
    required List<JournalSymptomeModel> journal,
    required List<JournalSymptomeModel> tousLesJournaux,
    required List<VaccinModel> vaccins,
    required List<RendezVousModel> rendezvous,
    required CroissanceModel? derniereMesure,
    required List<TraitementModel> traitements,
    required AnalyseSymptomes analyse,
    required DateTime periodeDebut,
    required DateTime periodeFin,
  }) async {
    final points = <String>[];
    final ageMois = _ageMois(enfant.dateNaissance);
    final ageLabel =
        enfant.age > 1 ? '${enfant.age} ans' : '$ageMois mois';

    points.add(
        'Enfant : ${enfant.nomComplet}, $ageLabel, ${enfant.sexe == 'F' ? 'fille' : 'garçon'}');
    if (enfant.allergies != null && enfant.allergies!.trim().isNotEmpty) {
      points.add('Allergies signalées : ${enfant.allergies}');
    }
    if (enfant.groupeSanguin != null && enfant.groupeSanguin!.isNotEmpty) {
      points.add('Groupe sanguin : ${enfant.groupeSanguin}');
    }

    final stats = await JournalSymptomeService.getStatistiques(
      enfant.id,
      entrees: tousLesJournaux,
    );

    if (journal.isEmpty) {
      points.add('Journal des symptômes : aucune entrée sur la période.');
    } else {
      final derniere = journal.first;
      final symptomes = derniere.symptomes.isEmpty
          ? 'aucun symptôme coché'
          : SymptomesCatalogue.libelleListe(derniere.symptomes);
      points.add(
          'Dernière entrée (${_fmtDate(derniere.date)}) : $symptomes'
          '${derniere.temperature != null ? ', température ${derniere.temperature!.toStringAsFixed(1)} °C' : ''}');
      points.add(
          'Fréquence du journal : ${stats.entrees7Jours} entrée(s) sur 7 jours, '
          '${stats.joursRenseignes7Jours}/7 jours renseignés.');
      if (stats.totalJoursFievre > 0) {
        points.add(
            'Fièvre : ${stats.totalJoursFievre} jour(s) avec température ≥ 38 °C.');
      }
      if (stats.symptomePrincipal != null) {
        points.add('Symptôme le plus fréquent (7 j) : ${stats.symptomePrincipal}');
      }
    }

    final vaccinsFaits = vaccins.length;
    final prochains = vaccins
        .where((v) => v.prochaineDate != null && v.prochaineDate!.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.prochaineDate!.compareTo(b.prochaineDate!));
    points.add(
        'Vaccination : $vaccinsFaits vaccin(s) enregistré(s)'
        '${prochains.isNotEmpty ? ', prochaine échéance ${prochains.first.nom} le ${_fmtDate(prochains.first.prochaineDate!)}' : ''}.');

    if (derniereMesure != null) {
      points.add(
          'Croissance : dernière mesure le ${_fmtDate(derniereMesure.date)} — '
          'poids ${derniereMesure.poids} kg, taille ${derniereMesure.taille} cm, IMC ${derniereMesure.imc.toStringAsFixed(1)}.');
    } else {
      points.add('Croissance : aucune mesure enregistrée.');
    }

    if (traitements.isEmpty) {
      points.add('Traitements en cours : aucun.');
    } else {
      points.add(
          'Traitements en cours : ${traitements.map((t) => '${t.nom}${t.posologie.isNotEmpty ? ' (${t.posologie})' : ''}').join(', ')}.');
    }

    final prochainRdv = rendezvous
        .where((r) => r.dateHeure.isAfter(DateTime.now()) && r.statut.name != 'annule')
        .toList()
      ..sort((a, b) => a.dateHeure.compareTo(b.dateHeure));
    if (prochainRdv.isNotEmpty) {
      points.add(
          'Prochain rendez-vous : ${prochainRdv.first.titre} avec Dr. ${prochainRdv.first.medecin} le ${_fmtDate(prochainRdv.first.dateHeure)} à ${_fmtHeure(prochainRdv.first.dateHeure)}.');
    }

    final suggestions = <String>[
      ...analyse.suggestions.map((s) => s.texte),
      'Apporter le carnet de vaccination, les ordonnances et les résultats d\'examens.',
      'Noter l\'évolution de la température et des symptômes jusqu\'à la consultation.',
      'Signaler immédiatement toute difficulté respiratoire, convulsion ou somnolence inhabituelle.',
    ];

    final resume = journal.isEmpty
        ? 'Résumé pré-consultation pour ${enfant.nomComplet} ($ageLabel). '
            'Aucune entrée récente dans le journal des symptômes. '
            'Les informations de vaccination, de croissance et de traitement sont disponibles dans PediCare AI.'
        : 'Résumé pré-consultation pour ${enfant.nomComplet} ($ageLabel). '
            '${journal.length} entrée(s) analysée(s) du ${_fmtDate(periodeDebut)} au ${_fmtDate(periodeFin)}. '
            'Dernière entrée le ${_fmtDate(journal.first.date)} : ${journal.first.resumeCourt}. '
            '${stats.totalJoursFievre > 0 ? 'Fièvre rapportée sur ${stats.totalJoursFievre} jour(s). ' : ''}'
            '${analyse.message}';

    return ResumeConsultationIA(
      titre: 'Résumé pré-consultation — ${_fmtDate(periodeFin)}',
      resume: resume,
      pointsCles: points,
      suggestions: suggestions,
      genereeIA: false,
      periodeDebut: periodeDebut,
      periodeFin: periodeFin,
      nbEntrees: journal.length,
    );
  }

  // ── Gemini (optionnel) ────────────────────────────────────────────────────
  static Future<String?> _enrichirAnalyse(
    EnfantModel enfant,
    List<JournalSymptomeModel> journal,
  ) async {
    final contexte = journal.take(10).map((e) => e.toMap()).toList();
    final prompt = '''
Tu es un assistant de santé infantile de l'application PediCare.
Analyse ces entrées du journal de ${enfant.nomComplet} (${enfant.age} ans) :
$contexte

Rédige 2 à 3 phrases en français, bienveillantes et NON diagnostiques.
Signale les signes qui justifieraient une consultation, sans nommer de maladie.
Termine par : "Ces conseils ne remplacent pas un avis médical."
''';
    return GeminiService.generer(
      prompt: prompt,
      temperature: 0.4,
      maxOutputTokens: 512,
    );
  }

  static Future<String?> _enrichirResume({
    required EnfantModel enfant,
    required List<JournalSymptomeModel> journal,
    required List<VaccinModel> vaccins,
    required List<RendezVousModel> rendezvous,
    required CroissanceModel? derniereMesure,
    required List<TraitementModel> traitements,
    required AnalyseSymptomes analyse,
  }) async {
    final journalStr = journal.take(15).map((e) =>
        '${_fmtDate(e.date)}: temp=${e.temperature ?? '-'}°C, symptômes=${e.symptomes.join('/')}, toux=${e.toux.name}, sommeil=${e.sommeil.name}, appétit=${e.appetit.name}, notes=${e.notes}').join(' | ');
    final prompt = '''
Rédige un résumé pré-consultation clair pour le pédiatre, en français, à partir de :
- Enfant : ${enfant.nomComplet}, ${enfant.age} ans
- Journal : ${journalStr.isEmpty ? 'aucune entrée' : journalStr}
- Vaccins enregistrés : ${vaccins.length}
- Dernière mesure : ${derniereMesure == null ? 'aucune' : '${derniereMesure.poids} kg, ${derniereMesure.taille} cm'}
- Traitements : ${traitements.map((t) => t.nom).join(', ')}
- Rendez-vous : ${rendezvous.length}
- Alertes : ${analyse.suggestions.map((s) => s.texte).join(' ')}

Contraintes : 5 à 7 phrases, ton professionnel, aucune conclusion diagnostique, texte pur sans markdown.
''';
    return GeminiService.generer(
      prompt: prompt,
      temperature: 0.5,
      maxOutputTokens: 1024,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static String _messageLocal(List<JournalSymptomeModel> sorted, int ageMois) {
    final latest = sorted.first;
    final base = latest.fievre
        ? 'Fièvre mesurée à ${latest.temperature!.toStringAsFixed(1)} °C lors de la dernière entrée.'
        : 'Dernière entrée : ${latest.resumeCourt}.';

    final joursFievre = _joursConsecutifs(sorted, (e) => e.fievre);
    if (joursFievre >= 3) {
      return '$base Fièvre depuis $joursFievre jours : pensez à consulter si elle persiste ou s\'aggrave. '
          'Ces conseils ne remplacent pas un avis médical.';
    }
    if (ageMois < 3 && latest.fievre) {
      return '$base Chez un nourrisson de moins de 3 mois, une fièvre nécessite un avis médical rapide. '
          'Ces conseils ne remplacent pas un avis médical.';
    }
    return '$base Continuez à renseigner le journal et surveillez l\'évolution. '
        'Ces conseils ne remplacent pas un avis médical.';
  }

  static int _joursConsecutifs(
    List<JournalSymptomeModel> sortedDesc,
    bool Function(JournalSymptomeModel) predicate,
  ) {
    if (sortedDesc.isEmpty) return 0;
    final jours = sortedDesc
        .where(predicate)
        .map((e) => _dateKey(e.date))
        .toSet();
    if (jours.isEmpty) return 0;

    var curseur = DateTime(
        sortedDesc.first.date.year,
        sortedDesc.first.date.month,
        sortedDesc.first.date.day);
    // Si la dernière entrée ne remplit pas le critère, la série est rompue.
    if (!jours.contains(_dateKey(curseur))) return 0;

    int count = 0;
    while (jours.contains(_dateKey(curseur))) {
      count++;
      curseur = curseur.subtract(const Duration(days: 1));
    }
    return count;
  }

  static List<SuggestionSante> _dedupliquer(List<SuggestionSante> input) {
    final seen = <String>{};
    final result = <SuggestionSante>[];
    for (final s in input) {
      if (seen.add(s.texte)) result.add(s);
    }
    return result;
  }

  static int _ageMois(DateTime naissance) {
    final now = DateTime.now();
    return (now.year - naissance.year) * 12 + (now.month - naissance.month);
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _fmtHeure(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';
}
