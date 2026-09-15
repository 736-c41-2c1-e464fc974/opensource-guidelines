# Translating these guidelines

Every document in `docs/` carries **all five languages in one `.adoc` file**.
There is no per-language copy of a file and no per-language directory — those
were removed on purpose, because five copies of a document drift apart the first
time someone fixes a typo in only one of them.

## How a document is structured

```asciidoc
:lang: en                                  <1>
ifeval::["{lang}" == "en"]
= Em002-5 EMOTA and OSS Factsheet          <2>
:title-logo-line1: Federal Chancellery FCh
:title-logo-line2: Digital Transformation and ICT Steering DTI
endif::[]
ifeval::["{lang}" == "de"]
= Em002-5 Merkblatt EMBAG und OSS
:title-logo-line1: Bundeskanzlei BK
:title-logo-line2: Digitale Transformation und IKT-Lenkung DTI
endif::[]
…fr, it, rm…
:govpress-style: report                    <3>
:toc:
…

ifeval::["{lang}" == "en"]                 <4>
…the whole English body…
endif::[]

ifeval::["{lang}" == "de"]
…the whole German body…
endif::[]

…fr, it, rm…
```

1. **Must stay the first line.** It is the default language when nobody pins
   one, which is what GitHub's `.adoc` preview and the open-govpress desktop app
   use. Without it the `ifeval::` guards have no `{lang}` to compare against and
   the document renders empty.
2. The **title** and the two **Kennzeichnung** lines are per-language.
3. Every other attribute is shared, written once, after the title chain.
4. The body is five blocks, always in the order `en, de, fr, it, rm`.

Language codes are the bare subtags `en de fr it rm` — never `de-CH`. The tool
reduces `de-CH` to `de` when it looks up captions, but `{lang}` would still hold
the literal `de-CH` and no `ifeval::` would ever match.

### The Kennzeichnung

Captions, the TOC heading and admonition labels are localised by open-govpress
from the active language. Leave them alone.

The **Kennzeichnung** on the title page is stated by the document itself.
`:title-logo-base: black` and the empty `:title-logo-line3:` are shared; lines 1
and 2 sit in the per-language blocks and must read exactly:

| lang | line1 | line2 |
|---|---|---|
| en | Federal Chancellery FCh | Digital Transformation and ICT Steering DTI |
| de | Bundeskanzlei BK | Digitale Transformation und IKT-Lenkung DTI |
| fr | Chancellerie fédérale ChF | Transformation numérique et gouvernance de l'informatique TNI |
| it | Cancelleria federale CaF | Trasformazione digitale e governance delle TIC TDT |
| rm | Chanzlia federala ChF | Transfurmaziun digitala e direcziun da las TIC TDT |

