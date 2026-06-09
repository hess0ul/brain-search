---
name: brain-search
description: Recherche et orientation rapides dans un vault Obsidian « second cerveau ». À utiliser dès qu'il faut localiser une note, retrouver où vit une information, savoir quels sujets existent, voir ce qui a changé récemment, agréger les notes pertinentes avant de répondre, ou fouiller la mémoire avant d'écrire — au lieu de tâtonner avec plusieurs Glob/Grep. Retriever borné (sortie jamais proportionnelle à la taille du vault, donc scale-safe) : un mode carte (aires → MOC), un mode recherche classée (titre + tags + headings + contenu, top 20 + snippet), un mode récent, un mode gather (agrège le corps des notes top), un mode audit. Complément du skill second-brain (qui régit l'écriture/lecture détaillée).
---

# Brain Search — retriever borné du second cerveau

Un script unique (`scripts/brain.sh`) qui sort **toujours une tranche bornée** (jamais le vault entier),
donc **scale-safe**. Cinq modes, recalculés à la volée (toujours à jour, ~0,4 s) :

```bash
bash ~/.claude/skills/brain-search/scripts/brain.sh map            # orientation
bash ~/.claude/skills/brain-search/scripts/brain.sh find <terme>   # recherche classée
bash ~/.claude/skills/brain-search/scripts/brain.sh recent [N]     # notes modifiées ces N jours
bash ~/.claude/skills/brain-search/scripts/brain.sh gather <terme> # agrège le corps des 5 notes top
bash ~/.claude/skills/brain-search/scripts/brain.sh audit          # hygiène
```

## `map` — s'orienter (taille constante)

Aires → nb de notes → lien MOC, + sous-dossiers par volume. La « vue d'ensemble » qui tient en quelques
lignes **quelle que soit la taille du vault**. À lancer au début d'une tâche large.

## `find <terme>` — le cœur (mieux que `grep`)

Fusionne **titre + tags + headings + contenu**, attribue un **score**, renvoie le **top 20** avec, par
note : chemin · titre · `[type·statut]` · `{tags}` · un **snippet** · ⭐ si c'est un hub/MOC.
- `<terme>` est une **regex insensible à la casse** (ex. `reverse.proxy`, `vault|secret`).
- Pourquoi mieux que `grep` : la note canonique remonte en tête, chaque hit est déjà classé et annoté,
  la sortie reste bornée à 20. Le bonus de rôle ne compte **que si la note matche**.

## `recent [N]` — quoi de neuf

Notes modifiées ces **N jours** (défaut 14), plus récentes d'abord, avec date. Parfait pour « remets-moi
à jour » ou pour reprendre après un `/compact`. Borné (top 40).

## `gather <terme>` — agréger pour raisonner

Prend les **5 notes les plus pertinentes** (même classement que `find`) et **concatène leur corps**
(frontmatter retiré, 60 lignes/note max) en un bloc. Au lieu d'ouvrir 5 notes une par une, on reçoit
la tranche utile d'un coup — « la demande + les notes pertinentes ». Borné par construction.

## `audit` — ce que ni grep ni les MOC ne savent dire

Liste les dossiers contenant des notes **sans hub `README.md`**. Hygiène (advisory) à mesure que le vault grossit.

## Usage

1. S'orienter → `map`. Localiser → `find <terme>`. Se remettre à jour → `recent`. Charger un sujet → `gather <terme>`.
2. Pour un besoin plein-texte exotique, compléter par un `Grep` brut.
3. **Racine du vault** : `BRAIN_VAULT=/chemin/vers/ton/vault`, ou lancer depuis le vault (défaut : `$PWD`).

## Rapport avec le skill second-brain

[second-brain](https://github.com/hess0ul/second-brain) = méthode d'écriture/lecture (bi-registre, MOC,
capture, survie au `/compact`) et c'est **lui qui porte l'orientation à grande échelle**. `brain-search`
**complète** : retriever toujours frais, classé, interrogeable, capable d'auditer la dérive. On
**cherche** avec `brain-search`, on **lit/écrit** avec `second-brain`.
