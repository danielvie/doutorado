# Deep research for recent introduction references

## Purpose

Conduct a deep literature search to support the introduction's funnel from power electronics to the paper's exact problem. Find recent, strong publications for each field and transition. Prioritize lawful, directly downloadable full texts that can be archived and checked before citation.

Do not rewrite `article.tex` during this task.

## Authoritative context

Read these first:

- `project-knowledge/README.md`
- `GOAL.md`
- `CONTEXT.md`
- `article.tex`, especially the Introduction and `Solver-free dwell-time conditioning`
- `research/recent-literature-2021-2026.md`
- `research/open-replacement-candidates-2020-2026.md`
- `research/articles/README.md`
- `research/novelty-review.md`
- `handoff/handoff-8-introduction-funnel-review-result.md`

Treat `article.tex` as authoritative when older notes conflict with it. In particular, some research notes and handoffs describe a common-quadratic Lyapunov certificate for active conditioning. The current manuscript does not contain that result. It explicitly makes no convergence claim while the conditioning factor is below one. Its current certificate is the maximal invariant subset of the Raw-Action Admissible Region under the linearized raw closed loop.

## Agreed introduction direction

The primary audience is control-systems researchers. Power electronics is the motivating application, not the theoretical boundary.

The agreed conceptual funnel is:

1. power electronics and converter control;
2. constraint-aware control under short computation times;
3. switched-affine models and periodic operation;
4. state-dependent mode selection versus switching-instant adjustment;
5. fixed-period cycle-to-cycle switching-time feedback;
6. minimum dwell-duration constraints and timing-action feasibility;
7. solver-free, direction-preserving conditioning and the invariant raw-action feasibility certificate.

Predictive control is a constraint-aware alternative, not the parent field of the proposed method. State-dependent mode-selection control should establish a neighboring branch, not occupy a full literature survey. Use reference periodic trajectory as the primary term when phase and timing matter; connect it to the established limit-cycle literature.

The introduction should eventually use one or two anchor citations per area, with additional citations only for specific methods or comparisons.

## Recency constraint

Candidate references must be no more than seven years old on 3 September 2026.

Apply the cutoff as follows:

- Prefer publications from 2020 through 2026.
- Accept a 2019 publication only when its official publication date is 3 September 2019 or later.
- For peer-reviewed articles, record both online-first and issue dates when they differ. Use the earliest official publication date to test the cutoff.
- For preprints, use the first public version date, not the date of a later revision.
- Do not recommend Kouro et al. 2009, Patiño et al. 2010, Flieller et al. 2006, Briat and Seuret 2013, Stellato et al. 2017, Repecho et al. 2017, or other older works as scene-setting references under this constraint.

Older works may still be identified in a separate historical-lineage note when they are the original source of a method, benchmark, or result. Do not silently replace direct attribution to an original source with a recent secondary citation. Report any conflict between the seven-year rule and scientifically necessary attribution.

## Fields to research

### 1. Power electronics and converter control

Find a recent review, tutorial, or broad peer-reviewed article that supports:

- semiconductor switching as the mechanism of power conversion;
- voltage, current, power, or stored-energy regulation;
- switching frequency and timing as control concerns;
- the practical importance of converter control.

Prefer a recent survey or tutorial over a narrow application paper.

### 2. Constraint-aware converter control under short computation times

Find publications supporting:

- explicit converter constraints in predictive or optimal control;
- short sampling or switching-cycle computation budgets;
- reduced decision spaces, candidate pruning, custom solvers, explicit control, or other methods used to reduce online cost;
- fixed-switching-frequency operation when relevant.

Separate finite-control-set mode selection from continuous switching-instant optimization. Do not present them as the same control variable.

### 3. Switched-affine and hybrid models for converters

Find publications connecting converter switch configurations to mode-dependent continuous dynamics, preferably switched-affine or hybrid-affine models. Favor work that retains interval-level switching behavior rather than relying only on averaged models.

### 4. Periodic trajectories and limit cycles in switched-affine systems

Find publications supporting:

- periodic trajectories or limit cycles as control objectives in switched or hybrid systems;
- sampled return-map or cycle-map stability analysis;
- phase-locked periodic-trajectory control when available.

Keep the distinction between a geometric target limit cycle and a phase-specific reference periodic trajectory.

### 5. Control mechanism: mode selection versus switching-instant adjustment

Find recent sources for both branches:

- state-dependent selection of the active subsystem;
- control or optimization through switching instants while a sequence or cycle structure is retained.

The purpose is to define the paper's actuator precisely, not to survey all switched-system controllers.

### 6. Fixed-period switching-time control and cycle-to-cycle feedback

Search specifically for:

- fixed mode order and fixed cycle period;
- interior switching instants as continuous control variables;
- one-cycle or cycle-sampled models;
- static or proportional cycle-to-cycle timing feedback;
- switching-instant sensitivity for mode-dependent dynamics.

This field may have sparse recent literature. Marcolino et al. 2021 is currently the closest eligible predecessor. Report scarcity rather than filling the section with only loosely related MPC papers.

### 7. Minimum dwell-duration constraints and action feasibility

