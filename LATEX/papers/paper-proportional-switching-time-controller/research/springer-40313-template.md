# Springer journal 40313: LaTeX template and author requirements

**Journal:** Journal of Control, Automation and Electrical Systems (ISSN 2195-3899)  
**Checked:** 2026-08-19  
**Scope:** Official Springer/Springer Nature sources only. The official package is stored under `springer-template/`; the manuscript conversion is recorded in `article.tex`.

## Bottom line

- The journal does **not** publish a separate `40313.cls` on its author page. Its submission instructions direct authors to the generic **Springer Nature LaTeX template**.
- For LaTeX, the journal specifically recommends the formatting option **`[iicol]`**.
- Submit the compiled PDF together with the complete editable source: the main `.tex`, all style/class files, bibliography files as applicable, and figures.

## Exact template/package

Springer Nature's official December 2024 package is version 3.1. The downloaded archive contains:

- `sn-article-template/sn-article.tex` — starter manuscript
- `sn-article-template/sn-jnl.cls` — base class
- `sn-article-template/bst/` — Springer bibliography styles
- `sn-article-template/user-manual.pdf` — template technical manual

Official download:

- [Springer Nature LaTeX Author Support](https://www.springernature.com/gp/authors/campaigns/latex-author-support)
- [Direct Springer Nature template package](https://cms-resources.apps.public.k8s.springernature.io/springer-cms/rest/v1/content/18782940/data/v12)

The Springer page also links this exact Overleaf project:

- [Springer Nature LaTeX Template on Overleaf](https://www.overleaf.com/latex/templates/springer-nature-latex-template/gsvvftmrppwq)

The template is generic rather than journal-specific. The journal's own instructions take precedence over the generic template defaults.

## Journal article types and length

The journal accepts three basic types:

- **Original papers:** new research, applications, or developments. The journal asks that first drafts be **fewer than 15 print pages**; additional pages may be allowed during review.
- **Survey papers:** extensive reviews. Prospective survey/tutorial authors should contact the Editor-in-Chief before preparing the contribution.
- **Technical correspondences:** letters/comments and similar items; comments on previously published papers are limited to **2 printed pages**.

Submissions must be in **English**. A submission implies that the work is unpublished, not under consideration elsewhere, and approved by all authors and relevant institutional authorities.

## Formatting and manuscript-structure requirements relevant to conversion

- Use LaTeX and the Springer Nature template; select **`[iicol]`** as specified by the journal.
- Use decimal headings with no more than **three levels**.
- Title page: concise title; all author names; affiliations including institution/department/city/state/country; corresponding-author indication and active email; ORCID IDs if available.
- Abstract: **150–250 words**; no undefined abbreviations or unspecified references.
- Keywords: **4–6**.
- Include a `Statements and Declarations` section as applicable, including competing interests. Funding, ethics/consent, data/material/code availability, and author-contribution statements should be included when applicable.
- Original research articles must include a **Data Availability Statement**.
- Acknowledgments belong in a separate title-page section; write funding-organization names in full.
- Scientific style: SI units; italic single-letter variables; upright operators/functions; bold vectors, tensors, and matrices.
- References use **name–year citations**. The reference list is alphabetized by first author; include only cited works that are published or accepted; include full DOI URLs when available.
- Tables: Arabic numbering, consecutive in-text citation, and explanatory captions.
- Figures: submit electronically and preferably within the text. Number figures consecutively with Arabic numerals. Captions are in the manuscript; the journal specifies bold `Fig.` and figure number, no punctuation after the number, and no punctuation at the end of the caption. Preferred artwork formats/resolutions are specified in the journal guidelines: EPS for vector art, TIFF for halftones; 1200 dpi line art, 300 dpi halftones, and 600 dpi combination art.

## Template conversion notes

- The Springer package's starter file is a single `sn-article.tex`; its comments say not to use `\input{...}` for included TeX files and to attach figures separately.
- Springer Nature's author-support page says not to use custom fonts and to encode special characters/diacritics with TeX commands.
- The journal page requires author–year references, but it does not name a specific `sn-jnl` bibliography option. Confirm the exact bibliography-style choice with the editorial office if the generic template's options do not reproduce the journal's required author–year output.

## Uncertainty and limits

- I found no official Springer page offering a journal-specific `40313` class or an article-type-specific LaTeX template; the official route is the generic Springer Nature package plus the journal's `[iicol]` instruction.
- The journal says surveys/tutorials should be discussed with the Editor-in-Chief first; it does not provide a separate survey template.
- The journal's page gives submission-format requirements, not a guaranteed final production layout. Springer Nature explicitly says journal-level instructions take precedence over the generic template.

## Sources

1. [Journal homepage](https://link.springer.com/journal/40313)
2. [Journal submission guidelines](https://link.springer.com/journal/40313/submission-guidelines)
3. [Springer Nature LaTeX Author Support](https://www.springernature.com/gp/authors/campaigns/latex-author-support)
4. [Official Springer Nature template package](https://cms-resources.apps.public.k8s.springernature.io/springer-cms/rest/v1/content/18782940/data/v12)
5. [Springer-linked Overleaf template](https://www.overleaf.com/latex/templates/springer-nature-latex-template/gsvvftmrppwq)
