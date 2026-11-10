/// Base locale de médicaments pédiatriques courants (Module 5 — PediPharma).
///
/// Remplace l'API RxNorm citée dans le cahier des charges : RxNorm couvre les
/// médicaments américains et ne reconnaît pas les noms commerciaux utilisés
/// en Tunisie et en France. Les informations sont générales et ne contiennent
/// volontairement AUCUNE posologie : la dose est celle de la prescription.
library;

const String avertissementMedicament =
    'Informations générales : elles ne remplacent pas l\'avis du médecin ou '
    'du pharmacien. Ne modifiez jamais une dose sans avis médical.';

/// Familles utilisées pour détecter les interactions.
enum FamilleMedicament {
  antalgique,
  ains,
  antibiotique,
  corticoide,
  antihistaminique,
  bronchodilatateur,
  pansementDigestif,
  rehydratation,
  supplement,
  lavageNasal,
}

class Medicament {
  final String id;

  /// Dénomination commune (molécule).
  final String dci;
  final List<String> nomsCommerciaux;
  final FamilleMedicament famille;
  final String classe;
  final String usage;
  final List<String> conseils;
  final List<String> precautions;

  const Medicament({
    required this.id,
    required this.dci,
    required this.nomsCommerciaux,
    required this.famille,
    required this.classe,
    required this.usage,
    this.conseils = const [],
    this.precautions = const [],
  });
}

