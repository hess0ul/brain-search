# Changelog

All notable changes to this skill are documented here. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/); the skill itself uses [SemVer](https://semver.org/).

## [1.1.0] — 2026-06-09

### Added
- `recent [N]` mode — notes changed in the last N days (default 14), newest first, with date. Top 40.
  Portable across macOS/Linux/WSL/Git-Bash (uses `perl` for mtime sort, not GNU `find -printf`).
- `gather <term>` mode — concatenates the bodies of the 5 most relevant notes (same ranking as `find`,
  frontmatter stripped, 60 lines/note) into one ready-to-reason block.

### Changed
- `find` and `gather` share a single `rank_records` helper; `recent` shares a `meta_of` annotator.

## [1.0.0] — 2026-06-09

Initial public release.

### Added
- **Brain Search** Claude Code skill: a bounded, dependency-free retriever for an Obsidian vault.
- `scripts/brain.sh` with three bounded modes (output never scales with vault size):
  - `map` — areas → note count → MOC link (constant size).
  - `find <term>` — ranked search fusing title + tags + headings + content; top 20 + snippet; role
    bonus (hub/MOC ⭐) counts only when the note actually matches.
  - `audit` — note folders missing a `README.md` hub.
- **Bilingual**: English skill (canonical) + French translation under `translations/fr/`.
- English and French READMEs.

Companion to the [second-brain](https://github.com/hess0ul/second-brain) skill.
