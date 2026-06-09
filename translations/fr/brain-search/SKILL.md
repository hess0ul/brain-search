---
name: brain-search
description: Recherche et orientation rapides dans un vault Obsidian « second cerveau ». À utiliser dès qu'il faut localiser une note, retrouver où vit une information, savoir quels sujets existent, ou fouiller la mémoire avant de répondre/écrire — au lieu de tâtonner avec plusieurs Glob/Grep. Retriever borné (sortie jamais proportionnelle à la taille du vault, donc scale-safe) : un mode carte (aires → MOC), un mode recherche classée (titre + tags + headings + contenu, top 20 + snippet), un mode audit (dossiers sans hub). Complément du skill second-brain (qui régit l'écriture/lecture détaillée).
---

# Brain Search — retriever borné du second cerveau

Un script unique (`scripts/brain.sh`) qui sort **toujours une tranche bornée** (jamais le vault entier),
donc **scale-safe**. Trois modes, recalculés à la volée (toujours à jour, ~0,4 s) :

```bash
bash ~/.claude/skills/brain-search/scripts/brain.sh map            # orientation
bash ~/.claude/skills/brain-search/scripts/brain.sh find <terme>   # recherche classée
bash ~/.claude/skills/brain-search/scripts/brain.sh audit          # hygiène
```

## `map` — s'orienter (taille constante)

Aires → nb de notes → lien MOC, + sous-dossiers par volume. La « vue d'ensemble » qui tient en quelques
lignes **quelle que soit la taille du vault**. À lancer au début d'une tâche large pour savoir quels
sujets existent et par où entrer, sans rien ouvrir.

## `find <terme>` — le cœur (mieux que `grep`)

Fusionne **titre + tags + headings + contenu**, attribue un **score**, renvoie le **top 20** avec, par
note : chemin · titre · `[type·statut]` · `{tags}` · un **snippet** du match · ⭐ si c'est un hub/MOC.
- `<terme>` est une **regex insensible à la casse** (ex. `reverse.proxy`, `vault|secret`).
- Pourquoi mieux que `grep` : la note canonique remonte en tête, chaque hit arrive *déjà trié et annoté*
  (type/statut/tags), donc on sait quoi ouvrir sans tâtonner — et la sortie reste bornée à 20.
- Le bonus de rôle (hub/MOC) ne compte **que si la note matche** — pas de pollution par les index.

## `audit` — ce que ni grep ni les MOC ne savent dire

Liste les dossiers contenant des notes **sans hub `README.md`**. Utile pour garder l'arborescence saine
à mesure que le vault grossit (advisory : certains dossiers feuilles peuvent légitimement ne pas en avoir).

## Usage

1. S'orienter → `map`. Localiser → `find <terme>`. Puis **ouvrir** la(les) note(s).
2. Pour un besoin plein-texte exotique que `find` ne couvre pas, compléter par un `Grep` brut.
3. **Racine du vault** : `BRAIN_VAULT=/chemin/vers/ton/vault`, ou lancer depuis le vault (défaut : `$PWD`).

## Rapport avec le skill second-brain

[second-brain](https://github.com/hess0ul/second-brain) = méthode d'écriture/lecture (bi-registre, MOC,
capture, survie au `/compact`) et c'est **lui qui porte l'orientation à grande échelle** (hiérarchie de
MOC = arbre de résumés). `brain-search` **complète** : retriever toujours frais, classé, interrogeable,
capable d'auditer la dérive. On **cherche** avec `brain-search`, on **lit/écrit** avec `second-brain`.
