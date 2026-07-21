# TECH_ARCHITECTURE — House For You

> **Statut : vivant.** Source de vérité technique du projet. Supersède la partie architecture d'[architecture-mvp.md](architecture-mvp.md) (conservé comme document historique du cahier des charges initial — voir note en tête de ce fichier). Toute évolution structurelle (nouveau dossier, nouveau pattern, nouvelle dépendance) doit être reflétée ici avant le commit qui l'introduit.
>
> Dernière mise à jour : 2026-07-21 (correctif UX ciblé — fluidité de la bottom sheet, seuil naturel du swipe vertical du feed).

---

## 1. Stack technique

| Couche | Choix | Version (pubspec.yaml) |
|---|---|---|
| Framework | Flutter | SDK Dart `>=3.3.0 <4.0.0` |
| State management | Riverpod | `flutter_riverpod ^2.5.1` |
| Navigation | GoRouter | `^14.2.0` |
| Backend (futur) | Supabase (Postgres, Auth, Storage) | non connecté au MVP |
| i18n | `flutter_localizations` + `.arb` (`intl ^0.20.2`) | fr rempli, nl/en présents |
| Config environnement | `flutter_dotenv ^5.1.0` | `.env` jamais commité, clé `anon` uniquement |
| Partage natif | `share_plus ^13.2.1` | — |
| Persistance locale | `shared_preferences ^2.5.5` | Favoris invité (voir [DECISIONS.md](DECISIONS.md) ADR-023), jusqu'à la synchronisation Supabase (étape 5/6) |
| Tests | `flutter_test`, `network_image_mock ^2.1.1`, `mockito` (dev) | — |
| Lint | `flutter_lints ^4.0.0` | règles renforcées, voir `analysis_options.yaml` |

Plateformes générées : iOS, Android, macOS, Web (`flutter create . --platforms=ios,android,macos,web`, org `be.hventures`). Vidéo prévue post-V1 photo via Cloudflare Stream ou Mux (modèle de données déjà prêt, voir [DATABASE_PLAN.md](DATABASE_PLAN.md)).

## 2. Principe d'architecture

Séparation stricte en 3 couches, par feature :

```
Présentation (features/, core/widgets/)
        │  ne connaît que les providers, jamais un repository concret
        ▼
Logique métier / état (data/providers/)
        │  orchestre les repositories, expose l'état (AsyncValue, StateNotifier)
        ▼
Accès aux données (data/repositories/ + data/datasources/ + data/models/)
        │  interface abstraite ↔ implémentation mock (aujourd'hui) ou Supabase (étape 10)
```

**Règle absolue (mock avant Supabase)** : aucun écran ne s'implémente contre une implémentation concrète. Chaque repository a une interface abstraite (`data/repositories/*.dart`) et une implémentation mock (`data/datasources/mock/*.dart`), branchée via un seul point d'injection Riverpod (`data/providers/repository_providers.dart`). Basculer vers Supabase à l'étape 10 ne changera **que** ce fichier — aucun écran, aucun provider dérivé ne devrait avoir besoin d'être modifié.

## 3. Arborescence réelle (`lib/`)

```
lib/
├── main.dart                          # bootstrap : charge .env (best-effort), runApp
├── app.dart                           # HouseForYouApp — porte son propre ProviderScope
│
├── core/
│   ├── auth/
│   │   └── auth_guard.dart            # authStateProvider (mock) + requireAuth()
│   ├── router/
│   │   ├── app_router.dart            # GoRouter : StatefulShellRoute 4 onglets + route /property/:id
│   │   ├── main_shell.dart            # Scaffold + NavigationBar
│   │   └── branch_fade_container.dart # fondu entre branches du shell
│   ├── services/
│   │   ├── analytics_service.dart     # interface + MockAnalyticsService (log console)
│   │   └── session_id.dart            # identifiant de session anonyme (analytics)
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_spacing.dart           # + AppRadius
│   │   ├── app_typography.dart
│   │   └── app_theme.dart             # ThemeData Material 3
│   └── widgets/                       # composants réutilisables — voir DESIGN_SYSTEM.md
│
├── data/
│   ├── models/                        # classes Dart pures, fromJson/toJson/copyWith manuels
│   ├── repositories/                  # interfaces abstraites uniquement
│   ├── datasources/
│   │   └── mock/                      # implémentations + données fictives (aucun dossier supabase/ pour l'instant)
│   └── providers/                     # injection Riverpod + providers dérivés (feed filtré, compteur, etc.)
│
├── features/
│   ├── discover/                      # feed (implémenté) + fiche détail (implémenté) + filtres (implémenté)
│   │   └── filters/                   # feuille de filtres et ses sous-composants
│   ├── search/                        # placeholder — étape 3
│   ├── favorites/                     # liste réelle, accès invité (étape 6 = sync multi-appareil)
│   └── profile/                       # placeholder invité — étape 8
│
└── l10n/                              # app_fr.arb (rempli), app_nl.arb / app_en.arb (présents, vides)
```

