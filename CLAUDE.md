# CLAUDE.md — contexte pour les futurs agents

Ce fichier oriente tout agent (Claude ou autre) qui reprend ce projet.

## Le projet

House For You — app de recherche immobilière mobile-first (Flutter + Supabase), lancée pour la Belgique francophone.

**La documentation officielle du dossier [`/docs`](docs/README.md) est la seule source de vérité produit et technique du projet**, à consulter avant toute décision et à maintenir à jour en continu — voir `docs/README.md` pour l'index complet. `docs/architecture-mvp.md` est un document historique (cahier des charges initial), conservé pour la trace mais supersédé par `docs/TECH_ARCHITECTURE.md`, `docs/DATABASE_PLAN.md` et `docs/PRODUCT_SPEC.md`.

## Règles de travail

- **Une seule étape à la fois.** Le plan (`docs/ROADMAP.md`) définit l'ordre exact et l'état de chaque étape. Ne pas anticiper une étape future sans validation explicite d'Hugo.
- **Mock avant Supabase.** Tant que l'étape "bascule Supabase" (10) n'est pas atteinte, toute nouvelle fonctionnalité data passe par une interface de repository (`lib/data/repositories/`) + une implémentation mock (`lib/data/datasources/mock/`). Ne jamais coder un écran contre une implémentation concrète directement.
- **Pas de secret dans l'app.** Seule la clé `anon` Supabase (publique) peut vivre dans `.env`/`.env.example`. Jamais de `service_role key` côté client.
- **Design system centralisé.** Toute couleur/espacement/typo passe par `lib/core/theme/` (détail dans `docs/DESIGN_SYSTEM.md`). Tout bouton/carte/chip réutilise `lib/core/widgets/` plutôt que des styles inline.
- **Accès invité par défaut.** Aucune action ne doit forcer une connexion au lancement. Seules les actions protégées (favori, contact, demande de visite, alerte) déclenchent la porte d'authentification, via `requireAuth()` (`lib/core/auth/auth_guard.dart`) — voir `docs/UX_RULES.md` section 14.
- **Commits réguliers, une fonctionnalité à la fois.** Éviter les commits fourre-tout.
- **Documentation mise à jour avant chaque commit de fonctionnalité.** Toute fonctionnalité validée (développée, testée) doit mettre à jour les documents `/docs` concernés — au minimum `PRODUCT_SPEC.md`, `ROADMAP.md`, `CHANGELOG.md`, et `DECISIONS.md` si un choix important a été fait — **avant** le commit qui la clôt, dans le même commit que le code. Voir `docs/CONTRIBUTING.md` section 6 pour le détail du processus.
- **Aucune règle d'UX ne se casse silencieusement.** Toute évolution qui s'écarte d'une règle de `docs/UX_RULES.md` doit d'abord avoir une entrée dans `docs/DECISIONS.md` expliquant pourquoi.

## Contraintes d'environnement connues

Le projet doit vivre sur un volume supportant les liens symboliques (APFS/HFS+/ext4...) — exFAT est incompatible avec les builds iOS/macOS (CocoaPods échoue sur les liens symboliques de `ios/Flutter/ephemeral/`). Voir `docs/TECH_ARCHITECTURE.md` section 13.

Si ce projet est repris depuis un environnement sandbox équivalent à celui de l'étape 0 : l'accès réseau à `pub.dev`, `storage.googleapis.com` et `dl.google.com` peut être bloqué par l'allowlist réseau, ce qui empêche d'installer/exécuter le SDK Flutter (`flutter pub get`, `flutter analyze`, `flutter test`, `flutter run` échoueront). `github.com` (clone git), `pypi.org` et `registry.npmjs.org` fonctionnent en revanche. Dans ce cas, écrire/modifier le code reste possible, mais la vérification (analyze/test/build) doit être déléguée à Hugo en local, ou à un environnement avec accès réseau complet.

## Où trouver quoi

Voir `docs/README.md` pour l'index complet et l'articulation entre les documents. Repères rapides :

- Vision produit, écrans, fonctionnalités en détail : `docs/PRODUCT_SPEC.md`.
- Étapes de développement, état actuel : `docs/ROADMAP.md`.
- Règles UX non négociables (gestes, navigation, transitions) : `docs/UX_RULES.md`.
- Couleurs, typographie, composants, animations : `docs/DESIGN_SYSTEM.md`.
- Arborescence Flutter, state management, préchargement/performance : `docs/TECH_ARCHITECTURE.md`.
- Schéma de base de données, RLS, rôles : `docs/DATABASE_PLAN.md`.
- Pourquoi tel choix (architecture, UX, package) : `docs/DECISIONS.md`.
- Idées non planifiées : `docs/BACKLOG.md`.
- Conventions Git/Flutter/tests : `docs/CONTRIBUTING.md`.
