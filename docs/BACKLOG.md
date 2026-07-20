# BACKLOG — House For You

> **Statut : vivant.** Toutes les idées du projet, classées par priorité. Aucune idée évoquée en cours de développement ne doit être perdue — si elle est écartée d'une étape en cours, elle atterrit ici plutôt que d'être oubliée. Une idée qui passe en développement est déplacée vers [ROADMAP.md](ROADMAP.md) et retirée d'ici.
>
> Dernière mise à jour : 2026-07-20.

---

## High Priority

*Idées directement enchaînables après l'étape en cours, forte valeur ou forte dépendance d'autres étapes.*

- **Recherche guidée + Résultats** (étape 3, [ROADMAP.md](ROADMAP.md)) — réutiliser `SearchFilters` et la feuille déjà construite plutôt que dupliquer la logique de filtrage.
- **Authentification réelle** (étape 5) — priorité haute car bloque favoris/leads/profil réels (étapes 6, 7, 8) et la porte d'authentification actuelle est un mock temporaire assumé (voir [DECISIONS.md](DECISIONS.md) ADR-014).
- **Persistance réelle des recherches enregistrées** — aujourd'hui purement mock statique (`mock_saved_searches.dart`), la table `saved_searches` est déjà préparée dans [DATABASE_PLAN.md](DATABASE_PLAN.md). À implémenter dès que l'authentification existe.
- **Décision property_type à 9 valeurs** — la feuille de filtres propose 9 types de bien, le modèle `Property`/la base n'en prévoit que 4. À trancher avant l'étape 10 (voir [DATABASE_PLAN.md](DATABASE_PLAN.md) section 9).

## Medium Priority

*Valeur claire, pas bloquant, à traiter après le cœur du MVP (étapes 3-9).*

- **Vidéo dans le feed** — le modèle de données est déjà prêt (`PropertyMedia.mediaType`, `storageProvider`, `playbackId`). Reste à choisir Cloudflare Stream vs Mux, intégrer un lecteur (`video_player`/`chewie` ou SDK du fournisseur choisi), et adapter la galerie du feed pour lire plutôt qu'afficher une vignette statique.
- **Fiche agence dédiée** — le modèle `Agency` existe et est déjà affiché (logo, nom) dans le feed et la fiche bien ; une vraie page accessible en push depuis la fiche bien reste à construire (pas d'annuaire/recherche d'agences au MVP, volontairement).
- **Dashboard agence** — consultation des statistiques réelles issues de `property_events` (vue `agency_property_stats` déjà esquissée dans [DATABASE_PLAN.md](DATABASE_PLAN.md)), gestion des leads reçus. Hors périmètre de l'app mobile grand public — probablement une interface web séparée.
- **Notifications push** — alertes sur recherche sauvegardée (`saved_searches.notify_on_new_match`), mise à jour de statut d'un lead. Infrastructure (FCM/APNs) non choisie.
- **Affichage carte** — nécessiterait PostGIS côté Supabase et une lib de carte côté Flutter (`google_maps_flutter`, `flutter_map`...) ; le modèle `Property` a déjà `display_latitude`/`display_longitude` publics et approximatifs, prêts pour ça.
- **Extraction de couleur dominante depuis la photo** pour un fond de feed adaptatif — envisagée puis écartée pour la sous-étape 2.1 au profit d'un fond sombre uni, plus simple et déjà suffisant (voir [DECISIONS.md](DECISIONS.md) ADR-013). À reconsidérer si un besoin de raffinement visuel supplémentaire émerge.
- **Animation Hero** entre la photo actuellement affichée dans le feed et la galerie de la fiche détail à l'ouverture — explicitement envisagée puis reportée lors du polish premium (2026-07-20) faute de temps face au périmètre du système de filtres, jugée « lorsque pertinent » donc non bloquante. Le geste de fermeture (retour au feed) est, lui, déjà traité sans flash blanc indépendamment de tout Hero (voir [DECISIONS.md](DECISIONS.md) ADR-005).

## Future

*Idées valables, horizon plus lointain, dépendent souvent d'autres briques non construites.*

- **Comparaison de biens** (sélectionner 2-3 biens, vue comparative côte à côte).
- **Collections de favoris** (dossiers thématiques, notes personnelles, partage d'une collection).
- **Visite virtuelle** (3D/vidéo 360°).
- **Documents PEB détaillés** (au-delà du badge placeholder actuel).
- **Calcul de mensualité / estimation des frais de notaire** à l'achat.
- **Calendrier de visite complet** (au-delà du formulaire de demande de visite simple prévu étape 7).
- **Chat en direct** avec une agence.
- **Paiements / abonnements** (modèle économique agence, mise en avant payante...).
- **Traduction NL/EN de l'interface** — structure `.arb` déjà prête (`app_nl.arb`, `app_en.arb` existent mais vides), seul le contenu manque.
- **Administration complète** (back-office multi-agences, modération).

## Expérimentations

*Pistes à évaluer avant tout engagement — risque ou incertitude technique/produit plus élevés.*

- **Recherche en langage naturel** (« maison 3 chambres avec jardin près de Namur, budget 350k ») traduite automatiquement en `SearchFilters` — nécessiterait un appel à un LLM, à évaluer coût/latence/pertinence avant tout engagement.
- **Suggestion automatique des tags « Ambiance de vie »** à partir des photos/description d'un bien publié (vision + LLM) — la section existe déjà dans la feuille de filtres mais est purement déclarative aujourd'hui (voir [PRODUCT_SPEC.md](PRODUCT_SPEC.md) section 10.2).
- **Recommandations personnalisées** basées sur le comportement réel de navigation (`property_events`) — nécessite un volume de données suffisant, prématuré avant la bascule Supabase.
- **Réseaux sociaux pour l'authentification** (Google/Apple Sign-In) en complément d'email/mot de passe.
- **Réévaluer `freezed`/`json_serializable`** pour les modèles si leur nombre ou la fréquence de leurs évolutions dépasse ce que l'écriture manuelle permet raisonnablement de maintenir (voir [DECISIONS.md](DECISIONS.md) ADR-010).
- **Mode sombre global** de l'application (au-delà de l'immersion locale du feed, voir [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) section 12).

---

**Documents liés** : [ROADMAP.md](ROADMAP.md) · [PRODUCT_SPEC.md](PRODUCT_SPEC.md) · [DECISIONS.md](DECISIONS.md) · [DATABASE_PLAN.md](DATABASE_PLAN.md)
