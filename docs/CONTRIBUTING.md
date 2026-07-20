# CONTRIBUTING — House For You

> **Statut : vivant.** Règles de développement. S'appliquent à tout contributeur — humain ou agent. Ce document est référencé par [CLAUDE.md](../CLAUDE.md) (racine du dépôt), qui reste la source des règles de travail à très haut niveau (une étape à la fois, mock avant Supabase...) ; ce document-ci détaille le *comment* : conventions concrètes de code, Git, tests.
>
> Dernière mise à jour : 2026-07-20.

---

## 1. Qualité obligatoire avant tout commit

Ces trois commandes doivent passer **sans aucune erreur ni avertissement** avant chaque commit — jamais d'exception :

```bash
dart format lib/ test/
flutter analyze
flutter test
```

La CI GitHub Actions (`.github/workflows/ci.yml`) exécute `flutter format --set-exit-if-changed .`, `flutter analyze` et `flutter test` sur chaque push et pull request vers `main` — un push qui casse l'une de ces trois commandes casse la CI. Ne jamais contourner (`--no-verify`, ignorer un avertissement d'analyse) sans une raison documentée dans le commit concerné.

**Documentation** — depuis la mise en place de `/docs` (2026-07-20), une quatrième vérification s'ajoute avant tout commit de fonctionnalité : **la documentation concernée est-elle à jour ?** Voir section 6.

## 2. Convention des commits

Format : `type: description courte en français, à l'impératif` suivi, si nécessaire, d'un corps expliquant le **pourquoi** (pas le quoi — le diff montre déjà le quoi).

**Types utilisés dans ce projet** (observés dans l'historique réel, `git log`) :

| Type | Usage |
|---|---|
| `feat` | Nouvelle fonctionnalité |
| `fix` | Correction de bug |
| `perf` | Optimisation de performance |
| `chore` | Tâche d'infrastructure (génération de plateformes, setup...) |
| `docs` | Documentation uniquement |
| `test` | Ajout/modification de tests sans changement de comportement |
| `refactor` | Changement de structure sans changement de comportement |

**Exemple réel** (`3c3759c`) :

```
perf: fluidité du swipe façon TikTok (sous-étape 2.1)

Ressort de fin de geste plus vif (SnappyPageScrollPhysics : masse plus
faible, raideur plus élevée que le défaut Flutter) sur le feed vertical,
la galerie photo de chaque carte et la galerie de la fiche détail...
```

Signature : chaque commit généré avec l'assistance d'un agent porte `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`.

**Un commit = une fonctionnalité ou un correctif cohérent.** Éviter les commits fourre-tout (règle déjà posée dans [CLAUDE.md](../CLAUDE.md)).

## 3. Convention des branches

**Pratique actuelle** : développement direct sur `main` (projet en phase de construction initiale rapide, un seul contributeur actif). Chaque commit est vérifié (section 1) avant d'être poussé.

**Convention cible**, à appliquer dès que le rythme de contribution le justifie (plusieurs contributeurs, ou changements plus risqués) :

- `main` — toujours déployable, toujours vert en CI.
- `feature/<nom-court>` — une fonctionnalité de la [ROADMAP.md](ROADMAP.md) (ex. `feature/recherche-guidee`).
- `fix/<nom-court>` — un correctif.
- Pull request obligatoire vers `main` dès que la branche directe cesse d'être la norme — la CI existante (`ci.yml`) est déjà déclenchée sur `pull_request`, prête pour ce basculement.

## 4. Convention Flutter

- **Design system centralisé** — toute couleur/espacement/typographie passe par `lib/core/theme/`. Jamais de `Color(0x...)`, de nombre magique d'espacement, ou de `TextStyle` ad hoc dans un écran (exception locale documentée : le fond `#0B0B0C` du feed, voir [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) section 2 et [DECISIONS.md](DECISIONS.md) ADR-013).
- **Composants réutilisables** — tout bouton/carte/chip réutilise `lib/core/widgets/` plutôt qu'un style inline répété.
- **Mock avant Supabase** — toute nouvelle fonctionnalité data passe par une interface de repository (`lib/data/repositories/`) + une implémentation mock (`lib/data/datasources/mock/`). Jamais un écran codé contre une implémentation concrète.
- **Pas de secret dans l'app** — seule la clé `anon` Supabase (publique) pourra un jour vivre dans `.env`/`.env.example`. Jamais de `service_role key` côté client.
- **Accès invité par défaut** — aucune action ne force une connexion au lancement. Seules les actions protégées (favori, contact, visite, alerte) déclenchent la porte d'authentification, via `requireAuth()` (`lib/core/auth/auth_guard.dart`).
- **Modèles Dart manuels** — `fromJson`/`toJson`/`copyWith` écrits à la main (voir [DECISIONS.md](DECISIONS.md) ADR-010), pas de `freezed`/`json_serializable` sans decision documentée qui change cette convention.
- **Commentaires** — seulement quand le *pourquoi* n'est pas évident (contrainte cachée, contournement d'un bug précis, comportement surprenant). Jamais un commentaire qui répète ce que le nom du symbole dit déjà.
- **Pas d'abstraction prématurée** — pas de couche/pattern ajouté « au cas où » ; trois lignes similaires valent mieux qu'une abstraction anticipée sur une hypothèse future.

