# DESIGN_SYSTEM — House For You

> **Statut : vivant.** Toute couleur, espacement, typographie ou composant utilisé dans l'app doit exister ici avant (ou en même temps) que dans le code. Si un écran introduit une valeur qui n'est pas documentée ici, c'est une anomalie — soit la valeur ne devrait pas exister, soit ce document est en retard.
>
> Source de vérité technique : `lib/core/theme/` et `lib/core/widgets/`. Ce document explique le *pourquoi* et sert de référence rapide ; en cas de divergence, le code fait foi et ce document doit être corrigé dans la foulée.
>
> Dernière mise à jour : 2026-07-20 (sous-étape 2.3 — recherche, filtres et recherches sauvegardées).

---

## 1. Principes

- **Palette restreinte.** Une couleur primaire, un accent, une échelle de neutres, trois couleurs sémantiques. Pas de couleur ad hoc par écran.
- **Une seule famille de police** (Roboto au MVP), échelle de tailles limitée et réutilisée partout.
- **Espacement en échelle fixe** (4/8/12/16/24/32) — jamais de valeur magique (`EdgeInsets.all(13)` interdit).
- **Rayons cohérents** — 4 valeurs seulement, jamais un rayon inventé à la volée.
- Tout ceci vit dans `lib/core/theme/` (`app_colors.dart`, `app_spacing.dart`, `app_typography.dart`, `app_theme.dart`) et ne doit **jamais** être dupliqué en valeur brute dans un écran.

## 2. Couleurs (`lib/core/theme/app_colors.dart`)

| Rôle | Token | Valeur | Usage |
|---|---|---|---|
| Primaire | `AppColors.primary` | `#1F6F5C` (vert forêt profond) | Boutons principaux, éléments sélectionnés, icônes actives |
| Primaire clair | `AppColors.primaryLight` | `#4C9C87` | Variantes claires, états hover/pressed futurs |
| Primaire foncé | `AppColors.primaryDark` | `#13473A` | Variantes foncées |
| Accent | `AppColors.accent` | `#E8A33D` (ocre doré) | Badges énergie, accents ponctuels, warning |
| Fond | `AppColors.background` | `#FAFAF8` (blanc cassé) | Fond des écrans « classiques » (fiche détail, filtres, placeholders) |
| Surface | `AppColors.surface` | `#FFFFFF` | Cartes, champs, boutons ronds |
| Bordure | `AppColors.border` | `#E3E1DC` | Séparateurs, contours de champs/cartes non sélectionnées |
| Texte principal | `AppColors.textPrimary` | `#1A1A18` | Texte sur fond clair |
| Texte secondaire | `AppColors.textSecondary` | `#6B6A64` | Sous-titres, légendes |
| Texte désactivé | `AppColors.textDisabled` | `#AFAEA8` | États désactivés |
| Succès | `AppColors.success` | `#2E7D32` | Confirmations |
| Erreur | `AppColors.error` | `#C62828` | Erreurs, favori actif (cœur rouge) |
| Avertissement | `AppColors.warning` | `#E8A33D` | Alertes non bloquantes (= `accent`) |
| Voile | `AppColors.overlayScrim` | `#CC000000` | Dégradé de lisibilité sur médias plein écran |

**Fond immersif du feed** : `#0B0B0C` (quasi noir), défini localement dans `discover_screen.dart` plutôt que dans `AppColors` — c'est un choix d'immersion propre au feed plein écran (jamais de blanc entre deux biens pendant le swipe, voir [DECISIONS.md](DECISIONS.md)), pas une couleur de palette générale réutilisable ailleurs.

**Certificat énergétique (PEB)** — échelle conventionnelle verte → rouge, définie dans `lib/features/discover/filters/filter_options.dart` (`energyScoreColors`) : A+ `#0E7C42`, A `#2E9E4B`, B `#7AB648`, C `#C7D046`, D `#F0C93E`, E `#EF9B3D`, F `#E96A2C`, G `#D8342A`.

## 3. Typographie (`lib/core/theme/app_typography.dart`)

Police système : **Roboto**. Échelle unique, réutilisée sur tout l'écosystème d'écrans :

| Style | Taille | Graisse | Usage |
|---|---|---|---|
| `titleLarge` | 28 | 700 | Titres d'écran, prix en fiche détail |
| `titleMedium` | 20 | 600 | Titres de section, prix en carte |
| `body` | 16 | 400 | Texte courant |
| `bodySecondary` | 14 | 400 | Sous-titres, texte secondaire |
| `caption` | 12 | 400 | Légendes, labels de puces |
| `button` | 16 | 600 | Libellés de boutons |

