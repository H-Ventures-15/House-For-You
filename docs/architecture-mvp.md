# House For You — Proposition d'architecture MVP (v3 — validée)

> Copie versionnée dans le dépôt Git pour que toute personne/agent qui clone le projet ait le contexte complet. Le fichier de travail original reste à la racine du dossier partagé (`House For You/architecture-mvp.md`, hors dépôt) — en cas de divergence, cette copie fait foi pour le code puisqu'elle est versionnée avec lui.
>
> v2 intégrait les 9 premiers retours : feed vertical réintégré au MVP, pas d'inscription forcée à l'ouverture, agences retirées de la navigation principale, demandes de contact/visite enregistrées en base, statistiques essentielles dès le MVP, colonnes structurées pour les critères de recherche fréquents, modèle d'équipe d'agence, et médias prêts pour la vidéo.
>
> v3 applique les 3 corrections finales : `address_full`/`latitude`/`longitude` isolées dans une table `property_private_locations` à part (une policy RLS protège des lignes, pas des colonnes — donc les données sensibles ne peuvent plus fuiter via une policy mal écrite sur `properties`) ; `property_events` n'accepte plus aucune insertion directe, tout passe par l'Edge Function `track-event` (validation, rate-limit, rejet des événements incohérents) ; `properties` gagne `published_at`/`archived_at`/`deleted_at` pour le tri du feed, les nouveautés, l'archivage et la suppression logique.
>
> **Architecture validée par Hugo — l'étape 0 (setup) est développée sur cette base.**

Stack confirmée : **Flutter** (mobile-first, iOS + Android), **Supabase** (Postgres, Auth, Storage), vidéo prévue juste après la V1 photo via Cloudflare Stream ou Mux, **GitHub** pour le versionnement. Cible initiale : Belgique francophone, structure prête pour NL/EN.

---

## 1. Architecture globale du projet

**Principe** : séparation stricte en 3 couches, par feature.

- **Présentation** (`screens`, `widgets`) — UI pure, pas de logique métier ni d'accès direct aux données.
- **Logique métier / état** (`providers`, `controllers`) — Riverpod. Orchestre les appels aux repositories, expose l'état à l'UI (loading/data/error).
- **Accès aux données** (`repositories`, `datasources`, `models`) — chaque repository a une interface abstraite avec deux implémentations : `MockXxxDataSource` (données fictives, actif au MVP) et `SupabaseXxxDataSource` (activé feature par feature). L'UI et les providers ne connaissent que l'interface, jamais l'implémentation concrète.

**Nouveau en v2** : un `core/services/analytics_service.dart` transversal (interface + implémentation mock/Supabase), appelé depuis les providers de chaque feature pour envoyer les événements (impression, ouverture fiche, favori, partage, contact, visite, durée) sans dupliquer la logique de tracking dans chaque écran. Côté Supabase, ce service n'insère jamais directement dans `property_events` : il appelle une Edge Function `track-event` qui valide, limite le débit et filtre les événements incohérents avant écriture (voir section 5).

**Accès invité vs connecté** : le "guard" d'authentification n'est plus une redirection globale au lancement, mais une vérification ponctuelle au niveau de l'action (favori, contact, visite, alerte). Concrètement : un `AuthGuard` (provider) que les boutons protégés interrogent avant d'exécuter leur action ; si pas de session, ouverture d'un écran de connexion modal avec callback vers l'action initiale une fois connecté.

**State management** : Riverpod. **Navigation** : GoRouter. **Backend** : Supabase Postgres + Auth + Storage, clé anon publique uniquement, sécurité réelle via RLS. **Internationalisation** : `.arb` dès le départ, `fr.arb` rempli, `nl.arb`/`en.arb` vides mais présents.

---

## 2. Arborescence Flutter

