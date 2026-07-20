# DATABASE_PLAN — House For You

> **Statut : vivant, non implémenté.** Ce document prépare intégralement le schéma Supabase (Postgres) qui sera mis en place à l'étape 10 ([ROADMAP.md](ROADMAP.md)). **Aucune migration réelle n'existe encore** — toutes les données de l'application actuelle sont mock (`lib/data/datasources/mock/`). Ce document doit rester synchronisé avec les modèles Dart (`lib/data/models/`) : tout nouveau champ ajouté à un modèle doit apparaître ici, et réciproquement.
>
> Dernière mise à jour : 2026-07-20.

---

## 1. Principes directeurs

1. **Séparation des données sensibles par table, pas par colonne.** Une policy RLS protège des *lignes*, jamais des colonnes. L'adresse exacte et les coordonnées précises d'un bien vivent dans une table à part (`property_private_locations`), inaccessible en lecture publique — une policy mal écrite sur `properties` ne peut donc jamais les faire fuiter.
2. **Colonnes structurées pour les critères fréquemment filtrés** (chambres, salles de bain, surface, jardin, garage, terrasse, PEB, année de construction) — jamais en lignes clé-valeur, pour des index et des filtres performants. Les critères rares/ad hoc restent en clé-valeur (`property_features`).
3. **Suppression logique uniquement.** Jamais de `DELETE` physique sur une ligne qui peut avoir des favoris, des leads ou des événements liés — `deleted_at` marque la suppression.
4. **Aucune écriture client directe sur les tables analytiques.** `property_events` n'accepte aucune policy `INSERT` côté client — tout événement transite par une Edge Function qui valide, limite le débit et rejette les événements incohérents.
5. **Vidéo-prêt dès le MVP.** `property_media` distingue déjà `photo`/`video` et le fournisseur de stockage, même si seules les photos sont peuplées initialement.

## 2. Schéma entité-relation (vue d'ensemble)

```
auth.users (Supabase Auth)
    │ 1:1
    ▼
profiles ──────────────┐
    │ 1:N                │ 1:N
    ▼                    ▼
agency_members       favorites ─────┐
    │ N:1                           │ N:1
    ▼                               ▼
agencies ◄──1:N── properties ◄──────┘
    │                  │ 1:N
    │                  ├──► property_media
    │                  ├──► property_features
    │                  ├──► property_translations
    │                  ├──► property_private_locations (1:1)
    │                  └──► property_events
    │
    └──1:N── leads ◄──N:1── properties

profiles ──1:N── saved_searches
```

## 3. Tables

### 3.1 `profiles` *(étend `auth.users`)*

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| `id` | `uuid` | PK, FK `auth.users(id)` | |
| `role` | `enum user_role` (`user`, `agent`, `admin`) | défaut `user` | modifiable uniquement par un admin |
| `first_name` | `text` | nullable | |
| `last_name` | `text` | nullable | |
| `phone` | `text` | nullable | |
| `avatar_url` | `text` | nullable | |
| `created_at` | `timestamptz` | défaut `now()` | |
| `updated_at` | `timestamptz` | nullable, trigger auto | voir section 6 |

Modèle Dart : `UserProfile` (`lib/data/models/user_profile.dart`).

### 3.2 `agencies`

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| `id` | `uuid` | PK, défaut `gen_random_uuid()` | |
| `name` | `text` | requis | |
| `description` | `text` | nullable | |
| `logo_url` | `text` | nullable | |
| `address` | `text` | nullable | |
| `postal_code` | `text` | nullable | |
| `city` | `text` | nullable | |
| `coverage_area` | `text` | nullable | |
| `specialties` | `text[]` | défaut `{}` | |
| `phone` | `text` | nullable | |
| `email` | `text` | nullable | |
| `website` | `text` | nullable | |
| `verified` | `boolean` | défaut `false` | badge de confiance affiché dans l'app |
| `created_at` | `timestamptz` | défaut `now()` | |

