# UX_RULES — House For You

> **Statut : vivant.** Ce document liste toutes les règles d'expérience utilisateur non négociables. **Aucune règle ici ne doit être cassée sans qu'une entrée correspondante soit ajoutée à [DECISIONS.md](DECISIONS.md) expliquant pourquoi.** Si le code et ce document divergent, le document doit être corrigé dans le même commit que le changement.
>
> Dernière mise à jour : 2026-07-20.

---

## 1. Principe directeur

> *« Simplicité visuelle, puissance fonctionnelle. »*

House For You vise la sensation d'une application Apple ou Airbnb — minimaliste, extrêmement fluide, intuitive — tout en offrant la puissance fonctionnelle d'un portail immobilier complet. Chaque règle ci-dessous découle de ce principe.

## 2. Mobile first

- Toute conception démarre par l'écran le plus petit visé (iPhone), jamais par le desktop.
- Le desktop reste **compatible** (l'app doit compiler et rester utilisable en `flutter run -d macos`/web) mais n'est **jamais** la contrainte de mise en page. Aucune fonctionnalité ne doit être conçue « pour le grand écran d'abord ».
- Référence : [architecture-mvp.md](architecture-mvp.md) section 1, [PRODUCT_SPEC.md](PRODUCT_SPEC.md) section 7.

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
- Ajoute le bien aux favoris s'il n'y est pas, le retire s'il y est déjà (même sémantique que le bouton cœur).
- Déclenche systématiquement une animation de cœur (rebond puis fondu), sauf si l'action est bloquée par la porte d'authentification (invité) — dans ce cas, seul le message de connexion s'affiche, aucune animation ne doit laisser croire que l'action a réussi.
- La séparation stricte des zones de geste (média = like, texte = ouvrir la fiche) est **testée** (`test/property_card_gestures_test.dart`) — toute évolution de `PropertyCard.feed` doit préserver ces tests ou les mettre à jour consciemment.

## 7. Ouverture de la fiche détail

- Un tap simple sur le **bloc texte** (prix, titre, localisation, description) d'une carte du feed ouvre la fiche détail — jamais un tap sur le média.
- Transition : fondu + léger glissement vers le haut (`CustomTransitionPage`, `lib/core/router/app_router.dart`), 320 ms à l'ouverture.

## 8. Fermeture de la fiche détail

- Swipe horizontal vers la droite, depuis la zone sous la galerie photo (la galerie garde son propre swipe horizontal dédié aux photos — pas de conflit, voir [DECISIONS.md](DECISIONS.md)).
- Effet « balancer » : translation + légère rotation autour du bord gauche, suivi du doigt en direct (1:1), seuil de distance (32 % de la largeur d'écran) ou de vitesse avant confirmation de fermeture.
- **Jamais de fond blanc pendant le geste** : la route est non opaque (`opaque: false`) et le feed déjà chargé en dessous transparaît directement à mesure que la fiche s'écarte — comme si la fiche flottait au-dessus du feed, jamais comme un écran qui se recharge.
- Après fermeture, retour exact au même bien dans le feed, swipe vertical immédiatement fonctionnel (aucun état résiduel du geste de fermeture ne doit persister).

## 9. Bottom Sheet (filtres, recherches enregistrées)

- Jamais une nouvelle page — toujours une feuille qui monte depuis le bas.
- Fond flouté (`BackdropFilter`, `lib/core/widgets/blurred_modal_sheet.dart`) plutôt qu'un simple assombrissement — signale immédiatement à l'utilisateur qu'il reste « au-dessus » du contexte précédent, pas dans un nouvel écran.
- Hauteur quasi pleine (94 % de l'écran) avec un liseré du fond flouté visible en haut — l'utilisateur comprend immédiatement où il est sans README.
- Poignée de glissement (petite barre grise) en haut de la feuille, coins arrondis 28 px.
- En-tête fixe : fermeture (X) à gauche, titre centré, « Réinitialiser » à droite (visible seulement si des filtres sont actifs).
- Pied fixe : bouton d'action principal, toujours visible même si le contenu défile.
- Le clavier ne doit **jamais** masquer le champ actif ou le bouton d'action — la feuille remonte avec `MediaQuery.viewInsets.bottom` (voir `FiltersSheet` dans `filters_sheet.dart`).

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
- Seules les actions qui **engagent** (favori, contacter une agence, demander une visite, créer une alerte) déclenchent la porte d'authentification (`requireAuth()`, `lib/core/auth/auth_guard.dart`).
- Tant que l'écran de connexion réel n'existe pas (avant l'étape 5), la porte affiche un message explicite (SnackBar) plutôt que de bloquer silencieusement ou de construire un écran de connexion prématuré — voir [DECISIONS.md](DECISIONS.md).

## 15. Performance perçue

- Précache systématique des médias adjacents (bien précédent/suivant dans le feed) — voir [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md) section « Préchargement ».
- `RepaintBoundary` autour de tout élément coûteux répété dans une liste/feed.
- Aucun appel réseau ou calcul lourd ne doit bloquer le thread principal pendant un geste actif (drag, animation).

---

**Documents liés** : [PRODUCT_SPEC.md](PRODUCT_SPEC.md) · [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) · [DECISIONS.md](DECISIONS.md) · [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md)