```
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── theme/
│   ├── router/
│   │   └── app_router.dart        # ShellRoute 4 onglets + route auth modale contextuelle
│   ├── widgets/
│   │   ├── ph_button.dart
│   │   ├── property_card.dart     # variantes .feed() plein écran et .list() compacte
│   │   ├── ph_chip.dart
│   │   ├── ph_slider.dart
│   │   ├── loading_state.dart
│   │   └── error_state.dart
│   ├── services/
│   │   └── analytics_service.dart # interface + impl mock/supabase
│   ├── auth/
│   │   └── auth_guard.dart        # vérifie session avant action protégée
│   ├── errors/
│   └── utils/
│
├── data/
│   ├── models/
│   ├── datasources/
│   │   ├── mock/
│   │   └── supabase/
│   └── repositories/
│
├── features/
│   ├── auth/                      # écran connexion/inscription, déclenché contextuellement
│   ├── discover/                  # feed vertical (Découvrir)
│   ├── search/                    # étapes guidées + résultats (liste)
│   ├── property_detail/           # fiche bien + bloc agence intégré
│   ├── agency/                    # fiche agence minimale (pas d'annuaire au MVP)
│   ├── leads/                     # formulaires contact + demande de visite
│   ├── favorites/
│   └── profile/
│
└── l10n/
    ├── app_fr.arb
    ├── app_nl.arb
    └── app_en.arb
```

`features/agency/` ne contient qu'un écran de détail (réutilisé depuis la fiche bien) — pas de liste/recherche d'agences au MVP, conformément au point 3.

---

## 3. Écrans du premier MVP

1. Splash — vérifie une session existante si présente, mais **n'oblige jamais** la connexion
2. Coquille de navigation — bottom bar 4 onglets : **Découvrir, Rechercher, Favoris, Profil**
3. Découvrir — feed vertical plein écran (photos, une carte-bien par page), accessible sans compte
4. Recherche guidée — étapes visuelles (transaction, type, localisation, budget, chambres, critères)
5. Résultats de recherche — liste de cartes (vue alternative au feed, mêmes données/composant carte)
6. Fiche détail d'un bien — galerie, infos, critères, bloc agence, boutons favori/contacter/demander une visite
7. Connexion / Inscription — écran modal déclenché uniquement par une action protégée
8. Formulaire de contact agence — court, enregistré en base
9. Formulaire de demande de visite — court, enregistré en base
10. Favoris — état invité (CTA connexion) ou liste des biens sauvegardés si connecté
11. Profil — état invité (CTA connexion) ou consultation/édition + déconnexion si connecté

---

## 4. Parcours utilisateur

**Premier lancement (invité)** : Splash → aucune vérification bloquante → arrivée directe sur **Découvrir** (feed vertical) → swipe vertical entre les biens → tap "voir la fiche" → fiche détail bien, accessible sans compte.

**Action protégée (favori / contacter / demander une visite / créer une alerte)** : tap sur le bouton → `AuthGuard` détecte l'absence de session → écran de connexion/inscription modal ("Crée un compte pour ajouter ce bien à tes favoris") → après connexion, l'action initiale s'exécute automatiquement (le favori s'ajoute, le formulaire s'ouvre...), pas besoin de reproduire le geste.

**Recherche** : onglet Rechercher → étapes guidées → bouton résultats → liste de cartes → tap → fiche détail (même écran que depuis le feed).

**Contact agence** : depuis la fiche bien, bouton "Contacter l'agence" → (gate auth si invité) → formulaire court (message, coordonnées pré-remplies depuis le profil) → création d'un `lead` type `contact`. Un lien secondaire (téléphone/email direct) reste disponible mais l'action principale passe par le formulaire enregistré, pour permettre de prouver la valeur aux agences.

**Demande de visite** : depuis la fiche bien, bouton "Demander une visite" → (gate auth) → formulaire (prénom, téléphone, message, 2-3 disponibilités, consentement) → création d'un `lead` type `visit`.

**Favoris (invité)** : écran avec message + CTA connexion. **Favoris (connecté)** : liste des biens sauvegardés, état vide propre si aucun favori.

**Profil (invité)** : écran de connexion/inscription. **Profil (connecté)** : infos personnelles, quelques préférences, déconnexion.

Session persistante entre les lancements une fois connecté — pas de reconnexion à chaque ouverture, mais jamais de connexion imposée à un utilisateur qui veut juste regarder.

---

## 5. Schéma minimal de base de données (Supabase Postgres)

**profiles** *(étend `auth.users`)*
`id (uuid, FK auth.users), role (enum: user/agent/admin), first_name, last_name, phone, avatar_url, created_at, updated_at`

**agencies**
`id, name, description, logo_url, address, postal_code, city, coverage_area, specialties (text[]), phone, email, website, verified (bool), created_at`