Modèle Dart : `Agency` (`lib/data/models/agency.dart`).

### 3.3 `agency_members` *(remplace un simple `agency_id` sur `profiles`)*

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| `agency_id` | `uuid` | FK `agencies(id)`, PK composite | |
| `user_id` | `uuid` | FK `profiles(id)`, PK composite | |
| `role` | `enum agency_member_role` (`owner`, `agent`) | requis | |
| `status` | `enum agency_member_status` (`pending`, `active`, `suspended`) | défaut `pending` | |
| `created_at` | `timestamptz` | défaut `now()` | |

Permet plusieurs agents par agence avec des droits différents, et sert de base à un futur onboarding d'agence sans migration. Modèle Dart : `AgencyMember`.

### 3.4 `properties`

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| `id` | `uuid` | PK | |
| `agent_id` | `uuid` | FK `profiles(id)`, nullable | |
| `agency_id` | `uuid` | FK `agencies(id)`, nullable | |
| `transaction_type` | `enum transaction_type` (`sale`, `rent`) | requis | |
| `property_type` | `enum property_type` (`house`, `apartment`, `land`, `other`) | requis | voir note ci-dessous |
| `price` | `numeric` | requis | |
| `currency` | `text` | défaut `EUR` | |
| `surface` | `numeric` | requis | m² habitables |
| `land_surface` | `numeric` | nullable | m² de terrain |
| `bedrooms` | `int` | défaut `0` | |
| `bathrooms` | `int` | nullable | |
| `garden` | `boolean` | défaut `false` | |
| `garage` | `boolean` | défaut `false` | |
| `terrace` | `boolean` | défaut `false` | |
| `energy_score` | `text` | nullable | `A+`…`G` |
| `construction_year` | `int` | nullable | |
| `postal_code` | `text` | requis | |
| `city` | `text` | requis | |
| `province` | `text` | nullable | |
| `display_latitude` | `double precision` | nullable | **publique, approximative** |
| `display_longitude` | `double precision` | nullable | **publique, approximative** |
| `location_precision` | `enum location_precision` (`exact`, `approximate`, `city_only`) | défaut `approximate` | choisi par l'agence |
| `status` | `enum property_status` (`draft`, `published`, `archived`) | défaut `draft` | |
| `published_at` | `timestamptz` | nullable, trigger auto | voir section 6 |
| `archived_at` | `timestamptz` | nullable | |
| `deleted_at` | `timestamptz` | nullable | suppression logique |
| `created_at` | `timestamptz` | défaut `now()` | |
| `updated_at` | `timestamptz` | trigger auto | voir section 6 |

L'adresse complète et les coordonnées exactes **ne vivent jamais dans cette table** — voir `property_private_locations`.

> **Écart avec l'app actuelle à trancher avant migration** : la feuille de filtres (`lib/features/discover/filters/filter_options.dart`) propose 9 types de bien à l'utilisateur (Maison, Appartement, Villa, Terrain, Projet neuf, Immeuble de rapport, Commerce, Entrepôt, Garage) alors que l'enum `property_type` n'en compte que 4. Ce choix est documenté dans [DECISIONS.md](DECISIONS.md) — **avant la bascule Supabase (étape 10), il faudra décider** d'étendre l'enum `property_type` à ces 9 valeurs ou d'ajouter une colonne `property_subtype` distincte. Ne pas migrer sans avoir tranché ce point.

Modèle Dart : `Property` (`lib/data/models/property.dart`).

### 3.5 `property_private_locations` *(sépare physiquement les données sensibles)*

| Colonne | Type | Contraintes |
|---|---|---|
| `property_id` | `uuid` | PK, FK `properties(id)` |
| `address_full` | `text` | requis |
| `latitude` | `double precision` | requis |
| `longitude` | `double precision` | requis |
| `updated_at` | `timestamptz` | trigger auto |

