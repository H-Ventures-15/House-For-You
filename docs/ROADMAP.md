# ROADMAP — House For You

> **Statut : vivant.** Chaque étape et sous-étape doit être mise à jour (état, date, commentaires) au moment où elle est validée — avant le commit qui la clôt. Ordre de développement fixé initialement par [architecture-mvp.md](architecture-mvp.md) section 9 ; ce document en est la version vivante et détaillée.
>
> Légende État : ✅ Terminé · 🟡 En cours · ⬜ À faire
>
> Dernière mise à jour : 2026-07-21 (sous-étape 2.4 — micro-interactions premium & corrections UX).

---

## Étape 0 — Setup

**Objectif** : scaffold Flutter complet, design system de base, navigation, state management, données mock.

**Description** : structure de dossiers (`core/`, `data/`, `features/`, `l10n/`), thème (couleurs/typographie/espacement), GoRouter, Riverpod, mocks initiaux (biens, agences, leads).

**État** : ✅ Terminé
**Date** : 2026-07-19
**Commentaires** : réalisé en environnement sandbox sans accès réseau à l'infrastructure Flutter — `flutter pub get`/`analyze`/`test` non exécutables à ce stade, delegués à l'exécution locale. Environnement ensuite déplacé sur un volume APFS (voir [DECISIONS.md](DECISIONS.md) — exFAT incompatible avec les builds iOS/macOS).

---

## Étape 1 — Coquille de navigation

**Objectif** : bottom bar 4 onglets, accessible sans compte, états invité pour Favoris/Profil.

**Description** : `StatefulShellRoute` GoRouter (Découvrir/Rechercher/Favoris/Profil), fondu entre branches, plateformes natives (iOS/Android/macOS/Web) générées.

**État** : ✅ Terminé
**Date** : 2026-07-19
**Commentaires** : commit `a3b7e54` (coquille) + `e42cc0c` (génération des plateformes natives). CocoaPods installé pour les builds iOS/macOS.

---

## Étape 2 — Feed Découvrir

**Objectif** : feed vertical plein écran type TikTok/Airbnb, fiche détail, système de filtres complet, fluidité irréprochable.

**Description** : cette étape a largement dépassé le périmètre initial d'`architecture-mvp.md` (« feed vertical plein écran, photos, tracking impressions basique ») à la demande explicite d'Hugo, qui a progressivement enrichi les objectifs en cours d'étape. Livrables, dans l'ordre :

1. **Feed de base + fiche détail** (commit `09be1a8`, 2026-07-19) — `PageView` vertical plein écran, galerie photo horizontale indépendante par carte, fiche détail complète (galerie, description, localisation, caractéristiques, énergie, agence), favoris/contact protégés par `requireAuth()`, partage natif (`share_plus`), tracking basique.
2. **Polish premium** (commit `3bbb3fe`, 2026-07-20) — barre de recherche flottante (verre dépoli, masquage animé au scroll), recherches enregistrées (mock), double tap like avec animation cœur, zones de gestes strictement séparées (média = like, texte = ouvrir la fiche), fermeture de fiche par swipe avec effet « balancer », ombres/dégradés/parallax.
3. **Système de filtres premium** (commit `4461646`, 2026-07-20) — feuille plein écran type Airbnb (fond flouté), 14 sections (localisation, transaction, budget, type de bien, chambres/salles de bain, surfaces, PEB, caractéristiques, état du bien, date de publication, tri, ambiance de vie, recherches enregistrées, CTA), compteur de résultats réellement calculé sur les données mock, feed réellement filtré.
4. **Sous-étape 2.1 — Fluidité du swipe façon TikTok** (commit `3c3759c`, 2026-07-20) — voir ci-dessous.
5. **Sous-étape 2.2 — Gestes & interactions naturelles** (2026-07-20) — voir ci-dessous.
6. **Sous-étape 2.3 — Recherche, filtres et recherches sauvegardées** (2026-07-20) — voir ci-dessous.
7. **Sous-étape 2.4 — Micro-interactions premium & corrections UX** (2026-07-21) — voir ci-dessous.

