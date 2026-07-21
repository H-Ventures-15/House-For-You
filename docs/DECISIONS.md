# DECISIONS — House For You

> **Statut : vivant.** Registre des décisions importantes (architecture, produit, UX, choix de packages). Format court : Contexte → Décision → Conséquences. **Toute règle d'[UX_RULES.md](UX_RULES.md) qui serait un jour cassée doit d'abord avoir une entrée ici expliquant pourquoi.** Les décisions ne se suppriment jamais, même remplacées — une décision remplacée reste tracée avec un renvoi vers celle qui la remplace.
>
> Dernière mise à jour : 2026-07-21 (correctif UX ciblé — fluidité de la bottom sheet, seuil naturel du swipe vertical du feed).

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

## ADR-018 — Mobile First : iOS est la plateforme de validation officielle, jamais le navigateur

**Contexte** : House For You a toujours été conçu mobile-first en principe ([UX_RULES.md](UX_RULES.md) section 2, [PRODUCT_SPEC.md](PRODUCT_SPEC.md) section 7 : « mobile first, une seule main », desktop compatible mais jamais la contrainte de conception). En pratique, une partie du développement et de la prévisualisation passe par le serveur web de développement (`.claude/launch.json`, voir [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md) section 13) — un outil précieux pour itérer vite, mais dont le rendu (gestes souris, absence de safe areas réelles, performance différente) peut diverger sensiblement d'un iPhone physique. Sans arbitrage explicite, cette commodité de développement risquait de dériver en arbitre implicite des décisions produit.

**Décision** : iOS (iPhone) est formellement la **seule** plateforme de validation officielle du produit. Web, macOS et Android ne servent qu'au développement, au débogage et aux tests rapides — jamais à trancher une décision produit. En cas de divergence de comportement observée entre le navigateur et l'iPhone, **l'iPhone fait toujours foi**, sans exception. Cette règle couvre en particulier les gestes, animations, transitions, performances, safe areas, interactions tactiles, fluidité et micro-interactions — c'est-à-dire l'essentiel de ce qui distingue une application « qui fonctionne » d'une application qui procure une sensation haut de gamme.

**Justification** : le navigateur de développement n'a ni les mêmes primitives de geste (pas de VoiceOver/TalkBack réel, pas de retour haptique, pas de safe areas natives type encoche/Dynamic Island), ni le même moteur de rendu/scroll, ni les mêmes contraintes de performance qu'un iPhone physique. Une fluidité perçue comme parfaite dans Chrome peut cacher une saccade réelle sur iPhone (et inversement) — seul le device cible réel peut juger. Cette règle formalise une pratique déjà appliquée en continu depuis la fin de l'étape 1 (voir [ROADMAP.md](ROADMAP.md) étape 11 : « l'app a été validée fonctionnelle sur iPhone physique... dès la fin de l'étape 1 »), sans changer l'architecture existante — elle rend explicite un arbitrage qui était jusqu'ici implicite.

**Conséquences** : création de [docs/QA_CHECKLIST.md](QA_CHECKLIST.md), la checklist officielle à dérouler avant chaque validation de sprint, organisée par catégories (feed, fiche du bien, filtres, navigation, micro-interactions, performances, accessibilité, qualité du code) — voir [CONTRIBUTING.md](CONTRIBUTING.md) pour le processus de validation complet qui l'intègre. Le sandbox de développement (serveur web) reste un outil d'itération légitime et encouragé, mais ne doit jamais servir d'arbitre final sur une question UX.

---

## ADR-019 — Bug de navigation rapporté : investigué en profondeur, non reproduit dans le code ni dans les tests

**Contexte** : Sprint 2.5, premier point demandé — Hugo rapporte qu'après avoir tapé sur Favoris ou Profil, il ne peut plus revenir correctement sur Découvrir. La demande était explicite : identifier la cause réelle dans GoRouter/`StatefulShellRoute`/l'architecture de navigation, corriger proprement, pas de contournement.

**Investigation** : lecture complète de `app_router.dart`, `main_shell.dart`, `branch_fade_container.dart` — le pattern (`StatefulShellRoute` + `goBranch(index, initialLocation: index == currentIndex)` + conteneur custom à fondu) est exactement le pattern recommandé par la documentation officielle de `go_router` (confirmé en lisant le code source du package, `go_router-14.8.1`). Instrumentation temporaire (`debugPrint` dans `MainShell.build`/`onDestinationSelected`) puis tests dédiés (`test/main_shell_test.dart`, groupe « séquences de navigation Sprint 2.5 ») couvrant exactement les séquences demandées (Découvrir→Favoris→Découvrir, Découvrir→Profil→Découvrir, Favoris→Profil→Découvrir, changements rapides, conservation du bien courant et des filtres actifs) : **tous passent, `NavigationBar.selectedIndex` reste systématiquement synchronisé avec le contenu affiché**, y compris après ouverture/fermeture d'une fiche détail avant un changement d'onglet.

