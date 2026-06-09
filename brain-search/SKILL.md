---
name: brain-search
description: Fast search and orientation inside an Obsidian "second brain" vault. Use it whenever you need to locate a note, find where some information lives, learn which topics exist, or sweep the memory before answering/writing — instead of fumbling with several Glob/Grep calls. A bounded retriever (output never scales with vault size, so it stays scale-safe): a map mode (areas → MOC), a ranked search mode (title + tags + headings + content, top 20 + snippet), and an audit mode (folders without a hub). Complements the second-brain skill (which governs detailed reading/writing).
---

# Brain Search — a bounded retriever for the second brain

A single script (`scripts/brain.sh`) that always returns a **bounded slice** (never the whole vault),
so it stays **scale-safe**. Three modes, recomputed on the fly (always current, ~0.4 s):

```bash
bash ~/.claude/skills/brain-search/scripts/brain.sh map           # orientation
bash ~/.claude/skills/brain-search/scripts/brain.sh find <term>   # ranked search
bash ~/.claude/skills/brain-search/scripts/brain.sh audit         # hygiene
```

## `map` — orient yourself (constant size)

Areas → note count → MOC link, plus subfolders by volume. The "bird's-eye view" that fits in a few
lines **regardless of vault size**. Run it at the start of a broad task to learn which topics exist
and where to enter, without opening anything.

## `find <term>` — the core (better than `grep`)

Fuses **title + tags + headings + content**, assigns a **score**, returns the **top 20** with, per
note: path · title · `[type·status]` · `{tags}` · a **snippet** of the match · ⭐ if it's a hub/MOC.
- `<term>` is a **case-insensitive regex** (e.g. `reverse.proxy`, `vault|secret`).
- Why it beats `grep`: the canonical note floats to the top, and each hit arrives *already ranked and
  annotated* (type/status/tags), so you know what to open without fumbling — and output stays capped at 20.
- The role bonus (hub/MOC) counts **only when the note actually matches** — no pollution by indexes.

## `audit` — what neither grep nor MOCs can tell you

Lists folders that contain notes but have **no `README.md` hub**. Useful to keep the tree healthy as
the vault grows (advisory: some leaf folders may legitimately not need one).

## Usage

1. Orient → `map`. Locate → `find <term>`. Then **open** the note(s) with your read tool.
2. For an exotic full-text need `find` doesn't cover, fall back to a raw `Grep`.
3. **Vault root**: set `BRAIN_VAULT=/path/to/your/vault`, or run from inside the vault (defaults to `$PWD`).

## Relation to the second-brain skill

The [second-brain](https://github.com/hess0ul/second-brain) skill is the reading/writing methodology
(dual-register, MOCs, capture, `/compact` survival) and **it carries large-scale orientation** (a MOC
hierarchy = a tree of summaries). `brain-search` **complements** it: an always-fresh, ranked,
queryable retriever that can also audit drift. You **search** with `brain-search`, you **read/write**
with `second-brain`.