Sector names are from the Federal Chancellery's own pages —
[de](https://www.bk.admin.ch/de/bereich-dti),
[fr](https://www.bk.admin.ch/fr/transformation-numerique-et-gouvernance-de-linformatique),
[it](https://www.bk.admin.ch/it/trasformazione-digitale-e-governance-delle-tic),
[en](https://www.bk.admin.ch/en/dti-sector),
[rm](https://www.bk.admin.ch/bk/rm/home/digitale-transformation-ikt-lenkung.html).
Note the sector abbreviation differs per language: **DTI** in German and
English, **TNI** in French, **TDT** in Italian *and Romansh*.

## Building

```sh
render-docs            # all five languages into build/
render-docs de rm      # just those two
```

Check a single document while translating it:

```sh
for l in en de fr it rm; do
  open-govpress render --lang "$l" -o "build/$l" docs/em002-5.adoc
done
```

A near-empty PDF means that language's body block is missing or its `endif::[]`
is malformed.

## Terminology

| en | de | fr | it | rm |
|---|---|---|---|---|
| EMOTA | EMBAG | LMETA | LMeCA | EMBAG |
| Federal Chancellery FCh | Bundeskanzlei BK | Chancellerie fédérale ChF | Cancelleria federale CaF | Chanzlia federala ChF |
| FOBL | BBL | OFCL | UFCL | UFCL |
| CCPP | KBB | CCMP | CCAP | CCA |
| FITSU | ISB | USIC | ODIC | ISB |
| DTI sector | Sektor DTI | secteur TNI | settore TDI | sectur TDI |
| open source software (OSS) | Open-Source-Software (OSS) | logiciel open source (OSS) | software open source (OSS) | software open source (OSS) |
| checklist | Checkliste | liste de contrôle | lista di controllo | glista da controlla |
| guidelines (Em002-3/-4) | Leitfaden | guide | guida | guida |
| practical guidelines (Em002-1) | Praxisleitfaden | guide pratique | guida pratica | guida pratica |
| instructions (Em002-2) | Anleitung | instructions | istruzioni | instrucziuns |
| information sheet / factsheet | Merkblatt | aide-mémoire | promemoria | fegl d'infurmaziun |
| administrative unit (OU) | Organisationseinheit (OE) | unité d'organisation (UO) | unità organizzativa (UO) | unitad d'organisaziun (UO) |

**Romansh (Rumantsch Grischun) is the weakest link.** `EMBAG` is used as the
short title because it is the abbreviation Romansh federal texts cite; if
Fedlex publishes a Romansh abbreviation for SR 172.019, use that instead. The
Romansh text in this repository has not been reviewed by a Romansh speaker.

## Rules

- **Preserve every AsciiDoc construct exactly.** `footnote:[SR 172.019]`,
  `image::` macros, `|===` table delimiters and cell counts, `a|` cell prefixes,
  `* [ ]` checklist items (they render as interactive checkboxes), inline roles
  such as `[.underline]#…#`, `'''` rules, `+` line breaks.
- **Translate image alt text.** Image *paths* are per-language where the picture
  contains words: `assets/four-cs/four-cs.de.svg` belongs in the German block
  and nowhere else. Those SVGs are generated — edit
  `tools/make-four-cs-svg.sh` and re-run it, never the `.svg` files.
- **Translate `link:…[display text]`, never the target.** Targets are `.pdf`
  because the links are followed inside the rendered PDFs, where the documents
  sit side by side in one language directory.
- **Switch the language segment of admin.ch and fedlex.admin.ch URLs** to match
  (`…/2023/682/en#art_9` → `…/2023/682/de#art_9`). Leave a URL alone when only
  one language of it exists — several `beschaffung.admin.ch` links are
  German-only and are cited as such in the English source too.
- **Keep abbreviations that the English source keeps**, such as `ISBO / DSBO`
  and `Application Manager`.
- Section numbering is generated (`:sectnums:`), so cross-references that name a
  section number stay valid in every language as long as the section structure
  is identical. Keep the same headings in the same order in all five blocks.

## Diagrams

Diagrams are `[mermaid]` blocks in the body, so **their labels are text you
translate** like any other. Four rules, each of which has bitten:

- **Never add `theme:`, `themeVariables`, a `---` frontmatter block or an
  `%%{init: …}%%` directive.** open-govpress supplies a 271-variable palette
  built from the document's own tokens; any inline theme override throws it
  away and the diagram renders off-brand.
- **Never set `layout: elk`** — the ELK package is not bundled — **or `look:`**,
  which is unverified against the Ruby pipeline's older `mmdc`.
- **`end` is a reserved word** and silently breaks a flowchart. Quote any node
  label that is just that word: `Fin(["Ende"])`, never `Fin([Ende])`.
- **Every block needs `alt=`**, translated. Without it the diagram reaches the
  PDF as an unlabelled figure and a screen reader reads its node labels in
  layout order, which is word salad.

A block that fails to parse degrades to a listing of its own source rather than
disappearing, so check the rendered PDF: Mermaid keywords in the text layer mean
a diagram did not draw.

Colour is used only where it carries meaning that the structure does not — the
licence-compatibility graph and the document map. Elsewhere the near-monochrome
house palette is correct, not a bug.

## Shared fragments

`docs/partials/` holds fragments that several documents `include::`, one file per
language — currently the map of Art. 9 documents, which four documents show and
`Em002` shows twice. **Translate the partial, not the inclusion**, and keep the
language of the file matching the `ifeval::` block that includes it.

A fragment is not a document: `render-docs` and `tools/site-index.sh` exclude
`docs/partials/` so it never becomes a PDF of its own. A missing `include::`
prints an error but still writes a PDF, so read the render output rather than
trusting the exit status.

## Status

The German, French, Italian and Romansh texts are **unreviewed machine
translation**. The binding versions of these documents are the ones published in
the official languages on the Federal Chancellery website. An FCh translation
review is required before the non-English versions here are treated as anything
more than drafts.