**État** : ✅ Terminé (le périmètre initial et ses extensions successives sont livrés). L'étape avait été formellement close avant l'étape 3 puis rouverte trois fois (sous-étapes 2.2, 2.3 et 2.4), à chaque fois à la demande explicite d'Hugo — cohérent avec la règle « une seule étape à la fois » de [CLAUDE.md](../CLAUDE.md) puisqu'aucune extension n'a été anticipée sans validation.
**Date** : 2026-07-19 → 2026-07-21
**Commentaires** : deux bugs réels découverts et corrigés en cours d'étape (documentés dans les commits et [DECISIONS.md](DECISIONS.md)) — `PageView` du feed sans `scrollDirection: Axis.vertical` explicite, et feuille de filtres sans ancêtre `Material` (cassait `TextField`/`InkWell`). Les deux ont été détectés par les tests avant merge.

### Sous-étape 2.1 — Fluidité du swipe façon TikTok

**Objectif** : que le swipe donne exactement la sensation de fluidité de TikTok/Instagram — suivi du doigt parfait, aucune saccade, changement de bien instantané.

**Description** : `SnappyPageScrollPhysics` (ressort de settle personnalisé, plus vif que le défaut Flutter) sur les trois `PageView` de l'app (feed, galerie carte, galerie fiche détail) ; `RepaintBoundary` par carte du feed ; préchargement renforcé des médias voisins (3 par voisin, erreurs silencieuses) ; `AutomaticKeepAliveClientMixin` déjà en place exploité pour préserver l'état des cartes visitées.

**État** : ✅ Terminé
**Date** : 2026-07-20
**Commentaires** : piste explorée puis écartée documentée — `allowImplicitScrolling` a été activé en pensant qu'il pré-montait les pages voisines en mémoire ; vérification empirique (test dédié) a montré que cette option Flutter ne sert que l'accessibilité VoiceOver/TalkBack. Gardée pour ce bénéfice réel, mais la documentation a été corrigée pour ne pas laisser croire qu'elle explique la fluidité — voir [DECISIONS.md](DECISIONS.md).

### Sous-étape 2.2 — Gestes & interactions naturelles

**Objectif** : compléter la palette de gestes du feed pour qu'elle semble directement reliée au doigt, sans aucun conflit perceptible entre swipe vertical, swipe horizontal, double tap, appui long et ouverture de fiche.

**Description** (désignée « Sprint 2.3 » dans la demande d'Hugo — numérotée ici comme sous-étape de l'Étape 2, dans la continuité de la sous-étape 2.1) :
- **Appui long sur le média** — masque le chrome de la carte (gradient haut, bloc prix/titre/description, indicateur photo, badge agence, rail favori/partager) et la barre de recherche flottante, transition 180 ms ; restaure exactement l'état précédent au relâchement (pas un état forcé) ; la bottom bar n'est volontairement pas masquée (voir [DECISIONS.md](DECISIONS.md) ADR-015).
- **Retour haptique léger** (`HapticFeedback.lightImpact()`) sur le double tap favori, uniquement quand l'action aboutit réellement.
- **Labels sémantiques** sur les actions principales (favori, partager, ouvrir la fiche, retour) pour les lecteurs d'écran, sans jamais rendre une fonctionnalité dépendante exclusivement d'un geste.
- Double tap (favori), tap simple sur le bloc texte (ouverture fiche), swipe horizontal (galerie), swipe vertical (feed) et fermeture de fiche par swipe droite existaient déjà depuis l'étape 2/2.1 — revérifiés et non modifiés (aucune régression).

**État** : ✅ Terminé
**Date** : 2026-07-20
**Commentaires** : 5 tests ajoutés (masquage/restauration du chrome et de la barre flottante, non-déclenchement du favori/de l'ouverture de fiche pendant l'appui long, labels sémantiques, scroll vertical sans fermeture accidentelle de la fiche) — 30 tests au total désormais (voir [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md) section 11). Aucune régression sur la fluidité de la sous-étape 2.1 (`SnappyPageScrollPhysics`, `RepaintBoundary`, `AutomaticKeepAliveClientMixin`, précache) — code non touché, tests correspondants toujours au vert.

