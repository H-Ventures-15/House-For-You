# API_PLAN — House For You

> **Statut : vivant, non implémenté.** House For You n'aura pas d'API REST maison — Supabase expose Postgres directement via PostgREST (requêtes filtrées protégées par RLS), complété par des Edge Functions pour tout ce qui doit être validé côté serveur. Ce document mappe chaque méthode de repository Dart existante à son futur point d'accès Supabase, pour que la bascule de l'étape 10 ([ROADMAP.md](ROADMAP.md)) soit une simple substitution.
>
> Dernière mise à jour : 2026-07-20 (sous-étape 2.3 — `SavedSearchesRepository` créé côté mock).

---

## 1. Principe

- **Lecture** : requêtes PostgREST directes via le SDK `supabase_flutter`, filtrées par les policies RLS (voir [DATABASE_PLAN.md](DATABASE_PLAN.md) section 5). Pas d'endpoint REST custom pour lire des données déjà protégées par RLS.
- **Écriture sensible ou qui doit être validée/limitée en débit** : Edge Function dédiée (Deno), jamais une insertion directe depuis le client. C'est le cas de `property_events` (voir section 5).
- **Authentification** : Supabase Auth (email/mot de passe au MVP, réseaux sociaux envisageables plus tard — voir [BACKLOG.md](BACKLOG.md)).
- **Fichiers** : Supabase Storage pour les photos, Cloudflare Stream ou Mux pour la vidéo (voir [DECISIONS.md](DECISIONS.md) et [BACKLOG.md](BACKLOG.md)).

Chaque repository Dart (`lib/data/repositories/*.dart`) restera l'unique point de contact entre l'app et cette couche — aucun écran n'appellera jamais directement le SDK Supabase.

## 2. Mapping repository → Supabase

### 2.1 `PropertyRepository`

| Méthode Dart | Implémentation Supabase future |
|---|---|
| `getFeed()` | `SELECT` sur la vue `published_properties` (voir [DATABASE_PLAN.md](DATABASE_PLAN.md) section 8), `ORDER BY published_at DESC`, avec jointure `property_media` (photo de couverture) et `property_translations` (locale courante). Pagination par curseur (`published_at`, `id`) à introduire dès que le volume de biens le justifie — absente au MVP mock (12 biens). |
| `search(SearchFilters)` | `SELECT` filtré : traduction directe des champs de `SearchFilters` en clauses `.eq()`/`.gte()`/`.lte()`/`.contains()` PostgREST. À évaluer en étape 10 : requête composée côté client vs fonction Postgres `search_properties` dédiée si la complexité des filtres (caractéristiques multiples, rayon géographique) dépasse ce que PostgREST exprime proprement. |
| `getById(String id)` | `SELECT` unique avec jointures (`property_media`, `property_features`, `property_translations`, `agencies`). `property_private_locations` **jamais** inclus dans cette requête publique. |
| `getByAgency(String agencyId)` | `SELECT` filtré `agency_id = :id AND status = 'published'`. |

### 2.2 `AgencyRepository`

| Méthode Dart | Implémentation Supabase future |
|---|---|
| `getAll()` | `SELECT * FROM agencies`. |
| `getById(String id)` | `SELECT` unique. |

### 2.3 `FavoritesRepository`

| Méthode Dart | Implémentation Supabase future |
|---|---|
| `getFavorites(userId)` | `SELECT` sur `favorites` jointe à `properties`, filtrée par RLS (`user_id = auth.uid()`). |
| `addFavorite(userId, propertyId)` | `INSERT` sur `favorites`. |
| `removeFavorite(userId, propertyId)` | `DELETE` sur `favorites`. |
| `isFavorite(userId, propertyId)` | `SELECT` avec `.maybeSingle()`. |

### 2.4 `LeadsRepository`

| Méthode Dart | Implémentation Supabase future |
|---|---|
| `createLead(Lead)` | `INSERT` sur `leads`, `user_id` forcé à `auth.uid()` côté RLS (jamais fourni par le client). |

### 2.5 `AnalyticsService`

| Méthode Dart | Implémentation Supabase future |
|---|---|
| `track(PropertyEvent)` | **Jamais un `INSERT` direct.** Appel à l'Edge Function `track-event` (voir section 5) — c'est la seule voie d'écriture vers `property_events`. |

### 2.6 `SavedSearchesRepository` *(créé à la sous-étape 2.3, mock complet)*

| Méthode Dart | Implémentation Supabase future |
|---|---|
| `getAll(userId)` | `SELECT` sur `saved_searches`, filtrée par RLS (`user_id = auth.uid()`). |
| `save(userId, label, filters)` | `INSERT` sur `saved_searches` — nécessite d'abord la sérialisation `toJson` de `SearchFilters` (voir [DATABASE_PLAN.md](DATABASE_PLAN.md) section 9, point 5). |
| `rename(userId, searchId, newLabel)` | `UPDATE saved_searches SET label = ... WHERE id = ...`. |
| `remove(userId, searchId)` | `DELETE` sur `saved_searches`. |