## 5. Tests obligatoires

Toute fonctionnalité interactive nouvelle doit être couverte par au moins un test — en particulier :

- Toute règle de geste ou de zone d'interaction (voir [UX_RULES.md](UX_RULES.md)) doit avoir un test qui la verrouille (voir `test/property_card_gestures_test.dart` comme référence).
- Tout état dérivé (compteur, résumé calculé) doit avoir un test qui vérifie sa valeur exacte plutôt qu'une approximation — l'historique du projet montre qu'un test trop permissif (`findsWidgets` plutôt qu'une valeur exacte) peut laisser passer un vrai bug (voir [DECISIONS.md](DECISIONS.md) ADR-006).

**Piège connu** : tout test qui rend un `Image.network` doit être enveloppé dans `mockNetworkImagesFor` (package `network_image_mock`) — sans ça, `flutter test` bloque toutes les requêtes HTTP et le test échoue avec un minuteur en attente (`Timer is still pending`), pas une erreur explicite sur l'image elle-même.

**Piège connu** : une feuille modale personnalisée (`showGeneralDialog`) n'a pas d'ancêtre `Material` par défaut — tout `TextField`/`InkWell` à l'intérieur y échouera silencieusement en debug (`No Material widget found`) tant qu'un `Material` explicite n'enveloppe pas le contenu. Voir `lib/core/widgets/blurred_modal_sheet.dart`.

## 6. Documentation — mise à jour obligatoire avant commit

Depuis le 2026-07-20, la documentation de `/docs` est la seule source de vérité produit/technique du projet. **Avant chaque commit qui clôt une fonctionnalité validée** :

1. La fonctionnalité est développée.
2. Elle est testée (`flutter test` passe).
3. **Les documents concernés sont mis à jour** — au minimum :
   - [PRODUCT_SPEC.md](PRODUCT_SPEC.md) si un écran ou une fonctionnalité change de comportement visible.
   - [ROADMAP.md](ROADMAP.md) — état/date/commentaires de l'étape ou sous-étape concernée.
   - [CHANGELOG.md](CHANGELOG.md) — nouvelle entrée (Ajouts/Corrections/Optimisations).
   - [DECISIONS.md](DECISIONS.md) si un choix important (architecture, UX, package) a été fait ou qu'une règle d'[UX_RULES.md](UX_RULES.md) a été affinée/cassée.
   - [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) si une couleur, un espacement, une animation ou un composant a été ajouté.
   - [DATABASE_PLAN.md](DATABASE_PLAN.md)/[API_PLAN.md](API_PLAN.md) si un modèle de données ou un contrat futur évolue.
4. Le commit est créé (documentation + code dans le même commit, jamais un commit de code suivi séparément d'un commit de documentation).
5. Le commit est poussé sur GitHub.

Si le code et la documentation divergent malgré tout (ça arrive), corriger la documentation **immédiatement** en la découvrant — jamais « plus tard ». Voir [DECISIONS.md](DECISIONS.md) ADR-007 pour un exemple concret de correction de documentation en cours de développement.

## 7. Environnement

- Le projet doit vivre sur un volume supportant les liens symboliques (voir [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md) section 13 — exFAT est incompatible avec les builds iOS/macOS).
- `flutter pub get` puis `flutter gen-l10n` avant tout premier lancement (voir [README.md](README.md) racine du dépôt).

---

**Documents liés** : [../CLAUDE.md](../CLAUDE.md) · [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md) · [DECISIONS.md](DECISIONS.md) · [CHANGELOG.md](CHANGELOG.md)
