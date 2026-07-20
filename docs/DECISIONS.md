# DECISIONS — House For You

> **Statut : vivant.** Registre des décisions importantes (architecture, produit, UX, choix de packages). Format court : Contexte → Décision → Conséquences. **Toute règle d'[UX_RULES.md](UX_RULES.md) qui serait un jour cassée doit d'abord avoir une entrée ici expliquant pourquoi.** Les décisions ne se suppriment jamais, même remplacées — une décision remplacée reste tracée avec un renvoi vers celle qui la remplace.
>
> Dernière mise à jour : 2026-07-20 (sous-étape 2.3 — recherche, filtres et recherches sauvegardées).

---

## ADR-001 — Feed plein écran plutôt qu'une liste classique

**Contexte** : les portails immobiliers existants (Immoweb, Zimmo) présentent les biens en liste dense de cartes. House For You vise une différenciation par l'expérience (voir [PRODUCT_SPEC.md](PRODUCT_SPEC.md) section 5).

**Décision** : le feed principal (onglet Découvrir) est un `PageView` vertical plein écran, un bien par page — chaque bien occupe 100 % de l'espace disponible, comme un feed social (TikTok, Instagram Reels).

**Conséquences** : nécessite une galerie photo indépendante par carte (swipe horizontal), une gestion de gestes soignée (voir ADR-002/003), un système de précache pour rester fluide (voir ADR-007). La liste classique (`PropertyCard.list()`) reste disponible comme vue alternative pour les résultats de recherche (étape 3) — les deux variantes partagent le même composant `PropertyCard` pour garantir la cohérence visuelle.

---

## ADR-002 — Swipe vertical (bien) et swipe horizontal (photo) sur des axes strictement indépendants

**Contexte** : un feed plein écran avec galerie interne a deux gestes de swipe naturels qui pourraient entrer en conflit — faire défiler les biens (vertical) et faire défiler les photos d'un bien (horizontal).

**Décision** : le swipe vertical fait défiler les biens, le swipe horizontal (à l'intérieur d'une carte) fait défiler les photos — jamais l'inverse, jamais de conflit.

**Justification technique** : Flutter désambiguïse nativement deux `PageView` imbriqués sur des axes **opposés** via l'arène de gestes (le `VerticalDragGestureRecognizer` du feed et le `HorizontalDragGestureRecognizer` de la galerie n'entrent en compétition que si le mouvement est ambigu ; un geste franchement vertical ou horizontal résout immédiatement vers le bon recognizer). Aucun hack, aucune gestion manuelle des gestes n'a été nécessaire — c'est le comportement par défaut de deux `PageView` d'axes opposés imbriqués. **Ce point a été vérifié empiriquement** : une tentative similaire (rendre la fiche détail fermable par swipe horizontal sur toute sa surface, y compris sur sa propre galerie qui swipe déjà horizontalement) a été écartée précisément parce que deux gestes de **même axe** imbriqués ne se désambiguïsent pas proprement — voir ADR-004.

**Conséquences** : testé explicitement (`test/discover_feed_test.dart` — « le swipe horizontal change de photo sans changer de bien ni de page »). Toute nouvelle galerie interne à un composant swipable doit respecter ce principe d'axes opposés.

---

## ADR-003 — Double tap réservé au média, jamais au bloc texte

**Contexte** : le like par double tap (convention Instagram/TikTok) doit cohabiter avec le tap simple qui ouvre la fiche détail, sur la même carte.

**Décision** : le double tap (like) ne fonctionne que sur la zone média (photo/vidéo) ; le tap simple qui ouvre la fiche ne fonctionne que sur le bloc texte (prix/titre/description) en bas de carte. Les deux zones ne se chevauchent jamais.

**Justification technique** : le bloc texte est un widget opaque (`HitTestBehavior.opaque`) positionné **au-dessus** de la galerie dans la pile (`Stack`) — il absorbe le tap avant qu'il n'atteigne le détecteur de double tap de la galerie en dessous. C'est le hit-testing standard de Flutter (le premier widget opaque dans l'ordre de peinture absorbe le geste), pas un hack.

