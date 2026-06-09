<!-- Si ton pseudo/repo GitHub diffère de `hess0ul/brain-search`, mets à jour les URLs de ce fichier. -->

# 🔎 Brain Search — un retriever borné pour un vault Obsidian

> Un skill [Claude](https://claude.com/claude-code) qui permet à Claude de **chercher et de s'orienter**
> dans un gros « second cerveau » Obsidian — sans déverser tout le vault dans son contexte. Il renvoie
> une **tranche bornée et classée** (jamais un firehose), donc il reste rapide et utile **quelle que
> soit la taille du vault**.

[English](README.md) · **Français**

![Licence : MIT](https://img.shields.io/badge/licence-MIT-3da639)
![Skill Claude Code](https://img.shields.io/badge/Claude%20Code-skill-da7756)
![Obsidian](https://img.shields.io/badge/Obsidian-vault-7c3aed)
![Langues : EN · FR](https://img.shields.io/badge/docs-EN%20%C2%B7%20FR-blue)
![Sans dépendance](https://img.shields.io/badge/deps-bash%20seul-lightgrey)

---

## Sommaire

- [Pourquoi ce skill](#pourquoi-ce-skill)
- [Les trois modes](#les-trois-modes)
- [Prérequis](#prérequis)
- [Installation](#installation)
- [Utilisation](#utilisation)
- [Structure du repo](#structure-du-repo)
- [FAQ](#faq)
- [Contribuer](#contribuer)
- [Licence & crédits](#licence--crédits)

---

## Pourquoi ce skill

Quand un vault Obsidian grossit, « donner toute la carte à l'IA » cesse de marcher : un index à plat de
milliers de notes est trop gros à lire et **dilue l'attention en brûlant le budget de contexte**. Ce qui
aide vraiment un LLM à raisonner, ce n'est pas *tout* le contexte — c'est **la bonne petite tranche**.

`brain-search` repose sur une règle : **la sortie est toujours bornée par la requête ou la structure,
jamais par la taille du vault.** Un seul script bash (~130 lignes, aucune dépendance, recalculé à la
volée donc toujours frais) donne à Claude trois vues bornées :

- 🗺️ **`map`** — une vue d'ensemble de taille constante (aires → nb de notes → lien MOC).
- 🔎 **`find`** — un retriever *classé* qui fusionne titres, tags, headings et contenu, et renvoie le
  **top 20** déjà annoté (type/statut/tags) avec un snippet. C'est ce qui bat `grep` : la note canonique
  remonte en tête, on sait quoi ouvrir sans tâtonner.
- 🧹 **`audit`** — repère les dossiers sans hub, ce que ni `grep` ni les MOC ne savent dire d'eux-mêmes.

C'est le compagnon du skill [second-brain](https://github.com/hess0ul/second-brain) : on **cherche** avec
`brain-search`, on **lit/écrit** avec `second-brain`.

---

## Les trois modes

### `map` — s'orienter (taille constante)

```text
# 🗺️ Vault — 211 notes, 4 aires

## WorkFlow/ — 117 notes · MOC: [[WorkFlow/README]]
  - Ingénieur DevOps & Cloud/ (45)
  - _Socle commun/ (38)
  ...
## Homelab/ — 69 notes · MOC: [[Homelab/Homelab]]
  - Networking/ (28)
  - Services/ (13)
  ...
```

### `find <terme>` — recherche classée (le cœur)

`<terme>` est une regex insensible à la casse (ex. `reverse.proxy`, `vault|secret`). Sortie bornée à 20 :

```text
# 🔎 « credential » — 11 note(s) trouvée(s)

- WorkFlow/.../Git - Configuration.md — Git - Configuration  {workflow, config, git, vcs}
  ↳ Un credential manager configuré évite de ressaisir les identifiants à chaque opération distante.
- WorkFlow/.../Shell WSL/Installation & config.md — Installation & config — Shell WSL  [procédure]  {wsl, shell}
  ↳ ## 9. GitHub depuis WSL (gh, navigateur, credentials)
- Homelab/.../README.md — 📦 Services  [moc]  {moc, service} ⭐
  ...
```

Le bonus de rôle (hub/MOC ⭐) ne compte **que si la note matche** la requête — les index ne polluent
jamais une recherche sans rapport.

### `audit` — hygiène

```text
# 🧹 Audit — dossiers de notes sans hub README
- Homelab/Compute/host/proxmox/  (pas de README hub)
- ...
```

---

## Prérequis

- **Claude Code** (CLI, desktop ou IDE) — ou toute surface Claude supportant les
  [Agent Skills](https://docs.claude.com/en/docs/claude-code/skills).
- **`bash`, `awk`, `find`, `sort`** — présents sur macOS/Linux, sous WSL, et dans Git-Bash sous Windows.
  Aucune autre dépendance.
- **Un vault Obsidian** (ou n'importe quel dossier de notes `.md`). Le frontmatter (`type`, `status`,
  `tags`) et les `[[wikilinks]]` enrichissent la sortie, mais des notes nues marchent aussi.

---

## Installation

### 1. Installer le skill

**macOS / Linux**
```bash
git clone https://github.com/hess0ul/brain-search.git
cp -r brain-search/translations/fr/brain-search ~/.claude/skills/brain-search
```

**Windows (PowerShell)**
```powershell
git clone https://github.com/hess0ul/brain-search.git
Copy-Item -Recurse brain-search\translations\fr\brain-search $env:USERPROFILE\.claude\skills\brain-search
```

> Version anglaise du skill : copie `brain-search/brain-search` à la place.

### 2. Pointer vers ton vault

Définis la racine une fois (ou lance le script depuis ton vault — défaut `$PWD`) :

```bash
export BRAIN_VAULT="$HOME/Obsidian/MonVault"     # à mettre dans ton rc pour persister
```

### 3. Vérifier

```bash
bash ~/.claude/skills/brain-search/scripts/brain.sh map
```

---

## Utilisation

```bash
S=~/.claude/skills/brain-search/scripts/brain.sh
bash "$S" map                  # quels sujets existent + par où entrer
bash "$S" find "reverse.proxy" # hits classés et annotés (top 20)
bash "$S" audit                # dossiers sans hub
```

Dans une session Claude, demande simplement — « où est la note sur X ? », « qu'a-t-on déjà sur Y ? »,
« donne-moi la carte du vault » — et Claude lance le bon mode, puis ouvre les notes pertinentes.

---

## Structure du repo

```
.
├── README.md                         # version anglaise
├── README.fr.md                      # tu es ici (français)
├── LICENSE                           # MIT
├── CHANGELOG.md
├── brain-search/                     # ← le skill (anglais, canonique)
│   ├── SKILL.md
│   └── scripts/brain.sh              # map | find <terme> | audit
└── translations/
    └── fr/brain-search/              # ← le skill (français) — installe celui-ci en FR
```

---

## FAQ

**En quoi c'est mieux que `grep` ?**
`grep -l X` te donne un tas de chemins à trier à la main. `find X` les classe (note canonique en tête),
annote chacun (type/statut/tags), montre un snippet, et borne à 20 — donc tu sais quoi ouvrir tout de
suite, et le résultat ne grossit jamais avec le vault.

**Faut-il un fichier d'index ou une base ?**
Non. Tout est recalculé à chaque appel (~0,4 s sur quelques centaines de notes) : toujours frais, rien
à maintenir.

**Ça scale à des milliers de notes ?**
C'est tout l'intérêt : chaque mode renvoie une tranche **bornée**. `map` est de taille constante ; `find`
est plafonné à 20. (L'*orientation* à grande échelle est surtout portée par la hiérarchie de MOC du
skill [second-brain](https://github.com/hess0ul/second-brain) — `brain-search` la complète.)

**D'où lit-il le vault ?**
`$BRAIN_VAULT`, ou le répertoire courant si la variable n'est pas définie.

---

## Contribuer

Issues et PRs bienvenues — réglage du ranking, un audit `--orphans`, une recherche multi-termes AND, et
les traductions surtout. Garde chaque mode **borné** (pas de firehose) — c'est l'invariant central.

---

## Licence & crédits

[MIT](LICENSE) © 2026 hess0ul.

- Compagnon du skill [second-brain](https://github.com/hess0ul/second-brain).
- Conçu pour les Agent Skills de [Claude Code](https://claude.com/claude-code). Bash pur, sans dépendance.