Sur médias (feed, galeries), tout texte reçoit `kOverlayTextShadow` (`lib/core/widgets/property_card.dart`) — une ombre portée légère (`Colors.black45`, flou 6, décalage (0,1)) qui garantit la lisibilité quel que soit le contraste de la photo derrière.

## 4. Espacement (`lib/core/theme/app_spacing.dart`)

Échelle fixe à 6 paliers — toujours `AppSpacing.xxx`, jamais un nombre en dur :

`xs = 4` · `sm = 8` · `md = 12` · `lg = 16` · `xl = 24` · `xxl = 32`

## 5. Rayons (`lib/core/theme/app_spacing.dart`, classe `AppRadius`)

`sm = 8` · `md = 12` · `lg = 20` · `pill = 999` (boutons/puces totalement arrondis)

La feuille de filtres utilise un rayon exceptionnel de `28` (coins supérieurs) — volontairement plus généreux que `AppRadius.lg` pour une identité de « feuille » clairement distincte d'une carte classique.

## 6. Ombres

| Token | Définition | Usage |
|---|---|---|
| `kFloatingButtonShadow` (`property_card.dart`) | `BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0,3))` | Boutons circulaires flottants sur média (favori, partage, retour, badge agence) — les détache visuellement de la photo |
| `kOverlayTextShadow` (`property_card.dart`) | `Shadow(color: Colors.black45, blurRadius: 6, offset: Offset(0,1))` | Tout texte superposé à une photo |

Aucune autre ombre libre ne doit apparaître dans le code — étendre `kFloatingButtonShadow`/`kOverlayTextShadow` ou en documenter une nouvelle ici avant de l'introduire.

## 7. Grilles

- **Type de bien** et **Caractéristiques** (feuille de filtres) : `GridView.count(crossAxisCount: 3)`, ratio `1.05`, espacement `AppSpacing.sm`.
- Pas de grille de mise en page globale (l'app est mobile-first, une colonne unique sur l'essentiel des écrans) — les grilles n'existent que pour les sélecteurs à icônes.

## 8. Responsive

- Priorité absolue à iPhone (voir [UX_RULES.md](UX_RULES.md) section 2).
- Le feed occupe toujours 100 % de la largeur/hauteur disponible, quel que soit l'appareil — pas de largeur maximale imposée.
- Le contenu texte des écrans « classiques » (placeholders) se limite à `maxWidth: 420` pour rester lisible sur desktop/web sans réécrire les écrans.
- Aucun breakpoint desktop dédié au MVP — le desktop hérite du même layout, simplement rendu sur un canvas plus grand.

## 9. Animations

| Effet | Détail | Fichier |
|---|---|---|
| Settle du swipe (feed, galeries) | Ressort personnalisé `SnappyPageScrollPhysics` (`mass: 0.3, stiffness: 180, ratio: 1`) — plus vif que le défaut Flutter (`mass: 0.5, stiffness: 100`), toujours critique/sur-amorti (jamais de rebond) | `lib/core/widgets/snappy_page_physics.dart` |
| Parallax entre cartes du feed | Échelle `1 → 0.94` en fonction de la distance à la page courante | `discover_screen.dart` |
| Cœur du double tap | `TweenSequence` : 0.3 → 1.2 (`easeOutBack`) → 1.0 (`easeOut`), fondu en sortie | `property_card.dart` (`_LikeBurst`) |
| Bouton favori | `AnimatedSwitcher` avec `ScaleTransition` en surcôte (0.6 → 1.25 → 1.0) au changement d'état | `property_card.dart` (`_FavoriteButton`) |
| Ouverture fiche détail | Fondu + glissement vertical léger (`Offset(0, 0.05) → Offset.zero`), `easeOutCubic`, 320 ms | `app_router.dart` |
| Fermeture fiche détail | Translation + rotation interactive suivant le doigt (« balancer »), seuil 32 % largeur ou vitesse, `easeIn`/`easeOutBack` selon confirmation | `property_detail_screen.dart` (`_SwipeToDismiss`) |
| Feuille de filtres/recherches enregistrées | Flou + assombrissement progressifs du fond, glissement depuis le bas, `easeOutCubic` (ouverture) / `easeInCubic` (fermeture), 380/260 ms | `lib/core/widgets/blurred_modal_sheet.dart` |
| Barre de recherche flottante | Opacité + translation verticale liées en continu à la position de scroll du feed (pas de show/hide binaire), recalée sur 0/1 dès qu'une page est franchie | `discover_screen.dart` |
| Indicateur photo (stories) | `AnimatedContainer` 200 ms sur chaque segment | `property_card.dart` (`_PhotoIndicator`) |
| Masquage de l'interface à l'appui long | `AnimatedOpacity` 180 ms, `Curves.easeOut`, sur l'ensemble du chrome de la carte (regroupé en un seul widget) et sur la barre flottante (réutilise sa visibilité continue existante) | `property_card.dart` (`_FeedCardState`), `discover_screen.dart` |
| Repli/dépliage « Plus de filtres » | `AnimatedSize` 220 ms, `Curves.easeOut` ; chevron `AnimatedRotation` 220 ms (0 → 0,5 tour) | `filters/filters_sheet.dart` |