**Conséquences** : testé explicitement (`test/property_card_gestures_test.dart`, 4 tests couvrant les 4 combinaisons zone × geste). Toute évolution du contenu de `PropertyCard.feed` doit préserver cette séparation ou mettre à jour consciemment les tests.

---

## ADR-004 — Fermeture de la fiche détail par swipe horizontal limitée à la zone sous la galerie

**Contexte** : la demande initiale (« swipe horizontal vers la droite pour fermer la fiche ») ne précisait pas de zone. Une implémentation naïve couvrant tout l'écran entrerait en conflit avec le swipe horizontal propre de la galerie photo de la fiche (même axe, geste ambigu — contrairement à ADR-002 où les axes sont opposés).

**Décision** : la zone de détection du geste de fermeture est limitée à la partie de l'écran **sous** la galerie photo (les sections info, majorité de la hauteur d'écran). La galerie garde son swipe horizontal dédié à la navigation entre photos, sans ambiguïté.

**Alternative envisagée et écartée** : une fine bande de détection sur le bord gauche de l'écran (façon retour système iOS), qui aurait permis de fermer même en swipant depuis la galerie. Écartée car elle recrée la même ambiguïté d'axe que l'arène de gestes ne résout pas de façon fiable pour deux recognizers de même axe imbriqués (contrairement à ADR-002) — la complexité d'ingénierie nécessaire (recognizer personnalisé à priorité forcée) n'était pas justifiée par le gain, la zone sous la galerie couvrant déjà la majorité de l'écran.

**Conséquences** : testé (`test/property_detail_dismiss_test.dart`). Le geste suit le doigt en direct (1:1) avec un effet de rotation (« balancer »), seuil de 32 % de la largeur d'écran ou de vitesse avant confirmation.

---

## ADR-005 — La fiche détail ne doit jamais montrer de fond blanc pendant sa fermeture

**Contexte** : par défaut, une route Flutter poussée par-dessus une autre est peinte comme opaque, et le Navigator cesse de peindre ce qui est en dessous une fois la transition terminée (optimisation de performance standard). Une fermeture interactive (glissement progressif) sur une route opaque révèle donc un fond de Scaffold générique, pas le contenu réel en dessous — perçu comme un flash blanc/un rechargement.

**Décision** : la route `/property/:id` est déclarée `opaque: false` (voir `app_router.dart`), et le `Scaffold` de la fiche détail a un fond transparent — c'est `_DetailBody` qui porte son propre fond opaque « au repos », à l'intérieur du contenu animé par le geste de fermeture. Résultat : pendant le swipe, le feed déjà chargé en dessous transparaît directement à mesure que la fiche s'écarte, comme si elle flottait au-dessus.