En revanche, le symptôme rapporté par Hugo **a bien été observé** dans le serveur web de développement (`.claude/launch.json`) : contenu et pastille de sélection de la bottom bar désynchronisés, y compris dès le tout premier chargement de page sans aucune interaction, et un journal navigateur montrant des `WebSocketConnectionClosed`/doubles exécutions côté DWDS après plusieurs redémarrages du serveur sur le même port. Ce comportement est resté strictement confiné au navigateur de développement (jamais reproduit par les tests `flutter test`, l'oracle déterministe).

**Décision** : ne pas modifier l'architecture de navigation (`StatefulShellRoute`/`BranchFadeContainer`/`goBranch`), aucune preuve de défaut dans le code — modification spéculative écartée (voir [CONTRIBUTING.md](CONTRIBUTING.md) section 4, « pas d'abstraction prématurée »/pas de changement sans preuve). À la place : ajout de tests de régression permanents verrouillant exactement les séquences demandées (section 15 du sprint), conformément à ADR-018 : le navigateur de développement n'est jamais l'arbitre, seul le comportement sur iPhone physique compte en cas de doute.

**Conséquences** : si le symptôme réapparaît sur iPhone physique (à vérifier par Hugo via [QA_CHECKLIST.md](QA_CHECKLIST.md) section 4 — c'est la seule vérification qui fait foi), il faudra le documenter avec un scénario de reproduction précis (quel geste, quelle vitesse, quel enchaînement) pour rouvrir l'investigation avec des éléments nouveaux ; l'hypothèse la plus probable dans ce cas serait une corruption d'état liée au hot reload en cours de développement (`StatefulShellRoute` utilise une `GlobalKey` interne au package, sensible à ce type d'artefact), pas un défaut du code compilé.

## ADR-020 — Fermeture de la feuille de filtres par swipe : notifications de scroll plutôt qu'un `GestureDetector` concurrent

**Contexte** : Sprint 2.5 demande que la feuille de filtres (`showBlurredModalSheet`) se ferme par swipe vers le bas, tout en gardant le scroll interne (`ListView` de `FiltersSheet`) prioritaire tant qu'il n'est pas remonté en haut — les deux gestes partagent le même axe (vertical), contrairement au cas déjà résolu de ADR-002 (axes opposés, désambiguïsation native).

**Décision** : plutôt qu'un second `VerticalDragGestureRecognizer` (via `GestureDetector`) placé au-dessus du contenu — qui entrerait en conflit de même axe avec le `Scrollable` du `ListView`, la classe de bug déjà documentée en ADR-004 — la fermeture repose entièrement sur les notifications de scroll (`OverscrollNotification` pour `ClampingScrollPhysics`, `ScrollUpdateNotification` avec `pixels < minScrollExtent` pour `BouncingScrollPhysics`, la physique par défaut sur iOS) qui remontent naturellement depuis le `ListView` via `NotificationListener<ScrollNotification>`. Ce mécanisme ne participe jamais à l'arène de gestes : il n'existe aucune concurrence à arbitrer, le scroll interne garde nativement la main tant qu'il n'est pas à sa borne.

**Alternative envisagée et écartée** : un `GestureDetector` sur une zone restreinte (la poignée grise en haut de la feuille uniquement), qui aurait évité tout conflit d'axe mais n'aurait permis de fermer qu'en saisissant précisément cette petite poignée — écarté car la demande explicite était de pouvoir « balayer vers le bas naturellement », depuis n'importe quelle zone du contenu.

**Conséquences** : `ListView` de `FiltersSheet` explicitement en `physics: const AlwaysScrollableScrollPhysics()` pour garantir que le geste fonctionne même quand le contenu ne déborde pas de l'écran (peu de filtres visibles). Seuil de fermeture identique à celui déjà établi pour la fiche détail (32 % de la hauteur ou vitesse de relâchement, voir ADR-004) — cohérence intentionnelle entre les deux mécanismes de fermeture par swipe de l'app. Testé (`test/filters_sheet_test.dart`, groupe « fermeture par swipe vers le bas » : swipe long, swipe court, scroll prioritaire, croix/retour système toujours fonctionnels).

## ADR-021 — Badges éditoriaux dérivés à la volée plutôt que stockés, champs sources ajoutés à `Property`

**Contexte** : Sprint 2.5 demande des badges (Nouveau, Exclusivité, Visite virtuelle, Coup de cœur, Prix réduit) « en prévoyant le modèle de données de façon propre sans connecter Supabase ». Aucun concept équivalent n'existait dans [DATABASE_PLAN.md](DATABASE_PLAN.md) avant ce sprint.

**Décision** : quatre champs bruts ajoutés à `Property` (`isExclusive`, `isFeatured`, `hasVirtualTour`, `previousPrice` — voir `lib/data/models/property.dart`), et une fonction pure `propertyBadges(Property)` (`lib/data/models/property_badge.dart`) qui dérive la liste des badges applicables (« Nouveau » se déduit de `publishedAt`, moins de 14 jours ; « Prix réduit » de `previousPrice > price` ; les trois autres sont des flags éditoriaux directs). Le composant d'affichage (`_BadgeStack`, `property_card.dart`) n'affiche jamais plus de 2 badges, dans un ordre de priorité fixe (Exclusivité → Coup de cœur → Prix réduit → Visite virtuelle → Nouveau).

**Justification** : dériver plutôt que stocker un « badge » explicite évite une désynchronisation possible (un bien publié il y a 20 jours ne doit plus jamais afficher « Nouveau », sans tâche de nettoyage périodique) et suit le même principe déjà appliqué aux recherches sauvegardées (`defaultSavedSearchName`/`savedSearchSubtitle`, voir [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md) section 5 bis) : dériver à la volée depuis des données déjà fiables plutôt que dupliquer un état.

**Conséquences** : ces quatre champs sont déjà ceux qui alimenteront la vraie donnée à la bascule Supabase (étape 10) — aucune migration de « badge » séparée à prévoir, seule une colonne par champ sur `properties`. Quelques biens mock (`mock_property_data.dart`) enrichis pour la démonstration. Testé (`test/property_badge_test.dart`, `test/property_card_gestures_test.dart`).

## ADR-022 — Partage : lien placeholder stable, annulation jamais comptée comme un partage réel

**Contexte** : Sprint 2.5 demande de « gérer proprement l'annulation » du partage natif (`share_plus`) et de « prévoir un lien placeholder stable », sans construire de deep link réel (explicitement reporté au backlog).

**Décision** : le texte partagé inclut désormais un lien `https://houseforyou.be/biens/{propertyId}` (placeholder — ce domaine ne résout rien de réel aujourd'hui, voir [BACKLOG.md](BACKLOG.md)) en plus du texte descriptif déjà existant. Le résultat de `SharePlus.instance.share()` (`ShareResult.status`) est vérifié : si l'utilisateur ferme la feuille de partage système sans choisir d'action (`ShareResultStatus.dismissed`), l'évènement `share` n'est **pas** envoyé à `AnalyticsService` — un partage annulé ne doit jamais gonfler artificiellement les statistiques de partage réelles.

**Conséquences** : `discover_screen.dart` et `property_detail_screen.dart` partagent la même logique (dupliquée à l'identique dans les deux fichiers, cohérent avec le fait qu'ils n'ont pas de contrôleur de partage commun aujourd'hui — pas d'abstraction prématurée pour deux occurrences, voir [CONTRIBUTING.md](CONTRIBUTING.md) section 4). Le jour où les deep links réels seront construits (voir [BACKLOG.md](BACKLOG.md)), seul le domaine/chemin du lien changera, pas la logique d'annulation.

---

## ADR-023 — Favoris accessibles sans compte, persistés localement (`SharedPreferences`)

**Contexte** : correctif rapide post-Sprint 2.5, validé sur iPhone physique — la porte d'authentification (`requireAuth()`) bloquait le double tap/bouton favori pour un invité, alors que le MVP doit permettre de tester les favoris sans créer de compte. La lecture initiale (ADR-014, favori listé parmi les actions « qui engagent ») s'est révélée trop stricte à l'usage réel.

**Décision** : le favori (double tap, bouton cœur du feed et de la fiche détail, listing de l'onglet Favoris) ne passe plus par `requireAuth()` — le contact agence, lui, reste protégé (aucun changement). `MockFavoritesDataSource` passe d'un stockage en mémoire (perdu à chaque redémarrage) à `SharedPreferences` (persistance réelle sur l'appareil), et `FavoritesController` s'hydrate désormais depuis le repository à sa création plutôt que de démarrer systématiquement vide.

**Justification** : un favori est une action d'exploration passive et personnelle (« je garde une trace de ce qui m'intéresse »), pas un engagement envers un tiers (agence) contrairement au contact ou à la demande de visite — la même distinction que celle déjà posée pour les recherches sauvegardées (ADR-016). Bloquer cette action derrière une authentification qui n'existe pas encore (étape 5) empêchait toute validation réelle du geste sur iPhone.

**Alternative envisagée et écartée** : garder le favori en mémoire simple (non persisté) le temps de l'étape 5. Écartée car Hugo teste l'app sur iPhone entre plusieurs sessions de développement — un favori qui disparaît à chaque relance de l'app aurait rendu le test impossible à mener sérieusement.

**Conséquences** : `FavoritesRepository` (interface) inchangée — seule `MockFavoritesDataSource` change d'implémentation, cohérent avec ADR-011 (mock avant Supabase, un seul fichier à remplacer par repository à la bascule). Nouvel écran `lib/features/favorites/favorites_screen.dart` (liste réelle des biens favoris, état vide sinon) — implémentation volontairement minimale (pas de swipe pour retirer, pas de tri) pour rester strictement dans la portée du correctif, l'écran complet de l'étape 6 restant à construire (multi-appareil, synchronisé). **Le jour où l'étape 5/6 sera construite**, réintroduire `requireAuth()` sur `toggle()` sera une extension mineure, et remplacer `SharedPreferences` par une synchronisation Supabase ne changera que `MockFavoritesDataSource`. Testé (`test/property_detail_test.dart`, `test/favorites_screen_test.dart`).

## ADR-024 — Fermeture de la feuille de filtres : suivre le delta brut du doigt, jamais `ScrollMetrics.pixels` amorti

**Contexte** : correctif rapide post-Sprint 2.5, validé sur iPhone physique — le swipe de fermeture (voir ADR-020) demandait un geste bien plus long que prévu pour se déclencher. L'implémentation initiale dérivait `_dragExtent` de `ScrollUpdateNotification.metrics.pixels`, en supposant que cette valeur reflétait fidèlement le déplacement du doigt au-delà du haut de la liste.

**Décision** : deux corrections combinées.
1. `_dragExtent` est désormais accumulé à partir de `ScrollNotification.dragDetails.delta` (le delta **brut** du doigt fourni par le framework), plus jamais de `ScrollMetrics.pixels`/`overscroll` — ces derniers sont amortis par la physique de scroll de la plateforme.
2. `ScrollEndNotification.dragDetails.velocity` est désormais réellement lu et transmis à la décision de fermeture — jusqu'ici jamais exploité, ce qui rendait le seuil de vitesse totalement inopérant (code mort).
Le seuil de distance est également abaissé de 32 % à 18 % de la hauteur, et le seuil de vitesse de 800 à 500 px/s — une bottom sheet doit se fermer d'un geste plus léger qu'une fiche plein écran (voir UX_RULES.md section 9).

**Justification technique** : `BouncingScrollPhysics` (physique par défaut sur iOS, la cible principale de l'app) applique un amortissement délibéré type « élastique » à `ScrollMetrics.pixels` au-delà des bornes du contenu (rubber-banding pensé pour un rebond de scroll visuel, jamais pour piloter un geste de fermeture) — un swipe de 200 px du doigt ne déplaçait `pixels` que de quelques dizaines de pixels. En conséquence, la feuille semblait « en retard » sur le doigt et n'atteignait le seuil de fermeture qu'après un geste bien plus ample que voulu. `ScrollNotification.dragDetails` (un `DragUpdateDetails`/`DragEndDetails` selon le type de notification) contourne entièrement ce problème : c'est le delta/la vitesse réels du geste, fournis par le framework indépendamment de la façon dont la physique de scroll choisit de les interpréter pour sa propre liste.

**Conséquences** : le geste suit désormais le doigt au pixel près, quelle que soit la physique de scroll (`BouncingScrollPhysics` iOS, `ClampingScrollPhysics` Android). Testé (`test/filters_sheet_test.dart` — swipe long, swipe court et lent, **swipe rapide et court** qui ferme via le seuil de vitesse, priorité au scroll interne, croix/retour système). Le même piège (confondre `ScrollMetrics.pixels` amorti avec le delta réel du doigt) est à surveiller pour toute future feuille interactive construite sur ce modèle.

---

## ADR-025 — Saccade du drag de fermeture de la feuille de filtres : `BackdropFilter` séparé du geste, ressort physique plutôt qu'un tween à durée fixe

**Contexte** : deuxième correctif rapide validé sur iPhone physique — malgré ADR-024 (suivi au pixel près), le geste de fermeture de la feuille de filtres restait perçu comme saccadé, sans inertie, « pas une sensation native iOS ».

**Décision** : deux corrections combinées dans `_DismissibleSheet` (`lib/core/widgets/blurred_modal_sheet.dart`).
1. **`BackdropFilter` (le flou de fond) découplé du geste de drag.** Il ne se reconstruit plus qu'au rythme de `routeAnimation` (l'animation d'ouverture/fermeture de la route, quelques centaines de ms), jamais au rythme de `_dragExtent` (qui peut varier à 60-120 fps pendant un drag actif de durée arbitraire). Seul l'assombrissement (`ColoredBox` à opacité variable, un simple alpha blend) reste continu pendant le drag, pour donner la sensation d'un fond « qui se révèle progressivement » sans jamais rejouer l'effet de flou.
2. **`SpringSimulation` (via `AnimationController.unbounded`) remplace le `Tween`/`Curves.easeOut` à durée fixe** pour le règlement au relâchement (confirmation ou annulation). Le ressort part de la vitesse réelle de relâchement (`DragEndDetails.velocity`, déjà lue depuis ADR-024) — l'inertie du geste se prolonge naturellement dans l'animation, qu'elle confirme la fermeture ou qu'elle y renonce. Même ressort critique que `SnappyPageScrollPhysics` (`mass: 0.3, stiffness: 180, ratio: 1`) pour une cohérence de sensation avec le reste de l'app.

**Justification technique** : `BackdropFilter` est l'un des effets les plus coûteux de Flutter — il ré-échantillonne et floute tout ce qu'il y a dessous à **chaque frame** où il est peint. L'implémentation précédente recalculait son `sigma` à partir de `1 - dragProgress` dans le **même** `AnimatedBuilder` que la translation du contenu, donc à chaque `setState` déclenché par le drag (potentiellement à chaque pixel de mouvement du doigt) — sur un iPhone physique (contrairement au simulateur/émulateur, où le coût réel du flou GPU n'est pas toujours représentatif), ce recalcul répété faisait chuter le frame rate en dessous de 60 fps, perçu comme des saccades. Séparer le flou (rythmé par la route, ~20 frames sur toute sa durée de vie) de la translation/l'assombrissement (rythmés par le drag, mais cette fois avec des opérations bon marché) élimine le goulot d'étranglement à la source. Par ailleurs, un `Tween`/`Curve` à durée fixe ignore complètement la vitesse de relâchement — un relâchement rapide et un relâchement lent produisaient la même animation de retour, ce qui explique le « manque d'inertie » et la sensation de « lutter contre le geste » signalés.

**Conséquences** : `AnimationController.unbounded` pilote directement `_dragExtent` en pixels (suivi 1:1 via `.value =` pendant le drag actif, `SpringSimulation` via `.animateWith()` au relâchement) — un seul contrôleur pour les deux mécanismes, plutôt qu'un champ brut + `setState` séparé d'une `AnimationController` de settle comme avant. Le haptique de franchissement de seuil est explicitement suspendu pendant la simulation de relâchement (`_settling`) pour ne pas revibrer inutilement quand le ressort traverse mécaniquement le seuil en allant vers sa cible. Testé (`test/filters_sheet_test.dart` — nouveau test vérifiant que la feuille suit le doigt en direct pendant un drag actif, avant même le relâchement ; tous les tests de seuil de distance/vitesse déjà existants restent verts).

## ADR-026 — Feed vertical trop sensible : `PageView` ignore silencieusement toute physique personnalisée sauf avec `pageSnapping: false`

**Contexte** : troisième correctif rapide validé sur iPhone physique — le feed changeait de bien pour un mouvement de quelques millimètres dès qu'il y avait la moindre vélocité, rendant l'expérience « nerveuse ». La demande explicite était un seuil naturel combinant distance parcourue (15-25 % de la hauteur) et vélocité, jamais un seuil arbitrairement bas.

**Découverte technique (le point le plus important de cet ADR)** : une première tentative a consisté à surcharger `createBallisticSimulation` dans une nouvelle physique (`FeedPageScrollPhysics`), en suivant exactement le même principe que `SnappyPageScrollPhysics`. **Cette surcharge s'est révélée totalement sans effet** : le code de `PageView` (`page_view.dart`, `PageViewState.build()`) compose sa physique effective ainsi, dès que `pageSnapping` vaut `true` (la valeur par défaut) :
```dart
_kPagePhysics.applyTo(widget.physics ?? ...)
```
c'est-à-dire que la physique fournie par l'application (`widget.physics`) devient le **parent** de `_kPagePhysics` — la physique interne, non modifiable, de Flutter — plutôt que l'inverse. Or `PageScrollPhysics.createBallisticSimulation` (la version de Flutter, non surchargée) ne délègue à son `parent.createBallisticSimulation` que dans le cas hors-limites (première/dernière page) ; dans tous les cas normaux, elle calcule elle-même la page cible via sa propre logique (`_getTargetPixels`, qui compare la vélocité à une tolérance quasi nulle — la cause originelle de la sur-sensibilité) et retourne directement sa simulation, **sans jamais consulter le parent**. Autrement dit : tant que `pageSnapping` reste à `true`, toute logique personnalisée de décision de page placée dans `widget.physics.createBallisticSimulation` est du code mort en pratique — elle ne s'exécute jamais pour les changements de page normaux. `pageSnapping: false` supprime cet enveloppement : `widget.physics` devient alors directement la physique active, et notre surcharge gouverne réellement la décision.

**Décision** : `FeedPageScrollPhysics extends SnappyPageScrollPhysics`, utilisée uniquement sur le `PageView` vertical du feed (`discover_screen.dart`) avec `pageSnapping: false` — jamais sur les deux galeries photo horizontales (`property_card.dart`, `property_detail_screen.dart`), qui restent volontairement aussi réactives qu'une galerie classique et inchangées par ce correctif. Seuils retenus : 20 % de la hauteur de page valide seul un changement (indépendamment de la vitesse) ; en dessous de 5 %, aucune vitesse ne suffit (protège d'un tremblement/tap involontaire) ; entre les deux, une vélocité ≥ 1200 px/s valide quand même un swipe court et rapide. Ces trois valeurs sont volontairement ajustables (constantes nommées) — Hugo doit confirmer la sensation réelle sur iPhone, les valeurs numériques n'étant qu'un point de départ raisonné, pas une vérité figée.

**Détail technique complémentaire** : l'« origine » du geste (le bien affiché avant le drag) ne peut pas être déduite de la position fractionnaire courante (`page.round()`) au-delà de 50 % de distance parcourue — au-delà de ce seuil, `round()` désigne déjà la page cible, pas l'origine, ce qui inversait le sens du calcul de progression pour un swipe long et lent (vélocité quasi nulle au relâchement). Corrigé en capturant l'origine réelle une seule fois, au tout début du geste (`ScrollStartNotification`, jamais mise à jour pendant le drag), plutôt qu'en la devinant : `_lastSettledIndex` (mis à jour par `onPageChanged`, qui se déclenche lui-même sur un simple `page.round()` dès 50 %, potentiellement **pendant** le drag) s'est révélé, pour cette même raison, être une source d'origine non fiable — piège découvert en écrivant les tests de ce correctif.

**Alternative envisagée et écartée** : conserver `pageSnapping: true` et n'ajuster que le ressort (`spring`) pour ralentir la sensation. Écartée car elle n'aurait rien changé à la décision de changement de page elle-même (le problème réel), seulement à la vitesse du settle une fois la décision déjà prise par Flutter — n'aurait pas résolu la sur-sensibilité rapportée.

**Conséquences** : `SnappyPageScrollPhysics` (utilisée telle quelle par les deux galeries horizontales, `pageSnapping: true` par défaut) souffre donc probablement du même enveloppement — son `spring` personnalisé n'est vraisemblablement, lui non plus, jamais consulté pour le settle normal des galeries. Volontairement **non corrigé dans ce correctif** (hors périmètre demandé, risque de « dégrader le swipe horizontal entre les médias » explicitement à éviter) — consigné dans [BACKLOG.md](BACKLOG.md) pour réévaluation future. Testé (`test/discover_feed_test.dart` — petit drag revient au bien courant, drag dépassant le seuil change de bien, swipe court mais rapide change de bien, geste diagonal faible ne change rien, swipe horizontal toujours indépendant).

---

**Documents liés** : [UX_RULES.md](UX_RULES.md) · [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md) · [ROADMAP.md](ROADMAP.md) · [CHANGELOG.md](CHANGELOG.md) · [QA_CHECKLIST.md](QA_CHECKLIST.md)
