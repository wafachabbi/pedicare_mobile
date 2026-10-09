import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/croissance_model.dart';

class CroissancePdfService {
  static Future<void> partagerCourbes({
    required String enfantNom,
    required String enfantAge,
    required String enfantSexe,
    required List<CroissanceModel> mesures,
  }) async {
    final pdf = pw.Document();

    final color1 = PdfColor.fromHex('1E6FDB');
    final color2 = PdfColor.fromHex('9B59B6');
    final colorAccent = PdfColor.fromHex('00C9A7');
    final colorBg = PdfColor.fromHex('F0F4FF');
    final colorGrey = PdfColor.fromHex('888888');

    // Trier par date croissante
    final sorted = List<CroissanceModel>.from(mesures)
      ..sort((a, b) => a.date.compareTo(b.date));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => _buildHeader(enfantNom, enfantAge, enfantSexe, color1, colorBg),
        footer: (ctx) => _buildFooter(ctx, colorGrey),
        build: (ctx) => [
          pw.SizedBox(height: 20),
          _buildSummaryCards(sorted, color1, color2, colorAccent),
          pw.SizedBox(height: 24),
          _buildSectionTitle('Historique des mesures', color1),
          pw.SizedBox(height: 10),
          _buildTable(sorted, color1, colorBg),
          pw.SizedBox(height: 24),
          _buildSectionTitle('Évolution du poids (kg)', color2),
          pw.SizedBox(height: 10),
          _buildBarChart(
            sorted,
            getValue: (m) => m.poids,
            color: color2,
            unit: 'kg',
          ),
          pw.SizedBox(height: 24),
          _buildSectionTitle('Évolution de la taille (cm)', colorAccent),
          pw.SizedBox(height: 10),
          _buildBarChart(
            sorted,
            getValue: (m) => m.taille,
            color: colorAccent,
            unit: 'cm',
          ),
          pw.SizedBox(height: 24),
          _buildSectionTitle('Évolution de l\'IMC', color1),
          pw.SizedBox(height: 10),
          _buildBarChart(
            sorted,
            getValue: (m) => m.imc,
            color: color1,
            unit: 'kg/m²',
          ),
          pw.SizedBox(height: 24),
          _buildNote(colorGrey),
        ],
      ),
    );

    // Sauvegarder le PDF
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/croissance_${enfantNom.replaceAll(' ', '_')}.pdf');
    await file.writeAsBytes(await pdf.save());

    // Partager
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Courbes de croissance — $enfantNom',
      text: 'Veuillez trouver ci-joint le suivi de croissance de $enfantNom.',
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  static pw.Widget _buildHeader(
    String nom, String age, String sexe,
    PdfColor color, PdfColor bg,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(8),
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
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold)),
              pw.Text('Suivi de croissance pédiatrique',
                  style: pw.TextStyle(color: PdfColors.grey300, fontSize: 11)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(nom,
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold)),
              pw.Text('$age — ${sexe == "F" ? "Fille" : "Garçon"}',
                  style: pw.TextStyle(color: PdfColors.grey300, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  static pw.Widget _buildFooter(pw.Context ctx, PdfColor color) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Généré par PediCare AI — ${_fmtDate(DateTime.now())}',
            style: pw.TextStyle(color: color, fontSize: 9)),
        pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}',
            style: pw.TextStyle(color: color, fontSize: 9)),
      ],
    );
  }

  // ── Cartes résumé ─────────────────────────────────────────────────────────
  static pw.Widget _buildSummaryCards(
    List<CroissanceModel> mesures,
    PdfColor c1, PdfColor c2, PdfColor c3,
  ) {
    if (mesures.isEmpty) return pw.SizedBox();
    final last = mesures.last;
    return pw.Row(
      children: [
        _card('Poids actuel', '${last.poids} kg', c1),
        pw.SizedBox(width: 12),
        _card('Taille actuelle', '${last.taille} cm', c2),
        pw.SizedBox(width: 12),
        _card('IMC', last.imc.toStringAsFixed(1), c3),
        pw.SizedBox(width: 12),
        _card('Mesures', '${mesures.length}', PdfColor.fromHex('E67E22')),
      ],
    );
  }

  static pw.Widget _card(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromInt(
              color.toInt() & 0xFFFFFF | 0x20000000),
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: color, width: 1),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(value,
                style: pw.TextStyle(
                    color: color, fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Text(label,
                style: pw.TextStyle(color: PdfColors.grey700, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  // ── Titre de section ──────────────────────────────────────────────────────
  static pw.Widget _buildSectionTitle(String title, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(color.toInt() & 0xFFFFFF | 0x15000000),
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border(left: pw.BorderSide(color: color, width: 3)),
      ),
      child: pw.Text(title,
          style: pw.TextStyle(
              color: color, fontSize: 13, fontWeight: pw.FontWeight.bold)),
    );
  }

  // ── Tableau ───────────────────────────────────────────────────────────────
  static pw.Widget _buildTable(List<CroissanceModel> mesures, PdfColor color, PdfColor bg) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: color),
          children: ['Date', 'Poids (kg)', 'Taille (cm)', 'IMC', 'Périm. crânien']
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(h,
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold)),
                  ))
              .toList(),
        ),
        // Rows
        ...mesures.asMap().entries.map((e) {
          final i = e.key;
          final m = e.value;
          final rowColor = i.isEven ? bg : PdfColors.white;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: rowColor),
            children: [
              _cell(_fmtDate(m.date)),
              _cell('${m.poids}'),
              _cell('${m.taille}'),
              _cell(m.imc.toStringAsFixed(1), color: _imcColor(m.imc)),
              _cell(m.perimeterCranien != null ? '${m.perimeterCranien} cm' : '—'),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _cell(String text, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(7),
      child: pw.Text(text,
          style: pw.TextStyle(
              fontSize: 10, color: color ?? PdfColors.black)),
    );
  }

  // ── Graphe en barres ──────────────────────────────────────────────────────
  static pw.Widget _buildBarChart(
    List<CroissanceModel> mesures, {
    required double Function(CroissanceModel) getValue,
    required PdfColor color,
    required String unit,
  }) {
    if (mesures.isEmpty) return pw.SizedBox();

    final values = mesures.map(getValue).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    const chartHeight = 100.0;
    const barMaxWidth = 30.0;

    return pw.Container(
      height: chartHeight + 40,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: mesures.asMap().entries.map((e) {
          final m = e.value;
          final val = getValue(m);
          final barH = maxVal > 0 ? (val / maxVal) * chartHeight : 0.0;

          return pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text('${val.toStringAsFixed(1)}$unit',
                  style: pw.TextStyle(fontSize: 7, color: color)),
              pw.SizedBox(height: 2),
              pw.Container(
                width: barMaxWidth,
                height: barH,
                decoration: pw.BoxDecoration(
                  color: color,
                  borderRadius: pw.BorderRadius.only(
                    topLeft: const pw.Radius.circular(3),
                    topRight: const pw.Radius.circular(3),
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(_fmtShort(m.date),
                  style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Note bas de page ──────────────────────────────────────────────────────
  static pw.Widget _buildNote(PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Text(
        '⚠️  Ce document est généré automatiquement par PediCare AI à titre informatif. '
        'Il ne remplace pas un avis médical. Consultez votre pédiatre pour toute interprétation.',
        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static PdfColor _imcColor(double imc) {
    if (imc < 18.5) return PdfColor.fromHex('1E6FDB');
    if (imc < 25) return PdfColor.fromHex('00C9A7');
    if (imc < 30) return PdfColor.fromHex('E67E22');
    return PdfColor.fromHex('FF6B6B');
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _fmtShort(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}
