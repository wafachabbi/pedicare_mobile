import 'package:flutter_test/flutter_test.dart';

import 'package:projet_mobile/data/symptomes_catalogue.dart';
import 'package:projet_mobile/models/journal_symptome_model.dart';

void main() {
  group('JournalSymptomeModel', () {
    test('détecte la fièvre à partir de 38 °C', () {
      final entree = JournalSymptomeModel(
        id: '1',
        enfantId: '1',
        date: DateTime(2026, 1, 1),
        temperature: 38.4,
      );

      expect(entree.fievre, isTrue);
      expect(entree.fievreElevee, isFalse);
    });

    test('le score de sévérité augmente avec les symptômes', () {
      final calme = JournalSymptomeModel(
        id: '1',
        enfantId: '1',
        date: DateTime(2026, 1, 1),
        temperature: 36.8,
      );
      final charge = JournalSymptomeModel(
        id: '2',
        enfantId: '1',
        date: DateTime(2026, 1, 1),
        temperature: 39.2,
        toux: NiveauToux.forte,
        comportement: EtatComportement.lethargique,
        sommeil: QualiteSommeil.mauvais,
        appetit: NiveauAppetit.faible,
        symptomes: const ['fievre', 'toux'],
      );

      expect(charge.scoreSeverite, greaterThan(calme.scoreSeverite));
      expect(charge.aSymptomeAlerte, isFalse);
    });

    test('détecte les symptômes nécessitant une vigilance', () {
      final entree = JournalSymptomeModel(
        id: '1',
        enfantId: '1',
        date: DateTime(2026, 1, 1),
        symptomes: const ['respiration'],
      );

      expect(entree.aSymptomeAlerte, isTrue);
    });
  });

  group('SymptomesCatalogue', () {
    test('associe un libellé et un emoji à chaque identifiant', () {
      expect(SymptomesCatalogue.labelDe('fievre'), 'Fièvre');
      expect(SymptomesCatalogue.emojiDe('toux'), isNotEmpty);
      expect(SymptomesCatalogue.parId('inconnu'), isNull);
    });
  });
}
