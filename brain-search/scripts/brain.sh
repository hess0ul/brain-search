#!/usr/bin/env bash
# brain-search — a bounded retriever for an Obsidian vault (never a firehose).
# Output is always bounded by the query/structure, NOT by vault size → scale-safe.
#
# Usage:
#   brain.sh map              overview: areas → note count → MOC (+ subfolders). Default.
#   brain.sh find <term>      RANKED search (title + tags + headings + content) → top 20 + snippet
#   brain.sh recent [N]       notes changed in the last N days (default 14), newest first
#   brain.sh gather <term>    AGGREGATE the body of the 5 most relevant notes → ready-to-reason block
#   brain.sh audit            hygiene: note folders without a README hub
#
# Vault root: set BRAIN_VAULT to your vault path, or run from inside the vault (defaults to $PWD).
# Dependencies: bash, awk, find, sort, perl (all standard on macOS/Linux/WSL/Git-Bash).
set -uo pipefail

ROOT="${BRAIN_VAULT:-$PWD}"
[ -d "$ROOT" ] || { echo "Vault not found: $ROOT (set BRAIN_VAULT to your vault root)" >&2; exit 1; }
cd "$ROOT" || exit 1
CMD="${1:-map}"
QUERY="${2:-}"

EXCLUDES=(-not -path './.obsidian/*' -not -path './.git/*' -not -path './.trash/*'
          -not -path '*/attachments/*')

list_md() { find . -type f -name '*.md' "${EXCLUDES[@]}" -print0 | sort -z; }

fmt_line() { # rel title type status tags -> "- rel — title [type·status]  {tags}"
  local rel="$1" title="$2" type="$3" status="$4" tags="$5" sfx="" line
  [ -n "$type" ] && sfx="$type"
  [ -n "$status" ] && sfx="${sfx:+$sfx·}$status"
  line="- $rel — $title"
  [ -n "$sfx" ] && line="$line [$sfx]"
  [ -n "$tags" ] && line="$line  {$tags}"
  printf '%s' "$line"
}

meta_of() { # $1=file -> "title\037type\037status\037tags"
  awk '
    NR==1 && $0=="---"{fm=1; next}
    fm==1 && $0=="---"{fm=2; next}
    fm==1{
      if($0~/^type:/){t=$0;sub(/^type:[ \t]*/,"",t)}
      else if($0~/^status:/){s=$0;sub(/^status:[ \t]*/,"",s)}
      else if($0~/^tags:/){g=$0;sub(/^tags:[ \t]*/,"",g)}
      next
    }
    title=="" && $0~/^#[ \t]+/{title=$0; sub(/^#[ \t]+/,"",title)}
    fm==2 && title!=""{exit}
    END{ gsub(/[][]/,"",g); sub(/^ /,"",g); sub(/ $/,"",g); print title "\037" t "\037" s "\037" g }
  ' "$1"
}