**agency_members** *(remplace le simple `agency_id` sur profiles)*
`agency_id (FK agencies), user_id (FK profiles), role (enum: owner/agent), status (enum: pending/active/suspended), created_at` — clé composite `(agency_id, user_id)`. Permet plusieurs agents par agence avec des droits différents, et sert de base à un futur onboarding d'agence sans migration.

**properties**
`id, agent_id (FK profiles, nullable), agency_id (FK agencies, nullable), transaction_type (vente/location), property_type (maison/appartement/terrain/autre), price, currency (défaut EUR), surface, land_surface, bedrooms, bathrooms, garden (bool), garage (bool), terrace (bool), energy_score, construction_year, postal_code, city, province, display_latitude, display_longitude (public, approximatif), location_precision (enum: exact/approximate/city_only — choisi par l'agence), status (draft/published/archived), published_at, archived_at, deleted_at, created_at, updated_at`

L'adresse complète et les coordonnées exactes ne vivent **plus dans cette table** — voir `property_private_locations` ci-dessous. Les critères fréquemment filtrés (bathrooms, land_surface, garden, garage, terrace, energy_score, construction_year) restent des **colonnes structurées** plutôt que des lignes clé-valeur, pour des filtres/index performants. Les champs `published_at`/`archived_at`/`deleted_at` permettent de trier le feed par nouveauté, de distinguer un bien archivé d'un bien supprimé, et de faire de la suppression logique (jamais de `DELETE` physique sur une ligne qui a déjà des favoris/leads/événements liés).

**property_private_locations** *(sépare physiquement les données sensibles)*
`property_id (FK properties, PK), address_full, latitude, longitude, updated_at`

Une policy RLS protège des **lignes**, pas des colonnes : si les invités peuvent lire `properties`, ils pourraient aussi lire `address_full`/`latitude`/`longitude` si ces champs y résidaient. En les isolant dans une table à part, accessible uniquement aux membres actifs de l'agence propriétaire (`agency_members`) et aux admins, une policy mal écrite sur `properties` ne peut plus faire fuiter l'adresse exacte — la table qui la contient n'a tout simplement pas de policy de lecture publique.

**property_translations** — `property_id, locale (fr/nl/en), title, description` — une seule ligne `locale='fr'` au MVP.

**property_media** *(vidéo-prête dès le MVP)*
`id, property_id, media_type (enum: photo/video), storage_provider (enum: supabase/cloudflare_stream/mux), storage_path, playback_id (nullable, rempli pour les vidéos CDN), thumbnail_url, position, is_cover (bool), processing_status (enum: ready/processing/failed), created_at` — seules les photos sont peuplées au MVP, mais aucune migration ne sera nécessaire pour brancher la vidéo ensuite.

**property_features** *(critères ad hoc/rares, plus rarement filtrés)*
`id, property_id, feature_key, feature_value`

**favorites**
`user_id (FK profiles), property_id (FK properties), created_at` — clé composite, nécessite une session.

**leads** *(remplace le simple lien téléphone/email/site)*
`id, property_id (FK), agency_id (FK), agent_id (FK profiles, nullable), user_id (FK profiles), type (enum: contact/visit), message, first_name, phone, availability_slots (jsonb, 2-3 créneaux pour les visites), consent (bool), status (enum: new/contacted/scheduled/closed), created_at`

**property_events** *(statistiques essentielles)*
`id, property_id (FK), user_id (FK profiles, nullable — les invités génèrent aussi des événements), session_id, event_type (enum: feed_impression/detail_open/favorite_add/favorite_remove/share/contact_request/visit_request/view_duration), value (numeric, nullable — ex. durée en secondes), created_at`

