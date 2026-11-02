import 'dart:math' as math;
import '../models/croissance_model.dart';

/// Tables OMS LMS pour poids (kg) et taille (cm) selon âge en mois et sexe.
/// Source : WHO Child Growth Standards (0-60 mois)
class PercentileService {
  // ── Tables poids garçon ────────────────────────────────────────────────────
  static const _poidsG = <int, _LMS>{
    0:  _LMS(L: 0.3487, M: 3.3464, S: 0.14602),
    1:  _LMS(L: 0.2297, M: 4.4709, S: 0.13395),
    2:  _LMS(L: 0.1970, M: 5.5675, S: 0.12385),
    3:  _LMS(L: 0.1738, M: 6.3762, S: 0.11727),
    4:  _LMS(L: 0.1553, M: 7.0023, S: 0.11316),
    6:  _LMS(L: 0.1250, M: 7.9340, S: 0.10958),
    9:  _LMS(L: 0.0875, M: 9.1828, S: 0.10737),
    12: _LMS(L: 0.0580, M: 10.154, S: 0.10851),
    18: _LMS(L: 0.0180, M: 11.494, S: 0.11278),
    24: _LMS(L: -0.016, M: 12.657, S: 0.11385),
    36: _LMS(L: -0.063, M: 14.619, S: 0.11659),
    48: _LMS(L: -0.100, M: 16.410, S: 0.12050),
    60: _LMS(L: -0.130, M: 18.261, S: 0.12420),
  };

  // ── Tables poids fille ─────────────────────────────────────────────────────
  static const _poidsF = <int, _LMS>{
    0:  _LMS(L: 0.3809, M: 3.2322, S: 0.14171),
    1:  _LMS(L: 0.1714, M: 4.1873, S: 0.13724),
    2:  _LMS(L: 0.1070, M: 5.1282, S: 0.13000),
    3:  _LMS(L: 0.0756, M: 5.8458, S: 0.12619),
    4:  _LMS(L: 0.0596, M: 6.4237, S: 0.12402),
    6:  _LMS(L: 0.0481, M: 7.2972, S: 0.12202),
    9:  _LMS(L: 0.0318, M: 8.4806, S: 0.12272),
    12: _LMS(L: 0.0131, M: 9.4498, S: 0.12579),
    18: _LMS(L: -0.018, M: 10.815, S: 0.13048),
    24: _LMS(L: -0.039, M: 11.992, S: 0.13261),
    36: _LMS(L: -0.081, M: 14.081, S: 0.13700),
    48: _LMS(L: -0.113, M: 15.963, S: 0.14176),
    60: _LMS(L: -0.139, M: 17.962, S: 0.14626),
  };

  // ── Tables taille garçon ───────────────────────────────────────────────────
  static const _tailleG = <int, _LMS>{
    0:  _LMS(L: 1.0, M: 49.884, S: 0.03795),
    1:  _LMS(L: 1.0, M: 54.724, S: 0.03557),
    2:  _LMS(L: 1.0, M: 58.425, S: 0.03424),
    3:  _LMS(L: 1.0, M: 61.429, S: 0.03328),
    4:  _LMS(L: 1.0, M: 63.886, S: 0.03260),
    6:  _LMS(L: 1.0, M: 67.624, S: 0.03144),
    9:  _LMS(L: 1.0, M: 72.004, S: 0.03022),
    12: _LMS(L: 1.0, M: 75.749, S: 0.02957),
    18: _LMS(L: 1.0, M: 82.316, S: 0.02923),
    24: _LMS(L: 1.0, M: 87.816, S: 0.03017),
    36: _LMS(L: 1.0, M: 96.107, S: 0.03168),
    48: _LMS(L: 1.0, M: 103.31, S: 0.03222),
    60: _LMS(L: 1.0, M: 110.05, S: 0.03228),
  };