**Conséquences** : léger coût de performance (le feed reste peint même quand la fiche est ouverte au-dessus) — jugé négligeable vu le nombre de biens en jeu (feed léger, un `PageView` avec peu d'éléments simultanément montés). L'image du bien affichée derrière est nécessairement déjà chargée (c'est la même carte, restée montée via `AutomaticKeepAliveClientMixin`) — aucun rechargement possible par construction.

---

## ADR-006 — La barre de recherche flottante suit le scroll en continu, pas un show/hide binaire

**Contexte** : la demande (« la barre disparaît en avançant, réapparaît en reculant ») pouvait se satisfaire d'un simple `if (scrollingForward) hide() else show()` déclenché au changement de page.

**Décision** : la visibilité de la barre est une valeur continue (0 à 1), recalculée à chaque frame de scroll en fonction de la fraction de page parcourue et de son sens — elle suit le doigt pendant le drag, pas seulement au relâchement.

**Détail technique** : un premier essai basé uniquement sur l'accumulation de deltas de scroll souffrait d'une dérive à la limite entre deux pages (léger dépassement de la simulation physique en fin de geste). Corrigé en ajoutant un recalage strict sur 0 ou 1 dès qu'une page est réellement franchie (`onPageChanged`), tout en gardant le suivi continu pendant le drag actif. Découvert et corrigé grâce à un test qui vérifiait une valeur d'opacité exacte plutôt qu'approximative.

**Conséquences** : testé (`test/discover_feed_test.dart` — « la barre de recherche se masque en avançant et réapparaît en reculant »).

---

## ADR-007 — Précache d'images plutôt que pré-montage de widgets pour la fluidité du feed

**Contexte** : sous-étape 2.1, objectif de fluidité maximale. L'hypothèse initiale était que `PageView(allowImplicitScrolling: true)` garderait les pages voisines réellement construites en mémoire à l'avance.

**Décision (et correction en cours de route)** : investigation empirique (test dédié construit puis supprimé après validation) a montré que `allowImplicitScrolling` ne pré-monte **pas** les widgets voisins — c'est une option d'accessibilité (comportement de scroll implicite pour VoiceOver/TalkBack), pas un mécanisme de cache de rendu, malgré ce que son nom suggère. La fluidité réelle du feed repose sur trois mécanismes différents, tous vérifiés efficaces :
1. `precacheImage` sur les photos des biens voisins (le facteur dominant de latence perçue dans un feed à médias réseau est le téléchargement, pas la construction du widget) ;
2. `AutomaticKeepAliveClientMixin` pour préserver l'état d'une carte déjà visitée ;
3. `RepaintBoundary` par carte pour isoler les repaints.

`allowImplicitScrolling` est resté activé, mais uniquement pour son bénéfice réel (accessibilité), et la documentation a été corrigée pour ne pas laisser croire qu'il explique la fluidité perçue.

**Conséquences** : exemple direct de la règle « si le code et la doc divergent, corriger la doc dans la foulée » — ce projet applique la rigueur qu'il documente. Voir [CONTRIBUTING.md](CONTRIBUTING.md).

---

## ADR-008 — Riverpod pour le state management

**Contexte** : choix à faire à l'étape 0 entre Provider, Riverpod, Bloc, GetX.

**Décision** : Riverpod (`flutter_riverpod`).

**Justification** : pas de dépendance à `BuildContext` dans la logique métier (contrairement à `Provider`), providers facilement testables en isolation, composition naturelle de providers dérivés (utilisée abondamment — `filteredPropertyCountProvider`, `agenciesByIdProvider`...) sans code de câblage manuel.

**Conséquences** : chaque écran qui lit de l'état est un `ConsumerWidget`/`ConsumerStatefulWidget`. `HouseForYouApp` porte son propre `ProviderScope` (autonomie/testabilité — voir [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md) section 7).

---

## ADR-009 — GoRouter pour la navigation

**Contexte** : choix à faire à l'étape 0 entre `Navigator` 2.0 manuel, GoRouter, auto_route.

**Décision** : GoRouter.

**Justification** : routes déclaratives, `StatefulShellRoute` adapté nativement au besoin de 4 onglets avec piles de navigation indépendantes, prêt pour le deep-linking futur, pas de génération de code (`build_runner`) requise contrairement à `auto_route`.

**Conséquences** : la fiche détail (`/property/:id`) est une route de premier niveau (hors shell) plutôt qu'imbriquée dans une branche — nécessaire pour obtenir une transition plein écran sans bottom bar et un contrôle fin de l'opacité de route (voir ADR-005).

---

## ADR-010 — Modèles Dart manuels plutôt que `freezed`/`json_serializable`

**Contexte** : choix à faire à l'étape 0 pour les modèles de données (`fromJson`/`toJson`/`copyWith`).

**Décision** : classes Dart manuelles, écrites à la main.

**Justification** : évite une dépendance à `build_runner` dès le MVP — pas de temps de génération de code à chaque modification de modèle, pas de fichiers `.g.dart` à gérer. Le nombre de modèles reste maîtrisable (11 classes) pour que le coût d'écriture manuelle reste raisonnable.

**Conséquences** : à réévaluer si le nombre de modèles ou la fréquence de leurs modifications augmente significativement (voir [BACKLOG.md](BACKLOG.md), section Expérimentations).

---

## ADR-011 — Mock avant Supabase, repository par repository

**Contexte** : le backend Supabase n'est pas encore connecté (prévu étape 10). Il fallait un moyen de développer tous les écrans sans en dépendre, ni recoder au moment de la bascule.

**Décision** : chaque source de données a une interface abstraite (`data/repositories/`) et une implémentation mock (`data/datasources/mock/`), branchée via un point d'injection unique (`repository_providers.dart`). Aucun écran ne connaît jamais l'implémentation concrète.

**Conséquences** : la bascule Supabase (étape 10) ne devrait modifier qu'un seul fichier par repository (la valeur retournée par son provider). Contrainte transversale : tout code nouveau doit respecter ce pattern, jamais un accès direct à une source de données concrète depuis un écran.

---

## ADR-012 — Feuille de filtres plutôt qu'un écran dédié

**Contexte** : la recherche/filtrage pourrait être un écran séparé (approche classique des portails immobiliers) ou une feuille modale par-dessus le feed.

**Décision** : une `Bottom Sheet` plein écran (94 % de hauteur, fond flouté) qui monte depuis le bas, jamais une nouvelle page/route.

**Justification** : cohérent avec le principe « simplicité visuelle, puissance fonctionnelle » ([PRODUCT_SPEC.md](PRODUCT_SPEC.md) section 7) — l'utilisateur ne perd jamais le contexte du feed qu'il consultait, la feuille se ferme d'un geste et il retrouve exactement où il en était. Une nouvelle page aurait cassé cette continuité et ajouté une transition de navigation complète pour une action qui reste, conceptuellement, un réglage temporaire de la vue courante.

**Conséquences** : implémentée via `showGeneralDialog` personnalisé (`showBlurredModalSheet`) plutôt que `showModalBottomSheet` standard, car ce dernier ne permet pas nativement de flouter l'arrière-plan. A révélé un bug réel (absence d'ancêtre `Material`, voir [CHANGELOG.md](CHANGELOG.md) du 2026-07-20) — tout nouveau composant Material (`TextField`, `InkWell`...) utilisé dans une feuille custom future doit être testé pour cette même classe de bug.

---

## ADR-013 — Fond sombre du feed plutôt que blanc, pour l'effet de parallax entre cartes

**Contexte** : un effet de profondeur (léger rétrécissement d'échelle) entre deux cartes du feed pendant le swipe vertical révélait un espace visuel autour de chaque carte, qui affichait par défaut le fond blanc/crème standard de l'app — perçu comme un flash blanc cassant l'immersion.

**Décision** : fond du feed réglé sur un quasi-noir (`#0B0B0C`) plutôt que d'utiliser `AppColors.background`. L'espace visuel entre deux cartes est conservé (demande explicite de garder une séparation légère plutôt que de coller les photos), mais ne lit jamais comme un blanc de page.

**Alternative envisagée** : extraction dynamique d'une couleur dominante depuis chaque photo pour un fond adaptatif. Écartée pour cette itération — complexité et coût de calcul non justifiés par rapport au gain, le fond sombre uni suffisant déjà à éliminer complètement la sensation de « flash blanc » signalée. Piste conservée dans [BACKLOG.md](BACKLOG.md) si un besoin de raffinement supplémentaire émerge.

**Conséquences** : cette couleur est définie localement dans `discover_screen.dart`, pas dans `AppColors` — c'est un choix d'immersion propre au feed plein écran, pas une couleur de palette générale (voir [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) section 2).

---

## ADR-014 — Accès invité par défaut, porte d'authentification contextuelle plutôt qu'un écran de connexion prématuré

**Contexte** : l'authentification réelle (Supabase Auth) n'existe pas encore (étape 5). Les actions qui devraient la nécessiter (favori, contact) existent pourtant déjà dans l'app depuis l'étape 2.

**Décision** : `requireAuth()` vérifie un état d'authentification mock (toujours `false` par défaut) et affiche un message explicite (SnackBar, ex. « Connecte-toi pour ajouter ce bien à tes favoris ») plutôt que de bloquer silencieusement l'action ou de construire un écran de connexion avant l'étape qui lui est dédiée.

**Justification** : respecte à la fois le principe produit (jamais de connexion forcée, voir [UX_RULES.md](UX_RULES.md) section 14) et la discipline de développement séquentiel (une seule étape à la fois, voir [CLAUDE.md](../CLAUDE.md)) — construire un écran de connexion maintenant aurait anticipé l'étape 5 sans validation.

**Conséquences** : le jour où l'étape 5 sera développée, `requireAuth()` devra rediriger vers l'écran de connexion réel et redéclencher automatiquement l'action initiale après succès (déjà spécifié dans [PRODUCT_SPEC.md](PRODUCT_SPEC.md) section 8/[architecture-mvp.md](architecture-mvp.md) section 4) — pas encore implémenté.

---

## ADR-015 — L'appui long qui masque l'interface du feed ne masque jamais la bottom bar, et restaure l'état précédent (pas un état forcé) au relâchement

**Contexte** : sous-étape 2.2 (gestes & interactions naturelles), la demande d'appui long pour masquer l'interface du feed (« voir le bien sans distraction ») listait explicitement la « navigation inférieure » parmi les éléments à masquer, « si cela reste cohérent avec l'architecture actuelle ».

**Décision** : l'appui long masque tout le chrome propre à l'onglet Découvrir (barre de recherche flottante, gradient/indicateur photo/badge agence/bloc texte/rail favori-partager de la carte) mais **ne masque jamais la bottom bar à 4 onglets**.

**Justification** : ce n'est pas cohérent avec l'architecture actuelle, pour deux raisons distinctes.
1. **Règle produit déjà posée** ([UX_RULES.md](UX_RULES.md) section 11) : « Quatre onglets permanents, jamais masqués sauf sur une route de premier niveau explicitement plein écran (fiche détail). » L'onglet Découvrir est une branche du shell (`StatefulShellRoute`), pas une route plein écran de premier niveau — la masquer romprait cette règle sans qu'un besoin produit fort le justifie (le geste sert à dégager la vue du *bien*, pas à sortir de la navigation).
2. **Frontière architecturale** ([TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md) section 2/3) : la bottom bar est rendue par `MainShell` (`lib/core/router/main_shell.dart`), un ancêtre du widget qui détecte l'appui long (`_FeedCard`, plusieurs niveaux plus bas dans l'arbre). La masquer aurait exigé un canal de communication ascendant supplémentaire (provider Riverpod dédié ou `InheritedWidget`) pour un geste local à un seul onglet — complexité non justifiée par le gain, alors que l'essentiel de l'objectif (« voir le bien sans distraction ») est déjà atteint en masquant le chrome de la carte et la barre flottante.

**Détail technique complémentaire** : la barre de recherche flottante ne se contente pas de repasser à visible au relâchement — elle restaure exactement sa valeur de visibilité continue d'avant l'appui long (`_barVisibilityBeforeLongPress` dans `discover_screen.dart`), cohérent avec le principe déjà posé en ADR-006 (visibilité continue plutôt que show/hide binaire) : si l'utilisateur avait déjà fait défiler le feed vers le bas (barre masquée par le scroll) puis fait un appui long, la barre reste masquée après relâchement plutôt que de réapparaître puis se re-masquer.

**Conséquences** : testé (`test/discover_feed_test.dart` — masquage/restauration de l'état précédent de la barre ; `test/property_card_gestures_test.dart` — masquage/restauration du chrome de la carte, non-déclenchement du double tap/de l'ouverture de fiche pendant l'appui). Si un besoin produit futur justifie de masquer aussi la bottom bar pendant l'appui long, ce sera un changement architectural à part entière (canal de communication shell ↔ feature) — pas une extension mineure de ce geste.

---

## ADR-016 — Les recherches sauvegardées ne passent pas par `requireAuth()`, contrairement aux favoris

**Contexte** : sous-étape 2.3, la demande couvrait explicitement un cycle complet enregistrer/charger/renommer/supprimer une recherche, avec validation attendue de chacune de ces actions. Le modèle de données cible ([DATABASE_PLAN.md](DATABASE_PLAN.md) section 3.12) prévoit une table `saved_searches` avec `user_id`, ce qui suggérerait par réflexe de reproduire le pattern `requireAuth()` déjà utilisé pour les favoris (ADR-014).

**Décision** : enregistrer, charger, renommer et supprimer une recherche sauvegardée restent des actions accessibles sans authentification à cette étape (mock/mémoire), en écart volontaire avec le pattern favoris.

**Justification** :
1. [UX_RULES.md](UX_RULES.md) section 14 liste explicitement les actions protégées : « favori, contacter une agence, demander une visite, créer une alerte ». Les recherches sauvegardées n'y figurent pas — ce n'est pas un oubli mais une lecture cohérente avec le principe « zéro friction à l'usage » ([PRODUCT_SPEC.md](PRODUCT_SPEC.md) section 4) : une recherche sauvegardée est un raccourci de la même exploration passive que les filtres eux-mêmes (regarder), pas un engagement envers un tiers (agence) ni une collection identitaire durable comme les favoris.
2. **Contrainte pratique décisive** : `authStateProvider` (`lib/core/auth/auth_guard.dart`) reste câblé sur `false` en permanence tant que l'étape 5 (authentification réelle) n'est pas construite — aucun écran de connexion n'existe encore pour passer la porte. Geler cette fonctionnalité derrière `requireAuth()` l'aurait rendue totalement invalidable dans ce sprint, alors que la checklist de validation demandée exige explicitement de tester sauvegarde/chargement/renommage/suppression bout en bout.

**Conséquences** : `SavedSearchesRepository`/`MockSavedSearchesDataSource` acceptent un `userId` sur chaque méthode (prépare la policy RLS Supabase future) mais l'implémentation mock l'ignore, faute d'une vraie session utilisateur à cette étape — voir [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md). **Le jour où l'étape 5 sera construite**, ajouter `requireAuth()` aux points d'entrée d'écriture (`_handleSaveSearch` dans `filters_sheet.dart`, `_handleRename`/`_handleDelete` dans `saved_searches_sheet.dart`) sera une extension mineure, cohérente avec ADR-014 — pas un changement d'architecture. Testé (`test/filters_sheet_test.dart`, `test/saved_searches_sheet_test.dart`).

---

## ADR-017 — Hiérarchie « Plus de filtres » repliée par défaut, plutôt qu'une liste plate de 14 sections

**Contexte** : la feuille de filtres construite à l'étape 2 (commit `4461646`) affichait ses 14 sections à plat, dans un ordre fixe, sans distinction d'importance. La demande de la sous-étape 2.3 insistait explicitement sur le fait de ne « jamais afficher tous les critères avec la même importance » et de ne jamais donner « l'impression de remplir un formulaire administratif ».

**Décision** : seuls 5 groupes de critères restent immédiatement visibles à l'ouverture (localisation + rayon, type de transaction, budget, type de bien, chambres), plus les recherches enregistrées (accès rapide à un jeu de critères déjà affiné). Les 8 groupes restants (salles de bain, surfaces, PEB, caractéristiques, état du bien, date de publication, tri, ambiance de vie) vivent sous une section repliable « Plus de filtres », avec un badge indiquant leur nombre actif pour ne jamais donner l'impression qu'un critère avancé actif serait « perdu » en repliant la section.

**Alternative envisagée et écartée** : conserver la liste plate mais réordonner les sections par fréquence d'usage supposée. Écartée car elle ne résout pas le problème de fond (14 sections d'un coup restent visuellement écrasantes au premier scroll, quel que soit l'ordre) — seul un repli réel réduit la charge visuelle initiale.

**Conséquences** : `_showMoreFilters` (état local à `FiltersSheet`) contrôle un `AnimatedSize` (220 ms, `Curves.easeOut`) — testé (`test/filters_sheet_test.dart`, « Plus de filtres est replié par défaut... »). Voir [UX_RULES.md](UX_RULES.md) section 9 bis pour la règle produit et [PRODUCT_SPEC.md](PRODUCT_SPEC.md) section 10.2 pour le détail des deux niveaux.

---

**Documents liés** : [UX_RULES.md](UX_RULES.md) · [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md) · [ROADMAP.md](ROADMAP.md) · [CHANGELOG.md](CHANGELOG.md)
