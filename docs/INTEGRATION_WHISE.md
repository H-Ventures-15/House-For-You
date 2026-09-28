# INTEGRATION_WHISE — House For You

> **Statut : préparation, non implémenté.** Ce document prépare l'intégration future de [Whise](https://whise.eu) (logiciel de gestion immobilière / CRM utilisé par de nombreuses agences belges) comme **source de biens** pour House For You. **Aucun code n'existe** : l'intégration dépend de Supabase (étape 10, [ROADMAP.md](ROADMAP.md)) et d'un accord avec au moins une agence utilisatrice de Whise. Décision d'architecture associée : [DECISIONS.md](DECISIONS.md) ADR-027.
>
> Dernière mise à jour : 2026-09-28.
>
> **Niveau de confiance des informations.** Ce qui est marqué ✅ provient directement du client PHP officiel `fw4/whise-api` (enums, endpoints). Ce qui est marqué ⚠️ est une **hypothèse à vérifier** contre la documentation Whise réelle (`https://api.whise.eu/WebsiteDesigner.html`) et une vraie réponse d'API — le client PHP ne contient pas le schéma complet d'un objet « estate ».

---

## 1. Principe : Whise reste la source de vérité, House For You est une vitrine

Une agence saisit et gère ses biens **dans Whise**, comme aujourd'hui. House For You ne demande aucune double saisie : les biens sont **copiés automatiquement** dans notre base Supabase, puis servis à l'app comme n'importe quel autre bien. L'app Flutter **ne sait pas que Whise existe** — elle lit uniquement `properties` (ADR-027).

```
Agence ──saisit──► Whise ──API REST──► [Job de synchronisation] ──écrit──► Supabase (properties…) ──► App Flutter
                                        (Edge Function planifiée,
                                         secrets côté serveur)
```

Sens de la synchro au MVP : **Whise → House For You uniquement (lecture seule côté Whise).** Les leads (demandes de contact/visite) renvoyés vers Whise (`contacts()`, `calendars()`) sont une évolution ultérieure, à ne pas coupler au premier livrable.

## 2. Authentification Whise ✅

- API REST, base `https://api.whise.eu/`.
- Un appel `POST /token` avec identifiant + mot de passe Whise **de l'agence** renvoie un jeton d'accès, ensuite envoyé sur chaque requête.
- Un identifiant Whise = une agence (ou un compte « client » regroupant plusieurs bureaux — endpoint `admin()`, à explorer).

**Conséquence : chaque agence connectée fournit ses propres identifiants Whise, jamais partagés entre agences.** Ils sont stockés chiffrés côté serveur (table dédiée non lisible par les clients, ou Supabase Vault) — **jamais** dans l'app, ni dans `.env`, ni dans Git (règle `CLAUDE.md` « pas de secret dans l'app », ADR-027).

## 3. Architecture cible de la synchronisation