  // ── Tables taille fille ────────────────────────────────────────────────────
  static const _tailleF = <int, _LMS>{
    0:  _LMS(L: 1.0, M: 49.148, S: 0.03790),
    1:  _LMS(L: 1.0, M: 53.687, S: 0.03560),
    2:  _LMS(L: 1.0, M: 57.067, S: 0.03438),
    3:  _LMS(L: 1.0, M: 59.803, S: 0.03360),
    4:  _LMS(L: 1.0, M: 62.090, S: 0.03298),
    6:  _LMS(L: 1.0, M: 65.731, S: 0.03176),
    9:  _LMS(L: 1.0, M: 70.144, S: 0.03058),
    12: _LMS(L: 1.0, M: 73.787, S: 0.03013),
    18: _LMS(L: 1.0, M: 80.256, S: 0.02980),
    24: _LMS(L: 1.0, M: 85.715, S: 0.03029),
    36: _LMS(L: 1.0, M: 94.386, S: 0.03107),
    48: _LMS(L: 1.0, M: 101.83, S: 0.03150),
    60: _LMS(L: 1.0, M: 108.96, S: 0.03144),
  };

  /// Percentile (0-100) d'une valeur selon OMS
  static double calculerPercentile({
    required double valeur,
    required int ageMois,
    required String sexe,
    required bool estPoids,
  }) {
    final table = estPoids
        ? (sexe == 'M' ? _poidsG : _poidsF)
        : (sexe == 'M' ? _tailleG : _tailleF);
    final lms = _interpoler(table, ageMois.clamp(0, 60));
    if (lms == null) return 50.0;
    final z = _zScore(valeur, lms).clamp(-4.0, 4.0);
    return _phi(z) * 100;
  }

  /// Valeurs de référence P3/P15/P50/P85/P97 pour un âge donné
  static Map<String, double> getReferences({
    required int ageMois,
    required String sexe,
    required bool estPoids,
  }) {
    final table = estPoids
        ? (sexe == 'M' ? _poidsG : _poidsF)
        : (sexe == 'M' ? _tailleG : _tailleF);
    final lms = _interpoler(table, ageMois.clamp(0, 60));
    if (lms == null) return {};
    return {
      'P3':  _lmsToVal(lms, -1.881),
      'P15': _lmsToVal(lms, -1.036),
      'P50': _lmsToVal(lms, 0.0),
      'P85': _lmsToVal(lms, 1.036),
      'P97': _lmsToVal(lms, 1.881),
    };
  }

  /// Détecte les anomalies dans une série de mesures
  static List<AlerteCroissance> detecterAnomalies({
    required List<CroissanceModel> mesures,
    required String sexe,
  }) {
    if (mesures.length < 2) return [];
    final alertes = <AlerteCroissance>[];
    final sorted = List<CroissanceModel>.from(mesures)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (int i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1];
      final curr = sorted[i];
      final jours = curr.date.difference(prev.date).inDays;
      if (jours == 0) continue;

      final diffPoids = curr.poids - prev.poids;
      final diffParMois = diffPoids / (jours / 30.0);

      // Perte de poids
      if (diffPoids < -0.2 && jours >= 7) {
        alertes.add(AlerteCroissance(
          type: TypeAlerte.pertePoids,
          date: curr.date,
          message: 'Perte de poids : ${diffPoids.abs().toStringAsFixed(1)} kg en $jours jours',
          gravite: diffPoids < -0.5 ? GraviteAlerte.elevee : GraviteAlerte.moderee,
        ));
      }

      // Gain excessif
      if (diffParMois > 2.0) {
        alertes.add(AlerteCroissance(
          type: TypeAlerte.gainExcessif,
          date: curr.date,
          message: 'Gain de poids rapide : +${diffPoids.toStringAsFixed(1)} kg en $jours jours',
          gravite: GraviteAlerte.moderee,
        ));
      }

      // Percentile poids
      final ageMois = _ageMois(sorted[0].date, curr.date);
      final pctPoids = calculerPercentile(
          valeur: curr.poids, ageMois: ageMois, sexe: sexe, estPoids: true);
      if (pctPoids < 3) {
        alertes.add(AlerteCroissance(
          type: TypeAlerte.poidsFaible,
          date: curr.date,
          message: 'Poids sous le 3ème percentile (P${pctPoids.round()}) — consulter le pédiatre',
          gravite: GraviteAlerte.elevee,
        ));
      } else if (pctPoids > 97) {
        alertes.add(AlerteCroissance(
          type: TypeAlerte.poidsEleve,
          date: curr.date,
          message: 'Poids au-dessus du 97ème percentile (P${pctPoids.round()})',
          gravite: GraviteAlerte.moderee,
        ));
      }

      // Percentile taille
      final pctTaille = calculerPercentile(
          valeur: curr.taille, ageMois: ageMois, sexe: sexe, estPoids: false);
      if (pctTaille < 3) {
        alertes.add(AlerteCroissance(
          type: TypeAlerte.tailleFaible,
          date: curr.date,
          message: 'Taille sous le 3ème percentile (P${pctTaille.round()}) — consulter le pédiatre',
          gravite: GraviteAlerte.elevee,
        ));
      }
    }