Règle transversale : toute transition respecte l'esprit Material 3 tout en visant une sensation proche d'iOS — courbes `easeOut*`/`easeIn*` privilégiées, jamais `Curves.linear` pour une animation perceptible par l'utilisateur.

## 10. Composants (`lib/core/widgets/`)

| Composant | Rôle | Variantes |
|---|---|---|
| `PhButton` | Bouton arrondi standard | `primary` / `secondary` / `text`, `expand` optionnel |
| `PropertyCard` | Carte bien — **un seul composant, deux variantes** pour garantir la cohérence visuelle entre le feed et les listes | `.feed()` (plein écran, gestes séparés média/texte) / `.list()` (compacte, pour les futurs résultats de recherche) |
| `PhChip` | Puce sélectionnable simple | Utilisée dans la recherche guidée (étape 3, à venir) |
| `PhSlider` | Curseur simple à une poignée | Critères continus hors filtres (recherche guidée à venir) |
| `LoadingState` | État de chargement uniforme | — |
| `ErrorState` | État d'erreur uniforme, bouton « Réessayer » optionnel | — |
| `PlaceholderScreen` | Écran temporaire élégant (icône + titre + sous-titre, entrée animée) | Utilisé par Rechercher/Favoris/Profil tant qu'ils ne sont pas développés |
| `FloatingSearchBar` | Barre flottante verre dépoli du feed | — |
| `BlurredModalSheet` (`showBlurredModalSheet`) | Feuille modale plein écran avec flou de fond | Utilisée par la feuille de filtres |
| `promptSavedSearchName` (`saved_search_name_dialog.dart`) | Dialogue `AlertDialog` standard partagé pour nommer/renommer une recherche sauvegardée, champ pré-rempli | Enregistrement (`filters_sheet.dart`) et renommage (`saved_searches_sheet.dart`) |

**Widgets de la feuille de filtres** (`lib/features/discover/filters/filter_widgets.dart`) — spécifiques à cet écran mais suivent strictement la palette/espacement globaux :

| Widget | Rôle |
|---|---|
| `SheetSectionHeader` | Titre + sous-titre de section |
| `BigChoiceCard` | Grande carte de choix (type de transaction) — icône, libellé, sous-titre, coche animée |
| `PillChoice` | Puce de choix générique (rayon, tri, état du bien, date, grade EPC — couleur d'accent personnalisable) |
| `IconGridChoice` | Case de grille à icône (type de bien, caractéristiques) |
| `QuickCountSelector` | Sélection rapide « 1+ / 2+ / 3+... » |
| `RangeSliderField` | Slider double poignée + champs de saisie manuelle synchronisés |

## 11. Icônes

Material Symbols (`Icons.*_rounded` systématiquement quand la variante existe — cohérence visuelle « arrondie » alignée sur les rayons du design system). Aucune icône custom au MVP.

## 12. Ce qui n'est **pas** encore standardisé

- Mode sombre (l'app est mode clair uniquement au MVP — le fond noir du feed est une exception immersive locale, pas un mode sombre global).
- Composants de formulaire dédiés (champ texte standard, sélecteur de date) — le dialogue de nommage des recherches sauvegardées (`promptSavedSearchName`) utilise volontairement l'`AlertDialog`/`TextField` par défaut de Material, sans habillage design system, en attendant les formulaires de lead (étape 7) qui justifieront un vrai composant de champ texte partagé.
- Grille desktop dédiée.

---

**Documents liés** : [UX_RULES.md](UX_RULES.md) · [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md) · [PRODUCT_SPEC.md](PRODUCT_SPEC.md)