const List<Medicament> medicamentsCatalogue = [
  Medicament(
    id: 'paracetamol',
    dci: 'Paracétamol',
    nomsCommerciaux: ['Doliprane', 'Efferalgan', 'Dafalgan', 'Panadol', 'Fervex'],
    famille: FamilleMedicament.antalgique,
    classe: 'Antalgique et antipyrétique',
    usage: 'Fait baisser la fièvre et soulage la douleur.',
    conseils: [
      'Respecter l\'intervalle minimal entre deux prises indiqué sur l\'ordonnance.',
      'La dose dépend du poids de l\'enfant : utiliser la pipette ou la cuillère fournie avec le flacon.',
    ],
    precautions: [
      'Ne pas donner en même temps un autre médicament contenant du paracétamol (risque de surdosage pour le foie).',
    ],
  ),
  Medicament(
    id: 'ibuprofene',
    dci: 'Ibuprofène',
    nomsCommerciaux: ['Advil', 'Nurofen', 'Brufen', 'Antarène'],
    famille: FamilleMedicament.ains,
    classe: 'Anti-inflammatoire non stéroïdien (AINS)',
    usage: 'Fait baisser la fièvre, soulage la douleur et l\'inflammation.',
    conseils: [
      'À donner de préférence pendant un repas.',
      'Bien faire boire l\'enfant.',
    ],
    precautions: [
      'Déconseillé en cas de varicelle, de déshydratation (vomissements, diarrhée) ou d\'asthme aggravé par les AINS.',
      'Ne pas associer à un autre anti-inflammatoire.',
    ],
  ),
  Medicament(
    id: 'ketoprofene',
    dci: 'Kétoprofène',
    nomsCommerciaux: ['Toprec', 'Profenid'],
    famille: FamilleMedicament.ains,
    classe: 'Anti-inflammatoire non stéroïdien (AINS)',
    usage: 'Soulage la douleur et la fièvre.',
    precautions: [
      'Ne pas associer à un autre anti-inflammatoire (ibuprofène, aspirine).',
    ],
  ),
  Medicament(
    id: 'aspirine',
    dci: 'Acide acétylsalicylique (aspirine)',
    nomsCommerciaux: ['Aspégic', 'Aspirine', 'Aspro', 'Catalgine'],
    famille: FamilleMedicament.ains,
    classe: 'Anti-inflammatoire, antalgique',
    usage: 'Soulage la douleur et la fièvre.',
    precautions: [
      'Généralement déconseillée chez l\'enfant sauf prescription spécifique (risque de syndrome de Reye lors d\'infections virales).',
      'Ne pas associer à un autre anti-inflammatoire.',
    ],
  ),
  Medicament(
    id: 'amoxicilline',
    dci: 'Amoxicilline',
    nomsCommerciaux: ['Clamoxyl', 'Hiconcil', 'Amoxil', 'Agram'],
    famille: FamilleMedicament.antibiotique,
    classe: 'Antibiotique (pénicilline)',
    usage: 'Traite certaines infections bactériennes (otite, angine, sinusite…).',
    conseils: [
      'Aller jusqu\'au bout du traitement, même si l\'enfant va mieux.',
      'Bien agiter la suspension avant chaque prise ; la conserver comme indiqué.',
    ],
    precautions: [
      'Contre-indiqué en cas d\'allergie aux pénicillines.',
      'Consulter en cas d\'éruption cutanée pendant le traitement.',
    ],
  ),
  Medicament(
    id: 'amox_clav',
    dci: 'Amoxicilline + acide clavulanique',
    nomsCommerciaux: ['Augmentin', 'Amoclan', 'Ciblor'],
    famille: FamilleMedicament.antibiotique,
    classe: 'Antibiotique (pénicilline)',
    usage: 'Traite certaines infections bactériennes.',
    conseils: [
      'À donner au début du repas pour une meilleure tolérance digestive.',
      'Aller jusqu\'au bout du traitement.',
    ],
    precautions: [
      'Contre-indiqué en cas d\'allergie aux pénicillines.',
      'Une diarrhée est possible : prévenir le médecin si elle est importante.',
    ],
  ),
  Medicament(
    id: 'azithromycine',
    dci: 'Azithromycine',
    nomsCommerciaux: ['Zithromax', 'Azithromax', 'Azitrocin'],
    famille: FamilleMedicament.antibiotique,
    classe: 'Antibiotique (macrolide)',
    usage: 'Traite certaines infections bactériennes, souvent en traitement court.',
    conseils: ['Respecter la durée prescrite, souvent de quelques jours seulement.'],
  ),
  Medicament(
    id: 'cefpodoxime',
    dci: 'Cefpodoxime / céfixime',
    nomsCommerciaux: ['Orelox', 'Oroken', 'Cefixime'],
    famille: FamilleMedicament.antibiotique,
    classe: 'Antibiotique (céphalosporine)',
    usage: 'Traite certaines infections bactériennes.',
    conseils: ['Aller jusqu\'au bout du traitement.'],
    precautions: ['Signaler toute allergie connue aux antibiotiques.'],
  ),
  Medicament(
    id: 'prednisolone',
    dci: 'Prednisolone / bétaméthasone',
    nomsCommerciaux: ['Solupred', 'Célestène', 'Celestene'],
    famille: FamilleMedicament.corticoide,
    classe: 'Corticoïde',
    usage: 'Réduit une inflammation importante (laryngite, asthme, allergie…).',
    conseils: ['Généralement donné le matin.'],
    precautions: [
      'Ne pas arrêter brutalement un traitement long sans avis médical.',
    ],
  ),
  Medicament(
    id: 'salbutamol',
    dci: 'Salbutamol',
    nomsCommerciaux: ['Ventoline', 'Airomir', 'Asmasal'],
    famille: FamilleMedicament.bronchodilatateur,
    classe: 'Bronchodilatateur inhalé',
    usage: 'Ouvre les bronches lors d\'une gêne respiratoire ou d\'une crise d\'asthme.',
    conseils: [
      'Chez l\'enfant, s\'utilise avec une chambre d\'inhalation adaptée à son âge.',
    ],
    precautions: [
      'Consulter en urgence si la gêne respiratoire ne s\'améliore pas après les bouffées prescrites.',
    ],
  ),
  Medicament(
    id: 'antihistaminique',
    dci: 'Cétirizine / desloratadine',
    nomsCommerciaux: ['Zyrtec', 'Aerius', 'Virlix', 'Clarityne'],
    famille: FamilleMedicament.antihistaminique,
    classe: 'Antihistaminique',
    usage: 'Soulage les symptômes d\'allergie (nez qui coule, démangeaisons, urticaire).',
    precautions: ['Une somnolence est possible.'],
  ),
  Medicament(
    id: 'diosmectite',
    dci: 'Diosmectite',
    nomsCommerciaux: ['Smecta'],
    famille: FamilleMedicament.pansementDigestif,
    classe: 'Pansement digestif',
    usage: 'Aide à réduire la diarrhée.',
    conseils: ['Bien hydrater l\'enfant en parallèle (soluté de réhydratation).'],
    precautions: [
      'Peut diminuer l\'absorption des autres médicaments : espacer les prises d\'environ 2 heures.',
    ],
  ),
  Medicament(
    id: 'sro',
    dci: 'Soluté de réhydratation orale (SRO)',
    nomsCommerciaux: ['Adiaril', 'Fanolyte', 'Hydrigoz', 'Alhydrate', 'SRO'],
    famille: FamilleMedicament.rehydratation,
    classe: 'Réhydratation',
    usage: 'Compense les pertes d\'eau et de sels en cas de diarrhée ou de vomissements.',
    conseils: [
      'Proposer en petites quantités, très souvent.',
      'Préparer avec le volume d\'eau indiqué, sans rien ajouter.',
    ],
    precautions: [
      'Consulter rapidement si l\'enfant refuse de boire, urine peu ou semble très fatigué.',
    ],
  ),
  Medicament(
    id: 'vitamine_d',
    dci: 'Vitamine D',
    nomsCommerciaux: ['Uvedose', 'ZymaD', 'Zyma D', 'Stérogyl', 'Sterogyl', 'Devit'],
    famille: FamilleMedicament.supplement,
    classe: 'Vitamine',
    usage: 'Aide à la croissance des os.',
    precautions: ['Ne pas cumuler plusieurs produits de vitamine D sans avis médical.'],
  ),
  Medicament(
    id: 'fer',
    dci: 'Fer',
    nomsCommerciaux: ['Ferrostrane', 'Fumafer', 'Tardyferon'],
    famille: FamilleMedicament.supplement,
    classe: 'Supplément en fer',
    usage: 'Traite ou prévient un manque de fer (anémie).',
    conseils: ['Les selles peuvent devenir foncées : c\'est habituel.'],
    precautions: ['Conserver hors de portée des enfants : un surdosage est dangereux.'],
  ),
  Medicament(
    id: 'serum_physio',
    dci: 'Sérum physiologique',
    nomsCommerciaux: ['Physiomer', 'Stérimar', 'Sterimar', 'Prorhinel', 'Serum physiologique'],
    famille: FamilleMedicament.lavageNasal,
    classe: 'Lavage de nez',
    usage: 'Nettoie le nez encombré.',
    conseils: ['Allonger l\'enfant sur le côté pour le lavage.'],
  ),
];