### Row Level Security — principes
- `properties` : lecture publique si `status='published'` et `deleted_at IS NULL` (seuls `city`, `postal_code`, `province`, `display_latitude`/`display_longitude` et `location_precision` sont exposés publiquement — l'adresse exacte n'existe même pas dans cette table) ; écriture pour les membres actifs de l'agence via `agency_members` ou l'agent propriétaire ; accès total admin.
- `property_private_locations` : **aucune policy de lecture publique** — lecture/écriture réservées aux membres actifs (`agency_members`) de l'agence propriétaire du bien et aux admins.
- `property_media`, `property_features`, `property_translations` : héritent des règles du bien parent.
- `favorites` : session requise, chacun ne voit/modifie que ses propres lignes.
- `leads` : création réservée aux utilisateurs connectés (leur propre `user_id`) ; lecture réservée aux membres actifs de l'agence concernée et aux admins.
- `property_events` : **aucune policy INSERT côté client**, ni anonyme ni authentifiée. Tout événement passe par une Edge Function `track-event` qui valide, limite le débit et rejette les événements incohérents avant écriture via `service_role`. Lecture agrégée réservée aux membres de l'agence propriétaire du bien et aux admins.
- `agency_members` : gestion réservée aux membres `role='owner'` de l'agence concernée et aux admins.
- `profiles` : chacun lit/modifie son propre profil ; le champ `role` n'est modifiable que par un admin.

---

## 6. Modèles de données (Dart, `data/models/`)

- `user_profile.dart` → `UserProfile`
- `agency.dart` → `Agency`
- `agency_member.dart` → `AgencyMember`
- `property.dart` → `Property`
- `property_private_location.dart` → `PropertyPrivateLocation`
- `property_media.dart` → `PropertyMedia`
- `property_feature.dart` → `PropertyFeature`
- `lead.dart` → `Lead`
- `property_event.dart` → `PropertyEvent`
- `search_filters.dart` → `SearchFilters`

---

## 7. Stratégie de navigation

- **Coquille principale** : `StatefulShellRoute` GoRouter, bottom bar 4 onglets (Découvrir, Rechercher, Favoris, Profil), **tous accessibles sans compte**.
- **Découvrir** : onglet par défaut à l'ouverture, feed vertical plein écran.
- **Favoris / Profil en mode invité** : l'onglet reste accessible, état "invité" avec CTA de connexion.
- **Rechercher** : sous-navigation interne en étapes, puis push vers Résultats.
- **Fiche bien** : route push réutilisée partout, incluant le bloc agence.
- **Auth** : route modale déclenchée contextuellement, redirection vers l'action initiale après succès.
- **Agence** : accessible uniquement en push depuis la fiche bien.

---

## 8. Design system de base

**Fondations** (`core/theme/`) : palette restreinte, 1 famille de police à échelle limitée, espacement en échelle fixe (4/8/12/16/24/32), rayons cohérents.

**Composants réutilisables** (`core/widgets/`) : `PhButton`, `PropertyCard` (`.feed()` / `.list()`), `PhChip`, `PhSlider`, `LoadingState` / `ErrorState`, animations légères.

---

## 9. Ordre exact de développement

| # | Étape | Contenu |
|---|---|---|
| 0 | Setup | Scaffold Flutter, design system, GoRouter, Riverpod, mocks (properties, agencies, leads) |
| 1 | Coquille de navigation | Bottom bar 4 onglets, accessible sans compte, états invité pour Favoris/Profil |
| 2 | Feed Découvrir | Feed vertical plein écran (photos, mock data), tracking impressions basique |
| 3 | Recherche guidée + Résultats | Étapes visuelles, liste de cartes (composant `PropertyCard.list()`) |
| 4 | Fiche détail bien | Galerie, infos structurées, bloc agence, bouton favori avec `AuthGuard` |
| 5 | Authentification contextuelle | Supabase Auth, écran modal déclenché à la demande, redirection post-login |
| 6 | Favoris | Table `favorites`, état invité vs connecté |
| 7 | Leads (contact + visite) | Table `leads`, deux formulaires courts |
| 8 | Profil | Consultation/édition, déconnexion |
| 9 | Analytics | Table `property_events` + Edge Function `track-event`, instrumentation |
| 10 | Bascule Supabase | Remplacement des mocks, mise en place des RLS |
| 11 | Test réel & polish | Test sur téléphone, corrections UX |

---

## 10. Reporté à plus tard (volontairement hors MVP)

Vidéo dans le feed · annuaire complet d'agences · affichage carte (et PostGIS) · recommandations personnalisées · recherche en langage naturel / assistant IA · alertes sur recherches sauvegardées · comparaison de biens · collections de favoris, notes personnelles, partage · visite virtuelle · documents PEB détaillés · calcul de mensualité, estimation des frais · calendrier de visite complet · chat en direct · paiements, abonnements · notifications push avancées · dashboard agence complet · administration complète · traduction NL/EN de l'interface.
