import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../data/symptomes_catalogue.dart';
import '../models/analyse_symptomes_model.dart';
import '../models/consultation_model.dart';
import '../models/enfant_model.dart';
import '../models/journal_symptome_model.dart';
import '../services/journal_symptome_service.dart';

class JournalPdfService {
  static final PdfColor _bleu = PdfColor.fromHex('1E6FDB');
  static final PdfColor _bleuClair = PdfColor.fromHex('4DAAFF');
  static final PdfColor _vert = PdfColor.fromHex('00C9A7');
  static final PdfColor _orange = PdfColor.fromHex('E67E22');
  static final PdfColor _rouge = PdfColor.fromHex('FF6B6B');
  static final PdfColor _fond = PdfColor.fromHex('F0F4FF');
  static final PdfColor _gris = PdfColor.fromHex('777777');

  // ── Partage du rapport de symptômes ───────────────────────────────────────
  static Future<void> partagerRapport({
    required EnfantModel enfant,
    required List<JournalSymptomeModel> journal,
    required JournalStats stats,
    required AnalyseSymptomes analyse,
    ConsultationModel? consultation,
  }) async {
    final bytes = await _buildRapportPdf(
      enfant: enfant,
      journal: journal,
      stats: stats,
      analyse: analyse,
      consultation: consultation,
    );
    final dir = await getTemporaryDirectory();
    final nom = enfant.nomComplet.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final file = File('${dir.path}/journal_symptomes_$nom.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Journal des symptômes — ${enfant.nomComplet}',
      text:
          'Veuillez trouver ci-joint le journal des symptômes de ${enfant.nomComplet}, '
          'à consulter avant le rendez-vous.',
    );
  }

  static Future<void> apercuRapport({
    required EnfantModel enfant,
    required List<JournalSymptomeModel> journal,
    required JournalStats stats,
    required AnalyseSymptomes analyse,
    ConsultationModel? consultation,
  }) async {
    final bytes = await _buildRapportPdf(
      enfant: enfant,
      journal: journal,
      stats: stats,
      analyse: analyse,
      consultation: consultation,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'Journal des symptômes — ${enfant.nomComplet}',
    );
  }

  // ── Partage d'un résumé pré-consultation ──────────────────────────────────
  static Future<void> partagerResume({
    required EnfantModel enfant,
    required ConsultationModel consultation,
  }) async {
    final bytes = await _buildResumePdf(enfant: enfant, consultation: consultation);
    final dir = await getTemporaryDirectory();
    final nom = enfant.nomComplet.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final file = File('${dir.path}/resume_consultation_$nom.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Résumé pré-consultation — ${enfant.nomComplet}',
      text:
          'Résumé pré-consultation de ${enfant.nomComplet} généré avec PediCare AI.',
    );
  }

