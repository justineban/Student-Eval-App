class Criterion {
  final String key;
  final String label;
  final Map<int, String> levelDescriptions; // 2,3,4,5 => description
  const Criterion({
    required this.key,
    required this.label,
    required this.levelDescriptions,
  });
}

const criteriaList = <Criterion>[
  Criterion(
    key: 'punctuality',
    label: 'Punctuality',
    levelDescriptions: {
      2: 'Was late or absent for most sessions. Llegó tarde o se ausentó frecuentemente.',
      3: 'Frequently arrived late or missed sessions. Llegó tarde con mucha frecuencia.',
      4: 'Was generally punctual and attended most sessions. Generalmente puntual.',
      5: 'Was consistently punctual and attended all sessions. Siempre puntual.',
    },
  ),
  Criterion(
    key: 'contributions',
    label: 'Contributions',
    levelDescriptions: {
      2: 'Contributed little or nothing. Aportes casi nulos.',
      3: 'Participated occasionally. Participación ocasional.',
      4: 'Made several useful contributions. Varios aportes útiles.',
      5: 'Provided enriching contributions throughout. Aportes enriquecedores.',
    },
  ),
  Criterion(
    key: 'commitment',
    label: 'Commitment',
    levelDescriptions: {
      2: 'Showed little commitment to tasks. Poco compromiso.',
      3: 'Commitment inconsistent, affected progress. Compromiso irregular.',
      4: 'Responsible most of the time. Responsable la mayor parte.',
      5: 'Consistently highly committed. Siempre muy comprometido.',
    },
  ),
  Criterion(
    key: 'attitude',
    label: 'Attitude',
    levelDescriptions: {
      2: 'Negative or indifferent attitude. Actitud negativa/indiferente.',
      3: 'Sometimes positive, limited impact. A veces positiva.',
      4: 'Mostly positive and helpful. Mayormente positiva.',
      5: 'Always positive and quality-focused. Siempre positiva.',
    },
  ),
];

const allowedCriterionLevels = [2, 3, 4, 5];
