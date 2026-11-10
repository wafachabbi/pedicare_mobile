/// Base de connaissances de l'assistant IA (RAG).
///
/// Fiches santé rédigées à partir de recommandations publiques (Assurance
/// Maladie, Santé publique France, HAS, OMS, Société française de pédiatrie).
/// Contenu général, sans posologie. À faire relire par l'équipe / l'encadrante.
///
/// Chaque section d'une fiche devient un passage indexé par le moteur de
/// recherche (BM25 + embeddings optionnels).
library;

class SectionFiche {
  final String titre;
  final String texte;
  const SectionFiche(this.titre, this.texte);
}

class FicheSante {
  final String id;
  final String titre;
  final String categorie;
  final String emoji;

  /// Organisme source (affiché dans les citations).
  final String source;

  /// Tranche d'âge concernée en mois (null = tout âge).
  final int? ageMinMois;
  final int? ageMaxMois;

  /// Synonymes et mots du langage courant pour améliorer la recherche.
  final List<String> motsCles;
  final List<SectionFiche> sections;

  const FicheSante({
    required this.id,
    required this.titre,
    required this.categorie,
    required this.emoji,
    required this.source,
    this.ageMinMois,
    this.ageMaxMois,
    this.motsCles = const [],
    required this.sections,
  });
}

const _ameli = 'Assurance Maladie (ameli.fr)';
const _spf = 'Santé publique France';
const _has = 'Haute Autorité de santé (HAS)';
const _oms = 'Organisation mondiale de la santé (OMS)';
const _sfp = 'Société française de pédiatrie (mpedia.fr)';
const _ansm = 'ANSM';

