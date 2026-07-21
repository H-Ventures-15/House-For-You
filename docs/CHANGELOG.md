# CHANGELOG — House For You

> **Statut : vivant.** Historique complet du projet. Une entrée doit être ajoutée pour **chaque** fonctionnalité validée, avant le commit qui la clôt — voir [CONTRIBUTING.md](CONTRIBUTING.md). Format inspiré de [Keep a Changelog](https://keepachangelog.com/) (catégories Ajouts / Corrections / Optimisations, comme demandé), adapté à un projet en construction (pas encore de version publiée).
>
> Version d'app actuelle (`pubspec.yaml`) : `0.1.0+1` — aucune version n'a encore été taguée sur GitHub, tout se trouve sous « Non publié » jusqu'à la première mise en production réelle (fin de bascule Supabase, étape 10).

---

## [Non publié] — 0.1.0

### 2026-07-21 — Correctif UX ciblé (fluidité de la bottom sheet, seuil naturel du swipe vertical)

**Corrections**
- Fermeture de la feuille de filtres par swipe : élimination de la saccade rapportée sur iPhone. Le flou de fond (`BackdropFilter`) ne se recalcule plus au rythme du drag (coût par frame parmi les plus élevés de Flutter) — seul un fondu d'assombrissement, bon marché, reste continu pendant le geste. Le règlement au relâchement (confirmation ou annulation) utilise désormais un `SpringSimulation` qui part de la vitesse réelle de relâchement, jamais une animation à durée fixe qui l'ignorait — voir [DECISIONS.md](DECISIONS.md) ADR-025.
- Swipe vertical du feed rendu moins sensible : un changement de bien exige désormais une intention nette (distance ≥ 20 % de la hauteur, ou vitesse ≥ 1200 px/s pour un swipe court), plus un simple flick de quelques millimètres. Découverte technique importante au passage : `PageView` ignore silencieusement toute physique personnalisée pour la décision de changement de page tant que `pageSnapping` (par défaut `true`) n'est pas explicitement mis à `false` — voir [DECISIONS.md](DECISIONS.md) ADR-026 pour le détail. Uniquement le feed vertical est concerné ; les deux galeries photo horizontales restent inchangées.
- Tests : `test/discover_feed_test.dart` (seuil naturel du swipe vertical — petit drag, distance suffisante, swipe court et rapide, geste diagonal faible), `test/filters_sheet_test.dart` (suivi du doigt en direct pendant le drag) — 72 tests au total désormais.

**Décisions produit**
- Voir [DECISIONS.md](DECISIONS.md) ADR-025 (fluidité bottom sheet) et ADR-026 (seuil du swipe vertical + découverte `pageSnapping`).

**Non modifié (revérifié sans régression)**
- Préchargement, `RepaintBoundary`, favoris, conservation du bien courant, swipe horizontal des galeries photo (`SnappyPageScrollPhysics` inchangée sur ces deux `PageView`) : aucune régression, tests correspondants toujours au vert.

### 2026-07-21 — Correctif rapide post-Sprint 2.5 (favoris sans compte, fermeture des filtres)

**Corrections**
- Favoris accessibles sans compte : le double tap et le bouton cœur (feed, fiche détail) ne passent plus par `requireAuth()`. Persistance locale réelle (`SharedPreferences` au lieu d'un stockage en mémoire perdu à chaque redémarrage) — `MockFavoritesDataSource`, `FavoritesController` s'hydrate désormais au démarrage.
- Nouvel écran `lib/features/favorites/favorites_screen.dart` : liste réelle des biens favoris (`PropertyCard.list()`), état vide explicite sinon — implémentation volontairement minimale, l'écran complet synchronisé reste à l'étape 6.
- Fermeture de la feuille de filtres par swipe assouplie : le geste suit désormais le doigt **au pixel près** (`ScrollNotification.dragDetails` brut plutôt que `ScrollMetrics.pixels`, amorti par `BouncingScrollPhysics` sur iOS — voir [DECISIONS.md](DECISIONS.md) ADR-024) ; seuil de distance abaissé de 32 % à 18 %, seuil de vitesse de 800 à 500 px/s. La vitesse de relâchement (`ScrollEndNotification.dragDetails.velocity`) est désormais réellement exploitée — elle ne l'était pas, rendant jusqu'ici le seuil de vitesse inopérant.
- Tests : `test/property_detail_test.dart` (favori sans compte, ajout/retrait, contact toujours protégé), `test/favorites_screen_test.dart` (nouveau fichier — état vide, bien favori affiché), `test/filters_sheet_test.dart` (swipe rapide et court qui ferme via le seuil de vitesse) — 67 tests au total désormais.

**Décisions produit**
- Voir [DECISIONS.md](DECISIONS.md) ADR-023 (favoris sans compte) et ADR-024 (delta brut du doigt pour le swipe de fermeture).

### 2026-07-21 — Micro-interactions premium & corrections UX (sous-étape 2.4 / « Sprint 2.5 »)

**Ajouts**
- Fermeture de la feuille de filtres par swipe vers le bas — suit le doigt en direct, priorité au scroll interne tant qu'il n'est pas remonté en haut, seuil de 32 % ou de vitesse, fond flouté proportionnel au geste (`lib/core/widgets/blurred_modal_sheet.dart`).
- Badges éditoriaux/commerciaux (Exclusivité, Coup de cœur, Prix réduit, Visite virtuelle, Nouveau) — jusqu'à 2 par carte, dérivés à la volée depuis `Property` (`lib/data/models/property_badge.dart`), champs mock ajoutés (`isExclusive`, `isFeatured`, `hasVirtualTour`, `previousPrice`).
- `PressableScale` (`lib/core/widgets/pressable_scale.dart`) — micro-réduction à l'appui, appliquée à `PhButton`, aux boutons favori/partager (feed et fiche détail) et aux icônes de la barre flottante.
- Retours haptiques cohérents : changement d'onglet de la navigation inférieure, sélection réelle du type de transaction, application des filtres, chargement d'une recherche sauvegardée, franchissement du seuil de fermeture (fiche détail et feuille de filtres).
- Animation du favori affinée : rebond marqué à l'ajout, fondu discret sans effet spectaculaire au retrait.
- Indicateur de médias : distinction photo/vidéo (icône caméra sur les segments vidéo), légère ombre portée pour la lisibilité sur fond clair.
- Dégradés du feed retravaillés : intensité concentrée sur la zone basse utile (prix/titre/description), jamais de grande zone noire.
- Partage : lien placeholder stable inclus dans le texte partagé, annulation (feuille système fermée sans choisir d'action) jamais comptée comme un partage réel dans les analytics.
- Tests : `test/main_shell_test.dart` (séquences de navigation complètes), `test/filters_sheet_test.dart` (fermeture par swipe), `test/property_badge_test.dart` (nouveau fichier), `test/property_card_gestures_test.dart` (badges, distinction vidéo) — 63 tests au total désormais.

**Investigation**
- Bug de navigation rapporté (Découvrir↔Favoris/Profil) : investigué en profondeur (lecture du code `go_router`, instrumentation, tests dédiés) — aucun défaut trouvé dans le code, non reproduit par `flutter test`. Le symptôme observé provenait du serveur web de développement (jamais l'arbitre officiel, voir [DECISIONS.md](DECISIONS.md) ADR-018/019). Tests de régression permanents ajoutés à la place d'une modification spéculative de l'architecture.

**Non modifié (revérifié sans régression)**
- Fluidité (2.1), gestes (2.2), filtres/recherches sauvegardées (2.3) : fichiers concernés non altérés en profondeur, seuls des ajouts ciblés (imports, wrapping `PressableScale`, nouveaux champs).

**Décisions produit**
- Voir [DECISIONS.md](DECISIONS.md) ADR-019 (navigation), ADR-020 (swipe de fermeture), ADR-021 (badges), ADR-022 (partage).

### 2026-07-20 — Gouvernance : Mobile First absolu + QA_CHECKLIST officielle

**Ajouts**
- Nouveau document [docs/QA_CHECKLIST.md](QA_CHECKLIST.md) : checklist officielle par catégories (feed, fiche du bien, filtres & recherche, navigation, micro-interactions, performances, accessibilité, qualité du code) à dérouler avant chaque validation de sprint.
- [DECISIONS.md](DECISIONS.md) ADR-018 : iOS formalisé comme seule plateforme de validation officielle du produit — Web/macOS/Android réservés au développement/débogage, l'iPhone fait foi en cas de divergence de comportement.
- [CONTRIBUTING.md](CONTRIBUTING.md) : nouveau processus de validation de sprint en 7 étapes (section 8), section « Amélioration continue » (section 9), règle de qualité à 3 critères pour toute nouvelle fonctionnalité, sinon [BACKLOG.md](BACKLOG.md) (section 10).
- [UX_RULES.md](UX_RULES.md) section 2 bis, [PRODUCT_SPEC.md](PRODUCT_SPEC.md) section 7, [CLAUDE.md](../CLAUDE.md) et [docs/README.md](README.md) : renvois croisés vers cette règle.

**Non modifié** : documentation uniquement, aucun code Dart touché — aucune régression possible sur les sprints précédents.

### 2026-07-20 — Recherche, filtres et recherches sauvegardées (sous-étape 2.3 / « Sprint 2.4 »)

**Ajouts**
- Hiérarchie des filtres à deux niveaux : critères principaux (localisation + rayon, type de transaction, budget, type de bien, chambres) toujours visibles ; 8 critères avancés (salles de bain, surfaces, PEB, caractéristiques, état du bien, date de publication, tri, ambiance de vie) repliés sous une section « Plus de filtres » avec badge de comptage (`lib/features/discover/filters/filters_sheet.dart`).
- Recherches sauvegardées réellement fonctionnelles : `SavedSearch` porte désormais de vrais `SearchFilters` (plus un libellé statique) ; `SavedSearchesRepository`/`MockSavedSearchesDataSource`/`SavedSearchesController` suivant le pattern déjà établi (ADR-011). Enregistrer propose un nom par défaut pertinent (modifiable, dialogue partagé `promptSavedSearchName`), confirme visuellement ; charger, renommer et supprimer sont fonctionnels depuis la feuille de filtres et l'accès rapide de la barre flottante (`lib/features/discover/saved_searches_sheet.dart`).
- Réinitialisation automatique du budget au changement de type de transaction (achat ↔ location) — échelles de prix incompatibles.
- État "zéro résultat" enrichi (`_NoFilteredResults`, `discover_screen.dart`) : trois actions (Modifier les filtres, Réinitialiser, Charger une recherche sauvegardée) plutôt qu'un message à bouton unique.
- Labels sémantiques (`Semantics(selected:, button:, label:)`) sur `PillChoice`, `IconGridChoice`, `BigChoiceCard` (`filter_widgets.dart`) — la sélection n'est jamais signalée uniquement par la couleur.
- Tests : `test/filters_sheet_test.dart`, `test/saved_searches_sheet_test.dart` (9 tests, 39 au total désormais).

**Non modifié (revérifié sans régression)**
- Gestes du feed (Sprint 2.3 : appui long, double tap, retour haptique, labels sémantiques du feed) et fluidité (Sprint 2.2 : `SnappyPageScrollPhysics`, `RepaintBoundary`, précache) : fichiers concernés non touchés.
- Les 14 sections de filtres existantes (étape 2) : comportement inchangé, seule leur disposition (principal/avancé) a changé.

**Décisions produit**
- Les recherches sauvegardées ne passent pas par `requireAuth()`, contrairement aux favoris — voir [DECISIONS.md](DECISIONS.md) ADR-016.
- « Plus de filtres » repliée par défaut plutôt qu'une liste plate de 14 sections — voir [DECISIONS.md](DECISIONS.md) ADR-017.

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