Contrairement à `FavoritesRepository`, les points d'entrée UI de ce repository ne passent pas encore par `requireAuth()` (voir [DECISIONS.md](DECISIONS.md) ADR-016) — à ajouter au même moment que la bascule Supabase, puisque la policy RLS `user_id = auth.uid()` exigera une session réelle.

### 2.7 Futurs repositories (non encore créés côté Dart)

| Repository (à créer) | Écran(s) concerné(s) | Étape |
|---|---|---|
| `AuthRepository` | Connexion/inscription modale | 5 |
| `UserProfileRepository` | Profil | 8 |

## 3. Authentification (étape 5)

- Supabase Auth, email/mot de passe au MVP.
- Écran modal contextuel, jamais un écran de démarrage obligatoire (voir [UX_RULES.md](UX_RULES.md) section 14).
- Après connexion réussie, l'action initiale qui a déclenché la porte (`requireAuth()`) doit s'exécuter automatiquement — pas besoin pour l'utilisateur de reproduire son geste (favori, contact...).
- Session persistée entre les lancements (`supabase_flutter` gère le rafraîchissement de token) — jamais de reconnexion systématique à chaque ouverture.
- `authStateProvider` (aujourd'hui un simple `StateProvider<bool>` mock, `lib/core/auth/auth_guard.dart`) sera remplacé par un `StreamProvider` écoutant `Supabase.instance.client.auth.onAuthStateChange`.

## 4. Upload (étape 10, côté agence — hors app mobile grand public)

L'upload de photos/vidéos par une agence est un flux **back-office**, hors périmètre de cette application de recherche (voir [PRODUCT_SPEC.md](PRODUCT_SPEC.md) section 10.7 et [BACKLOG.md](BACKLOG.md)). Prévu pour mémoire :

- Photos → Supabase Storage, bucket `property-media`, policy d'écriture réservée aux membres actifs de l'agence propriétaire.
- Vidéo → upload direct vers Cloudflare Stream ou Mux (à trancher), `playback_id` renvoyé et stocké dans `property_media`.

## 5. Edge Function `track-event`

Seul point d'écriture autorisé vers `property_events` (voir [DATABASE_PLAN.md](DATABASE_PLAN.md) section 5 et 7).

**Contrat proposé** (à affiner en étape 9) :

```
POST /functions/v1/track-event
{
  "propertyId": "uuid",
  "sessionId": "string",
  "eventType": "feed_impression | detail_open | favorite_add | favorite_remove | share | contact_request | visit_request | view_duration",
  "value": number | null
}
```

Responsabilités de la fonction :
1. Valider que `propertyId` existe et est publié.
2. Résoudre `userId` depuis le JWT si présent (invité autorisé — `userId` reste `null`).
3. Limiter le débit par `sessionId` (ex. une seule `feed_impression` par bien par session sur une fenêtre courte — cohérent avec la déduplication déjà faite côté app, `_trackedImpressions` dans `discover_screen.dart`).
4. Rejeter les événements incohérents (ex. `favorite_remove` sans historique d'ajout côté serveur).
5. `INSERT` via `service_role`, jamais exposé au client.

Note pour l'étape 9 : la logique de déduplication déjà présente côté app (`Set<String> _trackedImpressions`, `discover_screen.dart`) devra être **doublée** côté serveur — ne jamais faire confiance uniquement au client pour la qualité des statistiques envoyées aux agences.

## 6. Notifications (non développé, voir [BACKLOG.md](BACKLOG.md))

Aucune infrastructure de notification (push ou in-app) n'existe. Pistes à trancher avant implémentation :
- Notifications push (Firebase Cloud Messaging ou APNs/FCM via Supabase) pour les alertes de recherche sauvegardée (`saved_searches.notify_on_new_match`, voir [DATABASE_PLAN.md](DATABASE_PLAN.md)).
- Notification de mise à jour de statut d'un `lead` (l'agence a répondu).

## 7. Rate limiting & abus

- `track-event` : limité par session (voir section 5).
- Formulaires de lead (étape 7) : limiter le nombre de leads créés par utilisateur/agence sur une fenêtre glissante, pour éviter le spam d'une agence par un utilisateur malveillant — règle exacte à définir en étape 7.

---

**Documents liés** : [DATABASE_PLAN.md](DATABASE_PLAN.md) · [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md) · [DECISIONS.md](DECISIONS.md) · [BACKLOG.md](BACKLOG.md)
