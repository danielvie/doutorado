# Handoff: persist the six verified articles and refresh the archive

## Next-session objective

Download the six full-text articles verified during the reference-integration pass and store permanent local PDF copies in `research/articles/`. Then update the two Markdown files in that folder so they describe and link all 26 archived PDFs.

The previous session inspected temporary downloads but did not save them in the workspace. Success requires the six files to exist in `research/articles/`, pass PDF and identity checks, and be documented in both `research/articles/README.md` and `research/articles/literature-review.md`.

## Completed reference-integration work

The verification and manuscript integration are complete:

- `article.tex` now cites 14 distinct references, including five of the six verified papers.
- `references.bib` contains the five cited records.
- `fiore2016contraction` was verified but deliberately omitted from the manuscript and bibliography because its Filippov regularization framework does not support a necessary claim in the common-Lyapunov paragraph.
- `task build` passes with no LaTeX or BibTeX errors, undefined citations, duplicate-entry warnings, or overfull boxes.
- The source types, page-level evidence, metadata decisions, claim boundaries, and reason for omitting Fiore are recorded in `handoff/reference-usage-review.md`.
- The scope and original verification plan are in `handoff/handoff-5-reference-verification-and-integration.md`.

Do not repeat the literature search or alter citation placement unless a persistent PDF fails the identity check. The task is to preserve the already verified full texts and bring the archive documentation up to date.

## Existing archive conventions

`research/articles/` currently contains 20 validated PDFs numbered `01` through `20`, plus:

- `research/articles/README.md`, the archive manifest;
- `research/articles/literature-review.md`, the per-paper screening notes.

Keep the existing filenames and numbering unchanged. Add the six papers as entries `21` through `26`. Use lawful publisher, author, institutional-repository, HAL, UPCommons, or arXiv copies. Do not use unauthorized mirrors or bypass access controls.

## Download targets

Download each URL with redirects enabled and save it under the exact target filename.

| No. | Citation key | Target filename | Lawful full text | Source type |
|---:|---|---|---|---|
| 21 | `flieller2006limitCycles` | `21-flieller-2006-hybrid-limit-cycles.pdf` | `https://hal.science/hal-00119807v1/document` | HAL author-produced manuscript of the published article |
| 22 | `repecho2017switchingFrequency` | `22-repecho-2017-switching-frequency-regulation.pdf` | `https://upcommons.upc.edu/bitstream/2117/99560/1/paper_double_column_final.pdf` | UPCommons author postprint |
| 23 | `stellato2017fcsMpc` | `23-stellato-2017-high-speed-fcs-mpc.pdf` | `https://arxiv.org/pdf/1510.05578` | arXiv author preprint of the published article |
| 24 | `albea2021hybridAffinePwm` | `24-albea-sanchez-2021-hybrid-affine-pwm.pdf` | `https://laas.hal.science/hal-03326994v1/file/PWM_ST19.pdf` | HAL author manuscript of the published article |
| 25 | `briat2013dwellTimes` | `25-briat-2013-dwell-times.pdf` | `https://arxiv.org/pdf/1209.0444` | arXiv author preprint of the published article |
| 26 | `fiore2016contraction` | `26-fiore-2016-contraction-regularization.pdf` | `https://arxiv.org/pdf/1507.07126` | arXiv author preprint of the published article |

If a URL rejects a command-line client, use another lawful endpoint from the same repository or download it through the user's browser. Do not substitute a different paper. Record the final source URL and source type in `README.md`.

## Required identity and file checks

For every downloaded file:

1. Confirm the first five bytes are `%PDF-`.
2. Run `pdfinfo` and reject malformed or encrypted files that cannot be read.
3. Extract the first page with `pdftotext` and confirm the title and authors against `references.bib` or the metadata in `handoff/reference-usage-review.md`.
4. Confirm the file is the full article, not a repository landing page, abstract, supplementary file, or error document saved with a `.pdf` extension.
5. Keep the published journal year and metadata in the documentation even when the repository manuscript has an earlier submission date.

