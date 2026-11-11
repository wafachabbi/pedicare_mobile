import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/croissance_model.dart';
import '../models/document_medical_model.dart';
import '../models/enfant_model.dart';
import '../models/rendezvous_model.dart';
import '../models/vaccin_model.dart';
import '../services/document_service.dart';
import '../services/vaccin_service.dart';
import '../services/rendezvous_service.dart';
import '../services/croissance_service.dart';

/// Génère et partage le carnet de santé numérique complet d'un enfant en PDF.
///
/// Contenu :
///  - Fiche d'identité de l'enfant
///  - Résumé documents médicaux (par catégorie)
///  - Calendrier vaccinal
///  - Derniers rendez-vous
///  - Courbe de croissance (table)
class CarnetPdfService {
  CarnetPdfService._();

  static final _fmt = DateFormat('dd/MM/yyyy', 'fr_FR');

  static final _colorPrimary = PdfColor.fromHex('1E6FDB');
  static final _colorAccent = PdfColor.fromHex('00C9A7');
  static final _colorDanger = PdfColor.fromHex('FF6B6B');
  static final _colorOrange = PdfColor.fromHex('E67E22');
  static final _colorBg = PdfColor.fromHex('EBF3FF');
  static final _colorGrey = PdfColor.fromHex('888888');

  // ── Point d'entrée ────────────────────────────────────────────────────────