### Sous-étape 2.3 — Recherche, filtres et recherches sauvegardées

**Objectif** : un système de recherche simple visuellement mais puissant dans son fonctionnement — hiérarchie claire des filtres, recherches sauvegardées réellement fonctionnelles (sauvegarde/chargement/renommage/suppression), aucun cul-de-sac en cas de zéro résultat.

**Description** (désignée « Sprint 2.4 » dans la demande d'Hugo — numérotée ici comme sous-étape de l'Étape 2, dans la continuité des sous-étapes 2.1/2.2) : le système de filtres complet (barre flottante, feuille plein écran à 14 sections, compteur de résultats réel) existait déjà depuis l'étape 2 initiale — ce sprint a comblé les écarts réels entre la demande et l'existant :
- **Hiérarchie des filtres** — seuls les critères principaux (localisation + rayon, type de transaction, budget, type de bien, chambres) restent immédiatement visibles à l'ouverture ; les critères avancés (salles de bain, surfaces, PEB, caractéristiques, état du bien, date de publication, tri, ambiance de vie) vivent sous une section repliable « Plus de filtres » avec badge de comptage (voir [UX_RULES.md](UX_RULES.md) section 9 bis).
- **Recherches sauvegardées réelles** — `SavedSearch` porte désormais de vrais `SearchFilters` (plus un simple libellé statique), avec `SavedSearchesRepository`/`MockSavedSearchesDataSource`/`SavedSearchesController` suivant le pattern déjà établi (ADR-011). Enregistrer propose un nom par défaut pertinent (modifiable), confirme visuellement ; charger, renommer et supprimer sont tous fonctionnels, depuis la feuille de filtres et depuis l'accès rapide de la barre flottante.
- **Incompatibilité budget/transaction** — changer de type de transaction (achat ↔ location) réinitialise un budget déjà choisi, les deux échelles de prix n'ayant aucun rapport.
- **État "zéro résultat" enrichi** — trois issues concrètes (Modifier les filtres, Réinitialiser, Charger une recherche sauvegardée) plutôt qu'un message avec un unique bouton.
- **Accessibilité** — labels sémantiques (`selected`/`button`) sur les contrôles de sélection (puces, cartes, grilles à icônes), jamais la couleur seule pour signaler un état sélectionné.

**État** : ✅ Terminé
**Date** : 2026-07-20
**Commentaires** : 9 tests ajoutés dans deux nouveaux fichiers (`test/filters_sheet_test.dart`, `test/saved_searches_sheet_test.dart`) — 39 tests au total désormais (voir [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md) section 11). Aucune régression sur les Sprints 2.2/2.3 (gestes, fluidité) — fichiers concernés non modifiés, tests correspondants toujours au vert. Décision produit : les recherches sauvegardées ne passent volontairement pas par `requireAuth()` à cette étape (voir [DECISIONS.md](DECISIONS.md) ADR-016).

### Sous-étape 2.4 — Micro-interactions premium & corrections UX (« Sprint 2.5 »)

**Objectif** : transformer l'app d'un prototype fonctionnel en expérience mobile premium — micro-interactions, animations, retours haptiques, lisibilité, cohérence générale — sans anticiper l'Étape 3.

