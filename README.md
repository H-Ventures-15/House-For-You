# House For You

Application mobile de recherche immobilière, mobile-first, pour la Belgique francophone (structure prête pour NL/EN).

Voir [`docs/architecture-mvp.md`](docs/architecture-mvp.md) pour l'architecture complète, le schéma de base de données et l'ordre de développement du MVP.

## Statut

**Étape 0 — Setup.** L'app compile et affiche une page de confirmation (comptage des biens/agences fictifs chargés via les datasources mock). Aucune connexion Supabase réelle, aucun écran final n'est encore développé — c'est volontaire (voir plan, étape 1+).

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

Le détail complet de l'arborescence et des choix d'architecture est documenté dans `architecture-mvp.md`.

## Décisions techniques (étape 0)

- **State management** : Riverpod — pas de `BuildContext` requis dans la logique métier, providers facilement testables.
- **Navigation** : GoRouter — routes déclaratives, prêt pour le deep-linking futur.
- **Modèles sans codegen** : classes Dart manuelles (`fromJson`/`toJson`/`copyWith` écrits à la main) plutôt que `freezed`/`json_serializable`, pour éviter une dépendance à `build_runner` dès le MVP.
- **Mock-first** : chaque repository a une interface abstraite ; l'implémentation mock (données fictives) est branchée via Riverpod dans `lib/data/providers/repository_providers.dart`. Brancher Supabase plus tard = changer uniquement ce fichier.
- **`.env` jamais commité** : seule la clé publique `anon` de Supabase y vivra (voir `.env.example`) — la sécurité réelle repose sur les policies RLS, pas sur le secret de cette clé.

## Note environnement

Ce scaffold a été rédigé et versionné depuis un environnement sandbox sans accès réseau à l'infrastructure Flutter/Dart (pub.dev, storage.googleapis.com). Les commandes `flutter pub get` / `flutter analyze` / `flutter test` n'ont donc **pas pu être exécutées dans cet environnement** — à exécuter en priorité en local avant toute suite de développement (voir le message de livraison de l'étape 0 pour le détail).