Find recent work on:

- minimum or mode-dependent dwell-time constraints;
- dwell-constrained switched-system control;
- dwell-constrained switching-time or schedule optimization;
- feasibility filters or post-processing of requested switching actions;
- coupled dwell inequalities created by adjacent switching instants.

Distinguish stability under restricted switching signals from actuator-side correction of an infeasible timing command.

### 8. Closest alternatives to the proposed conditioner

Search deeply for methods using:

- radial or uniform scaling of a control vector;
- maximal feasible scalar contraction;
- direction-preserving constraint handling;
- projection onto a feasible timing polytope;
- componentwise clipping or saturation of switching instants;
- reference governors, command governors, or action filters applied to switching schedules;
- invariant or admissible sets for repeated raw-action feasibility.

This search is important for novelty positioning. Do not claim absence from the literature merely because keywords differ. Search neighboring terminology and follow citations from close papers.

## Source and download policy

Use only lawful sources. Preferred order:

1. open-access publisher PDF;
2. institutional repository accepted manuscript;
3. official author manuscript;
4. arXiv or another recognized preprint repository;
5. publisher abstract page when no lawful full text is available.

Do not use unauthorized mirrors or bypass access controls.

For every downloadable source:

- verify that the response is a real PDF, not an HTML error page;
- verify title, authors, year, publication venue, DOI, and publication status;
- record the direct PDF URL and its lawful source type;
- download it to `research/articles/` using the next available numeric prefix;
- update `research/articles/README.md` with the local path and provenance;
- inspect the full text and record the exact pages, sections, equations, or passages supporting the intended claim.

A downloadable preprint is not automatically strong. Prefer peer-reviewed journal or major conference publications when both are available.

## Abstract-only fallback

If downloadable sources for a field are too shallow, select a stronger peer-reviewed publication even when only its publisher abstract is accessible.

Label it `abstract-only`. Record:

- complete bibliographic data;
- DOI and publisher URL;
- why the venue and publication are stronger than the downloadable alternatives;
- exactly which claims the abstract supports;
- which claims cannot be verified without the full text.

Do not infer equations, guarantees, implementation details, experiments, or limitations from an abstract that does not state them. Do not download or archive an HTML abstract page as if it were a publication PDF.

## Quality and selection rules

- Prefer primary research, systematic reviews, surveys, and tutorials from reputable journals or major conferences.
- Prefer published work over preprints when relevance is comparable.
- Use recent surveys to establish broad areas and primary method papers for narrow technical claims.
- Avoid citation padding. Recommend at most two primary introduction citations per field unless a third source provides a genuinely different role.
- Separate evidence from interpretation. Mark every relevance or novelty conclusion as analysis rather than a fact stated by the source.
- Check all candidates against `references.bib` and `research/articles/README.md` before downloading duplicates.
- Verify whether claimed validation is simulation, embedded execution, hardware-in-the-loop, laboratory hardware, or deployment. Do not infer deployment from industrial motivation or author affiliation.
- Prefer final publications dated no later than 3 September 2026. Do not cite records that are future-dated or whose existence cannot be verified from a primary record.

## Required deliverables

Create `research/introduction-reference-review-2019-2026.md` containing:

1. the search date, databases or services queried, search strings, and access limitations;
2. a coverage matrix mapping each field to its strongest references;
3. for every selected reference:
   - complete citation;
   - publication and online-first dates;
   - DOI or stable identifier;
   - peer-reviewed, accepted-manuscript, or preprint status;
   - full-text, abstract-only, or unavailable status;
   - direct lawful download URL when available;
   - local PDF path when downloaded;
   - exact claim supported;
   - supporting pages or sections for full-text sources;
   - relevance to the introduction;
   - distinction from the present work;
4. a ranked recommendation of one or two citations per introduction area;
5. ready-to-add BibTeX entries for recommended sources not already in `references.bib`;
6. a list of current introduction citations that violate the seven-year rule, with recent replacements where scientifically valid;
7. a separate list of older sources that remain necessary for original attribution or benchmark provenance;
8. unresolved evidence gaps and fields where only abstract-level strong sources were found;
9. a conservative novelty assessment focused on the conditioner, coupled dwell feasibility, and invariant raw-action certificate as they exist in the current manuscript.

Update `research/articles/README.md` for every new local PDF. Do not edit `article.tex` or `references.bib` until the user reviews the research recommendations.

## Success criteria

The task is complete when:

- every funnel area has at least one recent, verified source or an explicit documented evidence gap;
- every recommended source satisfies the seven-year cutoff;
- downloadable references have lawful, validated local PDFs;
- stronger abstract-only references are clearly labeled and used only within the abstract's evidence;
- narrow control-variable distinctions are preserved;
- the report identifies any older citation that cannot be replaced without losing correct historical attribution;
- the report is sufficient to rewrite the introduction without another broad literature search.

## Suggested skills

- `research` for the literature search, source verification, and repository research report.
- `shared-understanding` if the seven-year rule conflicts with necessary attribution or if a field boundary changes during research.
- `unslop` for clear summaries and claim wording.