A suitable archive-level check from `research/articles/` is:

```sh
uv run python -c "from pathlib import Path; p=Path('.'); pdfs=sorted(p.glob('*.pdf')); urls=sorted(p.glob('*.url')); bad=[f.name for f in pdfs if f.read_bytes()[:5] != b'%PDF-']; print('pdfs',len(pdfs)); print('urls',len(urls)); print('bad_pdf_signatures',bad)"
```

Expected result after completion:

```text
pdfs 26
urls 0
bad_pdf_signatures []
```

## Review and update the Markdown documents

### `research/articles/README.md`

The current heading and opening text say that the archive covers only recent literature from 2021 to 2026. That description becomes inaccurate after adding papers from 2006, 2013, and 2017.

Make these focused updates:

- Rename the heading to a date-neutral form such as `# Literature archive`.
- State that the folder contains 26 validated PDFs.
- Explain that files `01` through `20` correspond to `research/recent-literature-2021-2026.md`, while files `21` through `26` come from the verification recorded in `handoff/reference-usage-review.md`.
- Add manifest rows 21 through 26 with citation key, local PDF status, DOI, repository identifier or URL, and source type.
- Change the footer count to `Downloaded PDFs: 26. Link-only records: 0.`
- Preserve the statement that no access controls were bypassed.

### `research/articles/literature-review.md`

The current document says it reviews 20 PDFs and classifies 13 as core and 7 as supporting. Extend it rather than replacing the existing reviews.

- Update the opening count to 26 PDFs.
- Add reviews 21 through 26 using the same headings and local-link format as reviews 01 through 20.
- Link each `Article` field to the exact local filename listed above.
- Use the verified claim boundaries from `handoff/reference-usage-review.md`; do not infer broader claims from titles or abstracts.
- A consistent classification is 16 core and 10 supporting after adding:
  - core: Flieller, Albea-Sanchez, and Briat;
  - supporting: Repecho, Stellato, and Fiore.
- State explicitly in Fiore's review that it is archived as checked background but is not cited in `article.tex`.
- Keep Patiño and Marcolino identified as the closest prior work. Do not turn the new sections into a broad related-work argument.

The six reviews should preserve these distinctions:

- Flieller covers switching-time sensitivity, periodic-orbit computation, and sampled-time local stability, not the present conditioner.
- Repecho regulates measured switching periods by changing a hysteresis band, not by shifting a fixed schedule's interior instants.
- Stellato reports deterministic timing for a specific fixed-point FPGA implementation with horizons one and two, not a hardware-independent computation bound.
- Albea-Sanchez uses hybrid-affine PWM and sample-and-hold variables and exact two-subinterval propagation, not the present prescribed nine-interval timing coordinates.
- Briat gives broader minimum and mode-dependent dwell-time stability conditions, not radial conditioning or the endpoint-norm certificate.
- Fiore studies contraction of bimodal Filippov systems through regularization and matrix measures, not the discrete-time cycle-map segment used in this article.

## Validation after documentation edits

1. Confirm exactly 26 PDFs and no `.url` files in `research/articles/`.
2. Confirm all six new PDF signatures and first-page identities.
3. Check that every local PDF link in `research/articles/literature-review.md` resolves to an existing file.
4. Search both Markdown files for stale totals such as `20 PDFs`, `13 core`, `7 supporting`, or `2021–2026` where they describe the whole archive.
5. Run `git diff --check`.
6. Do not change `article.tex`, `references.bib`, or citation counts merely because Fiore is now archived locally.

## Known unrelated manuscript issues

The generated PDF still displays the template's ORCID `TODO` and `IEEE, ??? (2010)` in the existing Patiño bibliography entry. They predate this archive task and should not be changed unless the user requests a separate cleanup.

## Suggested skills

- `research` for lawful PDF retrieval and first-page identity verification.
- `unslop` when extending `research/articles/README.md` and `research/articles/literature-review.md` in the existing plain style.
- `handoff` if any repository blocks persistent download and the six-file archive cannot be completed in one session.
