# UX_RULES — House For You

> **Statut : vivant.** Ce document liste toutes les règles d'expérience utilisateur non négociables. **Aucune règle ici ne doit être cassée sans qu'une entrée correspondante soit ajoutée à [DECISIONS.md](DECISIONS.md) expliquant pourquoi.** Si le code et ce document divergent, le document doit être corrigé dans le même commit que le changement.
>
> Dernière mise à jour : 2026-07-20 (règle Mobile First / iOS plateforme de validation officielle).

---

## 1. Principe directeur

> *« Simplicité visuelle, puissance fonctionnelle. »*

House For You vise la sensation d'une application Apple ou Airbnb — minimaliste, extrêmement fluide, intuitive — tout en offrant la puissance fonctionnelle d'un portail immobilier complet. Chaque règle ci-dessous découle de ce principe.

## 2. Mobile first

- Toute conception démarre par l'écran le plus petit visé (iPhone), jamais par le desktop.
- Le desktop reste **compatible** (l'app doit compiler et rester utilisable en `flutter run -d macos`/web) mais n'est **jamais** la contrainte de mise en page. Aucune fonctionnalité ne doit être conçue « pour le grand écran d'abord ».
- Référence : [architecture-mvp.md](architecture-mvp.md) section 1, [PRODUCT_SPEC.md](PRODUCT_SPEC.md) section 7.

### 2 bis. iOS, plateforme de validation officielle — règle absolue

- **iPhone (iOS) est la seule plateforme de référence pour valider le produit.** Web, macOS et Android ne servent qu'au développement, au débogage et aux tests rapides — jamais à trancher une décision produit.
- **En cas de divergence de comportement entre le navigateur et l'iPhone, l'iPhone fait toujours foi.** Aucune exception.
- Domaines concernés par cette règle, sans exhaustivité : gestes, animations, transitions, performances, safe areas, interactions tactiles, fluidité, micro-interactions.
- Toute décision UX doit être pensée pour l'usage réel sur iPhone — pas pour ce que le navigateur de développement permet ou facilite.
- Avant de considérer un sprint terminé, dérouler [docs/QA_CHECKLIST.md](QA_CHECKLIST.md), idéalement sur un iPhone physique (déjà en pratique depuis la fin de l'étape 1, voir [ROADMAP.md](ROADMAP.md) étape 11).
- Voir [DECISIONS.md](DECISIONS.md) ADR-018 pour la justification complète de cette règle.

## 3. Utilisation à une seule main

- Les actions fréquentes (favori, partager, filtres, retour) doivent être atteignables par le pouce sans changer sa prise en main du téléphone.
- Conséquence directe : le rail d'actions du feed (favori/partager) est positionné sur le bord droit, à mi-hauteur basse de l'écran — pas en haut.
- Conséquence directe : la feuille de filtres place son bouton d'action principal (« Afficher N biens ») en bas, jamais en haut ou au milieu.

## 4. Swipe vertical (feed)

- Fait défiler d'un bien à l'autre (`PageView` `Axis.vertical`, `lib/features/discover/discover_screen.dart`).
- Doit suivre le doigt exactement pendant le drag (comportement natif Flutter, ne jamais l'intercepter avec un `GestureDetector` concurrent).
- Le settle en fin de geste utilise `SnappyPageScrollPhysics` (ressort plus raide que le défaut Flutter) pour une sensation instantanée, sans rebond. Voir [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) section « Animations ».
- **Ne doit jamais** être interrompu par le swipe horizontal de la galerie interne à une carte — les deux gestes sont sur des axes opposés et se désambiguïsent nativement dans l'arène de gestes de Flutter (aucun hack nécessaire, voir [DECISIONS.md](DECISIONS.md)).

## 5. Swipe horizontal (galerie photo)

- À l'intérieur d'une carte du feed ou de la fiche détail, fait défiler les photos/vidéos du bien courant.
- Ne change **jamais** de bien, quelle que soit l'amplitude du geste.
- Indicateur de progression façon stories (barres segmentées) en haut de la galerie, jamais de numérotation brute type « 1/6 » sur le feed (réservé à la fiche détail, où l'espace le permet).

## 6. Double tap (like)

- Sur le **média uniquement** (photo/vidéo) d'une carte du feed — jamais sur le bloc texte (prix/titre/description).
- Ajoute le bien aux favoris s'il n'y est pas, le retire s'il y est déjà (même sémantique que le bouton cœur) — **fonctionne sans compte** et sans aucune porte d'authentification, voir section 14 et [DECISIONS.md](DECISIONS.md) ADR-023.
- Déclenche systématiquement une animation de cœur (rebond puis fondu) **et un retour haptique léger** (`HapticFeedback.lightImpact()`) — l'action aboutit toujours, l'animation et le haptique ne sont donc jamais court-circuités.
- La séparation stricte des zones de geste (média = like, texte = ouvrir la fiche) est **testée** (`test/property_card_gestures_test.dart`) — toute évolution de `PropertyCard.feed` doit préserver ces tests ou les mettre à jour consciemment.

## 6 bis. Appui long (masquer l'interface)

- Sur le **média uniquement** d'une carte du feed — jamais sur le bloc texte, qui garde son seul rôle d'ouverture de la fiche.
- Masque, le temps de l'appui, tout le « chrome » informatif au-dessus du média : gradient de lisibilité du haut, indicateur photo (stories), badge agence, bloc prix/titre/description, rail favori/partager, **et la barre de recherche flottante** (`discover_screen.dart`). Ne laisse visible que la photo/vidéo en cours.
- **La bottom bar (4 onglets) n'est jamais masquée par ce geste** — écart assumé par rapport à une lecture large de la demande initiale, documenté en [DECISIONS.md](DECISIONS.md) ADR-015 : la bottom bar appartient à la coquille de navigation (`MainShell`), hors du périmètre de l'onglet Découvrir, et la section 11 ci-dessous interdit déjà de la masquer hors d'une route de premier niveau explicitement plein écran (ce que Découvrir n'est pas).
- Transition rapide et douce (180 ms, `Curves.easeOut`) à la disparition comme à la réapparition — jamais un `setState` qui fait « sauter » les éléments (voir section 10).
- Au relâchement, chaque élément masqué réapparaît **exactement dans l'état où il était avant l'appui** — en particulier la barre de recherche flottante retrouve sa valeur de visibilité continue précédente (voir [DECISIONS.md](DECISIONS.md) ADR-006), pas une réapparition forcée à 100 % si elle était déjà partiellement masquée par le scroll.
- Aucun élément masqué ne reste interactif pendant qu'il est invisible (`IgnorePointer`) — un relâchement ne doit jamais déclencher un tap fantôme sur un bouton qu'on ne voyait plus.
- Un appui long ne déclenche jamais un double tap, un swipe (changement de bien/photo) ni l'ouverture de la fiche — l'arène de gestes Flutter les désambiguïse nativement (un mouvement du doigt avant le délai de reconnaissance cède la place au swipe ; un appui reconnu comme long ne peut plus redevenir un double tap).

## 7. Ouverture de la fiche détail

- Un tap simple sur le **bloc texte** (prix, titre, localisation, description) d'une carte du feed ouvre la fiche détail — jamais un tap sur le média.
- Transition : fondu + léger glissement vers le haut (`CustomTransitionPage`, `lib/core/router/app_router.dart`), 320 ms à l'ouverture.

## 8. Fermeture de la fiche détail

- Swipe horizontal vers la droite, depuis la zone sous la galerie photo (la galerie garde son propre swipe horizontal dédié aux photos — pas de conflit, voir [DECISIONS.md](DECISIONS.md)).
- Effet « balancer » : translation + légère rotation autour du bord gauche, suivi du doigt en direct (1:1), seuil de distance (32 % de la largeur d'écran) ou de vitesse avant confirmation de fermeture.
- Retour haptique léger (`HapticFeedback.lightImpact()`) au franchissement du seuil de confirmation, une seule fois par franchissement — pas à chaque frame de drag (voir section 7 bis).
- **Jamais de fond blanc pendant le geste** : la route est non opaque (`opaque: false`) et le feed déjà chargé en dessous transparaît directement à mesure que la fiche s'écarte — comme si la fiche flottait au-dessus du feed, jamais comme un écran qui se recharge.
- Après fermeture, retour exact au même bien dans le feed, swipe vertical immédiatement fonctionnel (aucun état résiduel du geste de fermeture ne doit persister).
- Le scroll vertical du contenu de la fiche (`CustomScrollView`) et le swipe horizontal de fermeture sont sur des axes opposés — même principe d'indépendance native que le swipe vertical/horizontal du feed (voir [DECISIONS.md](DECISIONS.md) ADR-002) : aucun scroll vertical, aussi rapide soit-il, ne déclenche une fermeture accidentelle.
- Le bouton retour visible (coin supérieur gauche) et le retour matériel/système (bouton Android, `Navigator.pop` standard) fonctionnent toujours, indépendamment du swipe interactif — ce sont trois chemins de fermeture distincts vers la même action.

## 7 bis. Retour haptique (Sprint 2.5)

- Léger et ponctuel — jamais répétitif sur un geste continu (scroll normal, swipe de feed) : uniquement sur une action qui aboutit ou un seuil franchi.
- Déclencheurs : ajout/retrait d'un favori (déjà posé section 6), franchissement du seuil de fermeture d'une fiche ou d'une bottom sheet, changement d'onglet de la navigation inférieure, sélection d'un filtre important (type de transaction), application des filtres, chargement d'une recherche sauvegardée.
- Un re-tap sur une valeur déjà sélectionnée (ex. retaper le type de transaction déjà actif) ne déclenche **jamais** de haptique — il ne représente aucun changement réel.
- Voir [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) section 12 pour le détail fichier par fichier.

## 9. Bottom Sheet (filtres, recherches enregistrées)

- Jamais une nouvelle page — toujours une feuille qui monte depuis le bas.
- Fond flouté (`BackdropFilter`, `lib/core/widgets/blurred_modal_sheet.dart`) plutôt qu'un simple assombrissement — signale immédiatement à l'utilisateur qu'il reste « au-dessus » du contexte précédent, pas dans un nouvel écran.
- Hauteur quasi pleine (94 % de l'écran) avec un liseré du fond flouté visible en haut — l'utilisateur comprend immédiatement où il est sans README.
- Poignée de glissement (petite barre grise) en haut de la feuille, coins arrondis 28 px.
- **Fermeture par swipe vers le bas** (Sprint 2.5), en plus de la croix et du retour système — trois chemins équivalents. Le geste suit le doigt **au pixel près** (fond qui se dé-floute/s'éclaircit proportionnellement) — voir [DECISIONS.md](DECISIONS.md) ADR-024 pour le piège corrigé (l'amortissement « élastique » du scroll iOS ne doit jamais piloter la translation de la feuille). Seuil volontairement permissif : 18 % de la hauteur **ou** une vitesse de relâchement suffisante (même un swipe très court referme la feuille s'il est rapide), retour doux en place sinon.
- **Priorité au scroll interne** : tant que le contenu de la feuille n'est pas remonté tout en haut, un swipe vers le bas fait défiler ce contenu — il ne ferme la feuille qu'une fois le scroll déjà à son sommet (voir [DECISIONS.md](DECISIONS.md) pour l'implémentation via les notifications de scroll plutôt qu'un geste concurrent).
- En-tête fixe : fermeture (X) à gauche, titre centré, « Réinitialiser » à droite (visible seulement si des filtres sont actifs).
- Pied fixe : bouton d'action principal, toujours visible même si le contenu défile.
- Le clavier ne doit **jamais** masquer le champ actif ou le bouton d'action — la feuille remonte avec `MediaQuery.viewInsets.bottom` (voir `FiltersSheet` dans `filters_sheet.dart`).

## 9 bis. Hiérarchie des filtres

- Deux niveaux, jamais un formulaire administratif à plat : les critères principaux (localisation, type de transaction, budget, type de bien, chambres) restent **toujours visibles** à l'ouverture de la feuille de filtres ; les critères avancés (salles de bain, surfaces, PEB, caractéristiques, état du bien, date de publication, tri, ambiance de vie) vivent sous une section repliable « Plus de filtres ».
- « Plus de filtres » affiche un badge de comptage dès qu'un critère avancé est actif — l'utilisateur ne perd jamais de vue qu'un filtre est appliqué même sans déplier la section.
- Les recherches enregistrées (aperçu horizontal + action d'enregistrement) restent au niveau principal, entre les critères de base et « Plus de filtres » — un accès rapide à une recherche déjà affinée ne doit jamais être noyé sous un repli.
- Dépliage/repli animé (`AnimatedSize`, 220 ms, `Curves.easeOut`) — jamais un saut de layout brutal.

## 10. Transitions

- Aucun effet brutal — toute apparition/disparition est animée (fondu, glissement, échelle), jamais un `setState` qui fait « sauter » un élément.
- Les durées sont courtes (180-380 ms selon le contexte) — assez visibles pour paraître intentionnelles, jamais assez longues pour donner une sensation de lenteur.
- Respecter l'esprit Material 3 (courbes, timings cohérents avec le reste du système) tout en visant une sensation proche des transitions iOS/Apple (`Curves.easeOutCubic`/`easeOutBack` privilégiées aux courbes linéaires).

## 11. Navigation

- Quatre onglets permanents, jamais masqués sauf sur une route de premier niveau explicitement plein écran (fiche détail).
- Chaque onglet préserve son propre historique de navigation en arrière-plan (`StatefulShellBranch`) — revenir sur un onglet quitté ne le réinitialise jamais.
- Le retour (bouton back matériel Android, geste de bord iOS, bouton retour explicite) doit toujours ramener l'utilisateur à l'état précédent le plus intuitif — jamais à l'écran d'accueil par défaut.

## 12. Hiérarchie visuelle

- Une seule action principale par écran, visuellement dominante (couleur pleine, taille, position) — les actions secondaires restent discrètes (contour, texte).
- Le texte superposé à une photo porte systématiquement une ombre portée légère (`kOverlayTextShadow`, voir [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md)) — jamais de texte blanc nu sur image, la lisibilité n'est jamais laissée au hasard du contraste de la photo.
- Les dégradés de lisibilité (bas de carte, haut de galerie) sont à paliers (3 arrêts), jamais un dégradé linéaire simple à 2 couleurs — rendu plus doux, moins « bande grise » visible.

## 13. Règles de design (renvoi)

Le détail des couleurs, typographies, espacements, rayons, ombres et composants est dans [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md). Règle de fond commune aux deux documents : **aucune valeur magique** — toute couleur, tout espacement, toute typographie passe par `lib/core/theme/`, jamais une valeur en dur dans un écran.

## 14. Accès invité par défaut

- Aucune action ne force une connexion au lancement de l'app.
- Seules les actions qui **engagent envers un tiers** (contacter une agence, demander une visite, créer une alerte) déclenchent la porte d'authentification (`requireAuth()`, `lib/core/auth/auth_guard.dart`).
- Tant que l'écran de connexion réel n'existe pas (avant l'étape 5), la porte affiche un message explicite (SnackBar) plutôt que de bloquer silencieusement ou de construire un écran de connexion prématuré — voir [DECISIONS.md](DECISIONS.md).
- **Exceptions documentées** : les favoris (double tap, bouton cœur, listing de l'onglet Favoris) et les recherches sauvegardées (enregistrer/charger/renommer/supprimer) ne déclenchent **pas** cette porte — les deux sont des actions d'exploration passive persistées localement à l'appareil, pas un engagement envers un tiers. Voir [DECISIONS.md](DECISIONS.md) ADR-016 (recherches sauvegardées) et ADR-023 (favoris).

## 15. Performance perçue

- Précache systématique des médias adjacents (bien précédent/suivant dans le feed) — voir [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md) section « Préchargement ».
- `RepaintBoundary` autour de tout élément coûteux répété dans une liste/feed.
- Aucun appel réseau ou calcul lourd ne doit bloquer le thread principal pendant un geste actif (drag, animation).

## 16. Accessibilité

- **Aucune fonctionnalité ne doit dépendre exclusivement d'un geste.** Chaque action atteignable par un geste (double tap, appui long) reste aussi atteignable par un élément visible et statique : bouton favori toujours affiché (rail d'actions du feed, fiche détail), bloc texte toujours tapable pour ouvrir la fiche, bouton retour toujours affiché en fiche détail.
- Les boutons et zones tactiles principaux (favori, partager, ouvrir la fiche, retour) portent un label sémantique explicite (`Semantics(button: true, label: ...)`) pour les lecteurs d'écran (VoiceOver/TalkBack) — voir `lib/core/widgets/property_card.dart` et `lib/features/discover/property_detail_screen.dart`.
- `allowImplicitScrolling: true` sur les `PageView` du feed et des galeries reste actif pour son bénéfice réel d'accessibilité (navigation VoiceOver/TalkBack) — voir [DECISIONS.md](DECISIONS.md) ADR-007.

## 17. États de recherche particuliers

- **Zéro résultat** — jamais un simple message avec un unique bouton « Réessayer » : trois issues concrètes toujours proposées ensemble — Modifier les filtres (rouvre la feuille), Réinitialiser les filtres, Charger une recherche sauvegardée (ouvre l'accès rapide de la barre flottante). Voir `_NoFilteredResults`, `discover_screen.dart`.
- **Filtres incompatibles** — changer de type de transaction (achat ↔ location) réinitialise un budget déjà choisi plutôt que de laisser une valeur numériquement absurde sur la nouvelle échelle (350 000 € de loyer mensuel, par exemple). Un simple re-tap de la transaction déjà sélectionnée ne déclenche jamais cette réinitialisation.
- **Recherche sans nom** — le dialogue d'enregistrement/renommage propose toujours un nom par défaut pertinent ; une confirmation avec un champ laissé vide retombe silencieusement sur ce nom par défaut plutôt que de créer/renommer une recherche sans libellé.
- **Recherche sauvegardée supprimée** — aucune référence résiduelle : les critères déjà chargés dans la feuille de filtres au moment de la suppression restent inchangés (une recherche sauvegardée n'est qu'un raccourci pour pré-remplir les filtres, jamais un lien vivant vers eux). La liste affiche un état vide explicite (icône + message + invitation à enregistrer une recherche) si elle ne contient plus aucune entrée.

---

**Documents liés** : [PRODUCT_SPEC.md](PRODUCT_SPEC.md) · [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) · [DECISIONS.md](DECISIONS.md) · [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md)