  static Future<void> genererEtPartager(EnfantModel enfant) async {
    // Chargement parallèle des données
    final results = await Future.wait([
      DocumentService.getDocuments(enfant.id),
      VaccinService.getVaccins(enfant.id),
      RendezVousService.getRendezVous(enfant.id),
      CroissanceService.getMesures(enfant.id),
    ]);

    final docs = results[0] as List<DocumentMedicalModel>;
    final vaccins = results[1] as List<VaccinModel>;
    final rdvs = results[2] as List<RendezVousModel>;
    final mesures = results[3] as List<CroissanceModel>;

    final pdf = pw.Document(
      title: 'Carnet de santé — ${enfant.nomComplet}',
      author: 'PediCare AI',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => _header(enfant),
        footer: (ctx) => _footer(ctx),
        build: (ctx) => [
          pw.SizedBox(height: 18),
          _identiteSection(enfant),
          pw.SizedBox(height: 20),
          if (docs.isNotEmpty) ...[
            _sectionTitle('📋 Documents médicaux (${docs.length})'),
            pw.SizedBox(height: 10),
            _docsTable(docs),
            pw.SizedBox(height: 20),
          ],
          if (vaccins.isNotEmpty) ...[
            _sectionTitle('💉 Calendrier vaccinal (${vaccins.length})'),
            pw.SizedBox(height: 10),
            _vaccinsTable(vaccins),
            pw.SizedBox(height: 20),
          ],
          if (rdvs.isNotEmpty) ...[
            _sectionTitle(
                '📅 Rendez-vous (${rdvs.length})'),
            pw.SizedBox(height: 10),
            _rdvsTable(rdvs),
            pw.SizedBox(height: 20),
          ],
          if (mesures.isNotEmpty) ...[
            _sectionTitle(
                '📏 Croissance (${mesures.length} mesures)'),
            pw.SizedBox(height: 10),
            _croissanceTable(mesures),
            pw.SizedBox(height: 20),
          ],
          _note(),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final fileName =
        'carnet_${enfant.nomComplet.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Carnet de santé — ${enfant.nomComplet}',
      text:
          'Carnet de santé numérique de ${enfant.nomComplet} généré par PediCare AI.',
    );
  }

  // ── Header / Footer ───────────────────────────────────────────────────────

  static pw.Widget _header(EnfantModel enfant) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: pw.BoxDecoration(color: _colorPrimary),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('PediCare AI',
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold)),
              pw.Text('Carnet de santé numérique',
                  style: pw.TextStyle(
                      color: PdfColors.grey300, fontSize: 10)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(enfant.nomComplet,
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold)),
              pw.Text(
                  '${enfant.age} ans · ${enfant.sexe == "F" ? "Fille" : "Garçon"}',
                  style: pw.TextStyle(
                      color: PdfColors.grey300, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context ctx) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Généré par PediCare AI le ${_fmt.format(DateTime.now())}',
          style: pw.TextStyle(color: _colorGrey, fontSize: 8),
        ),
        pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}',
            style: pw.TextStyle(color: _colorGrey, fontSize: 8)),
      ],
    );
  }

  // ── Fiche identité ────────────────────────────────────────────────────────

  static pw.Widget _identiteSection(EnfantModel enfant) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _colorBg,
        border: pw.Border.all(color: _colorPrimary, width: 0.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Fiche d\'identité',
              style: pw.TextStyle(
                  color: _colorPrimary,
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              _infoCell('Nom complet', enfant.nomComplet),
              pw.SizedBox(width: 10),
              _infoCell('Date de naissance',
                  _fmt.format(enfant.dateNaissance)),
              pw.SizedBox(width: 10),
              _infoCell('Sexe',
                  enfant.sexe == 'F' ? 'Féminin' : 'Masculin'),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _infoCell(
                  'Groupe sanguin', enfant.groupeSanguin ?? 'Non renseigné'),
              pw.SizedBox(width: 10),
              _infoCell('Allergies', enfant.allergies ?? 'Aucune connue'),
              pw.SizedBox(width: 10),
              _infoCell('Âge', '${enfant.age} ans'),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _infoCell(String label, String value) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: pw.TextStyle(color: _colorGrey, fontSize: 8)),
          pw.Text(value,
              style: pw.TextStyle(
                  color: PdfColors.black,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  // ── Documents médicaux ────────────────────────────────────────────────────

  static pw.Widget _docsTable(List<DocumentMedicalModel> docs) {
    final grouped = <CategorieDocument, List<DocumentMedicalModel>>{};
    for (final d in docs) {
      grouped.putIfAbsent(d.categorie, () => []).add(d);
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(1),
      },
      children: [
        _tableHeader(
            ['Titre', 'Catégorie', 'Date', 'Médecin', 'Partagé'],
            _colorPrimary),
        ...docs.take(30).toList().asMap().entries.map((e) {
          final i = e.key;
          final d = e.value;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
                color: i.isEven ? _colorBg : PdfColors.white),
            children: [
              _cell(d.titre),
              _cell(d.categorie.label),
              _cell(_fmt.format(d.dateDocument)),
              _cell(d.medecin ?? '—'),
              _cell(d.partagePediatre ? 'Oui' : 'Non',
                  color: d.partagePediatre ? _colorAccent : _colorGrey),
            ],
          );
        }),
        if (docs.length > 30)
          pw.TableRow(children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                '… et ${docs.length - 30} autres documents.',
                style: pw.TextStyle(
                    color: _colorGrey,
                    fontSize: 9,
                    fontStyle: pw.FontStyle.italic),
              ),
            ),
            ...List.generate(4, (_) => pw.SizedBox()),
          ]),
      ],
    );
  }

  // ── Vaccins ───────────────────────────────────────────────────────────────

  static pw.Widget _vaccinsTable(List<VaccinModel> vaccins) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        _tableHeader(['Vaccin', 'Maladie', 'Date', 'Médecin'],
            _colorOrange),
        ...vaccins.asMap().entries.map((e) {
          final i = e.key;
          final v = e.value;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
                color: i.isEven ? _colorBg : PdfColors.white),
            children: [
              _cell(v.nom),
              _cell(v.maladie),
              _cell(_fmt.format(v.dateAdministre)),
              _cell(v.medecin ?? '—'),
            ],
          );
        }),
      ],
    );
  }

  // ── Rendez-vous ───────────────────────────────────────────────────────────

  static pw.Widget _rdvsTable(List<RendezVousModel> rdvs) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        _tableHeader(['Titre', 'Date', 'Médecin', 'Statut'],
            _colorPrimary),
        ...rdvs.take(20).toList().asMap().entries.map((e) {
          final i = e.key;
          final r = e.value;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
                color: i.isEven ? _colorBg : PdfColors.white),
            children: [
              _cell(r.titre),
              _cell(_fmt.format(r.dateHeure)),
              _cell(r.medecin.isEmpty ? '—' : 'Dr. ${r.medecin}'),
              _cell(r.statut.name,
                  color: r.statut == StatutRDV.confirme ? _colorAccent : _colorGrey),
            ],
          );
        }),
      ],
    );
  }

  // ── Croissance ────────────────────────────────────────────────────────────

  static pw.Widget _croissanceTable(List<CroissanceModel> mesures) {
    final sorted = List<CroissanceModel>.from(mesures)
      ..sort((a, b) => b.date.compareTo(a.date));
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.8),
        1: const pw.FlexColumnWidth(1.3),
        2: const pw.FlexColumnWidth(1.3),
        3: const pw.FlexColumnWidth(1.3),
        4: const pw.FlexColumnWidth(1.8),
      },
      children: [
        _tableHeader(
            ['Date', 'Poids (kg)', 'Taille (cm)', 'IMC', 'Périm. crânien'],
            PdfColor.fromHex('9B59B6')),
        ...sorted.take(15).toList().asMap().entries.map((e) {
          final i = e.key;
          final m = e.value;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
                color: i.isEven ? _colorBg : PdfColors.white),
            children: [
              _cell(_fmt.format(m.date)),
              _cell('${m.poids}'),
              _cell('${m.taille}'),
              _cell(m.imc.toStringAsFixed(1)),
              _cell(m.perimeterCranien != null
                  ? '${m.perimeterCranien} cm'
                  : '—'),
            ],
          );
        }),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static pw.Widget _sectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: _colorBg,
        border: pw.Border(
            left: pw.BorderSide(color: _colorPrimary, width: 3)),
      ),
      child: pw.Text(title,
          style: pw.TextStyle(
              color: _colorPrimary,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.TableRow _tableHeader(List<String> labels, PdfColor color) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: color),
      children: labels
          .map((h) => pw.Padding(
                padding: const pw.EdgeInsets.all(7),
                child: pw.Text(h,
                    style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold)),
              ))
          .toList(),
    );
  }

  static pw.Widget _cell(String text, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text,
          style: pw.TextStyle(
              fontSize: 9, color: color ?? PdfColors.black)),
    );
  }

  static pw.Widget _note() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Text(
        'Ce document est généré automatiquement par PediCare AI à titre informatif. '
        'Il ne remplace pas un avis médical et ne constitue pas un diagnostic. '
        'Consultez votre pédiatre pour toute interprétation médicale.',
        style: pw.TextStyle(
            fontSize: 8,
            color: PdfColors.grey700,
            fontStyle: pw.FontStyle.italic),
      ),
    );
  }
}