rank_records() { # $1=lowercased query -> sorted "score\037rel\037title\037type\037status\037tags\037snip"
  local q="$1"
  list_md | xargs -0 awk -v q="$q" '
    # m = relevance (query matches) ; b = role bonus (counts ONLY if m>0). Emit if m>0.
    function flush(){ if(seen && m>0)
      printf "%d\037%s\037%s\037%s\037%s\037%s\037%s\n", m+b, rel, title, type, status, tags, snip }
    FNR==1{
      flush()
      rel=FILENAME; sub(/^\.\//,"",rel)
      fm=0; type=""; status=""; tags=""; title=""; m=0; b=0; snip=""; seen=1
      base=rel; sub(/.*\//,"",base); sub(/\.md$/,"",base)
      if(tolower(base) ~ q) m+=120; else if(tolower(rel) ~ q) m+=25
      if(tolower(base)=="readme") b+=10
      if($0=="---"){fm=1; next}
    }
    fm==1 && $0=="---"{fm=2; next}
    fm==1{
      if($0 ~ /^type:/){type=$0; sub(/^type:[ \t]*/,"",type); if(type ~ /moc|hub|index/) b+=20}
      else if($0 ~ /^status:/){status=$0; sub(/^status:[ \t]*/,"",status)}
      else if($0 ~ /^tags:/){tags=$0; sub(/^tags:[ \t]*/,"",tags); if(tolower(tags) ~ q) m+=55}
      next
    }
    title=="" && $0 ~ /^#[ \t]+/{title=$0; sub(/^#[ \t]+/,"",title); if(tolower(title) ~ q) m+=80}
    /^#{1,6}[ \t]/{ if(tolower($0) ~ q) m+=15 }
    { if(tolower($0) ~ q){ m+=3; if(snip==""){snip=$0; gsub(/^[ \t>*-]+/,"",snip)} } }
    END{flush()}
  ' | sort -t$'\037' -k1,1 -rn
}

cmd_map() {
  declare -A acount scount
  while IFS= read -r -d '' f; do
    rel=${f#./}; IFS='/' read -ra seg <<<"$rel"
    if [ "${#seg[@]}" -ge 2 ]; then area="${seg[0]}"; else area="(root)"; fi
    acount["$area"]=$(( ${acount["$area"]:-0}+1 ))
    [ "${#seg[@]}" -ge 3 ] && { sub="${seg[0]}/${seg[1]}"; scount["$sub"]=$(( ${scount["$sub"]:-0}+1 )); }
  done < <(list_md)
  local total=0 k; for k in "${!acount[@]}"; do total=$(( total + acount["$k"] )); done
  printf '# 🗺️ Vault — %d notes, %d areas (vault: %s)\n' "$total" "${#acount[@]}" "$ROOT"
  for k in "${!acount[@]}"; do printf '%d\t%s\n' "${acount[$k]}" "$k"; done | sort -rn \
  | while IFS=$'\t' read -r cnt area; do
      moc=""; for c in "$area/$area.md" "$area/README.md" "$area/Index.md"; do
        [ -f "$c" ] && { moc=" · MOC: [[${c%.md}]]"; break; }; done
      printf '\n## %s/ — %d notes%s\n' "$area" "$cnt" "$moc"
      for s in "${!scount[@]}"; do case "$s" in "$area"/*) printf '%d\t%s\n' "${scount[$s]}" "$s";; esac; done \
      | sort -rn | while IFS=$'\t' read -r scnt sname; do printf '  - %s/ (%d)\n' "${sname#*/}" "$scnt"; done
    done
  printf '\n→ drill into an area: open its MOC. Search: brain.sh find <term>.\n'
}

cmd_find() {
  [ -n "$QUERY" ] || { echo "usage: brain.sh find <term>" >&2; return 1; }
  local hits; hits=$(rank_records "$(printf '%s' "$QUERY" | tr 'A-Z' 'a-z')")
  local matched; matched=$(printf '%s' "$hits" | grep -c . || true)
  printf '# 🔎 "%s" — %s note(s) found\n\n' "$QUERY" "${matched:-0}"
  [ -z "$hits" ] && { echo "(no result — try a broader term, or a raw full-text Grep)"; return; }
  printf '%s\n' "$hits" | head -20 | awk -F'\037' '{
    role=""; if($4 ~ /moc|hub|index/) role=" ⭐"
    meta=$4; if($5!="") meta=(meta!=""? meta"·"$5 : $5)
    gsub(/[][]/,"",$6); sub(/^ +/,"",$6); sub(/ +$/,"",$6)
    line="- " $2 " — " $3
    if(meta!="") line=line " [" meta "]"
    if($6!="") line=line "  {" $6 "}"
    print line role
    sn=$7; if(length(sn)>110) sn=substr(sn,1,110) "…"; if(sn!="") print "  ↳ " sn
  }'
  [ "${matched:-0}" -gt 20 ] && printf '\n… (top 20 shown; refine the term if needed)\n'
}

cmd_recent() {
  local days="${QUERY:-14}" n=0
  printf '# 🕒 Recent — notes changed (≤ %s days), newest first\n\n' "$days"
  while IFS=$'\t' read -r date rel; do
    [ "$n" -ge 40 ] && { printf '\n… (40 most recent shown)\n'; break; }
    IFS=$'\037' read -r title type status tags < <(meta_of "$rel")
    [ -z "$title" ] && title="${rel##*/}"
    printf '%s  (%s)\n' "$(fmt_line "$rel" "$title" "$type" "$status" "$tags")" "$date"
    n=$((n+1))
  done < <(list_md | DAYS="$days" perl -0 -ne '
      BEGIN{ $cut = time - ($ENV{DAYS}+0)*86400 }
      chomp; push @f,$_;
      END{
        for (sort { (stat $b)[9] <=> (stat $a)[9] } grep { (stat $_)[9] >= $cut } @f) {
          my @t = localtime((stat $_)[9]); (my $r=$_) =~ s{^\./}{};
          printf "%04d-%02d-%02d\t%s\n", $t[5]+1900, $t[4]+1, $t[3], $r;
        }
      }')
  [ "$n" -eq 0 ] && printf '(no note changed in this window)\n'
  printf '\n— %d note(s) within ≤ %s days\n' "$n" "$days"
}

cmd_gather() {
  [ -n "$QUERY" ] || { echo "usage: brain.sh gather <term>" >&2; return 1; }
  local recs; recs=$(rank_records "$(printf '%s' "$QUERY" | tr 'A-Z' 'a-z')")
  [ -z "$recs" ] && { echo "(no relevant note to aggregate)"; return; }
  printf '# 📦 Bundle "%s" — bodies of the 5 most relevant notes\n' "$QUERY"
  printf '%s\n' "$recs" | head -5 | awk -F'\037' '{print $2}' | while IFS= read -r rel; do
    [ -f "$rel" ] || continue
    printf '\n---\n## %s\n\n' "$rel"
    awk 'NR==1&&$0=="---"{fm=1;next} fm==1&&$0=="---"{fm=2;next} fm==1{next} {print}' "$rel" | sed '/^$/N;/^\n$/D' | head -60
  done
  printf '\n---\n(body truncated to 60 lines/note; open the note for full detail)\n'
}

cmd_audit() {
  printf '# 🧹 Audit — note folders without a README hub\n\n'; local n=0
  while IFS= read -r -d '' d; do
    d=${d#./}; case "$d" in .obsidian*|.git*|.trash*) continue;; esac
    if compgen -G "$d/*.md" >/dev/null 2>&1; then
      [ -f "$d/README.md" ] && continue
      base=${d##*/}; [ -f "$d/$base.md" ] && continue
      printf -- '- %s/  (no README hub)\n' "$d"; n=$((n+1))
    fi
  done < <(find . -mindepth 1 -type d -not -path '*/.*' -print0 | sort -z)
  [ "$n" -eq 0 ] && printf '✅ every note folder has a hub.\n'
  printf '\n— %d folder(s) without a hub\n' "$n"
}

case "$CMD" in
  map)    cmd_map ;;
  find)   cmd_find ;;
  recent) cmd_recent ;;
  gather) cmd_gather ;;
  audit)  cmd_audit ;;
  *) echo "commands: map | find <term> | recent [N] | gather <term> | audit" >&2; exit 2 ;;
esac
