#!/usr/bin/env bash
#
# Fail on AsciiDoc that does not parse.
#
#   tools/check-asciidoc.sh [file.adoc...]
#
# With no arguments, checks every tracked .adoc; the git hook passes the files
# it is about to commit.
#
# git-hooks.nix ships no AsciiDoc linter, and the render pipeline is the only
# thing that reads these files -- so without this, a broken include or an
# unterminated block is first noticed by the CI render matrix, several minutes
# and five parallel jobs later. asciidoctor parses in well under a second per
# document, so the same class of mistake can be caught at commit time.
#
# Every document is parsed once per language. The bodies are five
# `ifeval::["{lang}" == "<lang>"]` blocks, so a conditional left unterminated in
# the Romansh block is simply invisible while parsing as English, which is what
# a single default-language pass would do.
#
# Output is discarded: this checks that the source parses, not what it renders.
# `--failure-level=WARN` is what makes warnings fatal -- asciidoctor otherwise
# prints "unterminated listing block" and still exits 0.
#
# Note this does not validate cross-references. asciidoctor reports an
# unresolvable xref below WARN and exits 0 even at --failure-level=INFO, so a
# dangling <<ref>> is out of reach here.

set -euo pipefail

# The five languages render-docs builds. A document that opts out of one with
# `:l10n-languages:` still has to parse in it -- the guards just yield an empty
# body -- so there is no reason to read that attribute here.
languages=(en de fr it rm)

files=()
if [[ "$#" -gt 0 ]]; then
    files=("${@}")
else
    tracked=$(git ls-files '*.adoc')
    while IFS= read -r file; do
        [[ -n "${file}" ]] || continue
        files+=("${file}")
    done <<<"${tracked}"
fi

if [[ "${#files[@]}" -eq 0 ]]; then
    exit 0
fi

# One asciidoctor per language rather than per file-and-language: the Ruby
# startup dominates the actual parse, and batching turns ~28s into ~2s across
# the whole repository. Errors still name the file and line they came from.
status=0
for lang in "${languages[@]}"; do
    if ! asciidoctor \
        --safe \
        --failure-level=WARN \
        --attribute lang="${lang}" \
        --out-file /dev/null \
        "${files[@]}"
    then
        echo "check-asciidoc.sh: failed to parse as '${lang}'" >&2
        status=1
    fi
done

exit "${status}"
