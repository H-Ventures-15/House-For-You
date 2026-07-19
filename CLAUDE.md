# CLAUDE.md — contexte pour les futurs agents

Ce fichier oriente tout agent (Claude ou autre) qui reprend ce projet.

## Le projet

House For You — app de recherche immobilière mobile-first (Flutter + Supabase), lancée pour la Belgique francophone. Le document de référence pour toute décision d'architecture est **`docs/architecture-mvp.md`** (versionné dans ce dépôt) — toujours le consulter avant de modifier le schéma de données, la navigation ou l'ordre de développement.

## Règles de travail

- **Une seule étape à la fois.** Le plan (section 9 d'`architecture-mvp.md`) définit l'ordre exact. Ne pas anticiper une étape future sans validation explicite d'Hugo.
- **Mock avant Supabase.** Tant que l'étape "bascule Supabase" n'est pas atteinte, toute nouvelle fonctionnalité data passe par une interface de repository (`lib/data/repositories/`) + une implémentation mock (`lib/data/datasources/mock/`). Ne jamais coder un écran contre une implémentation concrète directement.
- **Pas de secret dans l'app.** Seule la clé `anon` Supabase (publique) peut vivre dans `.env`/`.env.example`. Jamais de `service_role key` côté client.
- **Design system centralisé.** Toute couleur/espacement/typo passe par `lib/core/theme/`. Tout bouton/carte/chip réutilise `lib/core/widgets/` plutôt que des styles inline.
- **Accès invité par défaut.** Aucune action ne doit forcer une connexion au lancement. Seules les actions protégées (favori, contact, demande de visite, alerte) déclenchent l'écran de connexion, via le provider `authStateProvider` (`lib/core/auth/auth_guard.dart`).
- **Commits réguliers, une fonctionnalité à la fois.** Éviter les commits fourre-tout.

## Contraintes d'environnement connues

Si ce projet est repris depuis un environnement sandbox équivalent à celui de l'étape 0 : l'accès réseau à `pub.dev`, `storage.googleapis.com` et `dl.google.com` peut être bloqué par l'allowlist réseau, ce qui empêche d'installer/exécuter le SDK Flutter (`flutter pub get`, `flutter analyze`, `flutter test`, `flutter run` échoueront). `github.com` (clone git), `pypi.org` et `registry.npmjs.org` fonctionnent en revanche. Dans ce cas, écrire/modifier le code reste possible, mais la vérification (analyze/test/build) doit être déléguée à Hugo en local, ou à un environnement avec accès réseau complet.

## Où trouver quoi

- Schéma de base de données, RLS, rôles : `docs/architecture-mvp.md`, section 5.
- Arborescence Flutter complète et raisons des choix : `docs/architecture-mvp.md`, sections 1 et 2.
- Ordre de développement et ce qui est volontairement reporté : `docs/architecture-mvp.md`, sections 9 et 10.
