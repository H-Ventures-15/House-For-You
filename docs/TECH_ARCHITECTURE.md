# TECH_ARCHITECTURE — House For You

> **Statut : vivant.** Source de vérité technique du projet. Supersède la partie architecture d'[architecture-mvp.md](architecture-mvp.md) (conservé comme document historique du cahier des charges initial — voir note en tête de ce fichier). Toute évolution structurelle (nouveau dossier, nouveau pattern, nouvelle dépendance) doit être reflétée ici avant le commit qui l'introduit.
>
> Dernière mise à jour : 2026-07-20 (fin de l'étape 2.1).

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
│   ├── favorites/                     # placeholder invité — étape 6
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
| `saved_search.dart` | `SavedSearch` | Utilisé (mock statique) |

## 5. Repositories & datasources mock

| Repository (interface) | Implémentation mock | Provider (injection) |
|---|---|---|
| `PropertyRepository` | `MockPropertyDataSource` | `propertyRepositoryProvider` |
| `AgencyRepository` | `MockAgencyDataSource` | `agencyRepositoryProvider` |
| `FavoritesRepository` | `MockFavoritesDataSource` | `favoritesRepositoryProvider` |
| `LeadsRepository` | `MockLeadsDataSource` | `leadsRepositoryProvider` |
| `AnalyticsService` | `MockAnalyticsService` | `analyticsServiceProvider` |

Toute l'injection vit dans **un seul fichier** : `lib/data/providers/repository_providers.dart`. Basculer un repository vers Supabase = changer la valeur retournée par son provider, rien d'autre.

**Providers dérivés** (`lib/data/providers/feed_providers.dart`, `search_filters_controller.dart`, `favorites_controller.dart`) :

- `feedPropertiesProvider` (`FutureProvider<List<Property>>`) — biens publiés, triés par nouveauté.
- `agenciesByIdProvider` (`FutureProvider<Map<String, Agency>>`) — évite un appel par carte pour le logo agence.
- `propertyByIdProvider` (`FutureProvider.family<Property?, String>`) — fiche détail.
- `searchFiltersControllerProvider` (`StateNotifierProvider<SearchFiltersController, SearchFilters>`) — état des filtres actifs, lu/écrit en direct par la feuille de filtres et la barre flottante.
- `filteredPropertyCountProvider` (`Provider<int>`) — compteur du bouton « Afficher N biens », **calcul réel** sur les données mock via `SearchFilters.matches()` (voir section 6), pas un chiffre inventé.
- `favoritesControllerProvider` (`StateNotifierProvider<FavoritesController, Set<String>>`) — favoris de la session, avec un identifiant utilisateur mock unique (`mockSessionUserId`) tant que l'authentification réelle n'existe pas.

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
- **`SnappyPageScrollPhysics`** (`lib/core/widgets/snappy_page_physics.dart`) — ressort de fin de geste personnalisé (`mass: 0.3, stiffness: 180, ratio: 1`) appliqué au feed vertical, à la galerie photo de chaque carte et à la galerie de la fiche détail.
- **`allowImplicitScrolling: true`** sur les mêmes trois `PageView` — améliore la navigation VoiceOver/TalkBack. Vérifié empiriquement (test dédié, `test/snappy_page_physics_test.dart` + investigation documentée dans le commit `3c3759c`) que cette option ne pré-monte **pas** réellement les pages voisines en mémoire malgré son nom — ce n'est pas le mécanisme qui explique la fluidité, gardé uniquement pour son bénéfice d'accessibilité réel.

## 11. Tests

7 fichiers, ~25 tests (`flutter test`). Conventions : voir [CONTRIBUTING.md](CONTRIBUTING.md).

| Fichier | Couvre |
|---|---|
| `mock_data_test.dart` | Intégrité des données mock (agences référencées, photos de couverture, round-trip JSON) |
| `main_shell_test.dart` | Navigation 4 onglets |
| `discover_feed_test.dart` | Indépendance swipe vertical/horizontal, barre flottante, feuille de filtres, recherches enregistrées, `RepaintBoundary` |
| `property_card_gestures_test.dart` | Séparation stricte des zones de geste (média = like, texte = ouvrir la fiche) |
| `property_detail_test.dart` | Contenu de la fiche détail, porte d'authentification |
| `property_detail_dismiss_test.dart` | Fermeture par swipe (seuil de confirmation) |
| `snappy_page_physics_test.dart` | Tuning du ressort personnalisé |

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
