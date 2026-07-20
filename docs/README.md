# Documentation officielle — House For You

Cette documentation est la **seule source de vérité** du projet House For You, produit et technique. Elle est pensée pour qu'un développeur puisse reprendre le projet dans plusieurs années en ne lisant que ces documents — sans avoir besoin de l'historique de conversation qui a mené à leur rédaction.

**Règle de maintenance** : chaque fois qu'une fonctionnalité est validée (développée, testée), les documents concernés sont mis à jour **avant** le commit qui la clôt. Voir [CONTRIBUTING.md](CONTRIBUTING.md) section 6 pour le détail du processus.

## Objectif du projet, en une phrase

Une application mobile de recherche immobilière pour la Belgique francophone, avec la sensation d'un feed social (TikTok/Instagram/Airbnb) plutôt qu'un portail immobilier classique — voir [PRODUCT_SPEC.md](PRODUCT_SPEC.md) pour la vision complète.

## Structure de la documentation

| Document | Répond à la question |
|---|---|
| [PRODUCT_SPEC.md](PRODUCT_SPEC.md) | Quel produit construit-on, pour qui, et pourquoi ? La Bible produit — vision, écrans, fonctionnalités en détail. |
| [ROADMAP.md](ROADMAP.md) | Dans quel ordre construit-on le produit ? Étapes et sous-étapes, avec état, date, commentaires. |
| [CHANGELOG.md](CHANGELOG.md) | Qu'est-ce qui a réellement été livré, et quand ? Historique complet, version par version. |
| [UX_RULES.md](UX_RULES.md) | Quelles règles d'expérience ne doivent jamais être cassées sans le documenter ? |
| [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) | À quoi ressemble l'app, précisément (couleurs, typographies, composants, animations) ? |
| [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md) | Comment le code Flutter est-il structuré, et pourquoi ? |
| [DATABASE_PLAN.md](DATABASE_PLAN.md) | À quoi ressemblera la base Supabase, avant même qu'elle existe ? |
| [API_PLAN.md](API_PLAN.md) | Comment l'app parlera-t-elle au backend, une fois connecté ? |
| [BACKLOG.md](BACKLOG.md) | Quelles idées n'ont pas encore de date, classées par priorité ? |
| [DECISIONS.md](DECISIONS.md) | Pourquoi a-t-on choisi ceci plutôt que cela ? Registre des décisions importantes. |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Comment contribue-t-on au code (conventions Git, Flutter, tests) ? |

## Comment ces documents s'articulent

```
PRODUCT_SPEC.md  ──décrit le produit que──►  ROADMAP.md découpe en étapes
      │                                            │
      │ chaque fonctionnalité livrée               │ chaque étape terminée
      ▼                                            ▼
DESIGN_SYSTEM.md / UX_RULES.md            CHANGELOG.md s'enrichit
(comment ça doit se comporter)                     │
      │                                            │
      └──────────────► DECISIONS.md ◄──────────────┘
              (pourquoi on a fait ce choix,
               si une règle a dû être ajustée)

TECH_ARCHITECTURE.md décrit le code aujourd'hui
      │
      ├──► DATABASE_PLAN.md prépare la base pas encore connectée
      └──► API_PLAN.md prépare les échanges avec cette base

CONTRIBUTING.md décrit comment on écrit tout ce qui précède
      │
      └──► BACKLOG.md capture ce qu'on ne fait pas encore
```

En résumé : **PRODUCT_SPEC** dit *quoi*, **ROADMAP** dit *quand*, **DESIGN_SYSTEM**/**UX_RULES** disent *comment ça se comporte*, **TECH_ARCHITECTURE**/**DATABASE_PLAN**/**API_PLAN** disent *comment c'est construit*, **DECISIONS** dit *pourquoi*, **CHANGELOG** dit *ce qui a été fait*, **BACKLOG** dit *ce qu'on n'a pas encore fait*, **CONTRIBUTING** dit *comment on travaille*.

## Document historique

[architecture-mvp.md](architecture-mvp.md) est le document de cahier des charges initial (v3, validé) qui a servi de point de départ à l'étape 0. Il reste dans le dépôt pour la trace historique, mais **son contenu technique et produit est aujourd'hui remplacé par [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md), [DATABASE_PLAN.md](DATABASE_PLAN.md) et [PRODUCT_SPEC.md](PRODUCT_SPEC.md)**, qui reflètent l'état réel du projet et sont maintenus en continu.

## Voir aussi

Le [README.md](../README.md) à la racine du dépôt reste le point d'entrée pour lancer le projet en local (installation, commandes). Ce dossier `/docs` couvre le *produit* et l'*architecture* — pas les instructions d'installation.