**Description** (désignée « Sprint 2.5 » dans la demande d'Hugo — numérotée ici comme sous-étape de l'Étape 2, dans la continuité des sous-étapes 2.1/2.2/2.3) :
- **Bug de navigation rapporté** — investigation approfondie (code + tests dédiés) : aucun défaut trouvé dans `StatefulShellRoute`/`goBranch`/`BranchFadeContainer`, qui suivent le pattern officiellement recommandé par `go_router`. Le symptôme n'a été observé que dans le serveur web de développement, jamais reproduit par `flutter test` — voir [DECISIONS.md](DECISIONS.md) ADR-019 pour le détail de l'investigation. Tests de régression permanents ajoutés verrouillant exactement les séquences demandées.
- **Fermeture de la feuille de filtres par swipe vers le bas** — geste suivant le doigt en direct, priorité au scroll interne, seuil de 32 % ou de vitesse, fond flouté proportionnel au geste (`lib/core/widgets/blurred_modal_sheet.dart`) — voir [DECISIONS.md](DECISIONS.md) ADR-020.
- **Animation du favori affinée** — rebond marqué à l'ajout, fondu discret au retrait (`property_card.dart`).
- **Indicateur de médias** — distinction visuelle photo/vidéo (icône caméra), légère ombre pour la lisibilité sur fond clair.
- **Badges éditoriaux/commerciaux** (Exclusivité, Coup de cœur, Prix réduit, Visite virtuelle, Nouveau) — dérivés à la volée depuis `Property`, jamais plus de 2 par carte — voir [DECISIONS.md](DECISIONS.md) ADR-021.
- **Micro-animations de pression** (`PressableScale`, `lib/core/widgets/pressable_scale.dart`) sur favori, partager, agence, boutons de la barre flottante, CTA des filtres.
- **Retours haptiques cohérents** — changement d'onglet, sélection de filtre importante, application des filtres, chargement d'une recherche sauvegardée, franchissement des seuils de fermeture (fiche détail, feuille de filtres).
- **Dégradés retravaillés** — intensité concentrée sur la zone basse utile du feed, jamais de grande zone noire.
- **Partage amélioré** — lien placeholder stable, annulation jamais comptée comme un partage réel (`ShareResultStatus.dismissed`) — voir [DECISIONS.md](DECISIONS.md) ADR-022. Deep links réels reportés au [BACKLOG.md](BACKLOG.md).

**État** : ✅ Terminé (vérification code : `flutter analyze`/`flutter test` verts ; vérification [QA_CHECKLIST.md](QA_CHECKLIST.md) sur iPhone physique **à faire par Hugo** — voir [DECISIONS.md](DECISIONS.md) ADR-018, le navigateur de développement n'est jamais l'arbitre final).
**Date** : 2026-07-21
**Commentaires** : 21 tests ajoutés (`test/main_shell_test.dart` — séquences de navigation complètes ; `test/filters_sheet_test.dart` — fermeture par swipe ; `test/property_badge_test.dart` — dérivation des badges ; `test/property_card_gestures_test.dart` — badges affichés, distinction vidéo de l'indicateur) — 63 tests au total désormais. Aucune régression sur les sous-étapes 2.1/2.2/2.3 (fichiers de fluidité/gestes/filtres existants non modifiés en profondeur, seuls des ajouts ciblés).

---

## Étape 3 — Recherche guidée + Résultats

**Objectif** : étapes visuelles de recherche guidée, liste de résultats.

**Description** : recherche guidée par étapes (transaction → type → localisation → budget → chambres → critères) sur l'onglet Rechercher, résultats affichés en liste de cartes (`PropertyCard.list()`, déjà existant mais non utilisé en dehors des tests). Réutilisera vraisemblablement `SearchFilters` et sa feuille déjà construite à l'étape 2 plutôt que de dupliquer la logique de filtrage.

**État** : ⬜ À faire
**Date** : —
**Commentaires** : ne pas démarrer sans validation explicite d'Hugo (voir [CLAUDE.md](../CLAUDE.md) — « une seule étape à la fois »).

---

## Étape 4 — Fiche détail bien

**Objectif** : galerie, infos structurées, bloc agence, bouton favori avec `AuthGuard`.

**État** : ✅ Anticipé et livré dès l'étape 2 (la fiche détail complète existe déjà, y compris la porte d'authentification sur le favori) — cette étape du plan d'origine est donc déjà satisfaite. Aucune action supplémentaire requise à ce stade.
**Date** : 2026-07-19 (voir étape 2)
**Commentaires** : écart assumé par rapport à l'ordre séquentiel initial, à la demande explicite d'Hugo qui a intégré la fiche détail dès la construction du feed plutôt que dans une étape séparée.

---

## Étape 5 — Authentification contextuelle