    // Dédupliquer
    final vus = <String>{};
    return alertes.where((a) {
      final key = '${a.type}_${a.date.toIso8601String().split('T')[0]}';
      return vus.add(key);
    }).toList();
  }

  // ── Helpers privés ─────────────────────────────────────────────────────────
  static _LMS? _interpoler(Map<int, _LMS> table, int age) {
    if (table.containsKey(age)) return table[age];
    final keys = table.keys.toList()..sort();
    int? lo, hi;
    for (final k in keys) {
      if (k <= age) lo = k;
      if (k >= age && hi == null) hi = k;
    }
    if (lo == null) return table[keys.first];
    if (hi == null) return table[keys.last];
    if (lo == hi) return table[lo];
    final t = (age - lo) / (hi - lo);
    final a = table[lo]!, b = table[hi]!;
    return _LMS(L: a.L + t*(b.L-a.L), M: a.M + t*(b.M-a.M), S: a.S + t*(b.S-a.S));
  }

  static double _zScore(double val, _LMS lms) {
    if (lms.L.abs() < 1e-6) return (val / lms.M - 1) / lms.S;
    return (math.pow(val / lms.M, lms.L) - 1) / (lms.L * lms.S);
  }

  static double _lmsToVal(_LMS lms, double z) {
    if (lms.L.abs() < 1e-6) return lms.M * (1 + lms.S * z);
    return lms.M * math.pow(1 + lms.L * lms.S * z, 1 / lms.L).toDouble();
  }

  // Approximation de la CDF normale (Abramowitz & Stegun)
  static double _phi(double z) {
    final t = 1.0 / (1.0 + 0.2316419 * z.abs());
    const b = [0.319381530, -0.356563782, 1.781477937, -1.821255978, 1.330274429];
    final poly = ((((b[4]*t + b[3])*t + b[2])*t + b[1])*t + b[0]) * t;
    final n = (1.0 / math.sqrt(2 * math.pi)) * math.exp(-0.5 * z * z) * poly;
    return z >= 0 ? 1.0 - n : n;
  }

  static int _ageMois(DateTime naissance, DateTime mesure) {
    return (mesure.year - naissance.year) * 12 + (mesure.month - naissance.month);
  }
}

// ── Types ──────────────────────────────────────────────────────────────────────
class _LMS {
  final double L, M, S;
  const _LMS({required this.L, required this.M, required this.S});
}

enum TypeAlerte { pertePoids, gainExcessif, poidsFaible, poidsEleve, tailleFaible }
enum GraviteAlerte { moderee, elevee }

class AlerteCroissance {
  final TypeAlerte type;
  final DateTime date;
  final String message;
  final GraviteAlerte gravite;
  const AlerteCroissance({
    required this.type, required this.date,
    required this.message, required this.gravite,
  });
}