const List<FicheSante> fichesSante = [
  // ══ Symptômes courants ═════════════════════════════════════════════════════
  FicheSante(
    id: 'fievre',
    titre: 'Fièvre de l\'enfant',
    categorie: 'Symptômes',
    emoji: '🌡️',
    source: _ameli,
    motsCles: ['fievre', 'temperature', 'chaud', 'brulant', '38', '39', '40', 'thermometre'],
    sections: [
      SectionFiche('Définition',
          'On parle de fièvre quand la température dépasse 38 °C. La fièvre est une réaction '
          'normale de l\'organisme, le plus souvent due à une infection virale bénigne. '
          'Sa valeur ne reflète pas à elle seule la gravité : le comportement de l\'enfant compte davantage.'),
      SectionFiche('Que faire',
          'Proposer régulièrement à boire, ne pas trop couvrir l\'enfant et garder une pièce '
          'tempérée. Les bains frais et les enveloppements ne sont plus recommandés. '
          'Un médicament contre la fièvre ne se donne que pour le confort de l\'enfant, '
          'selon la prescription ou le conseil du pharmacien, sans alterner deux médicaments sans avis médical.'),
      SectionFiche('Quand consulter',
          'Consulter rapidement si l\'enfant a moins de 3 mois, si la fièvre dure plus de '
          '48 à 72 heures, si l\'enfant refuse de boire, vomit tout, est inhabituellement '
          'grognon ou somnolent, ou si la fièvre revient après quelques jours sans fièvre.'),
      SectionFiche('Signes d\'urgence',
          'Appeler le SAMU (190 en Tunisie, 15 en France) en cas de taches rouges ou violacées '
          'qui ne s\'effacent pas à la pression, de difficulté à respirer, de convulsion, '
          'de raideur de la nuque, d\'enfant difficile à réveiller ou d\'enfant qui ne réagit plus.'),
    ],
  ),
  FicheSante(
    id: 'temperature',
    titre: 'Bien prendre la température',
    categorie: 'Symptômes',
    emoji: '🌡️',
    source: _sfp,
    motsCles: ['thermometre', 'prendre la temperature', 'rectal', 'frontal', 'auriculaire'],
    sections: [
      SectionFiche('Méthode',
          'Utiliser un thermomètre électronique. Chez le nourrisson, la prise rectale reste la '
          'plus fiable. Chez l\'enfant plus grand, les thermomètres auriculaires ou frontaux '
          'sont pratiques mais moins précis. Les thermomètres au mercure ne doivent plus être utilisés.'),
      SectionFiche('Conseils',
          'Prendre la température au calme, à distance d\'un bain ou d\'un effort. Noter la valeur '
          'et l\'heure, par exemple dans le journal de santé de l\'application, pour en parler au médecin.'),
    ],
  ),
  FicheSante(
    id: 'gastro',
    titre: 'Gastro-entérite et diarrhée',
    categorie: 'Symptômes',
    emoji: '🤢',
    source: _ameli,
    motsCles: ['gastro', 'diarrhee', 'selles liquides', 'vomi', 'vomissement', 'mal au ventre', 'ventre'],
    sections: [
      SectionFiche('Le principal risque',
          'La gastro-entérite est le plus souvent d\'origine virale et guérit en quelques jours. '
          'Le principal danger, surtout chez le nourrisson, est la déshydratation causée par la '
          'diarrhée et les vomissements.'),
      SectionFiche('Réhydrater',
          'Donner un soluté de réhydratation orale (SRO), vendu en pharmacie, en petites quantités '
          'très souvent (quelques gorgées toutes les quelques minutes), puis augmenter selon la tolérance. '
          'L\'eau seule, les sodas ou les jus ne remplacent pas le SRO. Continuer l\'allaitement.'),
      SectionFiche('Alimentation',
          'Reprendre l\'alimentation habituelle rapidement, dès que les vomissements diminuent, '
          'en fractionnant les repas.'),
      SectionFiche('Quand consulter',
          'Consulter rapidement si l\'enfant a moins de 6 mois, s\'il refuse le SRO ou vomit tout, '
          's\'il présente des signes de déshydratation, du sang dans les selles, une fièvre élevée '
          'ou une douleur abdominale importante.'),
    ],
  ),
  FicheSante(
    id: 'deshydratation',
    titre: 'Reconnaître la déshydratation',
    categorie: 'Symptômes',
    emoji: '💧',
    source: _ameli,
    motsCles: ['deshydratation', 'deshydrate', 'boit pas', 'urine', 'couche seche', 'yeux creux'],
    sections: [
      SectionFiche('Signes d\'alerte',
          'Couches sèches ou urines rares, bouche et langue sèches, yeux creux, pleurs sans larmes, '
          'fontanelle déprimée chez le nourrisson, perte de poids, enfant somnolent, mou ou '
          'inhabituellement grognon.'),
      SectionFiche('Que faire',
          'En présence de ces signes, consulter en urgence. Une déshydratation peut s\'aggraver '
          'en quelques heures chez un nourrisson.'),
    ],
  ),
  FicheSante(
    id: 'rhume',
    titre: 'Rhume et nez bouché',
    categorie: 'Symptômes',
    emoji: '🤧',
    source: _ameli,
    motsCles: ['rhume', 'nez bouche', 'nez qui coule', 'morve', 'enrhume', 'rhinopharyngite', 'mouche'],
    sections: [
      SectionFiche('Évolution',
          'Le rhume (rhinopharyngite) est une infection virale fréquente qui guérit spontanément '
          'en 7 à 10 jours. Les antibiotiques sont inutiles contre les virus.'),
      SectionFiche('Soulager',
          'Laver le nez au sérum physiologique plusieurs fois par jour, surtout avant les repas et '
          'le coucher, faire boire régulièrement et aérer la chambre.'),
      SectionFiche('Quand consulter',
          'Consulter en cas de fièvre de plus de 3 jours, de douleur d\'oreille, d\'yeux qui '
          'collent avec fièvre, de gêne respiratoire ou si le nourrisson boit mal.'),
    ],
  ),
  FicheSante(
    id: 'lavage_nez',
    titre: 'Le lavage de nez',
    categorie: 'Soins',
    emoji: '💦',
    source: _sfp,
    motsCles: ['lavage de nez', 'serum physiologique', 'dosette', 'mouche bebe'],
    sections: [
      SectionFiche('Technique',
          'Allonger l\'enfant sur le côté en maintenant sa tête. Introduire l\'embout de la dosette '
          'de sérum physiologique dans la narine du haut et presser : le liquide ressort par l\'autre '
          'narine. Tourner l\'enfant de l\'autre côté et recommencer. Essuyer le nez.'),
      SectionFiche('Quand',
          'Avant les repas et avant le coucher, et chaque fois que le nez est encombré. '
          'Chez le nourrisson, qui respire par le nez, un nez dégagé facilite la prise des biberons.'),
    ],
  ),
  FicheSante(
    id: 'toux',
    titre: 'Toux de l\'enfant',
    categorie: 'Symptômes',
    emoji: '😷',
    source: _ameli,
    motsCles: ['toux', 'tousse', 'toux seche', 'toux grasse', 'sirop pour la toux', 'quinte'],
    sections: [
      SectionFiche('Origine',
          'La toux accompagne le plus souvent une infection virale des voies respiratoires. '
          'C\'est un réflexe utile qui aide à dégager les bronches.'),
      SectionFiche('Sirops contre la toux',
          'Les sirops contre la toux sont peu utiles chez l\'enfant et certains sont contre-indiqués '
          'chez le nourrisson (notamment les mucolytiques avant 2 ans). Ne pas en donner sans avis médical.'),
      SectionFiche('Quand consulter',
          'Consulter si l\'enfant respire vite ou difficilement, si sa respiration siffle, s\'il a de '
          'la fièvre plus de 3 jours, si la toux dure plus de 3 semaines ou survient brutalement '
          'pendant un repas ou un jeu (possible corps étranger).'),
    ],
  ),
  FicheSante(
    id: 'bronchiolite',
    titre: 'Bronchiolite du nourrisson',
    categorie: 'Symptômes',
    emoji: '🫁',
    source: _has,
    ageMaxMois: 24,
    motsCles: ['bronchiolite', 'respire vite', 'siffle', 'sifflement', 'encombre', 'vrs', 'tousse bebe'],
    sections: [
      SectionFiche('Qu\'est-ce que c\'est',
          'La bronchiolite est une infection virale des petites bronches qui touche les enfants de '
          'moins de 2 ans, surtout en hiver. Elle commence comme un rhume puis entraîne une toux et '
          'parfois une respiration rapide ou sifflante.'),
      SectionFiche('Que faire',
          'Laver le nez régulièrement, fractionner les repas (plus petits et plus fréquents), '
          'coucher l\'enfant sur le dos et ne pas fumer à proximité. La kinésithérapie respiratoire '
          'n\'est plus recommandée de manière systématique.'),
      SectionFiche('Signes de gravité',
          'Consulter en urgence si l\'enfant respire très vite, si ses côtes ou le creux du cou se '
          'creusent, s\'il boit moins de la moitié de ses biberons, s\'il a des pauses respiratoires, '
          's\'il change de couleur, s\'il a moins de 2 mois ou s\'il est très fatigué.'),
    ],
  ),
  FicheSante(
    id: 'otite',
    titre: 'Mal d\'oreille et otite',
    categorie: 'Symptômes',
    emoji: '👂',
    source: _ameli,
    motsCles: ['otite', 'oreille', 'mal a l oreille', 'touche son oreille', 'ecoulement oreille'],
    sections: [
      SectionFiche('Signes',
          'L\'otite survient souvent après un rhume. Le jeune enfant peut se toucher l\'oreille, '
          'pleurer, mal dormir ou avoir de la fièvre.'),
      SectionFiche('Que faire',
          'Consulter pour un examen des oreilles : seul le médecin peut confirmer une otite et '
          'décider si un antibiotique est utile. Ne rien introduire dans l\'oreille. '
          'Consulter rapidement en cas d\'écoulement de l\'oreille.'),
    ],
  ),
  FicheSante(
    id: 'angine',
    titre: 'Mal de gorge et angine',
    categorie: 'Symptômes',
    emoji: '🗣️',
    source: _ameli,
    motsCles: ['angine', 'mal de gorge', 'gorge', 'avaler', 'amygdales'],
    sections: [
      SectionFiche('Origine',
          'Avant 3 ans, les angines sont presque toujours virales. Après 3 ans, le médecin peut '
          'réaliser un test rapide en consultation pour savoir si un antibiotique est nécessaire.'),
      SectionFiche('Quand consulter',
          'Consulter si le mal de gorge s\'accompagne de fièvre, de difficulté à avaler ou si '
          'l\'enfant refuse de boire. Consulter en urgence s\'il a du mal à respirer ou bave '
          'parce qu\'il ne peut plus avaler.'),
    ],
  ),
  FicheSante(
    id: 'conjonctivite',
    titre: 'Conjonctivite',
    categorie: 'Symptômes',
    emoji: '👁️',
    source: _ameli,
    motsCles: ['conjonctivite', 'oeil rouge', 'yeux rouges', 'yeux qui collent', 'oeil qui coule'],
    sections: [
      SectionFiche('Soins',
          'Nettoyer les yeux plusieurs fois par jour avec du sérum physiologique et une compresse '
          'propre pour chaque œil, de l\'intérieur vers l\'extérieur. Se laver les mains avant et après.'),
      SectionFiche('Quand consulter',
          'Consulter si l\'œil est très rouge et douloureux, si la paupière est gonflée, si l\'enfant '
          'a de la fièvre, s\'il est gêné par la lumière ou s\'il s\'agit d\'un nouveau-né.'),
    ],
  ),
  FicheSante(
    id: 'varicelle',
    titre: 'Varicelle',
    categorie: 'Symptômes',
    emoji: '🔴',
    source: _ameli,
    motsCles: ['varicelle', 'boutons', 'vesicules', 'demangeaisons', 'eruption', 'gratte'],
    sections: [
      SectionFiche('Évolution',
          'La varicelle est une maladie virale contagieuse : des boutons apparaissent par poussées, '
          'deviennent des vésicules puis des croûtes. Elle guérit le plus souvent en 10 à 15 jours.'),
      SectionFiche('Soins',
          'Couper les ongles courts, laver la peau à l\'eau tiède et au savon doux, éviter de gratter. '
          'Les anti-inflammatoires comme l\'ibuprofène sont déconseillés pendant une varicelle '
          '(risque de complications cutanées graves).'),
      SectionFiche('Quand consulter',
          'Consulter si la fièvre est élevée ou persiste, si un bouton devient rouge, chaud et '
          'douloureux, si l\'enfant tousse ou respire mal, ou s\'il est inhabituellement somnolent.'),
    ],
  ),
  FicheSante(
    id: 'constipation',
    titre: 'Constipation',
    categorie: 'Symptômes',
    emoji: '🚽',
    source: _sfp,
    motsCles: ['constipation', 'constipe', 'selles dures', 'pousse', 'caca dur'],
    sections: [
      SectionFiche('Conseils',
          'Faire boire suffisamment et, selon l\'âge, proposer des fruits, des légumes et des '
          'céréales complètes. Chez l\'enfant propre, l\'habituer à aller aux toilettes à heure '
          'régulière, après un repas.'),
      SectionFiche('Quand consulter',
          'Consulter en cas de sang dans les selles, de vomissements, de ventre gonflé, de '
          'constipation chez un nourrisson de moins d\'un mois ou si elle dure plusieurs semaines.'),
    ],
  ),

  // ══ Nourrisson ═════════════════════════════════════════════════════════════
  FicheSante(
    id: 'coliques',
    titre: 'Pleurs et coliques du nourrisson',
    categorie: 'Nourrisson',
    emoji: '😢',
    source: _sfp,
    ageMaxMois: 6,
    motsCles: ['coliques', 'pleure', 'pleurs', 'crie', 'inconsolable', 'ventre bebe'],
    sections: [
      SectionFiche('Pleurs du nourrisson',
          'Les pleurs sont fréquents les premiers mois, souvent en fin de journée, avec un pic '
          'vers 6 semaines puis une diminution vers 3 à 4 mois. Ils ne signifient pas forcément '
          'une douleur.'),
      SectionFiche('Apaiser',
          'Bercer, porter l\'enfant contre soi, réduire les stimulations (lumière, bruit) et '
          'garder des rythmes réguliers. Si vous vous sentez à bout, couchez le bébé sur le dos '
          'dans son lit, sortez de la pièce et demandez de l\'aide : ne jamais secouer un bébé.'),
      SectionFiche('Quand consulter',
          'Consulter si les pleurs s\'accompagnent de fièvre, de vomissements, de refus de boire, '
          'd\'une mauvaise prise de poids, ou s\'ils sont inhabituels et persistants.'),
    ],
  ),
  FicheSante(
    id: 'bebe_secoue',
    titre: 'Ne jamais secouer un bébé',
    categorie: 'Nourrisson',
    emoji: '🚫',
    source: _has,
    ageMaxMois: 24,
    motsCles: ['secouer', 'secoue', 'bebe secoue', 'enerve', 'a bout', 'epuise'],
    sections: [
      SectionFiche('Pourquoi',
          'Secouer un bébé, même quelques secondes, peut provoquer des lésions cérébrales graves '
          'et définitives, voire le décès.'),
      SectionFiche('Si vous êtes à bout',
          'Couchez le bébé sur le dos dans son lit, quittez la pièce quelques minutes pour vous '
          'calmer et appelez un proche ou un professionnel. Un bébé qui pleure en sécurité dans '
          'son lit ne risque rien.'),
    ],
  ),
  FicheSante(
    id: 'regurgitations',
    titre: 'Régurgitations du nourrisson',
    categorie: 'Nourrisson',
    emoji: '🍼',
    source: _sfp,
    ageMaxMois: 18,
    motsCles: ['regurgitation', 'regurgite', 'rejette', 'renvoie', 'reflux', 'rot'],
    sections: [
      SectionFiche('C\'est fréquent',
          'Les régurgitations après les biberons ou les tétées sont fréquentes et le plus souvent '
          'sans gravité chez un bébé qui grossit bien. Elles diminuent avec l\'âge et disparaissent '
          'en général vers 12 à 18 mois.'),
      SectionFiche('Quand consulter',
          'Consulter si les rejets sont en jet, verts ou contiennent du sang, si le bébé pleure '
          'pendant les repas, refuse de boire ou ne prend pas assez de poids.'),
    ],
  ),
  FicheSante(
    id: 'dents',
    titre: 'Poussées dentaires',
    categorie: 'Nourrisson',
    emoji: '🦷',
    source: _ansm,
    ageMinMois: 3,
    ageMaxMois: 36,
    motsCles: ['dent', 'dents', 'poussee dentaire', 'gencive', 'bave', 'mordille'],
    sections: [
      SectionFiche('Soulager',
          'Proposer un anneau de dentition rafraîchi au réfrigérateur (pas au congélateur) et '
          'masser doucement la gencive avec un doigt propre.'),
      SectionFiche('À éviter',
          'Les colliers d\'ambre sont déconseillés en raison du risque d\'étranglement et '
          'd\'étouffement. Une poussée dentaire ne provoque pas de forte fièvre : une fièvre '
          'élevée doit faire chercher une autre cause.'),
    ],
  ),
  FicheSante(
    id: 'erytheme_fessier',
    titre: 'Érythème fessier (fesses rouges)',
    categorie: 'Nourrisson',
    emoji: '🧷',
    source: _sfp,
    ageMaxMois: 36,
    motsCles: ['erytheme fessier', 'fesses rouges', 'irritation couche', 'siege rouge'],
    sections: [
      SectionFiche('Soins',
          'Changer la couche souvent, nettoyer à l\'eau et au savon doux, bien sécher en tamponnant '
          'et laisser les fesses à l\'air quand c\'est possible. Une crème protectrice peut être appliquée.'),
      SectionFiche('Quand consulter',
          'Consulter si l\'irritation persiste plus de quelques jours malgré les soins, s\'il y a '
          'des boutons, des plaies ou de la fièvre.'),
    ],
  ),
  FicheSante(
    id: 'allaitement',
    titre: 'Allaitement maternel',
    categorie: 'Nutrition',
    emoji: '🤱',
    source: _oms,
    ageMaxMois: 24,
    motsCles: ['allaitement', 'allaiter', 'tetee', 'sein', 'lait maternel', 'tire lait'],
    sections: [
      SectionFiche('Recommandations',
          'L\'OMS recommande un allaitement exclusif jusqu\'à 6 mois, puis poursuivi avec une '
          'alimentation diversifiée. L\'allaitement se fait à la demande, jour et nuit.'),
      SectionFiche('Le bébé boit-il assez',
          'Un bébé qui mouille plusieurs couches par jour, a des selles régulières et prend du '
          'poids boit en général suffisamment. Le suivi de l\'allaitement dans l\'application aide '
          'à repérer le rythme des tétées.'),
      SectionFiche('Quand demander de l\'aide',
          'Demander conseil (sage-femme, médecin, consultante en lactation) en cas de douleurs '
          'pendant les tétées, de crevasses, ou si le bébé prend mal du poids.'),
    ],
  ),
  FicheSante(
    id: 'sommeil_sur',
    titre: 'Coucher bébé en sécurité',
    categorie: 'Sommeil',
    emoji: '🛏️',
    source: _spf,
    ageMaxMois: 12,
    motsCles: ['coucher', 'dormir', 'lit', 'mort subite', 'position', 'sur le dos', 'gigoteuse', 'couette'],
    sections: [
      SectionFiche('Les règles',
          'Toujours coucher le bébé sur le dos, dans un lit à barreaux avec un matelas ferme et '
          'adapté, sans oreiller, couette, tour de lit ni peluche. Utiliser une gigoteuse adaptée '
          'à sa taille.'),
      SectionFiche('L\'environnement',
          'Chambre aérée, autour de 18 à 20 °C, sans tabac. Il est recommandé que le bébé dorme '
          'dans la chambre des parents, dans son propre lit, pendant ses premiers mois.'),
    ],
  ),
  FicheSante(
    id: 'sommeil',
    titre: 'Le sommeil de l\'enfant',
    categorie: 'Sommeil',
    emoji: '😴',
    source: _oms,
    // Avant 1 an, c'est la fiche « Coucher bébé en sécurité » qui s'applique.
    ageMinMois: 12,
    motsCles: ['sommeil', 'dort', 'dormir', 'endormir', 'reveil', 'nuit', 'cauchemar', 'sieste'],
    sections: [
      SectionFiche('Durée de sommeil',
          'Les besoins varient selon l\'âge, siestes comprises : environ 11 à 14 heures entre 1 et 2 ans, '
          '10 à 13 heures entre 3 et 5 ans, 9 à 12 heures entre 6 et 12 ans.'),
      SectionFiche('Bien s\'endormir',
          'Des horaires réguliers et un rituel calme (bain, histoire, câlin) aident l\'enfant à '
          's\'endormir. Éviter les écrans dans l\'heure qui précède le coucher et dans la chambre.'),
      SectionFiche('Quand en parler',
          'En parler au pédiatre si les troubles du sommeil persistent, si l\'enfant ronfle fort '
          'avec des pauses respiratoires, ou s\'il est très fatigué dans la journée.'),
    ],
  ),
  FicheSante(
    id: 'ecrans',
    titre: 'Enfants et écrans',
    categorie: 'Prévention',
    emoji: '📱',
    source: _spf,
    motsCles: ['ecran', 'ecrans', 'television', 'tele', 'tablette', 'telephone', 'dessin anime'],
    sections: [
      SectionFiche('Repères',
          'Les recommandations françaises déconseillent les écrans avant 3 ans et conseillent un usage '
          'limité et accompagné ensuite. L\'OMS ne recommande pas de temps d\'écran avant 2 ans '
          'et au plus une heure par jour entre 2 et 4 ans.'),
      SectionFiche('Conseils',
          'Pas d\'écran pendant les repas, avant le coucher ni dans la chambre. Privilégier le jeu, '
          'la lecture et les activités physiques.'),
    ],
  ),

  // ══ Nutrition ══════════════════════════════════════════════════════════════
  FicheSante(
    id: 'hydratation',
    titre: 'Boire suffisamment',
    categorie: 'Nutrition',
    emoji: '🚰',
    source: _spf,
    motsCles: ['boire', 'eau', 'hydrater', 'soif', 'boisson', 'jus', 'soda'],
    sections: [
      SectionFiche('Repères',
          'Chez le nourrisson nourri au lait, le lait couvre les besoins en eau. Ensuite, l\'eau est '
          'la seule boisson indispensable. Les jus de fruits et sodas sont à limiter.'),
      SectionFiche('Par forte chaleur ou fièvre',
          'Proposer à boire plus souvent, sans attendre que l\'enfant le demande.'),
    ],
  ),
  FicheSante(
    id: 'reaction_allergique',
    titre: 'Réaction allergique alimentaire',
    categorie: 'Nutrition',
    emoji: '⚠️',
    source: _sfp,
    motsCles: ['allergie', 'allergique', 'reaction', 'urticaire', 'gonfle', 'plaques', 'boutons apres manger'],
    sections: [
      SectionFiche('Signes',
          'Une allergie alimentaire peut provoquer des plaques rouges qui démangent (urticaire), '
          'un gonflement des lèvres ou des paupières, des vomissements ou des douleurs abdominales '
          'peu après le repas.'),
      SectionFiche('Urgence',
          'Appeler immédiatement le SAMU (190 en Tunisie, 15 en France) en cas de gêne pour respirer, '
          'de voix modifiée, de gonflement de la gorge ou de malaise. Si un stylo d\'adrénaline a été '
          'prescrit, l\'utiliser selon les consignes du médecin.'),
      SectionFiche('Ensuite',
          'Éviter l\'aliment suspecté et consulter : seul un médecin peut confirmer une allergie. '
          'Les allergies confirmées sont enregistrées par le pédiatre dans l\'application.'),
    ],
  ),

  // ══ Médicaments ════════════════════════════════════════════════════════════
  FicheSante(
    id: 'donner_medicament',
    titre: 'Bien donner un médicament à l\'enfant',
    categorie: 'Médicaments',
    emoji: '💊',
    source: _ansm,
    motsCles: ['medicament', 'donner', 'pipette', 'seringue', 'dose', 'oubli', 'vomi le medicament', 'sirop'],
    sections: [
      SectionFiche('Les bons gestes',
          'Utiliser uniquement le dispositif doseur fourni avec le médicament (pipette, cuillère, '
          'seringue) : il est adapté à ce flacon. Ne jamais mélanger les dispositifs de deux médicaments. '
          'Vérifier la dose prescrite, souvent calculée selon le poids.'),
      SectionFiche('Oubli ou vomissement',
          'En cas d\'oubli ou si l\'enfant vomit juste après la prise, ne pas redonner une dose '
          'sans avis : demander conseil au médecin ou au pharmacien.'),
      SectionFiche('Sécurité',
          'Ranger les médicaments hors de portée et de vue des enfants. Ne pas réutiliser un '
          'médicament prescrit pour un autre enfant ou une autre maladie.'),
    ],
  ),
  FicheSante(
    id: 'antibiotiques',
    titre: 'Bon usage des antibiotiques',
    categorie: 'Médicaments',
    emoji: '🦠',
    source: _ameli,
    motsCles: ['antibiotique', 'antibiotiques', 'virus', 'bacterie', 'arreter antibiotique'],
    sections: [
      SectionFiche('Quand sont-ils utiles',
          'Les antibiotiques agissent seulement contre les bactéries. Ils sont inutiles contre les '
          'virus, responsables de la plupart des rhumes, bronchiolites et gastro-entérites.'),
      SectionFiche('Bien les prendre',
          'Respecter la dose, l\'horaire et la durée prescrits, même si l\'enfant va mieux. '
          'Ne pas garder les restes pour plus tard. Signaler une éruption ou une diarrhée importante.'),
    ],
  ),
  FicheSante(
    id: 'apres_vaccin',
    titre: 'Après un vaccin',
    categorie: 'Prévention',
    emoji: '💉',
    source: _spf,
    motsCles: ['vaccin', 'vaccination', 'piqure', 'apres le vaccin', 'rappel'],
    sections: [
      SectionFiche('Réactions fréquentes',
          'Une rougeur, un gonflement ou une douleur au point d\'injection et une fièvre modérée '
          'sont fréquents dans les 24 à 48 heures. Ils disparaissent en général rapidement.'),
      SectionFiche('Quand consulter',
          'Consulter en cas de fièvre élevée, de pleurs inhabituels et prolongés, de malaise ou '
          'de gonflement important. Le calendrier des vaccins est disponible dans le module Vaccination.'),
    ],
  ),

  // ══ Urgences et sécurité ═══════════════════════════════════════════════════
  FicheSante(
    id: 'urgences',
    titre: 'Quand appeler les urgences',
    categorie: 'Urgences',
    emoji: '🚑',
    source: _ameli,
    motsCles: ['urgence', 'urgences', 'samu', '190', '15', 'grave', 'hopital'],
    sections: [
      SectionFiche('Appeler le SAMU',
          'Appeler le 190 (Tunisie) ou le 15 (France) en cas de difficulté à respirer, de lèvres '
          'bleues, de convulsion, de perte de connaissance, d\'enfant qui ne réagit plus, de taches '
          'violacées sur la peau avec fièvre, d\'intoxication, de brûlure étendue ou de traumatisme grave.'),
      SectionFiche('En attendant les secours',
          'Rester avec l\'enfant, suivre les consignes du médecin régulateur et préparer le carnet '
          'de santé et la liste des traitements en cours.'),
    ],
  ),
  FicheSante(
    id: 'etouffement',
    titre: 'Étouffement : les gestes',
    categorie: 'Urgences',
    emoji: '🆘',
    source: _ameli,
    motsCles: ['etouffe', 'etouffement', 'avale de travers', 'fausse route', 'corps etranger', 'ne peut plus respirer', 'heimlich'],
    sections: [
      SectionFiche('Si l\'enfant tousse',
          'S\'il tousse, pleure ou parle, l\'encourager à tousser sans intervenir : la toux est le '
          'meilleur moyen d\'expulser l\'objet.'),
      SectionFiche('Si l\'enfant ne peut plus respirer',
          'Faire appeler immédiatement le SAMU (190 / 15). Nourrisson de moins d\'un an : le placer '
          'à plat ventre sur l\'avant-bras, tête plus basse que le corps, et donner jusqu\'à 5 tapes '
          'dans le dos, puis 5 compressions sur le thorax. Enfant plus grand : 5 tapes dans le dos '
          'puis 5 compressions abdominales. Répéter jusqu\'à l\'arrivée des secours.'),
    ],
  ),
  FicheSante(
    id: 'intoxication',
    titre: 'Intoxication et accidents domestiques',
    categorie: 'Urgences',
    emoji: '☠️',
    source: _spf,
    motsCles: ['avale', 'intoxication', 'produit menager', 'javel', 'medicaments avales', 'poison', 'accident', 'chute', 'fenetre', 'noyade'],
    sections: [
      SectionFiche('En cas d\'ingestion',
          'Si l\'enfant a avalé un produit ou un médicament, appeler immédiatement le SAMU (190 / 15) '
          'ou un centre antipoison. Ne pas le faire vomir, ne rien lui donner à boire, et garder '
          'l\'emballage du produit.'),
      SectionFiche('Prévenir',
          'Ranger produits ménagers et médicaments en hauteur et sous clé, sécuriser fenêtres et '
          'escaliers, ne jamais laisser un enfant seul dans le bain, même quelques secondes.'),
    ],
  ),
  FicheSante(
    id: 'brulure',
    titre: 'Brûlure',
    categorie: 'Urgences',
    emoji: '🔥',
    source: _ameli,
    motsCles: ['brulure', 'brule', 'eau chaude', 'four', 'casserole'],
    sections: [
      SectionFiche('Premier geste',
          'Refroidir immédiatement la brûlure sous l\'eau tempérée (environ 15 °C) pendant au moins '
          '15 minutes. Ne pas appliquer de glace, de corps gras ni de remède maison.'),
      SectionFiche('Quand consulter',
          'Consulter si la brûlure est plus grande que la paume de la main de l\'enfant, si elle '
          'touche le visage, les mains, les pieds ou les parties génitales, s\'il y a des cloques, '
          'ou chez un nourrisson. Appeler le SAMU si elle est étendue.'),
    ],
  ),
  FicheSante(
    id: 'choc_tete',
    titre: 'Chute et choc à la tête',
    categorie: 'Urgences',
    emoji: '🤕',
    source: _sfp,
    motsCles: ['chute', 'tombe', 'tete', 'cogne', 'bosse', 'choc'],
    sections: [
      SectionFiche('Surveiller',
          'Après un choc à la tête, surveiller l\'enfant pendant 24 à 48 heures : comportement, '
          'éveil, vomissements. Une bosse seule chez un enfant qui joue normalement est souvent bénigne.'),
      SectionFiche('Signes d\'urgence',
          'Appeler le SAMU (190 / 15) en cas de perte de connaissance, de vomissements répétés, '
          'de somnolence inhabituelle, de convulsion, de comportement anormal, d\'écoulement par '
          'le nez ou l\'oreille, ou chez un nourrisson après une chute importante.'),
    ],
  ),
  FicheSante(
    id: 'soleil',
    titre: 'Soleil et fortes chaleurs',
    categorie: 'Prévention',
    emoji: '☀️',
    source: _spf,
    motsCles: ['soleil', 'chaleur', 'canicule', 'coup de chaleur', 'creme solaire', 'plage'],
    sections: [
      SectionFiche('Protéger du soleil',
          'Éviter l\'exposition directe des bébés au soleil. Pour les enfants : chapeau, vêtements '
          'couvrants, lunettes, crème solaire à indice élevé renouvelée régulièrement, et pas de '
          'sortie aux heures les plus chaudes.'),
      SectionFiche('Fortes chaleurs',
          'Faire boire souvent, garder l\'enfant au frais et ne jamais le laisser dans une voiture. '
          'Consulter en urgence en cas de fièvre élevée, de somnolence, de vomissements ou de '
          'peau chaude et sèche.'),
    ],
  ),
];
