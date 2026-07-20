# CHANGELOG — House For You

> **Statut : vivant.** Historique complet du projet. Une entrée doit être ajoutée pour **chaque** fonctionnalité validée, avant le commit qui la clôt — voir [CONTRIBUTING.md](CONTRIBUTING.md). Format inspiré de [Keep a Changelog](https://keepachangelog.com/) (catégories Ajouts / Corrections / Optimisations, comme demandé), adapté à un projet en construction (pas encore de version publiée).
>
> Version d'app actuelle (`pubspec.yaml`) : `0.1.0+1` — aucune version n'a encore été taguée sur GitHub, tout se trouve sous « Non publié » jusqu'à la première mise en production réelle (fin de bascule Supabase, étape 10).

---

## [Non publié] — 0.1.0

### 2026-07-20 — Gestes & interactions naturelles (sous-étape 2.2 / « Sprint 2.3 »)

**Ajouts**
- Appui long sur le média d'une carte du feed : masque le chrome (gradient haut, bloc prix/titre/description, indicateur photo, badge agence, rail favori/partager) et la barre de recherche flottante, transition 180 ms ; tout réapparaît exactement dans l'état précédent au relâchement (`lib/core/widgets/property_card.dart`, `lib/features/discover/discover_screen.dart`).
- Retour haptique léger (`HapticFeedback.lightImpact()`) sur le double tap favori, uniquement quand l'action aboutit.
- Labels sémantiques (`Semantics(button: true, label: ...)`) sur les boutons favori/partager, la zone d'ouverture de fiche et les boutons de la fiche détail (retour/favori/partage), pour les lecteurs d'écran.
- Tests : `test/property_card_gestures_test.dart` (masquage/restauration du chrome à l'appui long, non-déclenchement du favori/de l'ouverture de fiche pendant l'appui, labels sémantiques), `test/discover_feed_test.dart` (restauration de l'état précédent de la barre flottante après un appui long), `test/property_detail_dismiss_test.dart` (scroll vertical du contenu de la fiche sans fermeture accidentelle).

**Non modifié (revérifié sans régression)**
- Double tap favori, tap simple sur le bloc texte, swipe horizontal (galerie), swipe vertical (feed), fermeture de fiche par swipe droite : gestes déjà livrés à l'étape 2/2.1, comportement et tests inchangés.
- Fluidité de la sous-étape 2.1 (`SnappyPageScrollPhysics`, `RepaintBoundary`, `AutomaticKeepAliveClientMixin`, précache des médias voisins) : code non touché.

**Décision produit**
- La bottom bar de navigation n'est pas masquée par l'appui long (conflit avec une règle UX déjà posée et frontière architecturale shell/feature) — voir [DECISIONS.md](DECISIONS.md) ADR-015.

### 2026-07-20 — Documentation officielle

**Ajouts**
- Dossier `/docs` complet : `README.md`, `PRODUCT_SPEC.md`, `ROADMAP.md`, `UX_RULES.md`, `DESIGN_SYSTEM.md`, `TECH_ARCHITECTURE.md`, `DATABASE_PLAN.md`, `API_PLAN.md`, `BACKLOG.md`, `DECISIONS.md`, `CONTRIBUTING.md`, ce `CHANGELOG.md`.

### 2026-07-20 — Fluidité du swipe façon TikTok (sous-étape 2.1) — `3c3759c`

**Ajouts**
- `SnappyPageScrollPhysics` (`lib/core/widgets/snappy_page_physics.dart`) — ressort de fin de geste personnalisé, appliqué au feed vertical, à la galerie photo de chaque carte et à la galerie de la fiche détail.
- `RepaintBoundary` dédié par carte du feed.
- Test `test/snappy_page_physics_test.dart`.

**Optimisations**
- Préchargement des médias voisins étendu à 3 éléments par voisin (au lieu de 2), erreurs de précache rendues silencieuses.
- `allowImplicitScrolling: true` activé sur les trois `PageView` de l'app (bénéfice réel : accessibilité VoiceOver/TalkBack — voir [DECISIONS.md](DECISIONS.md) pour la piste de performance explorée puis écartée).

### 2026-07-20 — Système de filtres premium — `4461646`

**Ajouts**
- Feuille de filtres plein écran (`lib/features/discover/filters/`) : localisation avec suggestions instantanées + rayon, type de transaction, budget (slider double poignée + saisie manuelle), grille de types de bien, chambres/salles de bain, surfaces habitable/terrain, certificat énergétique, grille de caractéristiques (17 options), état du bien, date de publication, tri, section « Ambiance de vie », recherches enregistrées.
- `SearchFilters` étendu (localisation, rayon, types multiples, surfaces, PEB, caractéristiques, état, date de publication, tri, ambiances) et `matches()` réellement câblé sur les données mock.
- `searchFiltersControllerProvider` et `filteredPropertyCountProvider` (Riverpod) — le feed applique désormais réellement les filtres actifs, le bouton « Afficher N biens » affiche un compte réellement calculé.
- `showBlurredModalSheet` (`lib/core/widgets/blurred_modal_sheet.dart`) — feuille modale plein écran réutilisable avec flou de fond progressif.
- Quelques biens mock enrichis de caractéristiques manquantes (parking, climatisation, cuisine équipée...) pour que chaque filtre ait au moins un résultat de démonstration.

**Corrections**
- Bug réel : la feuille de filtres (route `showGeneralDialog` personnalisée) n'avait pas d'ancêtre `Material`, ce qui cassait silencieusement `TextField`/`InkWell` en son sein — découvert par les tests, corrigé avant merge.

### 2026-07-20 — Polish premium du feed — `3bbb3fe`

**Ajouts**
- Barre de recherche flottante (`FloatingSearchBar`, verre dépoli) au-dessus du feed, masquage/réapparition animés et suivis en continu selon le sens du scroll.
- Recherches enregistrées (mock) accessibles depuis la barre flottante.
- Double tap sur le média d'une carte : ajoute/retire le favori avec animation de cœur ; zones de gestes strictement séparées entre le média (like) et le bloc texte (ouverture de la fiche).
- Fermeture de la fiche détail par swipe horizontal avec effet « balancer » (translation + rotation, suivi du doigt en direct).
- Finitions : ombres sur les boutons flottants et le badge agence, dégradés à paliers, léger parallax entre les cartes du feed, micro-animation de rebond sur le bouton favori.
- Tests `test/property_card_gestures_test.dart`, `test/property_detail_dismiss_test.dart`.

### 2026-07-19 → 2026-07-20 — Feed Découvrir (base) — `09be1a8`

**Ajouts**
- Feed vertical plein écran (`DiscoverScreen`), un bien par page, galerie photo horizontale indépendante par carte.
- Fiche détail complète (`PropertyDetailScreen`) : galerie, description, localisation, caractéristiques, équipements, énergie (placeholder), bloc agence, boutons favori/contacter/partager.
- Favoris et contact protégés par `requireAuth()` (porte d'authentification par SnackBar tant que l'écran de connexion n'existe pas).
- Partage natif (`share_plus`).
- Tracking basique (`AnalyticsService` mock) : impressions, ouverture de fiche, partage, favoris.
- `HouseForYouApp` porte désormais son propre `ProviderScope` (autonome, testable seule).

**Corrections**
- Bug réel : le `PageView` du feed n'avait pas `scrollDirection: Axis.vertical` explicite (défaut horizontal) — trouvé par les tests, corrigé.

### 2026-07-19 — Génération des plateformes natives — `e42cc0c`

**Ajouts**
- Dossiers `ios/`, `android/`, `macos/`, `web/` générés (`flutter create .`, org `be.hventures`).

**Corrections**
- Projet déplacé d'un volume exFAT (incompatible avec les liens symboliques requis par les builds iOS/macOS) vers un volume APFS. CocoaPods installé.

### 2026-07-19 — Coquille de navigation — `a3b7e54`

**Ajouts**
- Bottom bar 4 onglets (Découvrir, Rechercher, Favoris, Profil), `StatefulShellRoute` GoRouter, fondu entre branches (`BranchFadeContainer`).

### 2026-07-19 — Setup initial — `7970812` et antérieurs

**Ajouts**
- Scaffold Flutter complet : thème (`core/theme/`), datasources et modèles mock initiaux (biens, agences, leads), architecture en couches (présentation / logique métier / accès aux données).
- `docs/architecture-mvp.md` versionné dans le dépôt.

---

**Documents liés** : [ROADMAP.md](ROADMAP.md) · [DECISIONS.md](DECISIONS.md) · [CONTRIBUTING.md](CONTRIBUTING.md)
