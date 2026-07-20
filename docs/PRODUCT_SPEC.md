# PRODUCT_SPEC — House For You

> **Statut : vivant.** Ce document est la Bible produit de House For You. Toute fonctionnalité validée (code mergé sur `main`, testée) doit y être décrite avant le commit qui la clôt. Si ce document et le code divergent, c'est une anomalie à corriger immédiatement — pas une des deux sources qui « a raison ».
>
> Dernière mise à jour : 2026-07-20 (fin de l'étape 2.1 — voir [ROADMAP.md](ROADMAP.md)).

---

## 1. Vision

Rendre la recherche d'un bien immobilier aussi agréable, rapide et intuitive que parcourir un réseau social — sans jamais sacrifier la rigueur des données qu'un achat ou une location exige.

Aujourd'hui, chercher un bien en Belgique francophone signifie naviguer des portails conçus il y a quinze ans : formulaires denses, listes de résultats austères, fiches surchargées, aucune sensation de fluidité. House For You part du principe inverse : **l'immobilier mérite le même niveau de soin produit qu'Airbnb, Apple ou TikTok.**

## 2. Mission

Construire l'application mobile de référence pour chercher un bien en Belgique francophone, en combinant :

- une **expérience de découverte** aussi addictive et fluide qu'un feed social (swipe vertical entre biens, swipe horizontal entre photos, gestes naturels) ;
- une **puissance de recherche** au niveau des meilleurs portails du marché (filtres exhaustifs, recherche géographique, tri multi-critères) ;
- une **relation de confiance avec les agences** : statistiques réelles sur les biens publiés, prospects qualifiés via des formulaires courts plutôt que des liens téléphone/email perdus dans la nature.

## 3. Objectifs

| Horizon | Objectif |
|---|---|
| MVP (étapes 0-11, voir [ROADMAP.md](ROADMAP.md)) | Une app iOS/Android complète en mode mock, prête à être connectée à Supabase, testable en conditions réelles sur téléphone. |
| Post-MVP proche | Bascule Supabase complète (auth, données réelles, RLS), premières agences pilotes en Belgique francophone. |
| Moyen terme | Vidéo dans le feed, recherche géographique (carte), alertes personnalisées, écosystème agence (dashboard, statistiques avancées). |
| Long terme | Extension NL/EN (structure i18n déjà en place), fonctionnalités IA (voir section 14), potentiel d'expansion hors Belgique. |

## 4. Valeur ajoutée

**Pour le chercheur de bien :**
- Découverte passive et agréable (feed) *et* recherche active et précise (filtres) — les deux logiques cohabitent, l'utilisateur choisit.
- Zéro friction à l'usage : aucune connexion imposée pour regarder, seules les actions qui engagent (favori, contact, visite) demandent un compte.
- Une seule main suffit du début à la fin (voir [UX_RULES.md](UX_RULES.md)).

**Pour l'agence immobilière :**
- Des prospects qualifiés et traçables (table `leads`) plutôt qu'un numéro de téléphone qui sonne dans le vide.
- Des statistiques réelles sur chaque bien publié (impressions, ouvertures de fiche, favoris, partages — voir `property_events`).
- Une présence différenciante sur un canal moderne, sans effort de maintenance (l'agence publie, l'app fait le reste).

## 5. Positionnement

House For You ne cherche pas à être un portail exhaustif (Immoweb, Zimmo) ni un simple agrégateur. Le positionnement est **« le portail immobilier le plus agréable à utiliser »** — la différenciation est produit et expérience, pas volume de biens à ce stade. Voir [DECISIONS.md](DECISIONS.md) pour le raisonnement détaillé derrière chaque choix d'expérience qui découle de ce positionnement.

Concurrents directs (Immoweb, Zimmo, Logic-Immo) : forte notoriété, volume, mais expérience mobile datée, aucune dimension « découverte ». House For You ne les affronte pas frontalement sur le volume — il capte l'attention par l'expérience, puis convertit grâce à la puissance de recherche.

## 6. Public cible

- **Primaire** : particuliers 25-45 ans en Belgique francophone, recherche active d'un bien à l'achat ou à la location, à l'aise avec les usages mobiles modernes (habitués Instagram/TikTok/Airbnb).
- **Secondaire** : agences immobilières indépendantes et réseaux de taille moyenne en Wallonie et à Bruxelles, cherchant un canal de diffusion différenciant.
- **Hors cible (MVP)** : promoteurs de projets neufs à grande échelle, marché commercial/professionnel pur (entrepôts, bureaux) — le modèle de données les anticipe (voir type de bien dans les filtres) mais ce n'est pas le focus initial.

## 7. Philosophie UX

> *« Simplicité visuelle, puissance fonctionnelle. »*

Trois principes non négociables, détaillés et appliqués dans [UX_RULES.md](UX_RULES.md) :

1. **Mobile first, une seule main.** Chaque écran est pensé pour un usage au pouce, en mouvement. Le desktop reste compatible mais n'est jamais la contrainte de conception.
2. **Aucune sensation de latence.** Chaque geste doit donner l'impression que l'interface est reliée directement au doigt — swipe, double tap, ouverture/fermeture de fiche, feuille de filtres. Aucun flash blanc, aucune saccade, précache systématique.
3. **Accès invité par défaut.** Aucune action ne force une connexion au lancement. Seules les actions qui engagent réellement (favori, contact, visite) déclenchent une porte d'authentification contextuelle.

## 8. Fonctionnement général de l'application

Quatre onglets permanents, accessibles sans compte : **Découvrir · Rechercher · Favoris · Profil**. Voir `lib/core/router/main_shell.dart` et `lib/core/router/app_router.dart`.

- Chaque onglet a sa propre pile de navigation indépendante (`StatefulShellBranch`) — changer d'onglet préserve l'état de navigation de l'onglet quitté.
- La fiche détail d'un bien (`/property/:id`) est une route de premier niveau, poussée par-dessus le shell (donc sans la bottom bar), réutilisée depuis n'importe quel point d'entrée (feed, futurs résultats de recherche).
- L'authentification, quand elle existera (étape 5), sera une route modale déclenchée contextuellement — jamais un écran de démarrage obligatoire.

## 9. Description détaillée de chaque écran

### 9.1 Découvrir (`lib/features/discover/discover_screen.dart`) — **implémenté**

Feed vertical plein écran, un bien par page (`PageView` vertical). Voir section 10.1 pour le détail du feed lui-même.

- **Barre de recherche flottante** en haut de l'écran (verre dépoli), résumé de la recherche active, accès aux filtres et aux recherches enregistrées. Se masque en glissant hors de l'écran quand l'utilisateur avance dans le feed, réapparaît quand il recule (`lib/core/widgets/floating_search_bar.dart`).
- Fond sombre (`#0B0B0C`) derrière le feed — jamais de blanc visible pendant les transitions.

### 9.2 Rechercher (`lib/features/search/search_screen.dart`) — **placeholder**

Recherche guidée par étapes (transaction → type → localisation → budget → chambres → critères) puis liste de résultats (`PropertyCard.list()`). Prévu étape 3 — voir [ROADMAP.md](ROADMAP.md).

### 9.3 Favoris (`lib/features/favorites/favorites_screen.dart`) — **placeholder invité**

État invité : message + CTA de connexion. État connecté (étape 6) : liste des biens sauvegardés, état vide propre si aucun favori. Le contrôleur de favoris (`lib/data/providers/favorites_controller.dart`) et son repository mock existent déjà et sont fonctionnels depuis le feed et la fiche détail — seul l'écran de listing reste à construire.

### 9.4 Profil (`lib/features/profile/profile_screen.dart`) — **placeholder invité**

État invité : message + CTA de connexion. État connecté (étape 8) : consultation/édition du profil, déconnexion.

### 9.5 Fiche détail d'un bien (`lib/features/discover/property_detail_screen.dart`) — **implémenté**

Route push plein écran (`/property/:id`), non opaque pour laisser le feed déjà chargé transparaître pendant la fermeture (voir section 10.3 et [DECISIONS.md](DECISIONS.md)).

Contenu : galerie photo complète, prix, titre, localisation (ville/code postal/province — jamais l'adresse exacte, voir [DATABASE_PLAN.md](DATABASE_PLAN.md)), description intégrale, caractéristiques, équipements, certificat énergétique (placeholder visuel), bloc agence, boutons favori/partager/contacter.

### 9.6 Feuille de filtres (`lib/features/discover/filters/filters_sheet.dart`) — **implémenté**

Voir section 10.2.

### 9.7 Connexion / Inscription — **non développé**

Écran modal, déclenché uniquement par une action protégée (`requireAuth()`, `lib/core/auth/auth_guard.dart`). En attendant l'étape 5, la porte d'authentification affiche un message explicite (SnackBar) plutôt que de construire un écran de connexion prématuré.

### 9.8 Formulaires de contact / demande de visite — **non développé**

Prévus étape 7. Le bouton « Contacter l'agence » existe déjà sur la fiche détail et est protégé par `requireAuth()` ; il affiche pour l'instant un message « bientôt disponible ».

## 10. Description détaillée de chaque fonctionnalité

### 10.1 Le feed — explication complète

Le cœur de l'expérience House For You. Un `PageView` vertical plein écran (`_DiscoverFeed` dans `discover_screen.dart`), un bien par page, physique de scroll personnalisée (`SnappyPageScrollPhysics`, voir [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md)) pour un settle rapide et sans rebond façon TikTok/Instagram.

**Deux gestes, deux axes, jamais de conflit :**

| Geste | Zone | Effet |
|---|---|---|
| Swipe vertical | Toute la carte | Bien suivant/précédent |
| Swipe horizontal | Média (photo/vidéo) | Photo suivante/précédente dans la galerie du bien |
| Double tap | Média uniquement | Ajoute/retire le favori, avec animation de cœur |
| Tap simple | Bloc texte (prix/titre/description) uniquement | Ouvre la fiche détail |

Cette séparation stricte des zones de gestes est une décision produit documentée dans [DECISIONS.md](DECISIONS.md).

**Chaque carte affiche** : galerie photo/vidéo plein écran avec indicateur de progression façon stories, dégradé de lisibilité à trois paliers, badge agence (logo + nom), prix, ville, type de bien, surface, chambres, salles de bain, description tronquée à 2 lignes + « Voir plus », boutons favori/partager avec ombre portée.

**Fluidité (étape 2.1)** : précache des photos du bien précédent et suivant dès qu'une page se stabilise (`precacheImage`), `RepaintBoundary` par carte pour isoler les repaints, `AutomaticKeepAliveClientMixin` pour préserver l'état (photo affichée) d'une carte déjà visitée. Le facteur dominant de latence perçue dans un feed à médias réseau est le téléchargement de l'image, pas la construction du widget — voir [DECISIONS.md](DECISIONS.md) pour le détail du raisonnement.

**Tracking** : chaque impression de bien (`feedImpression`), ouverture de fiche (`detailOpen`), partage (`share`) et ajout/retrait de favori (`favoriteAdd`/`favoriteRemove`) est envoyé à `AnalyticsService` (mock aujourd'hui — logué en console — Supabase à l'étape 9).

### 10.2 Recherche — feuille de filtres

Accessible depuis la barre flottante du feed. Feuille plein écran qui monte depuis le bas avec un fond flouté (jamais une nouvelle page — voir `lib/core/widgets/blurred_modal_sheet.dart`).

**Sections, dans l'ordre d'affichage :**

1. **Localisation** — recherche texte (ville/code postal/province/région) avec suggestions instantanées, puis rayon de recherche (5/10/20/50 km/toute la Belgique).
2. **Type de transaction** — grandes cartes : Acheter, Louer, Projet neuf.
3. **Budget** — slider double poignée + saisie manuelle, plage adaptée automatiquement à la transaction (achat vs location).
4. **Type de bien** — grille à icônes, sélection multiple (Maison, Appartement, Villa, Terrain, Projet neuf, Immeuble de rapport, Commerce, Entrepôt, Garage).
5. **Chambres** / **Salles de bain** — sélection rapide 1+ à 5+.
6. **Surface habitable** — slider. **Surface du terrain** — slider, affiché seulement si le type de bien sélectionné le justifie (maison/terrain, ou aucun type choisi).
7. **Certificat énergétique** — sélection multiple A+ à G, couleur conventionnelle par grade.
8. **Caractéristiques** — grille à icônes, sélection multiple (17 options : jardin, terrasse, piscine, garage, parking, cave, bureau, dressing, cheminée, ascenseur, accès PMR, cuisine équipée, climatisation, pompe à chaleur, panneaux photovoltaïques, borne électrique, vue dégagée).
9. **État du bien** — Neuf, Excellent, Bon, À rénover, Gros œuvre.
10. **Date de publication** — Aujourd'hui, 7 jours, 30 jours, Toutes.
11. **Trier par** — Pertinence, Nouveautés, Prix croissant/décroissant, Surface, Prix/m².
12. **Ambiance de vie** *(section différenciante, voir ci-dessous)*.
13. **Recherches enregistrées** — aperçu horizontal + action « Enregistrer cette recherche ».
14. **Bouton final** — « Afficher N biens », N calculé en direct sur les données mock via `SearchFilters.matches()`.

Les filtres s'appliquent en direct (pas de distinction brouillon/validé) : chaque sélection met à jour immédiatement le résumé de la barre flottante et le feed sous-jacent. Voir [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md) pour l'implémentation (`searchFiltersControllerProvider`).

**Ambiance de vie** — la section qui différencie House For You des portails classiques : explorer par ressenti (🌳 Calme, ☀️ Très lumineux, 👨‍👩‍👧 Familial, 🏙 Centre-ville, 🌲 Proche nature, 💼 Télétravail, 🍷 Haut de gamme, 🎓 Étudiant, 🚉 Proche transports) plutôt que par seuls critères techniques. Purement déclaratif au MVP (aucune donnée mock ne permet encore de la faire influencer les résultats) — vouée à être alimentée par un tag de contenu ou un signal IA (voir section 14).

### 10.3 Favoris — état actuel

Le contrôleur (`FavoritesController`, `StateNotifier<Set<String>>`) et le repository mock (`MockFavoritesDataSource`) sont fonctionnels : toggle depuis le feed (bouton ou double tap) et la fiche détail, protégés par `requireAuth()`. **L'écran de listing des favoris reste à construire** (étape 6, avec la vraie notion de session).

### 10.4 Notifications — non développé

Aucune notification (push ou in-app) n'existe au MVP. Prévues post-MVP : alertes sur recherche sauvegardée, nouveaux biens correspondant à un filtre, mise à jour de statut d'un lead. Voir [BACKLOG.md](BACKLOG.md).

### 10.5 Profil — non développé

Voir section 9.4. Le modèle `UserProfile` (rôle, prénom/nom, téléphone, avatar) existe déjà (`lib/data/models/user_profile.dart`), prêt à être consommé dès que l'authentification (étape 5) et l'écran (étape 8) seront construits.

### 10.6 Pages agences — non développé

Le modèle `Agency` et son repository mock existent et sont déjà utilisés (logo + nom affichés dans le feed et la fiche détail). Une **fiche agence dédiée** (accessible en push depuis la fiche bien) est prévue mais non prioritaire au MVP — pas d'annuaire/recherche d'agences (voir section 10 d'`architecture-mvp.md`, choix volontairement reporté).

### 10.7 Publication des annonces — hors périmètre app

House For You est une application **de recherche**, pas un outil de publication. La publication d'un bien par une agence est un flux back-office (futur dashboard agence, hors périmètre de cette application mobile) — voir [BACKLOG.md](BACKLOG.md) pour la réflexion produit associée.

### 10.8 IA — non développé, vision posée

Aucune fonctionnalité IA n'est développée au MVP. Pistes identifiées pour la suite (voir [BACKLOG.md](BACKLOG.md)) :
- recherche en langage naturel (« maison 3 chambres avec jardin près de Namur, budget 350k ») traduite automatiquement en `SearchFilters` ;
- suggestion automatique des tags « Ambiance de vie » à partir des photos/description d'un bien publié ;
- recommandations personnalisées basées sur `property_events` (comportement réel de navigation).

## 11. Navigation

Voir section 8 ci-dessus et [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md) pour le détail technique (GoRouter, `StatefulShellRoute`, transitions).

## 12. Roadmap fonctionnelle

Voir [ROADMAP.md](ROADMAP.md) pour le détail étape par étape avec statut, dates et commentaires. Résumé de l'état actuel : étapes 0, 1, 2 et 2.1 terminées (setup, navigation, feed + fiche + filtres, fluidité). Étape 3 (recherche guidée + résultats) non commencée.

## 13. Contraintes

- **Mock avant Supabase** — aucune fonctionnalité data ne s'implémente contre une source concrète tant que l'étape 10 n'est pas atteinte (voir [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md)).
- **Aucun secret côté client** — seule la clé publique `anon` Supabase pourra un jour vivre dans `.env`.
- **Une adresse exacte ne doit jamais transiter par le modèle `Property` public** — voir [DATABASE_PLAN.md](DATABASE_PLAN.md), séparation `property_private_locations`.
- **Belgique francophone au lancement**, structure i18n (`.arb`) prête pour NL/EN sans refonte.
- **Mobile-first strict** — voir [UX_RULES.md](UX_RULES.md).

## 14. IA — vision détaillée

*(Renvoi depuis 10.8 pour éviter la duplication — voir [BACKLOG.md](BACKLOG.md) section « Expérimentations » pour le détail des pistes et leur priorisation.)*

## 15. Bonnes pratiques

Voir [CONTRIBUTING.md](CONTRIBUTING.md) (conventions de code, Git, tests) et [UX_RULES.md](UX_RULES.md) (conventions d'expérience). Ce document (`PRODUCT_SPEC.md`) décrit le *quoi* et le *pourquoi* produit ; il ne doit jamais dupliquer le *comment* technique déjà couvert par [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md).

---

**Documents liés** : [ROADMAP.md](ROADMAP.md) · [UX_RULES.md](UX_RULES.md) · [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) · [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md) · [DATABASE_PLAN.md](DATABASE_PLAN.md) · [DECISIONS.md](DECISIONS.md) · [BACKLOG.md](BACKLOG.md)