**Aucune policy de lecture publique** (voir section 5). Modèle Dart : `PropertyPrivateLocation` — existe déjà côté Dart, non consommé par aucun écran/repository pour l'instant.

### 3.6 `property_translations`

| Colonne | Type | Contraintes |
|---|---|---|
| `property_id` | `uuid` | FK `properties(id)`, PK composite |
| `locale` | `text` (`fr`, `nl`, `en`) | PK composite |
| `title` | `text` | requis |
| `description` | `text` | requis |

Une seule ligne `locale='fr'` au MVP.

### 3.7 `property_media` *(vidéo-prête dès le MVP)*

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| `id` | `uuid` | PK | |
| `property_id` | `uuid` | FK `properties(id)` | |
| `media_type` | `enum media_type` (`photo`, `video`) | requis | seules les photos sont peuplées au MVP |
| `storage_provider` | `enum storage_provider` (`supabase`, `cloudflare_stream`, `mux`) | requis | |
| `storage_path` | `text` | requis | |
| `playback_id` | `text` | nullable | rempli pour les vidéos CDN |
| `thumbnail_url` | `text` | nullable | |
| `position` | `int` | défaut `0` | ordre d'affichage dans la galerie |
| `is_cover` | `boolean` | défaut `false` | |
| `processing_status` | `enum processing_status` (`ready`, `processing`, `failed`) | défaut `ready` | |
| `created_at` | `timestamptz` | défaut `now()` | |

Modèle Dart : `PropertyMedia`.

### 3.8 `property_features` *(critères ad hoc/rares)*

| Colonne | Type | Contraintes |
|---|---|---|
| `id` | `uuid` | PK |
| `property_id` | `uuid` | FK `properties(id)` |
| `feature_key` | `text` | requis |
| `feature_value` | `text` | requis |

**Clés utilisées par la feuille de filtres actuelle** (`lib/features/discover/filters/filter_options.dart`, section « Caractéristiques ») : `piscine`, `parking`, `cave`, `bureau`, `dressing`, `cheminee`, `ascenseur`, `pmr`, `cuisine_equipee`, `climatisation`, `pompe_a_chaleur`, `panneaux_photovoltaiques`, `borne_electrique`, `vue_degagee` (`garden`/`garage`/`terrace` restent des colonnes structurées sur `properties`, jamais dupliquées ici). Cette liste de clés n'est pas contrainte en base au MVP (texte libre) — à surveiller si elle dérive de la liste affichée côté app.

### 3.9 `favorites`

| Colonne | Type | Contraintes |
|---|---|---|
| `user_id` | `uuid` | FK `profiles(id)`, PK composite |
| `property_id` | `uuid` | FK `properties(id)`, PK composite |
| `created_at` | `timestamptz` | défaut `now()` |

Nécessite une session — jamais accessible à un invité.

### 3.10 `leads` *(remplace un simple lien téléphone/email)*

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| `id` | `uuid` | PK | |
| `property_id` | `uuid` | FK `properties(id)` | |
| `agency_id` | `uuid` | FK `agencies(id)` | |
| `agent_id` | `uuid` | FK `profiles(id)`, nullable | |
| `user_id` | `uuid` | FK `profiles(id)` | |
| `type` | `enum lead_type` (`contact`, `visit`) | requis | |
| `message` | `text` | nullable | |
| `first_name` | `text` | requis | |
| `phone` | `text` | requis | |
| `availability_slots` | `jsonb` | défaut `[]` | 2-3 créneaux pour une demande de visite |
| `consent` | `boolean` | requis | |
| `status` | `enum lead_status` (`new`, `contacted`, `scheduled`, `closed`) | défaut `new` | |
| `created_at` | `timestamptz` | défaut `now()` | |

