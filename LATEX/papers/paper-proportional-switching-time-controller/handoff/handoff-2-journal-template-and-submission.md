# Journal template and submission handoff

## User goal

Check the target journal's article template, adapt this manuscript to its requirements, and provide a separately built publisher sample for visual comparison. The next session should explain the submission process and resolve remaining formatting questions, especially columns and references.

Target: [Journal of Control, Automation and Electrical Systems](https://link.springer.com/journal/40313).

Start with `project-knowledge/README.md`, then the paper-root `README.md`. The manuscript is `latex/main.tex`. Preserve scientific content, the author-owned Introduction, and generated numerical evidence during formatting work.

## Column layout: preserve `iicol`

The current manuscript uses:

```latex
\documentclass[pdflatex,iicol,sn-mathphys-ay]{sn-jnl}
```

The unchanged publisher sample uses:

```latex
\documentclass[pdflatex,sn-mathphys-num]{sn-jnl}
```

These are different configurations of the same class. The generic sample defaults to one column and numbered references. `iicol` selects two columns. Its absence from the sample is not evidence that this journal requires single-column submissions.

The research child's partial findings report that the [journal submission guidelines](https://link.springer.com/journal/40313/submission-guidelines) explicitly recommend `iicol`. This journal-specific guidance takes precedence over the generic sample. The user was told to keep two columns.

Important correction: before receiving that finding, the parent suggested removing `iicol` as a conservative submission choice. That recommendation was withdrawn. No column-layout change was applied.

Evidence distinction: the local publisher manual directly confirms that `iicol` switches to double columns to suit journal requirements. The journal-specific recommendation came from the research child's partial output, not a successfully completed research report. Recheck the live guideline and capture its exact wording before presenting a final compliance audit.

## Template archive and completed checks

The sole retained publisher package is [`templates/springer-template/springer-template.zip`](../templates/springer-template/springer-template.zip). It is the generic Springer Nature template, version 3.1 from December 2024, with SHA-256 `812e76dcaa9c28dc1bff1fb6065d51729b67d4ea140552a05088317414a3ecae`. The archive includes the sample source, compiled publisher sample, user manual, class, and bibliography styles.

A temporary extracted copy was checked byte-for-byte against this archive. Its unchanged sample compiled to 12 pages with font-substitution and box warnings. The manuscript's existing class and author-year BST also matched the archive. `task build` and `task check-links` passed, and the link check found 156 valid local links at that point.

The extracted comparison directory and its `task template-build` command were later removed to avoid retaining duplicate files. Extract the ZIP to a temporary directory if another stock-sample comparison is needed. The generic sample does not establish the journal-specific class options.

## Submission findings to verify and apply

The following came from the failed research run's partial output. They are useful leads, not a completed compliance certification. Authoritative source: [submission guidelines](https://link.springer.com/journal/40313/submission-guidelines).

### Template and reference style

Official links reported by the child:

- [Springer Nature LaTeX support](https://www.springernature.com/gp/authors/campaigns/latex-author-support)
- [Template ZIP](https://cms-resources.apps.public.k8s.springernature.io/springer-cms/rest/v1/content/18782940/data/v12)
- [Overleaf template](https://www.overleaf.com/latex/templates/springer-nature-latex-template/gsvvftmrppwq)

The support page reportedly offers the same December 2024 v3.1 distribution already stored locally.

The child reported author-year citations and APA 7 reference guidance, and proposed:

```latex
\documentclass[pdflatex,iicol,sn-apa]{sn-jnl}
```

Treat `sn-apa` as the child's proposed mapping of journal guidance to a template option, not an explicitly mandated journal class line. Verify it before changing the current `sn-mathphys-ay`. The APA option uses the supplied `sn-apacite.bst`; all publisher styles are inside `templates/springer-template/springer-template.zip` under `sn-article-template/bst/`. APA 7 compatibility of the supplied style still needs inspection, including the reported author-list rule: all authors through 20, otherwise first 19, ellipsis, final author. No bibliography-style change has been made.

### Preparing a submission

Reported requirements and recommendations:

- English manuscript. LaTeX submission is supported/requested; Word is also accepted.
- Submit the compiled PDF and all editable sources, including class/style files and figures.
- Original-paper first drafts are requested to be under 15 print pages. The child did not characterize this as an absolute maximum. Technical correspondence has a separate two-page limit.
- Use decimal headings, at most three levels; define abbreviations; use SI units.
- Include all author names and affiliations, corresponding-author email, and ORCIDs if available. Do not invent or reproduce personal details in handoff notes.
- Abstract: 150–250 words. Keywords: 4–6. The current source has approximately 199 whitespace-separated abstract words and six keywords; count rendered text accurately if needed.
- Include relevant funding, competing-interest, ethics/consent, data/materials/code availability, and author-contribution declarations before references. The current manuscript already contains author-owned TODOs in its declaration block. These must be resolved before submission, not filled with invented statements.
- The submission interface also asks for funding, competing interests, and author contributions.
- The child reported single-anonymous review from the journal's official Ethics & disclosures page. Keep author information in the manuscript. `referee` means double line spacing, not anonymization; `lineno` adds line numbers.
- Verify current artwork, caption, acknowledgement-placement, and bibliography details directly in the guidelines before preparing the upload package.

The generic template's source explicitly requests one `.tex` manuscript without `\input` files. Its manual also cautions against figure subfolders and requests a single image file per figure. The working manuscript currently uses generated metric inputs, a TikZ input, a figures subfolder, and a multi-file timing figure. Do not destroy this reproducible source organization. If needed, prepare a separate flattened submission package and check the actual portal's requirements. No packaging tool or submission ZIP was created in this session.

No submission portal workflow, account, upload, or final submission was performed. Do not infer that the article is ready to submit merely because it builds.

## Research failure and checkout state

The web lookup used the `searcher` agent within one async subagent workflow.

- Workflow: `e4029d39-cfca-4e95-96f9-8391ef0a010b`.
- Child: `5b56df35-1295-495e-9e93-bb7e463f6839`, key `journal-requirements`.
- Final status: failed. Error: `Run 'journal-requirements' failed` with `Request was aborted`.
- Saved child output was unavailable. The failure notification included the partial findings summarized above.
- Receipt location: `%TEMP%/pi-subagents-user-*/async-subagent-runs/e4029d39-cfca-4e95-96f9-8391ef0a010b/workflow-receipt.json`.

Repository root: the existing `doutorado.git` checkout. Workspace: `LATEX/papers/paper-proportional-switching-time-controller/`. Branch `main`, HEAD `c64bbe245c85d6b8351d15c77b853c23791fb15c`. There was no isolated child worktree; `git worktree list` showed only the source checkout.

When this work began, pending changes included `README.md`, `Taskfile.yml`, and a new `templates/journal-40313/` folder. The temporary template directory and its README and task references were later removed; the original ZIP remains under `templates/springer-template/`. `latex/main.tex`, numerical evidence, and `article.pdf` were unchanged. Research scratch HTML files appeared temporarily at the repository root, but were absent from the final status check. No commit was made.

Do not silently change execution mode after this subagent failure. Recheck the diff and retry web verification through the same approved subagent protocol. Follow current tool instructions for capability discovery and retries; foreground/external-CLI fallback requires explicit approval where the protocol governs the work.

## Suggested next steps

1. Verify the journal's exact `iicol` recommendation and reference-style guidance from the live official page; retain the two-column manuscript in the meantime.
2. If useful, extract the stock package temporarily and build a separate journal-configured sample for comparison.
3. Confirm the bibliography option, apply only justified formatting changes, and rebuild. Keep scientific wording and numerical outputs unchanged.
4. List remaining author-supplied declarations and prepare a submission-package checklist. Resolve single-file source and artwork packaging separately from manuscript maintenance.

## Suggested skills

- `unslop`: required for concise prose and documentation.
- `web-search-subagent`: verify current official submission rules and download links.
- `pi-subagents`: inspect the failed workflow and perform any same-protocol research retry.
- `handoff`: maintain a focused continuation note without copying existing artifacts.
