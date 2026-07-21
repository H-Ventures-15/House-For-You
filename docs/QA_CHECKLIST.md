# QA_CHECKLIST — House For You

> **Statut : vivant.** Checklist officielle à dérouler avant de considérer un sprint terminé — voir [CONTRIBUTING.md](CONTRIBUTING.md) section 8 pour le processus de validation complet dans lequel elle s'insère. **Aucun sprint ne doit être annoncé comme terminé sans l'avoir déroulée.**
>
> Dernière mise à jour : 2026-07-20.

---

## 0. Plateforme de référence

**iOS (iPhone) est la seule plateforme de validation officielle du produit — voir [DECISIONS.md](DECISIONS.md) ADR-018.** Le Web, macOS et Android ne servent qu'au développement, au débogage et aux tests rapides ; ils ne remplacent jamais une vérification sur iPhone, idéalement physique. En cas de doute ou de divergence de comportement entre le navigateur et l'iPhone, **l'iPhone fait foi**.

Chaque catégorie ci-dessous doit être vérifiée en gardant cette règle en tête — un geste « fluide » dans Chrome qui saccade sur iPhone est un échec de cette checklist, pas une réussite.

Les cases non applicables à une fonctionnalité donnée (ex. « vidéos » avant que le lecteur vidéo n'existe) peuvent être ignorées ponctuellement, mais **jamais cochées par complaisance** — voir les annotations *(à venir)* ci-dessous pour les fonctionnalités non encore construites.

---

## 1. Feed (Découvrir)

- [ ] Swipe vertical parfaitement fluide (changement de bien, `SnappyPageScrollPhysics`)
- [ ] Swipe horizontal parfaitement fluide (changement de photo au sein d'un bien)
- [ ] Aucun conflit de gestes (vertical/horizontal/double tap/appui long — voir [UX_RULES.md](UX_RULES.md) sections 4-6 bis)
- [ ] Aucun écran blanc, aucun flash pendant le scroll ou les transitions
- [ ] Préchargement fonctionnel (médias du bien précédent/suivant déjà en cache au moment d'y arriver)
- [ ] Aucun saut de layout (barre flottante, rail d'actions, indicateur photo)
- [ ] Images déjà chargées au moment de leur apparition (pas de pop-in visible sur un swipe normal)
- [ ] Vidéos prêtes à la lecture *(à venir — aucun lecteur vidéo n'est encore implémenté, voir [BACKLOG.md](BACKLOG.md) « Vidéo dans le feed » ; ne pas cocher tant que la fonctionnalité n'existe pas)*
- [ ] Barre de recherche flottante correcte (résumé exact, masquage/réapparition au scroll et à l'appui long — voir [UX_RULES.md](UX_RULES.md) section 6 bis)

## 2. Fiche du bien

- [ ] Ouverture fluide depuis le feed (fondu + glissement, 320 ms)
- [ ] Fermeture par swipe vers la droite (zone sous la galerie, seuil 32 % ou vitesse)
- [ ] Retour exact au même bien dans le feed après fermeture
- [ ] Retour exact au même média (photo affichée dans la galerie) après fermeture
- [ ] Aucun fond blanc pendant l'ouverture, la fermeture ou le geste interactif (route `opaque: false`, voir [DECISIONS.md](DECISIONS.md) ADR-005)
- [ ] Hero Animation entre la vignette du feed et la galerie de la fiche *(à venir — envisagée puis reportée lors du polish premium, voir [BACKLOG.md](BACKLOG.md) ; ne pas cocher tant que non implémentée)*
- [ ] Scroll du contenu de la fiche sans conflit avec le geste de fermeture (axes opposés, voir [UX_RULES.md](UX_RULES.md) section 8)

## 3. Filtres & recherche

- [ ] Ouverture de la feuille de filtres (bouton/tap sur la barre flottante)
- [ ] Fermeture par la croix
- [ ] Fermeture par swipe vers le bas / retour système
- [ ] Réouverture sans état résiduel incohérent
- [ ] Hiérarchie « Plus de filtres » : repliée par défaut, se déplie correctement, badge de comptage exact (voir [UX_RULES.md](UX_RULES.md) section 9 bis)
- [ ] Recherche sauvegardée : enregistrement (nom par défaut pertinent, confirmation visuelle)
- [ ] Recherche sauvegardée : chargement (depuis la feuille de filtres et depuis l'accès rapide de la barre)
- [ ] Recherche sauvegardée : renommer
- [ ] Recherche sauvegardée : supprimer (avec confirmation)
- [ ] Réinitialisation des filtres
- [ ] État zéro résultat : les trois actions sont proposées et fonctionnelles (Modifier les filtres / Réinitialiser / Charger une recherche sauvegardée — voir [UX_RULES.md](UX_RULES.md) section 17)
- [ ] Compteur de résultats exact (« Afficher N biens », recalculé à chaque changement de filtre)
- [ ] Changement de type de transaction réinitialise un budget déjà choisi (échelles achat/location incompatibles)

## 4. Navigation

- [ ] Onglet Découvrir fonctionne
- [ ] Onglet Favoris fonctionne (état invité correct tant que l'authentification n'existe pas)
- [ ] Onglet Profil fonctionne (état invité correct tant que l'authentification n'existe pas)
- [ ] Retour vers Découvrir depuis n'importe quel onglet
- [ ] Conservation de l'état de chaque onglet au changement de branche (`StatefulShellBranch`)
- [ ] Navigation cohérente au retour matériel/geste système (jamais un retour à l'écran d'accueil par défaut)

## 5. Micro-interactions

- [ ] Double tap sur le média ajoute/retire le favori
- [ ] Animation du cœur (apparition rapide, légère augmentation de taille, disparition douce — jamais agressive ni enfantine)
- [ ] Boutons (favori, partager, filtres, retour) réagissent immédiatement au tap
- [ ] Badges (agence, indicateur photo, badges éditoriaux Exclusivité/Coup de cœur/Prix réduit/Visite virtuelle/Nouveau — max 2 par carte) affichés correctement
- [ ] Haptic Feedback présent et discret (double tap favori — voir [UX_RULES.md](UX_RULES.md) section 6)
- [ ] Transitions cohérentes avec l'esprit iOS (`easeOut*`/`easeInBack`, jamais `Curves.linear` sur une animation perceptible)
- [ ] Indicateur de médias (stories) synchronisé avec la photo affichée

## 6. Performances

- [ ] Aucune régression sur les optimisations déjà en place (`SnappyPageScrollPhysics`, `RepaintBoundary`, `AutomaticKeepAliveClientMixin`, précache — voir [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md) section 10)
- [ ] Aucune saccade perceptible pendant un geste actif sur iPhone
- [ ] Aucune reconstruction inutile de widgets coûteux (feed entier reconstruit à chaque changement de filtre, par exemple)
- [ ] Fluidité constante sur l'ensemble du feed, pas seulement sur les premières cartes
- [ ] Aucun ralentissement perceptible à l'usage prolongé (fuite mémoire, accumulation d'écouteurs non disposés)
- [ ] Optimisations des sprints précédents conservées (vérifier qu'aucun fichier des sprints de fluidité/gestes n'a été modifié sans revue explicite)

## 7. Accessibilité

- [ ] Labels sémantiques sur les actions principales (`Semantics(button:, selected:, label:)`)
- [ ] Contraste suffisant, en particulier le texte superposé aux photos (`kOverlayTextShadow`)
- [ ] Zones tactiles suffisamment grandes (cible minimale ~44×44 pt)
- [ ] Dynamic Type respecté autant que possible (pas de texte tronqué de façon illisible à une taille de police agrandie)
- [ ] Aucune information ou état de sélection signalé uniquement par la couleur

## 8. Qualité du code

Avant chaque commit, sans exception :

```bash
dart format lib/ test/
flutter analyze
flutter test
```

- [ ] `dart format` ne modifie plus aucun fichier
- [ ] `flutter analyze` ne remonte aucune erreur ni avertissement
- [ ] `flutter test` : tous les tests passent
- [ ] Aucun test désactivé/ignoré sans justification documentée

---

## Comment utiliser cette checklist

1. Dérouler chaque catégorie pertinente pour le sprint en cours — un sprint qui ne touche pas aux filtres peut ignorer la section 3, mais doit tout de même repasser sur les sections 1, 2, 6 et 8 (feed, fiche, performance et qualité de code sont transverses à presque tout changement).
2. Vérifier prioritairement sur iPhone physique ou, à défaut, simulateur iOS — jamais uniquement sur le navigateur de développement (voir [DECISIONS.md](DECISIONS.md) ADR-018).
3. Une case qui échoue bloque la validation du sprint — corriger avant de continuer, pas après.
4. Voir [CONTRIBUTING.md](CONTRIBUTING.md) section 8 pour la place exacte de cette checklist dans le processus de validation d'un sprint (développer → tester → dérouler cette checklist → mettre à jour la documentation → commit → push → attendre validation).

---

**Documents liés** : [CONTRIBUTING.md](CONTRIBUTING.md) · [UX_RULES.md](UX_RULES.md) · [DECISIONS.md](DECISIONS.md) · [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md)
