# House For You

Application mobile de recherche immobilière, mobile-first, pour la Belgique francophone (structure prête pour NL/EN).

## Documentation

La documentation officielle et à jour du projet vit dans [`/docs`](docs/README.md) — c'est la seule source de vérité produit et technique, maintenue à chaque fonctionnalité livrée. À lire en priorité :

- [`docs/PRODUCT_SPEC.md`](docs/PRODUCT_SPEC.md) — vision, écrans, fonctionnalités en détail.
- [`docs/ROADMAP.md`](docs/ROADMAP.md) — étapes de développement, état actuel.
- [`docs/TECH_ARCHITECTURE.md`](docs/TECH_ARCHITECTURE.md) — architecture Flutter complète.
- [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md) — conventions de développement.

Voir [`docs/README.md`](docs/README.md) pour l'index complet des douze documents.

## Statut

Étapes 0, 1, 2 et 2.1 terminées : setup, coquille de navigation à 4 onglets, feed Découvrir plein écran (galerie, fiche détail, système de filtres complet), fluidité du swipe façon TikTok. Aucune connexion Supabase réelle — toutes les données sont mock, c'est volontaire (voir [`docs/ROADMAP.md`](docs/ROADMAP.md)).

## Prérequis

- Flutter SDK ≥ 3.22 (canal stable), Dart ≥ 3.3
- Un simulateur/émulateur iOS ou Android, ou un appareil physique

## Lancer le projet

```bash
# 1. Récupérer les dépendances
flutter pub get

# 2. Générer les fichiers de localisation (lib/l10n/app_localizations.dart)
flutter gen-l10n

# 3. Copier la config d'environnement (optionnel au MVP — mode mock par défaut)
cp .env.example .env

# 4. Lancer l'app (mode mock, aucune donnée réelle)
flutter run
```

## Vérifications

```bash
flutter format --set-exit-if-changed .
flutter analyze
flutter test
```

Ces trois commandes sont aussi exécutées automatiquement par la CI GitHub Actions sur chaque push/PR (voir `.github/workflows/ci.yml`).

## Structure du projet

```
lib/
├── core/        # thème, router, widgets partagés, services transversaux (analytics, auth guard)
├── data/        # modèles, interfaces de repositories, datasources (mock aujourd'hui, Supabase plus tard)
├── features/    # un dossier par fonctionnalité (découvrir, recherche, favoris, profil, etc.)
└── l10n/        # fichiers .arb (fr rempli, nl/en présents mais vides)
```

Le détail complet de l'arborescence et des choix d'architecture est documenté dans [`docs/TECH_ARCHITECTURE.md`](docs/TECH_ARCHITECTURE.md). Les décisions techniques (pourquoi Riverpod, pourquoi GoRouter, pourquoi pas de codegen...) sont dans [`docs/DECISIONS.md`](docs/DECISIONS.md).

- **`.env` jamais commité** : seule la clé publique `anon` de Supabase y vivra (voir `.env.example`) — la sécurité réelle repose sur les policies RLS, pas sur le secret de cette clé.

## Environnement de développement

Le projet doit vivre sur un volume supportant les liens symboliques (APFS/HFS+/ext4...) — **exFAT est incompatible** avec les builds iOS/macOS (CocoaPods échoue sur les liens symboliques de `ios/Flutter/ephemeral/`). Voir [`docs/TECH_ARCHITECTURE.md`](docs/TECH_ARCHITECTURE.md) section 13.