**Écart assumé avec le plan initial** (`architecture-mvp.md` section 2) : la fiche détail vit dans `features/discover/` plutôt que dans un `features/property_detail/` séparé — elle est aujourd'hui exclusivement ouverte depuis le feed, et sera déplacée si/quand elle devient réellement partagée par plusieurs points d'entrée (résultats de recherche, étape 3). Pas de dossier `features/agency/`, `features/leads/`, `features/auth/` tant que ces écrans n'existent pas — créés au moment de leur étape respective, jamais en avance.

## 4. Modèles de données (`lib/data/models/`)

| Fichier | Classe | Statut |
|---|---|---|
| `property.dart` | `Property`, `TransactionType`, `PropertyType`, `PropertyStatus`, `LocationPrecision` | Utilisé |
| `property_media.dart` | `PropertyMedia`, `MediaType`, `StorageProvider`, `MediaProcessingStatus` | Utilisé (photo uniquement peuplé) |
| `property_feature.dart` | `PropertyFeature` | Utilisé (caractéristiques ad hoc) |
| `property_private_location.dart` | `PropertyPrivateLocation` | Modèle prêt, aucun repository/écran ne l'utilise encore |
| `property_event.dart` | `PropertyEvent`, `PropertyEventType` | Utilisé (tracking mock) |
| `agency.dart` | `Agency` | Utilisé |
| `agency_member.dart` | `AgencyMember`, `AgencyMemberRole`, `AgencyMemberStatus` | Modèle prêt, non consommé |
| `user_profile.dart` | `UserProfile`, `UserRole` | Modèle prêt, non consommé (attend l'étape 5/8) |
| `lead.dart` | `Lead`, `LeadType`, `LeadStatus` | Modèle prêt, non consommé (attend l'étape 7) |
| `search_filters.dart` | `SearchFilters`, `PropertyCondition`, `PublicationRecency`, `SortOption` | Utilisé — voir section 6 |
| `saved_search.dart` | `SavedSearch` | Utilisé — porte de vrais `SearchFilters` depuis la sous-étape 2.3 (plus un simple libellé statique), voir section 5 bis |
| `property_badge.dart` | `PropertyBadge`, `propertyBadges()`, `propertyBadgeLabel()`, `propertyBadgeIcon()` | Utilisé depuis la sous-étape 2.4 — dérive les badges affichés sur le feed depuis `Property.isExclusive`/`isFeatured`/`hasVirtualTour`/`previousPrice`/`publishedAt`, voir [DECISIONS.md](DECISIONS.md) ADR-021 |

## 5. Repositories & datasources mock

| Repository (interface) | Implémentation mock | Provider (injection) |
|---|---|---|
| `PropertyRepository` | `MockPropertyDataSource` | `propertyRepositoryProvider` |
| `AgencyRepository` | `MockAgencyDataSource` | `agencyRepositoryProvider` |
| `FavoritesRepository` | `MockFavoritesDataSource` (persistance `SharedPreferences`, voir [DECISIONS.md](DECISIONS.md) ADR-023) | `favoritesRepositoryProvider` |
| `LeadsRepository` | `MockLeadsDataSource` | `leadsRepositoryProvider` |
| `SavedSearchesRepository` | `MockSavedSearchesDataSource` | `savedSearchesRepositoryProvider` |
| `AnalyticsService` | `MockAnalyticsService` | `analyticsServiceProvider` |

Toute l'injection vit dans **un seul fichier** : `lib/data/providers/repository_providers.dart`. Basculer un repository vers Supabase = changer la valeur retournée par son provider, rien d'autre.

**Providers dérivés** (`lib/data/providers/feed_providers.dart`, `search_filters_controller.dart`, `favorites_controller.dart`, `saved_searches_controller.dart`) :

- `feedPropertiesProvider` (`FutureProvider<List<Property>>`) — biens publiés, triés par nouveauté.
- `agenciesByIdProvider` (`FutureProvider<Map<String, Agency>>`) — évite un appel par carte pour le logo agence.
- `propertyByIdProvider` (`FutureProvider.family<Property?, String>`) — fiche détail.
- `searchFiltersControllerProvider` (`StateNotifierProvider<SearchFiltersController, SearchFilters>`) — état des filtres actifs, lu/écrit en direct par la feuille de filtres et la barre flottante.
- `filteredPropertyCountProvider` (`Provider<int>`) — compteur du bouton « Afficher N biens », **calcul réel** sur les données mock via `SearchFilters.matches()` (voir section 6), pas un chiffre inventé.
- `favoritesControllerProvider` (`StateNotifierProvider<FavoritesController, Set<String>>`) — favoris persistés localement (`SharedPreferences`, identifiant mock unique `mockSessionUserId` tant que l'authentification réelle n'existe pas), hydratés depuis le repository à la création du contrôleur. Ses écritures ne sont **pas** gardées par `requireAuth()` — voir [DECISIONS.md](DECISIONS.md) ADR-023.
- `savedSearchesControllerProvider` (`StateNotifierProvider<SavedSearchesController, AsyncValue<List<SavedSearch>>>`) — recherches sauvegardées de la session (`save`/`rename`/`remove`), voir section 5 bis. Comme `favoritesControllerProvider`, ses écritures ne sont **pas** gardées par `requireAuth()` à cette étape (voir [DECISIONS.md](DECISIONS.md) ADR-016).

## 5 bis. Recherches sauvegardées

`SavedSearch` (`lib/data/models/saved_search.dart`) porte un `id`, un `label` et de vrais `SearchFilters` (plus `createdAt`) — le libellé par défaut, le sous-titre et l'icône affichés dans les listes/aperçus se dérivent des critères à la volée (`defaultSavedSearchName`/`savedSearchSubtitle`/`savedSearchIcon`, `lib/features/discover/filters/filter_options.dart`) plutôt que d'être stockés en double.

`MockSavedSearchesDataSource` (`lib/data/datasources/mock/mock_saved_searches_datasource.dart`) tient une liste en mémoire, semée de 4 recherches de démonstration — dont « Maison à Mons », volontairement construite pour ne matcher aucun bien mock (aucune localité « Mons » dans `mock_property_data.dart`), utilisée comme démonstration prête à l'emploi de l'état "zéro résultat" (voir [UX_RULES.md](UX_RULES.md) section 17). Chaque méthode du repository (`getAll`/`save`/`rename`/`remove`) accepte un `userId`, ignoré par le mock (voir [DECISIONS.md](DECISIONS.md) ADR-016) mais déjà correct pour la future policy RLS Supabase (`saved_searches.user_id`, voir [DATABASE_PLAN.md](DATABASE_PLAN.md) section 3.12).

Points d'entrée UI :
- **Enregistrer** — `_handleSaveSearch` (`filters_sheet.dart`) ouvre `promptSavedSearchName` (`saved_search_name_dialog.dart`, dialogue partagé avec le renommage) pré-rempli d'un nom par défaut, puis confirme visuellement (`SnackBar`).
- **Charger** — depuis l'aperçu horizontal de `filters_sheet.dart` (reste ouverte) ou depuis `saved_searches_sheet.dart` (ferme immédiatement le panneau) : les deux appellent `searchFiltersControllerProvider.notifier.update((_) => search.filters)`, remplaçant l'état actif par les critères sauvegardés.
- **Renommer** / **Supprimer** — uniquement depuis `saved_searches_sheet.dart` (icônes dédiées par ligne), avec confirmation avant suppression.

## 6. `SearchFilters` — le modèle de recherche

Objet non persisté, construit par la feuille de filtres (étape 2) et, plus tard, par la recherche guidée (étape 3). Couvre : transaction, types de bien (multi-sélection), localisation (ville/province/rayon), budget, chambres/salles de bain, surfaces habitable et terrain, certificat énergétique (multi-sélection), caractéristiques (clés libres — `garden`/`garage`/`terrace` mappées aux colonnes structurées de `Property`, le reste comparé à `Property.features`), état du bien, date de publication, tri, ambiances de vie.

`matches(Property)` implémente le filtrage réel contre les données mock. **Champs qui n'influencent volontairement pas le résultat** (documenté pour éviter toute confusion future) : `condition` (aucune colonne équivalente dans `Property` au MVP), `ambiances` (section exploratoire, voir [PRODUCT_SPEC.md](PRODUCT_SPEC.md) 10.2), `radiusKm` (aucune donnée de géocodage disponible), `sortOption` (trie, ne filtre pas).

## 7. State management (Riverpod)

- `ConsumerWidget`/`ConsumerStatefulWidget` pour tout écran qui lit l'état.
- `StateNotifierProvider` pour l'état mutable simple (favoris, filtres).
- `FutureProvider`/`FutureProvider.family` pour les données asynchrones dérivées d'un repository.
- `Provider` pour les valeurs dérivées calculées (compteur filtré, session id).
- `ProviderScope` porté par `HouseForYouApp` elle-même (`app.dart`) — l'app est autonome et testable sans wrapper externe (`main.dart` ne fait qu'appeler `runApp(const HouseForYouApp())`).

## 8. Navigation (GoRouter)

- `StatefulShellRoute` — 4 branches (`/discover`, `/search`, `/favorites`, `/profile`), chacune avec sa propre pile de navigation préservée au changement d'onglet.
- `BranchFadeContainer` remplace l'`IndexedStack` par défaut pour un fondu enchaîné entre onglets (branches gardées montées, `IgnorePointer`/`TickerMode` désactivés sur les branches inactives).
- `/property/:id` — route de premier niveau (hors shell), `CustomTransitionPage` avec transition fondu + glissement, **`opaque: false`** : le feed reste peint sous la fiche pendant toute la transition et le geste de fermeture interactif (voir [DECISIONS.md](DECISIONS.md)).

## 9. Gestion des médias

- `Image.network` avec `frameBuilder` (fondu 300 ms à la première apparition) et `errorBuilder` (icône de repli) systématiques — jamais un `Image.network` nu.
- Vidéo : le modèle (`PropertyMedia.mediaType`, `storageProvider`, `playbackId`) est prêt, mais **aucun lecteur vidéo n'est implémenté** et aucune donnée mock n'en contient — un média `video` affiche aujourd'hui sa vignette (`thumbnailUrl`) avec une icône de lecture superposée, sans lecture réelle.

## 10. Préchargement & performance (étape 2.1)

- **`precacheImage`** sur les photos du bien précédent et suivant (3 médias par voisin), à chaque changement de page settlé — la latence perçue d'un feed à médias réseau vient du téléchargement, pas de la construction du widget ; précharger l'image élimine ce coût avant que la carte ne soit réellement construite.
- **`AutomaticKeepAliveClientMixin`** sur l'état de chaque carte du feed (`_FeedCardState`) — préserve la photo affichée d'une carte déjà visitée tant qu'elle reste dans la fenêtre du `PageView`.
- **`RepaintBoundary`** par carte du feed — isole le repaint de chaque page, le scroll ne force jamais le repaint des cartes voisines.
- **`SnappyPageScrollPhysics`** (`lib/core/widgets/snappy_page_physics.dart`) — ressort de fin de geste personnalisé (`mass: 0.3, stiffness: 180, ratio: 1`) appliqué au feed vertical (via `FeedPageScrollPhysics`, voir section 10 quinquies), à la galerie photo de chaque carte et à la galerie de la fiche détail.
- **`allowImplicitScrolling: true`** sur les mêmes trois `PageView` — améliore la navigation VoiceOver/TalkBack. Vérifié empiriquement (test dédié, `test/snappy_page_physics_test.dart` + investigation documentée dans le commit `3c3759c`) que cette option ne pré-monte **pas** réellement les pages voisines en mémoire malgré son nom — ce n'est pas le mécanisme qui explique la fluidité, gardé uniquement pour son bénéfice d'accessibilité réel.

## 10 bis. Gestes du feed (sous-étape 2.2)

- **Appui long sur le média** (`_FeedCard`, `lib/core/widgets/property_card.dart`) — `onLongPressStart`/`onLongPressEnd`/`onLongPressCancel` sur le même `GestureDetector` que le double tap (au-dessus de `_Gallery`). Un seul `AnimatedOpacity` (clé `feed-card-chrome`) enveloppé d'un `IgnorePointer` regroupe tout le chrome de la carte (gradient haut, bloc infos, indicateur photo, badge agence, rail favori/partager) : un seul point de bascule plutôt qu'un état dupliqué par élément.
- `PropertyCard.feed` expose `onLongPressStart`/`onLongPressEnd` (optionnels, absents sur `.list()`) pour que `DiscoverScreen` masque aussi la barre de recherche flottante en synchronisant `_barVisibility` — la valeur *précédente* est sauvegardée avant le masquage et restaurée telle quelle au relâchement (pas une réapparition forcée), cohérent avec le mécanisme de visibilité continue déjà en place (voir ADR-006).
- **Retour haptique** (`HapticFeedback.lightImpact()`, `flutter/services.dart`) déclenché dans `_handleDoubleTap` uniquement quand `onToggleFavorite()` aboutit réellement (pas bloqué par `requireAuth()`).
- **Accessibilité** : `Semantics(button: true, label: ...)` sur les boutons favori/partager (`property_card.dart`), la zone d'ouverture de fiche (`property_card.dart`), et les boutons retour/favori/partage de la fiche détail (`_RoundIconButton`, `property_detail_screen.dart`).
- La bottom bar (`MainShell`) n'est volontairement pas masquée par ce geste — voir [DECISIONS.md](DECISIONS.md) ADR-015 pour la justification architecturale (frontière shell/feature) et produit (UX_RULES.md section 11).

## 10 ter. Hiérarchie des filtres (sous-étape 2.3)

- `_FiltersSheetState._showMoreFilters` (bool local) contrôle un `AnimatedSize` (220 ms, `Curves.easeOut`) enveloppant les 8 sections avancées (salles de bain, surfaces, PEB, caractéristiques, état du bien, date de publication, tri, ambiance de vie) — repliées par défaut (`SizedBox` vide) tant que l'utilisateur n'a pas tapé sur « Plus de filtres ». Les widgets des sections avancées ne sont **pas construits du tout** tant que repliées (branche conditionnelle du `Column`, pas un simple `Visibility`/opacité) — coût de build nul à l'état replié.
- `_advancedFilterCount(filters)` calcule le nombre de groupes avancés actifs pour le badge du bouton « Plus de filtres » — même logique que `SearchFilters.activeFilterCount` mais restreinte aux seuls critères déplacés sous le repli.
- Changer de type de transaction réinitialise `budgetMin`/`budgetMax` (sauf re-tap de la transaction déjà sélectionnée) — voir [DECISIONS.md](DECISIONS.md) et [UX_RULES.md](UX_RULES.md) section 17.
- L'état "zéro résultat" (`_NoFilteredResults`, `discover_screen.dart`) remplace le feed entier — y compris la barre de recherche flottante, qui vit dans `_DiscoverFeed` — quand `filtered.isEmpty` ; ses trois actions (`showFiltersSheet`, `showSavedSearchesSheet`, `searchFiltersControllerProvider.notifier.reset()`) restent toutes accessibles depuis cet écran de secours.

## 10 quater. Micro-interactions premium (sous-étape 2.4)

- **Fermeture de la feuille de filtres par swipe** (`lib/core/widgets/blurred_modal_sheet.dart`, `_DismissibleSheet`) — voir [DECISIONS.md](DECISIONS.md) ADR-020 pour le choix technique (notifications de scroll plutôt qu'un `GestureDetector` concurrent).
- **`PressableScale`** (`lib/core/widgets/pressable_scale.dart`) — `Listener` (jamais `GestureDetector`, pour ne jamais intercepter le tap du widget enveloppé) piloté par `onPointerDown`/`onPointerUp`/`onPointerCancel`, anime une `AnimatedScale` à 0.94 sur 120 ms. Enveloppe `PhButton` (donc tous ses usages : CTA des filtres, « Contacter l'agence »...), les boutons favori/partager du feed et de la fiche détail, les icônes de la barre flottante.
- **Badges éditoriaux** (`lib/data/models/property_badge.dart`, `_BadgeStack`/`_BadgeChip` dans `property_card.dart`) — voir [DECISIONS.md](DECISIONS.md) ADR-021.
- **Retours haptiques** — `HapticFeedback.selectionClick()` sur changement d'onglet (`main_shell.dart`), sélection réelle du type de transaction et application des filtres (`filters_sheet.dart`), chargement d'une recherche sauvegardée (`filters_sheet.dart`, `saved_searches_sheet.dart`) ; `HapticFeedback.lightImpact()` au franchissement du seuil de fermeture (fiche détail, feuille de filtres), une seule fois par franchissement (bool `_hapticFired`/`_dismissHapticFired`, réinitialisé si on repasse sous le seuil).
- **Partage** — vérification de `ShareResult.status` avant de tracker l'évènement `share` (voir [DECISIONS.md](DECISIONS.md) ADR-022).

## 10 quinquies. Correctif UX ciblé — fluidité de la bottom sheet, seuil naturel du swipe vertical (post-Sprint 2.5)

- **Fermeture de la feuille de filtres, réécrite pour la fluidité** (`_DismissibleSheet`, `lib/core/widgets/blurred_modal_sheet.dart`) — voir [DECISIONS.md](DECISIONS.md) ADR-025 :
  - `BackdropFilter` (flou de fond) piloté par sa propre `AnimatedBuilder`, qui n'écoute que `routeAnimation` (l'animation d'ouverture/fermeture de la route) — jamais `_dragController`. Coût de re-flou payé une seule fois par transition (~300 ms), jamais à chaque frame d'un drag actif de durée arbitraire.
  - L'assombrissement (simple `ColoredBox` à alpha variable) et la translation (`Transform.translate`) restent seuls à réagir en continu au drag, via `Listenable.merge([routeAnimation, _dragController])`.
  - `_dragController` est un `AnimationController.unbounded` unique : `.value =` pour le suivi 1:1 pendant le drag actif (arrête net toute simulation en cours), `.animateWith(SpringSimulation(...))` pour le règlement au relâchement, en utilisant la vitesse réelle de `DragEndDetails.velocity` comme vitesse initiale du ressort — jamais un `Tween`/`Curve` à durée fixe qui ignorerait cette vitesse.
- **`FeedPageScrollPhysics`** (`lib/core/widgets/snappy_page_physics.dart`) — remplace la décision de changement de page pour le feed vertical uniquement (jamais les galeries horizontales). Voir [DECISIONS.md](DECISIONS.md) ADR-026 pour la découverte technique centrale : `PageView` enveloppe systématiquement toute physique fournie dans sa propre `_kPagePhysics` interne tant que `pageSnapping` (par défaut `true`) n'est pas explicitement mis à `false` — sans quoi `createBallisticSimulation` d'une physique personnalisée n'est **jamais** consultée pour les changements de page normaux (seulement pour le rattrapage hors-limites). `DiscoverScreen` déclare donc `pageSnapping: false` sur son `PageView`.
  - Seuils : 20 % de la hauteur de page valide seul un changement ; sous 5 %, aucune vitesse ne suffit ; entre les deux, une vélocité ≥ 1200 px/s valide un swipe court et rapide.
  - `currentPage` (un `int Function()` fourni par `_DiscoverFeedState`) donne l'origine réelle du geste — capturée une seule fois par `ScrollStartNotification` (`_gestureOriginPage`), jamais déduite de la position fractionnaire courante (`page.round()` désigne la page cible, pas l'origine, au-delà de 50 % de distance parcourue) ni de `_lastSettledIndex` (mis à jour par `onPageChanged`, qui se déclenche lui-même dès qu'un simple `page.round()` dépasse 50 % — potentiellement pendant le drag, avant que notre propre seuil n'ait tranché).

## 11. Tests

11 fichiers, 72 tests (`flutter test`). Conventions : voir [CONTRIBUTING.md](CONTRIBUTING.md).

| Fichier | Couvre |
|---|---|
| `mock_data_test.dart` | Intégrité des données mock (agences référencées, photos de couverture, round-trip JSON) |
| `main_shell_test.dart` | Navigation 4 onglets, séquences complètes de la sous-étape 2.4 (Découvrir↔Favoris↔Profil, changements rapides, conservation du bien courant et des filtres actifs) |
| `discover_feed_test.dart` | Indépendance swipe vertical/horizontal, barre flottante (masquage/réapparition au scroll et à l'appui long, état précédent restauré), feuille de filtres, recherches enregistrées, `RepaintBoundary`, seuil naturel du swipe vertical (petit drag = retour, distance suffisante = changement, swipe court et rapide = changement, geste diagonal faible = pas de changement — correctif post-Sprint 2.5) |
| `property_card_gestures_test.dart` | Séparation stricte des zones de geste (média = like/appui long, texte = ouvrir la fiche), masquage/restauration du chrome à l'appui long, non-déclenchement du favori/de la fiche pendant l'appui long, labels sémantiques, badges affichés (sous-étape 2.4), distinction vidéo de l'indicateur photo |
| `property_detail_test.dart` | Contenu de la fiche détail, favori sans compte (ajout/retrait), contact agence toujours protégé par la porte d'authentification |
| `property_detail_dismiss_test.dart` | Fermeture par swipe (seuil de confirmation), scroll vertical du contenu sans fermeture accidentelle |
| `snappy_page_physics_test.dart` | Tuning du ressort personnalisé |
| `filters_sheet_test.dart` | Repli/dépliage de « Plus de filtres », enregistrement d'une recherche (dialogue + confirmation), réinitialisation du budget au changement de transaction, état "zéro résultat", fermeture par swipe vers le bas (distance, vitesse, priorité au scroll interne, suivi du doigt en direct pendant le drag — correctif post-Sprint 2.5) |
| `saved_searches_sheet_test.dart` | Chargement/renommage/suppression d'une recherche sauvegardée depuis l'accès rapide, état vide, chargement d'une recherche menant à "zéro résultat" |
| `property_badge_test.dart` | Dérivation des 5 badges (`propertyBadges()`), ordre de priorité, round-trip JSON des champs sources |
| `favorites_screen_test.dart` | État vide, bien favori réellement affiché dans l'onglet Favoris |

`network_image_mock` est requis dans tout test qui rend un `Image.network` — sans lui, `flutter test` bloque toutes les requêtes HTTP et fait échouer le test avec un timer en attente (voir [CONTRIBUTING.md](CONTRIBUTING.md)).

## 12. Connexion future Supabase (étape 10)

- Postgres + Auth + Storage. Clé publique `anon` uniquement côté client (`.env`, jamais commité) — la sécurité repose sur les policies RLS, jamais sur le secret d'une clé.
- Schéma complet préparé dans [DATABASE_PLAN.md](DATABASE_PLAN.md) — aucune table n'a encore de migration réelle, tout est mock.
- Bascule prévue **repository par repository**, jamais en bloc : chaque `MockXxxDataSource` sera remplacé par un `SupabaseXxxDataSource` dans `data/datasources/supabase/` (dossier à créer à ce moment-là), branché dans `repository_providers.dart`. Aucun écran ne devrait nécessiter de modification.
- Vidéo : Cloudflare Stream ou Mux (à trancher, voir [BACKLOG.md](BACKLOG.md)) — le modèle `PropertyMedia` est déjà prêt (`storageProvider`, `playbackId`).

## 13. Environnement de développement

- Le projet doit vivre sur un volume supportant les liens symboliques (APFS/HFS+/ext4...) — **exFAT est incompatible** avec les builds iOS/macOS (CocoaPods échoue silencieusement sur les liens symboliques de `ios/Flutter/ephemeral/`). Voir historique de session pour le détail du diagnostic si le projet est de nouveau déplacé.
- CocoaPods requis pour les builds iOS/macOS (plugins natifs : `share_plus`).
- `.claude/launch.json` configure un serveur web de développement (`flutter run -d web-server`) pour la prévisualisation en environnement sandboxé.

---

**Documents liés** : [DATABASE_PLAN.md](DATABASE_PLAN.md) · [API_PLAN.md](API_PLAN.md) · [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) · [DECISIONS.md](DECISIONS.md) · [CONTRIBUTING.md](CONTRIBUTING.md) · [architecture-mvp.md](architecture-mvp.md) (historique)