| Brique | Rôle |
|---|---|
| Table `agency_integrations` *(nouvelle, à ajouter à [DATABASE_PLAN.md](DATABASE_PLAN.md) au moment de la migration)* | Une ligne par agence connectée : `agency_id`, `provider` (`whise`), identifiants chiffrés, `last_synced_at`, `last_error`, `enabled`. Aucune policy de lecture côté client. |
| Colonnes `external_source` / `external_id` sur `properties` *(à ajouter)* | Relient un bien à son équivalent Whise (`'whise'` + id estate) pour faire de l'upsert idempotent et détecter les suppressions. Index unique `(external_source, external_id)`. |
| Edge Function `sync-whise` | Pour chaque agence active : obtient un jeton, pagine `estates()->list()`, transforme (section 4), `upsert` dans `properties`/`property_media`/`property_private_locations`, marque comme `archived` les biens disparus ou vendus. |
| Planificateur (`pg_cron` ou Supabase Scheduled Functions) | Déclenche la synchro (proposition : toutes les 15 min au départ ; le client PHP supporte le cache PSR-6, l'API impose probablement des limites de débit ⚠️ à vérifier). |
| Écran/flux d'onboarding agence *(hors app grand public)* | Permet à l'agence de saisir ses identifiants Whise. Probablement le futur dashboard agence ([BACKLOG.md](BACKLOG.md)) — jamais dans l'app mobile grand public. |

Robustesse à prévoir : synchro **incrémentale** (filtre par date de modification si l'API l'expose ⚠️), retries, journalisation des erreurs par agence dans `agency_integrations.last_error`, une agence en erreur ne doit jamais bloquer les autres.

## 4. Table de correspondance Whise → `Property`

Endpoint source ✅ : `estates()->list()` (filtres vus dans le client : `EstateIds`, `CategoryIds`, `StatusIds`, `DisplayStatusIds`, `Price`…) et `estates()->get()`.

### 4.1 Champs de classification — confirmés par les enums du client ✅

| Concept Whise | Valeurs Whise ✅ | Champ House For You | Règle de conversion |
|---|---|---|---|
| `Purpose` (type de transaction) | `1` Sale, `2` Rent, `3` LifeAnnuity | `transaction_type` (`sale`, `rent`) | 1→`sale`, 2→`rent`. **3 (viager) : non supporté au MVP → bien ignoré** (à documenter côté agence). |
| `Category` | `1` House, `2` Flat, `3` Plot, `4` Office, `5` Commercial, `6` Industrial, `7` GarageParking | `property_type` (`house`, `apartment`, `land`, `other`) | 1→`house`, 2→`apartment`, 3→`land`, 4-7→`other`. **Perte d'information tant que la décision « 9 types » n'est pas tranchée** ([DATABASE_PLAN.md](DATABASE_PLAN.md) section 9, point 1) : dans ce cas conserver la catégorie Whise brute dans `property_subtype`. |
| `Status` (cycle de vie de la fiche) | `1` Active, `5` Archived, `6` Deleted | `status` / `deleted_at` | 1→`published` (si en plus `PurposeStatus` publiable), 5→`archived`, 6→`deleted_at = now()` (suppression logique, jamais `DELETE`, principe 3 de [DATABASE_PLAN.md](DATABASE_PLAN.md)). |
| `PurposeStatus` (état commercial) | `1` ForSale, `2` ForRent, `3` Sold, `4` Rented, `5`/`6` sous option, `8`/`9` annulé, `10`/`11` suspendu, `14` vendu sous conditions, `19`/`23` prospection, `20`/`27`/`28` préparation, `21` réservé, `22` compromis, `24`-`26` estimation… | `status` (`published` ou `archived`) | **N'exposer publiquement que `1` (à vendre) et `2` (à louer).** Tout le reste (vendu, loué, option, compromis, prospection, estimation, préparation, suspendu, annulé) → non publié ou `archived`. Les biens « sous option/réservé/compromis » pourraient plus tard devenir un badge — décision produit, hors périmètre. |
| `DisplayStatus` | enum présente dans le client ✅ (valeurs non relevées) | *(filtre)* | ⚠️ À lire : probablement le contrôle « publier sur les sites web » — à respecter impérativement (**ne jamais publier un bien que l'agence n'a pas autorisé à diffuser**). |
| `ContractType` (mandat) | `1` Exclusive, `2` Cooperation, `3` NonExclusive, `4` CoExclusive, `5` ExclusiveAndByOwner, … `9` NoMandate | `is_exclusive` (badge « Exclusivité », voir [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md)) | `is_exclusive = ContractType ∈ {1, 5}` ⚠️ (à confirmer avec une agence : `4` co-exclusif compte-t-il ?). |
| `Availability` | `1` AtContract, `5` Immediately, `7` ToBeAgreedUpon, … | *(non modélisé)* | Ignoré au MVP. Candidat futur : « Disponible immédiatement ». |
| `Country` | enum présente ✅ | — | MVP Belgique uniquement : filtrer/ignorer les autres pays. |

### 4.2 Champs de contenu — hypothèses ⚠️ (schéma à confirmer sur une vraie réponse)

Le client PHP ne définit pas la liste des champs d'un estate. Le tableau suivant est **la correspondance visée** ; les noms de champs Whise sont à remplacer par les vrais après un premier appel réel.

| Champ House For You (`properties`…) | Source Whise probable ⚠️ | Remarque |
|---|---|---|
| `title` / `description` (table `property_translations`) | nom/description multilingue de la fiche | Whise est en principe multilingue (FR/NL/EN) → alimente directement `property_translations` par `locale`. Vérifier les langues disponibles. |
| `price`, `currency` | prix de vente ou loyer | Devise `EUR`. Pour une location, vérifier si loyer et charges sont séparés. |
| `previous_price` | historique de prix si exposé | Sinon dérivé par notre propre job (comparer à la synchro précédente) — alimente le badge « Prix réduit ». |
| `surface` | surface habitable | m². |
| `land_surface` | surface du terrain | m². |
| `bedrooms`, `bathrooms` | nombre de chambres / salles de bain | Enums `Details/BathroomType`… décrivent le *type*, pas le nombre ✅. |
| `garden`, `terrace`, `garage` | équipements booléens ou nombre/surface | Convertir `> 0`/présent en `true`. |
| `energy_score` | classe PEB | Attention aux régimes régionaux belges (Wallonie, Bruxelles, Flandre) : normaliser vers `A+`…`G`. |
| `construction_year` | année de construction | |
| `postal_code`, `city`, `province` | adresse publique | — |
| `display_latitude/longitude`, `location_precision` | coordonnées | **Ne jamais copier les coordonnées exactes dans `properties`** : rester sur l'arrondi approximatif (principe 1 de [DATABASE_PLAN.md](DATABASE_PLAN.md)). |
| `property_private_locations` (adresse exacte) | rue, numéro, coordonnées exactes | Alimenté côté serveur uniquement, jamais lisible publiquement. |
| `property_media` (photos, vidéos) | images + éventuelle visite virtuelle | Il faudra soit **copier** les images dans notre stockage (contrôle, CDN, indépendance), soit **référencer** les URL Whise (simple mais fragile). Recommandation : copier. `has_virtual_tour` ← présence d'un lien de visite virtuelle. |
| `property_features` (critères rares) | détails `Details/*` (`KitchenType`, `HeatingSource`, `RoofType`, …) ✅ | Ces enums existent dans le client : ils alimentent naturellement `property_features` (clé/valeur), une fois la liste de clés autorisées tranchée ([DATABASE_PLAN.md](DATABASE_PLAN.md) section 9, point 2). |
| `agency_id` | bureau Whise (`admin()->offices`) | Un bureau Whise ↔ une `agency` chez nous. |
| `agent_id` | représentant Whise (`admin()->representatives`) | Nécessite un mapping vers un `profile` de rôle `agent`, ou un champ texte tant que l'agent n'a pas de compte. |
| `is_featured` | *(aucun équivalent probable)* | Reste **éditorial House For You** (mise en avant payante future) — jamais alimenté par Whise. |
| `created_at` / `published_at` | dates de création/modification | Alimente le badge « Nouveau » (14 jours, `kNewListingWindow`). |

## 5. Points de vigilance

1. **Droit de diffusion** — Whise a une notion de statut d'affichage (`DisplayStatus`). Ne publier que les biens explicitement diffusables.
2. **Conformité (RGPD)** — les données Whise contiennent aussi des contacts de vendeurs/acquéreurs (`contacts()`) : **ne jamais les synchroniser** au MVP, uniquement les biens.
3. **Idempotence** — la synchro doit pouvoir être rejouée sans doublon (clé `(external_source, external_id)`).
4. **Modifications côté House For You** — les champs importés sont en lecture seule côté agence dans notre base, sinon la prochaine synchro les écrase. Les champs purement House For You (`is_featured`, badges éditoriaux) ne sont jamais touchés par la synchro.
5. **Volume et limites de débit** — ⚠️ à vérifier avant dimensionnement.
6. **Gestion d'erreur d'authentification** — identifiants changés/révoqués côté Whise → désactiver la synchro de l'agence et lui signaler, sans jamais réessayer en boucle.
7. **Autres logiciels** — d'autres CRM immobiliers existent en Belgique ; garder l'abstraction `provider` pour ne pas coder « Whise » en dur dans le schéma.

## 6. Étapes quand on décidera de l'implémenter

Pré-requis : étape 10 (Supabase) terminée + au moins une agence pilote avec identifiants Whise API + accès à la doc Whise complète.

1. Récupérer la doc Whise réelle, faire un premier appel de test, **valider/corriger la table 4.2**.
2. Trancher les points ouverts de [DATABASE_PLAN.md](DATABASE_PLAN.md) section 9 (types de bien, clés de `property_features`).
3. Migration : `agency_integrations`, `properties.external_source/external_id`.
4. Edge Function `sync-whise` + planification.
5. Flux d'onboarding agence (identifiants), probablement via le futur dashboard.
6. Tests d'intégration avec un jeu de données Whise anonymisé.

---

**Documents liés** : [DATABASE_PLAN.md](DATABASE_PLAN.md) · [DECISIONS.md](DECISIONS.md) (ADR-027) · [BACKLOG.md](BACKLOG.md) · [ROADMAP.md](ROADMAP.md) · [API_PLAN.md](API_PLAN.md)
