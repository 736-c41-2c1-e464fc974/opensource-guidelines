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
endif::[]
ifeval::["{lang}" == "de"]
= Em002-5 Merkblatt EMBAG und OSS
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
2. Only the **title** is per-language in the header.
3. Every other attribute is shared, written once, after the title chain.
4. The body is five blocks, always in the order `en, de, fr, it, rm`.

Language codes are the bare subtags `en de fr it rm` — never `de-CH`. The tool
reduces `de-CH` to `de` when it looks up captions, but `{lang}` would still hold
the literal `de-CH` and no `ifeval::` would ever match.

### What you must not localise by hand

The **Kennzeichnung** on the title page (`Departement` / `Amt` and its
equivalents) and every caption, TOC heading and admonition label are localised
by open-govpress from the active language. Do not add `:title-logo-base:` or
`:title-logo-line1:`/`line2:`/`line3:` to a document — their mere *presence*
switches the automatic localisation off and pins whatever language they were
written in across all five outputs.

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
is malformed. A PDF where all five languages show the same Kennzeichnung means a
`title-logo-*` attribute crept back in.

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
- **Translate image alt text**, but not image paths — all five languages share
  `docs/assets/`.
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

## Status

The German, French, Italian and Romansh texts are **unreviewed machine
translation**. The binding versions of these documents are the ones published in
the official languages on the Federal Chancellery website. An FCh translation
review is required before the non-English versions here are treated as anything
more than drafts.
