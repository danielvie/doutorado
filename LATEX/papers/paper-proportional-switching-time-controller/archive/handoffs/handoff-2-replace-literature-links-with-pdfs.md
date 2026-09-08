# Handoff: replace literature links with PDFs

## Completed

Replaced all link-only records in `research/articles/` with lawful local PDF copies. The archive now contains 20 PDFs and 0 `.url` records. Ten inaccessible 2021–2026 records were replaced with distinct 2023–2026 arXiv author manuscripts after extending the search window to 2020–2026.

## Current state

- The paper now cites 20 recent papers in `article.tex`; their BibTeX entries are in `references.bib`.
- The full primary-source literature review is in `research/recent-literature-2021-2026.md`.
- The archive manifest is `research/articles/README.md`.
- The archive has 20 validated PDFs and no `.url` shortcuts. The original 10 accessible PDFs were preserved.
- PDFs were downloaded only from lawful publisher, author, institutional-repository, arXiv, or pre-existing thesis-archive sources. Do not use paywall bypasses or unauthorized mirrors.
- The paper's role is a solver-free, direction-preserving dwell-time conditioner for fixed-period switching-time feedback, with a common-Lyapunov certificate. It is not a general dwell-constrained MPC or a new switching-time-optimization method.

## Link-only replacement targets

Use the local `.url` file first. It records the most relevant publisher or repository source. For each successful replacement, copy or move the PDF into the same directory with the filename below, delete the `.url`, update `README.md`, and verify the first five bytes are `%PDF-`.

| No. | Citation key | Target PDF filename | Why this paper was retained and cited | Current access status |
|---:|---|---|---|---|
| 2 | `dellarossa2022frequency` | `02-della-rossa-2022-switching-frequency.pdf` | Establishes recent stability certification under switching-frequency restrictions. It contrasts with correction of switching instants in a fixed schedule. | Publisher subscription link. DOI: `10.1016/j.automatica.2021.110099`. |
| 5 | `ma2023periodic` | `05-ma-2023-periodic-hybrid-converter.pdf` | Closest recent converter result using periodic time-triggered switched-affine control. It supports the application relevance of the paper's periodic setting. | IEEE subscription link. DOI: `10.1109/TIE.2022.3150085`. |
| 7 | `albea2024limit` | `07-albea-2024-hybrid-limit-cycles.pdf` | Recent hybrid-limit-cycle stabilization with dwell times. It narrows the claim that periodic-orbit stabilization itself is new. | Lawful HAL manuscript exists at `https://hal.science/hal-04814278/document`, but the repository rejected automated clients. |
| 8 | `deaecto2024tracking` | `08-deaecto-2024-periodic-tracking.pdf` | Recent periodic-affine trajectory tracking comparison. It contrasts state-dependent mode selection with the paper's fixed-mode-order timing feedback. | Publisher subscription link. DOI: `10.1080/00207721.2024.2302883`. |
| 9 | `ghawash2025embedded` | `09-ghawash-2025-embedded-dwell-mpc.pdf` | Strongest embedded implementation comparison for dwell-constrained switched-affine MPC. It motivates avoiding online optimization. | Publisher subscription link. DOI: `10.1016/j.ejcon.2025.101347`. |
| 11 | `zhu2023switching` | `11-zhu-2023-switching-time-optimization.pdf` | Positions switching instants as continuous decision variables and contrasts full schedule optimization with static cycle-to-cycle feedback. | Publisher article is open access, but its automated PDF endpoint returned no content. Landing page: `https://www.aimsciences.org/article/doi/10.3934/jimo.2022067`. |
| 12 | `peng2024robust` | `12-peng-2024-robust-switching-time-mpc.pdf` | Represents the online-MPC route to robust switching-time optimization. It contrasts with the paper's $O(N)$ solver-free scan. | IEEE subscription link. DOI: `10.1109/TNNLS.2023.3246041`. |
| 15 | `zhang2023sequence` | `15-zhang-2023-mmc-switching-sequence.pdf` | Supports the broad converter funnel: practical control reduces online search through sequence restriction. | IEEE subscription link. DOI: `10.1109/TIE.2022.3194599`. |
| 16 | `jayan2023multilevel` | `16-jayan-2023-dual-output-multilevel-mpc.pdf` | Supports the converter and microgrid funnel, showing cascaded MPC used to reduce computational burden. | Lawful NTU author manuscript exists at `https://dr.ntu.edu.sg/bitstream/10356/164479/2/FINAL%20VERSION.pdf`, but the repository requires a browser verification challenge. |
| 19 | `gao2024constraints` | `19-gao-2024-mmc-input-constraints.pdf` | Supports the claim that physical input bounds belong in converter-control design. It contrasts online bound-constrained QP with the scalar dwell conditioner. | IEEE subscription link. DOI: `10.1109/TPEL.2023.3318320`. |
| 20 | `raja2024sparse` | `20-raja-2024-data-driven-mmc-mpc.pdf` | Supports the converter funnel's theme of reducing model and candidate-set cost for embedded feasibility. | Publisher paper is open access at `https://onlinelibrary.wiley.com/doi/pdfdirect/10.1049/elp2.12523`, but Cloudflare rejected automated download. |

## Why the 20 papers were used

The set builds a funnel from industrially relevant converter applications and their computation limits, through switched-affine and periodic control, to switching-time optimization and dwell-time feasibility. The full evidence, application type, method, and contrast for all 20 papers are in `research/recent-literature-2021-2026.md`.

The introduction uses all 20 citations. The 11 above remain necessary because they cover distinct parts of the positioning:

- broad converter constraints and computation: 15, 16, 19, 20;
- periodic switched-affine control: 5, 7, 8;
- dwell and embedded control: 2, 9;
- switching-time optimization alternatives: 11, 12.

## Replacement procedure

1. Check `downloads/` for new PDFs before searching online. The previous session found four there and copied them into the archive.
2. Prefer publisher open-access PDFs, author manuscripts, institutional repositories, or arXiv.
3. For subscription-only papers, rely on the user's lawful institutional-browser access. Do not request or store credentials.
4. Match the title using `pdftotext <file> -` before copying it.
5. Copy to the filename in the table. Preserve the original file in `downloads/` unless the user asks to remove it.
6. Delete the matching `.url` only after validating the copied PDF.
7. Update `README.md` with source type and adjust the PDF and link counts.
8. The ten replacements are documented in `research/open-replacement-candidates-2020-2026.md`; `article.tex`, `references.bib`, and `research/recent-literature-2021-2026.md` now use the replacement keys and revised claims.

## Validation commands

Run from `research/articles/`:

```sh
uv run python -c "from pathlib import Path; p=Path('.'); pdfs=sorted(p.glob('*.pdf')); urls=sorted(p.glob('*.url')); bad=[f.name for f in pdfs if f.read_bytes()[:5] != b'%PDF-']; print('pdfs',len(pdfs)); print('urls',len(urls)); print('bad_pdf_signatures',bad)"
```

For title matching:

```sh
pdftotext "<candidate.pdf>" -
```

## Suggested skills

- `research` for locating lawful full-text copies and verifying findings against primary sources.
- `unslop` only if the next session revises prose in `article.tex` after reviewing the downloaded papers.
- `handoff` if the remaining link-only records cannot be resolved in one session.
