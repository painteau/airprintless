# Changelog

Toutes les évolutions notables de `airprintless` sont documentées ici.

Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/), versionnage
[SemVer](https://semver.org/lang/fr/). La section `[Unreleased]` accumule au fil de l'eau et
est renommée en numéro de version au moment de poser le tag.

Ce fichier est créé le 2026-09-05, après la mise en service : les évolutions antérieures ne sont
pas reconstituées, ce qui serait de la réécriture d'historique plutôt que de la documentation.
L'historique git reste la source de vérité pour ce qui précède.

## [Unreleased]

## [0.1.0] - 2026-09-05

### Modifié

- **Le déploiement ne part plus sur un push de branche, mais sur un tag `vX.Y.Z`.** Pousser un
  correctif de documentation ou une expérimentation sur `main` déclenchait jusqu'ici une livraison
  en production, ce qui va contre la règle du parc et rend toute modification du dépôt risquée.
  `workflow_dispatch` est conservé comme filet, ainsi que les crons de reconstruction et les
  déclencheurs de `pull_request`, qui sont des vérifications et non des livraisons.
- Volontairement **sans filtre de chemin** : GitHub combine (branches/tags) ET `paths`, ce qui rend
  un déclencheur sur tag imprévisible dès qu'un filtre de chemin subsiste.

### Ajouté

- **Convention changelog du parc posée sur ce dépôt** : ce fichier, les hooks `pre-commit` et
  `pre-push` dans `.githooks/`, et le workflow `changelog-guard.yml` qui rejoue les mêmes
  contrôles en CI au moment du tag. Ce dépôt en était dépourvu alors qu'il est déployé, ce qui
  le laissait hors de la garantie que les autres ont.