**Objectif** : Supabase Auth, écran modal déclenché à la demande, redirection post-connexion.

**État** : ⬜ À faire
**Date** : —
**Commentaires** : `authStateProvider` et `requireAuth()` existent déjà en mock (`lib/core/auth/auth_guard.dart`) — cette étape remplace le mock par une vraie session Supabase sans changer l'interface consommée par le reste de l'app.

---

## Étape 6 — Favoris

**Objectif** : table `favorites` réelle, état invité vs connecté, écran de listing.

**État** : ⬜ À faire
**Date** : —
**Commentaires** : le contrôleur et le repository mock existent déjà et sont fonctionnels (toggle depuis le feed et la fiche détail) — reste à construire l'écran de listing et à brancher la vraie session utilisateur.

---

## Étape 7 — Leads (contact + visite)

**Objectif** : table `leads` réelle, deux formulaires courts.

**État** : ⬜ À faire
**Date** : —
**Commentaires** : le modèle `Lead` et l'interface `LeadsRepository` existent déjà. Le bouton « Contacter l'agence » existe sur la fiche détail et affiche un message « bientôt disponible » derrière la porte d'authentification.

---

## Étape 8 — Profil

**Objectif** : consultation/édition du profil, déconnexion.

**État** : ⬜ À faire
**Date** : —
**Commentaires** : le modèle `UserProfile` existe déjà.

---

## Étape 9 — Analytics

**Objectif** : table `property_events` réelle + Edge Function `track-event`, instrumentation complète.

**État** : ⬜ À faire
**Date** : —
**Commentaires** : `AnalyticsService` (interface) et son implémentation mock existent déjà et sont appelés depuis le feed et la fiche détail (`feedImpression`, `detailOpen`, `share`, `favoriteAdd`/`favoriteRemove`). Voir [API_PLAN.md](API_PLAN.md) section 5 pour le contrat prévu de l'Edge Function.

---

## Étape 10 — Bascule Supabase

**Objectif** : remplacement des mocks par de vraies données, mise en place des RLS.

**État** : ⬜ À faire
**Date** : —
**Commentaires** : schéma complet préparé dans [DATABASE_PLAN.md](DATABASE_PLAN.md). Points à trancher avant de migrer : voir [DATABASE_PLAN.md](DATABASE_PLAN.md) section 9 (extension de l'enum `property_type`, clés de `property_features`, notifications, fournisseur vidéo).

---

## Étape 11 — Test réel & polish

**Objectif** : test sur téléphone physique, corrections UX.

**État** : 🟡 Partiellement en cours en continu — chaque étape a été vérifiée avec `flutter analyze`/`flutter test`, et l'app a été validée fonctionnelle sur iPhone physique (build iOS complet réussi, signature de code en attente de l'action manuelle d'Hugo dans Xcode) dès la fin de l'étape 1.
**Date** : en continu depuis 2026-07-19
**Commentaires** : cette étape n'est pas un bloc isolé en fin de projet — elle est appliquée en continu (voir [CONTRIBUTING.md](CONTRIBUTING.md), qualité obligatoire avant chaque commit). Le polish final dédié reste à faire une fois les étapes 3-10 terminées.

---

## Hors roadmap séquentielle — Documentation officielle

**Objectif** : structurer le projet comme un vrai produit, documentation professionnelle et vivante.

**Description** : création du dossier `/docs` complet (ce document et les onze autres listés dans [README.md](README.md)).

**État** : ✅ Terminé
**Date** : 2026-07-20
**Commentaires** : mise en place explicitement demandée par Hugo avant toute nouvelle fonctionnalité, pour que le projet soit compréhensible sans l'historique de conversation. Voir [CONTRIBUTING.md](CONTRIBUTING.md) — toute fonctionnalité future doit mettre à jour la documentation concernée avant son commit.

---

**Documents liés** : [PRODUCT_SPEC.md](PRODUCT_SPEC.md) · [CHANGELOG.md](CHANGELOG.md) · [BACKLOG.md](BACKLOG.md) · [DECISIONS.md](DECISIONS.md)
