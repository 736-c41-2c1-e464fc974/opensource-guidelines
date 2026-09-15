#!/usr/bin/env bash
#
# Write the language chooser at the root of the published site.
#
#   tools/site-root.sh <dir>
#
# Lists only the language directories that were actually built, so a language
# whose render job failed is absent rather than a dead link.

set -euo pipefail

dir="${1:?usage: site-root.sh <dir>}"

# Endonyms, left untranslated by convention: a reader looking for their own
# language recognises its own name, not its name in someone else's.
label_of() {
    case "$1" in
        en) echo "English" ;;
        de) echo "Deutsch (Schweiz)" ;;
        fr) echo "Français (Suisse)" ;;
        it) echo "Italiano (Svizzera)" ;;
        rm) echo "Rumantsch (Svizra)" ;;
        *)  echo "$1" ;;
    esac
}

{
    cat <<'HTML'
<!doctype html>
<html>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Open Source Guidelines</title>
<style>
  :root { color-scheme: light dark; }
  body { margin: 0 auto; padding: 3rem 1rem 4rem; max-width: 34rem;
         font: 16px/1.6 system-ui, -apple-system, "Segoe UI", sans-serif; }
  h1 { font-size: 1.5rem; margin: 0 0 .5rem; }
  p.lead { margin: 0 0 2.5rem; opacity: .7; font-size: .9rem; }
  ul { list-style: none; margin: 0; padding: 0; }
  li { border-top: 1px solid rgba(128,128,128,.3); }
  li:last-child { border-bottom: 1px solid rgba(128,128,128,.3); }
  a { display: block; padding: .9rem .25rem; text-decoration: none; color: inherit; }
  a:hover, a:focus { background: rgba(128,128,128,.12); }
  a .code { float: right; opacity: .5; font-size: .8rem; text-transform: uppercase; }
  footer { margin-top: 2.5rem; font-size: .8rem; opacity: .65; }
</style>
<h1>Open Source Guidelines</h1>
<p class="lead">Tools for publishing open source software in the Swiss Federal
Administration. Choose a language.</p>
<ul>
HTML

    for lang in en de fr it rm; do
        [ -d "$dir/$lang" ] || continue
        printf '  <li><a href="%s/"><span class="code">%s</span>%s</a></li>\n' \
            "$lang" "$lang" "$(label_of "$lang")"
    done

    cat <<'HTML'
</ul>
<footer>The German, French, Italian and Romansh versions are unreviewed
translations. The binding versions are published in the official languages by
the Federal Chancellery.</footer>
</html>
HTML
} > "$dir/index.html"

echo "wrote $dir/index.html"