  // ── Construction du rapport complet ───────────────────────────────────────
  static Future<Uint8List> _buildRapportPdf({
    required EnfantModel enfant,
    required List<JournalSymptomeModel> journal,
    required JournalStats stats,
    required AnalyseSymptomes analyse,
    ConsultationModel? consultation,
  }) async {
    final pdf = pw.Document();
    final sorted = List<JournalSymptomeModel>.from(journal)
      ..sort((a, b) => b.date.compareTo(a.date));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (ctx) => _entete(enfant, 'Rapport de symptômes'),
        footer: (ctx) => _piedDePage(ctx),
        build: (ctx) => [
          pw.SizedBox(height: 16),
          _carteEnfant(enfant),
          pw.SizedBox(height: 14),
          _cartesStats(stats),
          pw.SizedBox(height: 18),
          _titreSection('Analyse contextuelle (non diagnostique)'),
          pw.SizedBox(height: 8),
          _encadreAnalyse(analyse),
          pw.SizedBox(height: 18),
          _titreSection('Fréquence des symptômes'),
          pw.SizedBox(height: 8),
          _tableFrequence(sorted),
          pw.SizedBox(height: 18),
          _titreSection('Évolution de la température'),
          pw.SizedBox(height: 8),
          _grapheTemperature(sorted),
          pw.SizedBox(height: 18),
          _titreSection('Historique chronologique'),
          pw.SizedBox(height: 8),
          _tableJournal(sorted),
          if (consultation != null) ...[
            pw.SizedBox(height: 18),
            _titreSection('Dernier résumé pré-consultation'),
            pw.SizedBox(height: 8),
            _encadreResume(consultation),
          ],
          pw.SizedBox(height: 18),
          _noteLegale(),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> _buildResumePdf({
    required EnfantModel enfant,
    required ConsultationModel consultation,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (ctx) => _entete(enfant, 'Résumé pré-consultation'),
        footer: (ctx) => _piedDePage(ctx),
        build: (ctx) => [
          pw.SizedBox(height: 16),
          _carteEnfant(enfant),
          pw.SizedBox(height: 14),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: _fond,
              border: pw.Border.all(color: _bleuClair),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(consultation.titre,
                    style: pw.TextStyle(
                        color: _bleu,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Text(
                    'Période : ${_fmtDate(consultation.periodeDebut)} — ${_fmtDate(consultation.periodeFin)}'
                    ' · ${consultation.nbEntrees} entrée(s) du journal',
                    style: pw.TextStyle(fontSize: 9, color: _gris)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          _titreSection('Résumé général'),
          pw.SizedBox(height: 8),
          pw.Text(consultation.resume,
              style: const pw.TextStyle(fontSize: 10, lineSpacing: 3)),
          pw.SizedBox(height: 16),
          if (consultation.pointsClesListe.isNotEmpty) ...[
            _titreSection('Points clés'),
            pw.SizedBox(height: 8),
            _listePuce(consultation.pointsClesListe, _bleu),
            pw.SizedBox(height: 16),
          ],
          if (consultation.suggestionsListe.isNotEmpty) ...[
            _titreSection('Suggestions de suivi'),
            pw.SizedBox(height: 8),
            _encadreListe(consultation.suggestionsListe),
          ],
          pw.SizedBox(height: 20),
          _noteLegale(),
        ],
      ),
    );
    return pdf.save();
  }

  // ── Blocs PDF ─────────────────────────────────────────────────────────────
  static pw.Widget _entete(EnfantModel enfant, String titre) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _bleu,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('PediCare AI',
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 17,
                      fontWeight: pw.FontWeight.bold)),
              pw.Text(titre,
                  style: pw.TextStyle(color: PdfColors.grey300, fontSize: 10)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(enfant.nomComplet,
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold)),
              pw.Text('${enfant.age} ans · ${enfant.sexe == 'F' ? 'Fille' : 'Garçon'}',
                  style: pw.TextStyle(color: PdfColors.grey300, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _piedDePage(pw.Context ctx) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Généré par PediCare AI le ${_fmtDate(DateTime.now())}',
            style: pw.TextStyle(color: _gris, fontSize: 8)),
        pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}',
            style: pw.TextStyle(color: _gris, fontSize: 8)),
      ],
    );
  }

  static pw.Widget _carteEnfant(EnfantModel enfant) {
    final infos = <String>[
      'Né(e) le ${_fmtDate(enfant.dateNaissance)}',
      if (enfant.groupeSanguin != null && enfant.groupeSanguin!.isNotEmpty)
        'Groupe sanguin : ${enfant.groupeSanguin}',
      if (enfant.allergies != null && enfant.allergies!.isNotEmpty)
        'Allergies : ${enfant.allergies}',
    ];
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _fond,
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Informations de l\'enfant',
              style: pw.TextStyle(
                  color: _bleu, fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(infos.join(' · '),
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  static pw.Widget _cartesStats(JournalStats stats) {
    return pw.Row(
      children: [
        _carteStat('Entrées (7 j)', '${stats.entrees7Jours}', _bleu),
        pw.SizedBox(width: 8),
        _carteStat('Jours renseignés', '${stats.joursRenseignes7Jours}/7', _vert),
        pw.SizedBox(width: 8),
        _carteStat('Temp. moyenne', stats.temperatureMoyenneLabel, _orange),
        pw.SizedBox(width: 8),
        _carteStat('Jours de fièvre', '${stats.totalJoursFievre}', _rouge),
      ],
    );
  }

  static pw.Widget _carteStat(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromInt(color.toInt() & 0xFFFFFF | 0x20000000),
          border: pw.Border.all(color: color),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(value,
                style: pw.TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold)),
            pw.Text(label,
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _titreSection(String titre) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 9),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(_bleu.toInt() & 0xFFFFFF | 0x15000000),
        border: pw.Border(left: pw.BorderSide(color: _bleu, width: 3)),
      ),
      child: pw.Text(titre,
          style: pw.TextStyle(
              color: _bleu, fontSize: 11, fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _encadreAnalyse(AnalyseSymptomes analyse) {
    final couleur = analyse.aUrgence
        ? _rouge
        : analyse.aAttention
            ? _orange
            : _vert;
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(couleur.toInt() & 0xFFFFFF | 0x18000000),
        border: pw.Border.all(color: couleur),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(analyse.message,
              style: const pw.TextStyle(fontSize: 9, lineSpacing: 2)),
          if (analyse.suggestions.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            ...analyse.suggestions.map((s) => pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text('• ${s.texte}',
                      style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                )),
          ],
          pw.SizedBox(height: 4),
          pw.Text('Source : ${analyse.iaDisponible ? 'Gemini' : 'analyse locale PediCare'}',
              style: pw.TextStyle(fontSize: 8, color: _gris)),
        ],
      ),
    );
  }

  static pw.Widget _tableFrequence(List<JournalSymptomeModel> journal) {
    final frequence = <String, int>{};
    for (final e in journal) {
      for (final id in e.symptomes) {
        frequence[id] = (frequence[id] ?? 0) + 1;
      }
    }
    if (frequence.isEmpty) {
      return pw.Text('Aucun symptôme coché dans le journal.',
          style: pw.TextStyle(fontSize: 9, color: _gris));
    }
    final entries = frequence.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return pw.Wrap(
      spacing: 8,
      runSpacing: 6,
      children: entries
          .map((e) => pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: _fond,
                  border: pw.Border.all(color: _bleuClair),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Text(
                    '${SymptomesCatalogue.labelDe(e.key)} : ${e.value}',
                    style: pw.TextStyle(fontSize: 8, color: _bleu)),
              ))
          .toList(),
    );
  }

  static pw.Widget _grapheTemperature(List<JournalSymptomeModel> journal) {
    final points = journal
        .where((e) => e.temperature != null)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (points.isEmpty) {
      return pw.Text('Aucune température mesurée dans le journal.',
          style: pw.TextStyle(fontSize: 9, color: _gris));
    }
    const chartHeight = 90.0;
    return pw.Container(
      height: chartHeight + 34,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: points.asMap().entries.map((entry) {
          final p = entry.value;
          final temp = p.temperature!;
          final ratio = ((temp - 35) / 6).clamp(0.05, 1.0).toDouble();
          final barColor = temp >= 39
              ? _rouge
              : temp >= 38
                  ? _orange
                  : _vert;
          return pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text('${temp.toStringAsFixed(1)}°',
                  style: pw.TextStyle(fontSize: 7, color: barColor)),
              pw.SizedBox(height: 2),
              pw.Container(
                width: 16,
                height: chartHeight * ratio,
                decoration: pw.BoxDecoration(
                  color: barColor,
                  borderRadius: const pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(2),
                    topRight: pw.Radius.circular(2),
                  ),
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(_fmtShort(p.date),
                  style: pw.TextStyle(fontSize: 7, color: _gris)),
            ],
          );
        }).toList(),
      ),
    );
  }

  static pw.Widget _tableJournal(List<JournalSymptomeModel> journal) {
    if (journal.isEmpty) {
      return pw.Text('Aucune entrée dans le journal des symptômes.',
          style: pw.TextStyle(fontSize: 9, color: _gris));
    }
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(3),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(2.2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _bleu),
          children: ['Date', 'Temp.', 'Symptômes', 'Sommeil / appétit', 'Notes']
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(h,
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold)),
                  ))
              .toList(),
        ),
        ...journal.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
                color: i.isEven ? _fond : PdfColors.white),
            children: [
              _cellule('${_fmtDate(e.date)}\n${_fmtHeure(e.date)}'),
              _cellule(e.temperature == null
                  ? '—'
                  : '${e.temperature!.toStringAsFixed(1)}°'),
              _cellule(SymptomesCatalogue.libelleListe(e.symptomes)),
              _cellule(
                  '${_labelSommeil(e.sommeil)}\n${_labelAppetit(e.appetit)}'),
              _cellule(e.notes.isEmpty ? '—' : e.notes),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _cellule(String texte) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(texte, style: const pw.TextStyle(fontSize: 7.5)),
    );
  }

  static pw.Widget _encadreResume(ConsultationModel consultation) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _fond,
        border: pw.Border.all(color: _bleuClair),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(consultation.titre,
              style: pw.TextStyle(
                  color: _bleu,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(consultation.resume,
              style: const pw.TextStyle(fontSize: 9, lineSpacing: 2)),
        ],
      ),
    );
  }

  static pw.Widget _listePuce(List<String> items, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items
          .map((item) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      margin: const pw.EdgeInsets.only(top: 3, right: 5),
                      width: 4,
                      height: 4,
                      decoration: pw.BoxDecoration(
                          color: color,
                          borderRadius: pw.BorderRadius.circular(2)),
                    ),
                    pw.Expanded(
                      child: pw.Text(item,
                          style: const pw.TextStyle(fontSize: 9, lineSpacing: 2)),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  static pw.Widget _encadreListe(List<String> items) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(_orange.toInt() & 0xFFFFFF | 0x12000000),
        border: pw.Border.all(color: _orange),
      ),
      child: _listePuce(items, _orange),
    );
  }

  static pw.Widget _noteLegale() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(9),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Text(
        'Ce document est généré automatiquement par PediCare AI à titre informatif. '
        'Il ne remplace pas un avis médical et ne constitue pas un diagnostic. '
        'Consultez votre pédiatre pour toute interprétation.',
        style: pw.TextStyle(fontSize: 8, color: _gris),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  static String _fmtShort(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  static String _fmtHeure(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';

  static String _labelSommeil(QualiteSommeil s) {
    switch (s) {
      case QualiteSommeil.bon:
        return 'Sommeil bon';
      case QualiteSommeil.moyen:
        return 'Sommeil moyen';
      case QualiteSommeil.agite:
        return 'Sommeil agité';
      case QualiteSommeil.mauvais:
        return 'Sommeil mauvais';
    }
  }

  static String _labelAppetit(NiveauAppetit a) {
    switch (a) {
      case NiveauAppetit.normal:
        return 'Appétit normal';
      case NiveauAppetit.diminue:
        return 'Appétit diminué';
      case NiveauAppetit.faible:
        return 'Appétit faible';
      case NiveauAppetit.excessif:
        return 'Appétit excessif';
    }
  }
}
