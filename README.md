<!-- If your GitHub username/repo differs from `hess0ul/brain-search`, update the URLs throughout this file. -->

# 🔎 Brain Search — a bounded retriever for an Obsidian vault

> A [Claude](https://claude.com/claude-code) skill that lets Claude **search and orient itself** inside
> a large Obsidian "second brain" — without dumping the whole vault into context. It returns a
> **bounded, ranked slice** (never a firehose), so it stays fast and useful **no matter how big the
> vault grows**.

**English** · [Français](README.fr.md)

![License: MIT](https://img.shields.io/badge/license-MIT-3da639)
![Claude Code skill](https://img.shields.io/badge/Claude%20Code-skill-da7756)
![Obsidian](https://img.shields.io/badge/Obsidian-vault-7c3aed)
![Languages: EN · FR](https://img.shields.io/badge/docs-EN%20%C2%B7%20FR-blue)
![No dependencies](https://img.shields.io/badge/deps-bash%20only-lightgrey)

---

## Table of contents

- [Why this exists](#why-this-exists)
- [The three modes](#the-three-modes)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Repository structure](#repository-structure)
- [FAQ](#faq)
- [Contributing](#contributing)
- [License & credits](#license--credits)

---

## Why this exists

As an Obsidian vault grows, "give the AI the whole map" stops working: a flat index of thousands of
notes is too big to read and **dilutes attention while burning context budget**. What actually helps an
LLM reason is not *all* the context — it's **the right small slice**.

`brain-search` is built on one rule: **output is always bounded by the query or the structure, never by
the vault size.** A single ~130-line bash script (no dependencies, recomputed on the fly so it's always
fresh) gives Claude three bounded views:

- 🗺️ **`map`** — a constant-size bird's-eye view (areas → note count → MOC link).
- 🔎 **`find`** — a *ranked* retriever that fuses titles, tags, headings and content, and returns the
  **top 20** hits already annotated (type/status/tags) with a snippet. This is the part that beats raw
  `grep`: the canonical note floats to the top, and you know what to open without fumbling.
- 🧹 **`audit`** — surfaces folders missing a hub, something neither `grep` nor your MOCs can self-report.

It is the companion to the [second-brain](https://github.com/hess0ul/second-brain) skill: you **search**
with `brain-search`, you **read/write** with `second-brain`.

---

## The three modes

### `map` — orient (constant size)

```text
# 🗺️ Vault — 211 notes, 4 areas

## WorkFlow/ — 117 notes · MOC: [[WorkFlow/README]]
  - Ingénieur DevOps & Cloud/ (45)
  - _Socle commun/ (38)
  ...
## Homelab/ — 69 notes · MOC: [[Homelab/Homelab]]
  - Networking/ (28)
  - Services/ (13)
  ...
```

### `find <term>` — ranked search (the core)

`<term>` is a case-insensitive regex (e.g. `reverse.proxy`, `vault|secret`). Output is capped at 20:

```text
# 🔎 "credential" — 11 note(s) found

- WorkFlow/.../Git - Configuration.md — Git - Configuration  {workflow, config, git, vcs}
  ↳ A configured credential manager avoids re-entering identifiers on every remote operation.
- WorkFlow/.../Shell WSL/Installation & config.md — Install & config — Shell WSL  [procédure]  {wsl, shell}
  ↳ ## 9. GitHub from WSL (gh, browser, credentials)
- Homelab/.../README.md — 📦 Services  [moc]  {moc, service} ⭐
  ...
```

The role bonus (hub/MOC ⭐) counts **only when the note actually matches** the query — so indexes never
pollute unrelated searches.

### `audit` — hygiene

```text
# 🧹 Audit — note folders without a README hub
- Homelab/Compute/host/proxmox/  (no README hub)
- ...
```

---

## Prerequisites

- **Claude Code** (CLI, desktop, or IDE) — or any Claude surface that supports
  [Agent Skills](https://docs.claude.com/en/docs/claude-code/skills).
- **`bash`, `awk`, `find`, `sort`** — present on macOS/Linux, in WSL, and in Git-Bash on Windows. No
  other dependencies.
- **An Obsidian vault** (or any folder of `.md` notes). Frontmatter (`type`, `status`, `tags`) and
  `[[wikilinks]]` make the output richer, but plain notes work too.

---

## Installation

### 1. Install the skill

**macOS / Linux**
```bash
git clone https://github.com/hess0ul/brain-search.git
cp -r brain-search/brain-search ~/.claude/skills/brain-search
```

**Windows (PowerShell)**
```powershell
git clone https://github.com/hess0ul/brain-search.git
Copy-Item -Recurse brain-search\brain-search $env:USERPROFILE\.claude\skills\brain-search
```

> French version of the skill: copy `brain-search/translations/fr/brain-search` instead.

### 2. Point it at your vault

Set the vault root once (or run the script from inside your vault — it defaults to `$PWD`):

```bash
export BRAIN_VAULT="$HOME/Obsidian/MyVault"     # add to your shell rc to persist
```

### 3. Verify

```bash
bash ~/.claude/skills/brain-search/scripts/brain.sh map
```

---

## Usage

```bash
S=~/.claude/skills/brain-search/scripts/brain.sh
bash "$S" map                 # what topics exist + where to enter
bash "$S" find "reverse.proxy" # ranked, annotated hits (top 20)
bash "$S" audit               # folders missing a hub
```

In a Claude session, just ask — "where is the note about X?", "what do we already have on Y?",
"give me the map of the vault" — and Claude runs the right mode, then opens the relevant notes.

---

## Repository structure

```
.
├── README.md                         # you are here (English)
├── README.fr.md                      # French
├── LICENSE                           # MIT
├── CHANGELOG.md
├── brain-search/                     # ← the skill (English, canonical) — install this
│   ├── SKILL.md
│   └── scripts/brain.sh              # map | find <term> | audit
└── translations/
    └── fr/brain-search/              # the skill (French) — same structure
```

---

## FAQ

**How is this better than `grep`?**
`grep -l X` gives you a pile of paths to triage by hand. `find X` ranks them (canonical note first),
annotates each with type/status/tags, shows a snippet, and caps the output at 20 — so you know what to
open immediately, and the result never grows with the vault.

**Does it need an index file or a database?**
No. It recomputes on every call (~0.4 s on a few hundred notes), so it's always fresh and there's
nothing to maintain.

**Does it scale to thousands of notes?**
That's the whole point: every mode returns a **bounded** slice. `map` is constant-size; `find` is capped
at 20. (Large-scale *orientation* is mostly carried by the MOC hierarchy of the
[second-brain](https://github.com/hess0ul/second-brain) skill — `brain-search` complements it.)

**Where does it read the vault from?**
`$BRAIN_VAULT`, or the current directory if that's unset.

---

## Contributing

Issues and PRs welcome — ranking tweaks, an `--orphans` audit, multi-term AND search, and translations
especially. Keep every mode **bounded** (no firehose) — that's the core invariant.

---

## License & credits

[MIT](LICENSE) © 2026 hess0ul.

- Companion to the [second-brain](https://github.com/hess0ul/second-brain) skill.
- Built for [Claude Code](https://claude.com/claude-code) Agent Skills. Pure bash, no dependencies.