Modèle Dart : `Lead` (déjà prêt, non consommé — attend l'étape 7).

### 3.11 `property_events` *(statistiques essentielles)*

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| `id` | `uuid` | PK | |
| `property_id` | `uuid` | FK `properties(id)` | |
| `user_id` | `uuid` | FK `profiles(id)`, nullable | les invités génèrent aussi des événements |
| `session_id` | `text` | requis | voir `lib/core/services/session_id.dart` côté app |
| `event_type` | `enum property_event_type` (`feed_impression`, `detail_open`, `favorite_add`, `favorite_remove`, `share`, `contact_request`, `visit_request`, `view_duration`) | requis | |
| `value` | `numeric` | nullable | ex. durée en secondes pour `view_duration` |
| `created_at` | `timestamptz` | défaut `now()` | |

Modèle Dart : `PropertyEvent`. Côté app, `AnalyticsService` (mock aujourd'hui) émet déjà `feed_impression`, `detail_open`, `share`, `favorite_add`, `favorite_remove` — `contact_request`, `visit_request` et `view_duration` seront émis à partir des étapes 7/9.

### 3.12 `saved_searches` *(nouveau — non présent dans `architecture-mvp.md` v3)*

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| `id` | `uuid` | PK | |
| `user_id` | `uuid` | FK `profiles(id)` | nécessite une session |
| `label` | `text` | requis | ex. « Maison à Mons » |
| `filters` | `jsonb` | requis | sérialisation de `SearchFilters` |
| `notify_on_new_match` | `boolean` | défaut `false` | base pour les futures alertes, voir [BACKLOG.md](BACKLOG.md) |
| `created_at` | `timestamptz` | défaut `now()` | |

**Ajouté par anticipation** : la fonctionnalité « recherches enregistrées » existe déjà côté app en mock statique (`lib/data/models/saved_search.dart`, `mock_saved_searches.dart`) et sera nécessairement persistée à un moment donné. Ce n'était pas dans le schéma v3 d'origine — ajout documenté ici plutôt que découvert au moment de la migration.

## 4. Index

| Table | Index | Raison |
|---|---|---|
| `properties` | `(status, deleted_at)` | filtre de lecture publique, appliqué à chaque requête du feed |
| `properties` | `(published_at DESC)` | tri du feed par nouveauté |
| `properties` | `(city)`, `(postal_code)`, `(province)` | recherche par localisation |
| `properties` | `(transaction_type, property_type)` | filtres les plus fréquents |
| `properties` | `(price)` | slider budget |
| `properties` | `(agency_id)` | fiche agence, dashboard futur |
| `property_media` | `(property_id, position)` | ordre de galerie |
| `property_features` | `(property_id, feature_key)` | filtre caractéristiques |
| `favorites` | `(user_id)` | écran Favoris |
| `leads` | `(agency_id, status)` | dashboard agence futur |
| `property_events` | `(property_id, created_at)` | agrégation de statistiques par bien |
| `property_events` | `(session_id)` | déduplication/rate-limit côté Edge Function |
| `saved_searches` | `(user_id)` | écran recherches enregistrées |

## 5. Row Level Security — principes et matrice

| Table | Lecture publique (invité) | Lecture connectée | Écriture |
|---|---|---|---|
| `properties` | Oui, si `status='published'` et `deleted_at IS NULL` — seuls `city`, `postal_code`, `province`, `display_latitude`/`display_longitude`, `location_precision` et les colonnes structurées sont exposés | Idem | Membres actifs de l'agence (`agency_members`) ou agent propriétaire ; accès total admin |
| `property_private_locations` | **Aucune** | **Aucune** | Membres actifs de l'agence propriétaire + admin uniquement |
| `property_media`, `property_features`, `property_translations` | Héritent des règles du bien parent | Idem | Idem `properties` |
| `favorites` | Non | Chacun voit/modifie ses propres lignes | Idem |
| `saved_searches` | Non | Chacun voit/modifie ses propres lignes | Idem |
| `leads` | Non | Lecture réservée aux membres actifs de l'agence concernée et aux admins | Création réservée à l'utilisateur connecté, pour son propre `user_id` |
| `property_events` | Non | Lecture agrégée réservée aux membres de l'agence propriétaire du bien et aux admins | **Aucune policy INSERT côté client** — voir section 7 |
| `agency_members` | Non | Membres de l'agence concernée (lecture) | Gestion réservée aux membres `role='owner'` de l'agence et aux admins |
| `profiles` | Non | Chacun lit/modifie son propre profil | `role` modifiable uniquement par un admin |
| `agencies` | Oui (infos publiques : nom, logo, description, coordonnées) | Idem | Membres actifs de l'agence (owner) + admin |

**Principe fondamental** : une policy RLS protège des **lignes**, jamais des colonnes. C'est pourquoi `property_private_locations` existe en table séparée plutôt qu'en colonnes sur `properties` — une policy mal écrite sur `properties` ne peut alors jamais faire fuiter l'adresse exacte, car la table qui la contient n'a tout simplement aucune policy de lecture publique.

## 6. Triggers

| Trigger | Table | Déclencheur | Effet |
|---|---|---|---|
| `set_updated_at` | `profiles`, `properties`, `property_private_locations` | `BEFORE UPDATE` | met à jour `updated_at = now()` automatiquement |
| `set_published_at` | `properties` | `BEFORE UPDATE` quand `status` passe à `published` et `published_at IS NULL` | fige `published_at = now()` à la première publication (permet de republier sans perdre la date de nouveauté d'origine — à confirmer en étape 10 selon le comportement produit voulu) |
| `set_archived_at` | `properties` | `BEFORE UPDATE` quand `status` passe à `archived` | fige `archived_at = now()` |

## 7. Fonctions & Edge Functions

| Fonction | Type | Rôle |
|---|---|---|
| `track-event` | Edge Function | Seul point d'écriture dans `property_events`. Valide le `event_type`, limite le débit par `session_id`, rejette les événements incohérents (ex. `favorite_remove` sans `favorite_add` préalable dans la session), écrit via `service_role`. |
| `search_properties` (à évaluer) | Fonction Postgres (`SECURITY DEFINER`) ou requête directe avec RLS | Point d'entrée unique pour la recherche filtrée (aujourd'hui `SearchFilters.matches()` côté Dart, contre les données mock) — à trancher en étape 10 entre requête PostgREST filtrée côté client vs fonction dédiée. |

## 8. Vues (proposées, non tranchées)

| Vue | Utilité |
|---|---|
| `published_properties` | `SELECT * FROM properties WHERE status='published' AND deleted_at IS NULL` — simplifie toutes les requêtes de lecture publique, un seul endroit pour la règle de visibilité. |
| `agency_property_stats` | Agrégation par agence des `property_events` (impressions, ouvertures, favoris, contacts) sur 30 jours glissants — base du futur dashboard agence (voir [BACKLOG.md](BACKLOG.md)). |

## 9. Ce qui reste à trancher avant la migration (étape 10)

1. Extension de l'enum `property_type` (9 valeurs côté app vs 4 en base aujourd'hui) — voir note section 3.4 et [DECISIONS.md](DECISIONS.md).
2. Liste de clés autorisées pour `property_features.feature_key` — texte libre aujourd'hui, à contraindre (enum ou table de référence) une fois la liste de caractéristiques stabilisée côté produit.
3. Comportement exact de `saved_searches.notify_on_new_match` (alertes) — dépend de l'infrastructure de notifications push, non choisie (voir [BACKLOG.md](BACKLOG.md)).
4. Fournisseur vidéo définitif (Cloudflare Stream vs Mux) — voir [BACKLOG.md](BACKLOG.md).

---

**Documents liés** : [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md) · [API_PLAN.md](API_PLAN.md) · [DECISIONS.md](DECISIONS.md) · [architecture-mvp.md](architecture-mvp.md) (schéma d'origine v3)
