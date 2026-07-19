import '../../models/agency.dart';

/// Données fictives — au moins 3 agences, réalistes pour la Belgique
/// francophone. Remplacées par Supabase à l'étape 10 du plan (bascule
/// Supabase), sans changement côté UI.
final List<Agency> mockAgencies = [
  Agency(
    id: 'agency-1',
    name: 'Immo Delacroix',
    description:
        'Agence bruxelloise spécialisée dans les appartements et maisons de '
        'standing, active depuis 1998.',
    logoUrl: 'https://picsum.photos/seed/agency1/200/200',
    address: 'Avenue Louise 149',
    postalCode: '1050',
    city: 'Bruxelles',
    coverageArea: 'Bruxelles-Capitale',
    specialties: const ['Appartements', 'Résidentiel haut de gamme'],
    phone: '+32 2 123 45 67',
    email: 'contact@immodelacroix.be',
    website: 'https://immodelacroix.be',
    verified: true,
    createdAt: DateTime(2020, 3, 12),
  ),
  Agency(
    id: 'agency-2',
    name: 'Agence du Parc',
    description:
        'Agence familiale namuroise, experte des maisons avec jardin et des '
        'propriétés en périphérie.',
    logoUrl: 'https://picsum.photos/seed/agency2/200/200',
    address: 'Rue de Fer 22',
    postalCode: '5000',
    city: 'Namur',
    coverageArea: 'Province de Namur',
    specialties: const ['Maisons', 'Terrains'],
    phone: '+32 81 22 33 44',
    email: 'info@agenceduparc.be',
    website: 'https://agenceduparc.be',
    verified: true,
    createdAt: DateTime(2016, 6, 1),
  ),
  Agency(
    id: 'agency-3',
    name: 'Wallonie Immo Conseil',
    description: "Réseau d'agents indépendants couvrant Liège et sa région, "
        'spécialisé en location et primo-accession.',
    logoUrl: 'https://picsum.photos/seed/agency3/200/200',
    address: 'Boulevard d\'Avroy 78',
    postalCode: '4000',
    city: 'Liège',
    coverageArea: 'Province de Liège',
    specialties: const ['Location', 'Primo-accédants'],
    phone: '+32 4 987 65 43',
    email: 'contact@wic-immo.be',
    website: 'https://wic-immo.be',
    verified: false,
    createdAt: DateTime(2022, 1, 20),
  ),
];
