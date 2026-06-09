---
name: brain-search
description: Fast search and orientation inside an Obsidian "second brain" vault. Use it whenever you need to locate a note, find where some information lives, learn which topics exist, see what changed recently, gather the relevant notes before answering, or sweep the memory before writing — instead of fumbling with several Glob/Grep calls. A bounded retriever (output never scales with vault size, so it stays scale-safe): a map mode (areas → MOC), a ranked search mode (title + tags + headings + content, top 20 + snippet), a recent mode, a gather mode (aggregate the top notes' bodies), and an audit mode. Complements the second-brain skill (which governs detailed reading/writing).
---

# Brain Search — a bounded retriever for the second brain

A single script (`scripts/brain.sh`) that always returns a **bounded slice** (never the whole vault),
so it stays **scale-safe**. Five modes, recomputed on the fly (always current, ~0.4 s):

```bash
bash ~/.claude/skills/brain-search/scripts/brain.sh map           # orientation
bash ~/.claude/skills/brain-search/scripts/brain.sh find <term>   # ranked search
bash ~/.claude/skills/brain-search/scripts/brain.sh recent [N]    # notes changed in the last N days
bash ~/.claude/skills/brain-search/scripts/brain.sh gather <term> # aggregate the 5 top notes' bodies
bash ~/.claude/skills/brain-search/scripts/brain.sh audit         # hygiene
```

## `map` — orient yourself (constant size)

Areas → note count → MOC link, plus subfolders by volume. The "bird's-eye view" that fits in a few
lines **regardless of vault size**. Run it at the start of a broad task.

## `find <term>` — the core (better than `grep`)

Fuses **title + tags + headings + content**, assigns a **score**, returns the **top 20** with, per
note: path · title · `[type·status]` · `{tags}` · a **snippet** · ⭐ if it's a hub/MOC.
- `<term>` is a **case-insensitive regex** (e.g. `reverse.proxy`, `vault|secret`).
- Why it beats `grep`: the canonical note floats to the top, each hit is already ranked and annotated,
  and output stays capped at 20. The role bonus counts **only when the note actually matches**.

## `recent [N]` — what changed

Notes modified in the last **N days** (default 14), newest first, with date. Great for "catch me up"
or to resume after a `/compact` (see what moved). Bounded (top 40).

## `gather <term>` — aggregate to reason

Takes the **5 most relevant notes** (same ranking as `find`) and **concatenates their bodies**
(frontmatter stripped, 60 lines/note max) into one block. Instead of opening 5 notes one by one, you
get the useful slice at once — "the request + the relevant notes." Bounded by construction.

## `audit` — what neither grep nor MOCs can tell you

Lists folders that contain notes but have **no `README.md` hub**. Advisory hygiene as the vault grows.

## Usage

1. Orient → `map`. Locate → `find <term>`. Catch up → `recent`. Load a topic → `gather <term>`.
2. For an exotic full-text need, fall back to a raw `Grep`.
3. **Vault root**: set `BRAIN_VAULT=/path/to/your/vault`, or run from inside the vault (defaults to `$PWD`).

## Relation to the second-brain skill

The [second-brain](https://github.com/hess0ul/second-brain) skill is the reading/writing methodology
(dual-register, MOCs, capture, `/compact` survival) and **it carries large-scale orientation** (a MOC
hierarchy = a tree of summaries). `brain-search` **complements** it: an always-fresh, ranked,
queryable retriever that can also audit drift. You **search** with `brain-search`, you **read/write**
with `second-brain`.
