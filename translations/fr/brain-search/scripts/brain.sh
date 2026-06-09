#!/usr/bin/env bash
# brain-search — retriever borné pour un vault Obsidian (jamais un firehose).
# Sortie toujours bornée par la requête/structure, PAS par la taille du vault → scale-safe.
#
# Usage:
#   brain.sh map                 vue d'ensemble : aires → nb notes → MOC (+ sous-dossiers). Défaut.
#   brain.sh find <terme>        recherche CLASSÉE (titre+tags+headings+contenu) → top 20 + snippet
#   brain.sh audit               hygiène : dossiers de notes sans hub README
#
# Racine du vault : variable BRAIN_VAULT, ou lance depuis le vault (défaut : $PWD).
set -uo pipefail

ROOT="${BRAIN_VAULT:-$PWD}"
[ -d "$ROOT" ] || { echo "Vault introuvable: $ROOT (définis BRAIN_VAULT vers la racine du vault)" >&2; exit 1; }
cd "$ROOT" || exit 1
CMD="${1:-map}"
QUERY="${2:-}"

list_md() {
  find . -type f -name '*.md' \
    -not -path './.obsidian/*' -not -path './.git/*' -not -path './.trash/*' \
    -not -path '*/attachments/*' \
    -print0 | sort -z
}

cmd_map() {
  declare -A acount scount
  while IFS= read -r -d '' f; do
    rel=${f#./}
    IFS='/' read -ra seg <<<"$rel"
    if [ "${#seg[@]}" -ge 2 ]; then area="${seg[0]}"; else area="(racine)"; fi
    acount["$area"]=$(( ${acount["$area"]:-0}+1 ))
    if [ "${#seg[@]}" -ge 3 ]; then
      sub="${seg[0]}/${seg[1]}"; scount["$sub"]=$(( ${scount["$sub"]:-0}+1 ))
    fi
  done < <(list_md)

  local total=0 k
  for k in "${!acount[@]}"; do total=$(( total + acount["$k"] )); done
  printf '# 🗺️ Vault — %d notes, %d aires (vault: %s)\n' "$total" "${#acount[@]}" "$ROOT"

  for k in "${!acount[@]}"; do printf '%d\t%s\n' "${acount[$k]}" "$k"; done | sort -rn \
  | while IFS=$'\t' read -r cnt area; do
      moc=""
      for c in "$area/$area.md" "$area/README.md" "$area/Index.md"; do
        [ -f "$c" ] && { moc=" · MOC: [[${c%.md}]]"; break; }
      done
      printf '\n## %s/ — %d notes%s\n' "$area" "$cnt" "$moc"
      for s in "${!scount[@]}"; do
        case "$s" in "$area"/*) printf '%d\t%s\n' "${scount[$s]}" "$s";; esac
      done | sort -rn | while IFS=$'\t' read -r scnt sname; do
        printf '  - %s/ (%d)\n' "${sname#*/}" "$scnt"
      done
    done
  printf '\n→ détail d'\''une aire : ouvre sa MOC. Recherche : brain.sh find <terme>.\n'
}

cmd_find() {
  [ -n "$QUERY" ] || { echo "usage: brain.sh find <terme>" >&2; return 1; }
  local q; q="$(printf '%s' "$QUERY" | tr 'A-Z' 'a-z')"
  local hits
  hits=$(list_md | xargs -0 awk -v q="$q" '
    # m = pertinence (matchs requête) ; b = bonus de rôle (ne compte QUE si m>0). Émet si m>0.
    function flush(){ if(seen && m>0)
      printf "%d\037%s\037%s\037%s\037%s\037%s\037%s\n", m+b, rel, title, type, status, tags, snip }
    FNR==1{
      flush()
      rel=FILENAME; sub(/^\.\//,"",rel)
      fm=0; type=""; status=""; tags=""; title=""; m=0; b=0; snip=""; seen=1
      base=rel; sub(/.*\//,"",base); sub(/\.md$/,"",base)
      if(tolower(base) ~ q) m+=120
      else if(tolower(rel) ~ q) m+=25
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
  ' | sort -t$'\037' -k1,1 -rn)

  local matched; matched=$(printf '%s' "$hits" | grep -c . || true)
  printf '# 🔎 « %s » — %s note(s) trouvée(s)\n\n' "$QUERY" "${matched:-0}"
  [ -z "$hits" ] && { echo "(aucun résultat — essaie un terme plus large, ou un Grep plein-texte)"; return; }
  printf '%s\n' "$hits" | head -20 | awk -F'\037' '{
    role=""; if($4 ~ /moc|hub|index/) role=" ⭐"
    meta=$4; if($5!="") meta=(meta!=""? meta"·"$5 : $5)
    gsub(/[][]/,"",$6); sub(/^ +/,"",$6); sub(/ +$/,"",$6)
    line="- " $2 " — " $3
    if(meta!="") line=line " [" meta "]"
    if($6!="") line=line "  {" $6 "}"
    print line role
    sn=$7; if(length(sn)>110) sn=substr(sn,1,110) "…"
    if(sn!="") print "  ↳ " sn
  }'
  [ "${matched:-0}" -gt 20 ] && printf '\n… (top 20 affichés ; affine le terme si besoin)\n'
}

cmd_audit() {
  printf '# 🧹 Audit — dossiers de notes sans hub README\n\n'
  local n=0
  while IFS= read -r -d '' d; do
    d=${d#./}
    case "$d" in .obsidian*|.git*|.trash*) continue;; esac
    if compgen -G "$d/*.md" >/dev/null 2>&1; then
      [ -f "$d/README.md" ] && continue
      base=${d##*/}
      [ -f "$d/$base.md" ] && continue   # aire avec MOC homonyme
      printf -- '- %s/  (pas de README hub)\n' "$d"; n=$((n+1))
    fi
  done < <(find . -mindepth 1 -type d -not -path '*/.*' -print0 | sort -z)
  [ "$n" -eq 0 ] && printf '✅ tous les dossiers de notes ont un hub.\n'
  printf '\n— %d dossier(s) sans hub\n' "$n"
}

case "$CMD" in
  map)   cmd_map ;;
  find)  cmd_find ;;
  audit) cmd_audit ;;
  *) echo "commandes: map | find <terme> | audit" >&2; exit 2 ;;
esac
