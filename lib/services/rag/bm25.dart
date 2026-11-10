import 'dart:math' as math;
import '../nutrition_service.dart';

/// Tokenisation française simple pour la recherche : minuscules, sans
/// accents, sans mots vides, avec une racinisation légère et des synonymes
/// du langage courant des parents.
class TokeniseurFr {
  TokeniseurFr._();

  static const Set<String> motsVides = {
    'a', 'au', 'aux', 'avec', 'ce', 'ces', 'cet', 'cette', 'comment', 'dans',
    'de', 'des', 'du', 'elle', 'en', 'est', 'et', 'il', 'ils', 'je', 'la', 'le',
    'les', 'leur', 'lui', 'ma', 'mais', 'me', 'mes', 'mon', 'ne', 'nous', 'on',
    'ou', 'par', 'pas', 'pour', 'qu', 'que', 'quel', 'quelle', 'quoi', 'qui',
    'sa', 'se', 'ses', 'son', 'sur', 'ta', 'te', 'tes', 'ton', 'tu', 'un', 'une',
    'vos', 'votre', 'vous', 'y', 'l', 'd', 'j', 'c', 's', 'n', 'm', 't', 'faire',
    'fait', 'peut', 'puis', 'dois', 'doit', 'faut', 'ai', 'as', 'avoir', 'etre',
    'sont', 'suis', 'tres', 'plus', 'bien', 'mal', 'enfant', 'enfants', 'bebe',
    'bebes', 'fils', 'fille', 'depuis', 'quand', 'si', 'cela', 'ca', 'aussi',
  };

  /// Synonymes : forme courante → forme utilisée dans les fiches.
  static const Map<String, List<String>> synonymes = {
    'vomi': ['vomissement'],
    'vomit': ['vomissement'],
    'vomir': ['vomissement'],
    'gerbe': ['vomissement'],
    'dodo': ['sommeil'],
    'dort': ['sommeil'],
    'dormir': ['sommeil'],
    'chaud': ['fievre'],
    'brulant': ['fievre'],
    'temperature': ['fievre'],
    'caca': ['selle'],
    'popo': ['selle'],
    'mange': ['alimentation', 'repas'],
    'manger': ['alimentation', 'repas'],
    'nourrir': ['alimentation'],
    'tousse': ['toux'],
    'tousser': ['toux'],
    'pleure': ['pleur'],
    'pleurer': ['pleur'],
    'respire': ['respiration', 'respirer'],
    'souffle': ['respiration'],
    'nez': ['rhume'],
    'morve': ['rhume'],
    'gorge': ['angine'],
    'oreille': ['otite'],
    'piqure': ['vaccin'],
    'medoc': ['medicament'],
    'sirop': ['medicament'],
    'tele': ['ecran'],
    'tablette': ['ecran'],
    'telephone': ['ecran'],
    'cogne': ['choc', 'tete'],
    'tombe': ['chute'],
    'avale': ['ingestion', 'etouffement'],
    'boutons': ['eruption', 'varicelle'],
    'plaque': ['urticaire'],
    'dent': ['dentaire'],
  };

  /// Racinisation légère : retire les terminaisons plurielles et quelques
  /// suffixes fréquents pour rapprocher « vomissements » et « vomissement ».
  static String raciner(String mot) {
    var m = mot;
    if (m.length > 4 && (m.endsWith('s') || m.endsWith('x'))) {
      m = m.substring(0, m.length - 1);
    }
    for (final suffixe in const ['ement', 'ation', 'euse', 'eux', 'ique', 'ite']) {
      if (m.length > suffixe.length + 3 && m.endsWith(suffixe)) {
        return m.substring(0, m.length - suffixe.length);
      }
    }
    if (m.length > 5 && m.endsWith('e')) m = m.substring(0, m.length - 1);
    return m;
  }

  /// Termes indexés pour un texte.
  static List<String> tokens(String texte, {bool avecSynonymes = false}) {
    final res = <String>[];
    for (final mot in NutritionService.normaliser(texte).split(' ')) {
      if (mot.isEmpty || motsVides.contains(mot)) continue;
      // Les nombres utiles (38, 39, 190, 15) sont gardés tels quels.
      res.add(raciner(mot));
      if (avecSynonymes) {
        for (final s in synonymes[mot] ?? const <String>[]) {
          res.add(raciner(s));
        }
      }
    }
    return res;
  }
}

/// Index BM25 (Okapi) en mémoire.
class Bm25Index {
  final double k1;
  final double b;
  final List<Map<String, int>> _frequences = [];
  final List<int> _longueurs = [];
  final Map<String, int> _documentsParTerme = {};
  double _longueurMoyenne = 0;

  Bm25Index({this.k1 = 1.2, this.b = 0.75});

  int get taille => _longueurs.length;

  /// Ajoute un document (déjà tokenisé) ; renvoie son indice.
  int ajouter(List<String> termes) {
    final freq = <String, int>{};
    for (final t in termes) {
      freq[t] = (freq[t] ?? 0) + 1;
    }
    for (final t in freq.keys) {
      _documentsParTerme[t] = (_documentsParTerme[t] ?? 0) + 1;
    }
    _frequences.add(freq);
    _longueurs.add(termes.length);
    _longueurMoyenne =
        _longueurs.fold<int>(0, (s, l) => s + l) / _longueurs.length;
    return _longueurs.length - 1;
  }

  double _idf(String terme) {
    final n = _documentsParTerme[terme] ?? 0;
    return math.log(1 + (taille - n + 0.5) / (n + 0.5));
  }

  /// Score BM25 de chaque document pour la requête (tokenisée).
  List<double> scores(List<String> requete) {
    final res = List<double>.filled(taille, 0);
    final termes = requete.toSet();
    for (final t in termes) {
      if (!_documentsParTerme.containsKey(t)) continue;
      final idf = _idf(t);
      for (var i = 0; i < taille; i++) {
        final f = _frequences[i][t];
        if (f == null) continue;
        final norme = k1 * (1 - b + b * _longueurs[i] / _longueurMoyenne);
        res[i] += idf * (f * (k1 + 1)) / (f + norme);
      }
    }
    return res;
  }
}
