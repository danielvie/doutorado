## Review

### Blockers
- None.

### Worthwhile fixes
- **Moderate — `article.tex:33`, anchor “the raw offset vector is multiplied by the largest factor in \([0,1]\)”**: State the required nominal-feasibility hypothesis. The proof assumes a **strict nominal dwell margin** at `article.tex:219–224`; without it, a feasible factor need not exist and direction preservation at the zero factor becomes problematic. Suggested qualification: “For a nominal schedule with strict dwell margin, …”
- **Moderate — `article.tex:33`, anchor “still settles in 6 cycles, against 20 for a conservative law that never violates it”**: This over-compresses simulation evidence into an unqualified settling claim. The evidence is an exact nonlinear, 100-cycle simulation (`article.tex:357–365`, `results/metrics.tex:28–37`), and “settling” specifically means first crossing of \(\|S_x^{-1}e_k\|_2<0.01\) (`article.tex:363–365`). The conservative law’s reported feasibility is observed in that run, with minimum dwell \(15.502\,\mu\mathrm{s}\), not a general guarantee (`results/metrics.tex:36`). Prefer wording such as “In an exact nonlinear simulation, … reaches the stated error threshold at cycle 6, versus 20 for a conservative law that remained feasible throughout the run.”

### Optional polish
- **Low — `article.tex:33`, anchor “which lets the state matrix and the affine term change together”**: “Allows both the state matrix and affine term to vary by mode interval” is more precise and matches the mode-dependent formulation at `article.tex:290–306`.
- **Low — `article.tex:33`, anchor “or even reverse it”**: “Make the requested dwell negative” or “invert adjacent cycle boundaries” is technically clearer; the demonstrated raw dwell is \(-43.045\,\mu\mathrm{s}\) (`results/metrics.tex:34`, `article.tex:385`).

### Author decisions
- None required beyond deciding whether abstract length permits the two recommended qualifications above.

### Correct
- The conditioned matrix segment and arbitrary-sequence certificate are accurately stated: `article.tex:252–273`.
- The abstract correctly limits the common-Lyapunov result to the linearized family and the exact nonlinear guarantee to a local neighborhood: `article.tex:278`.
- Numerical values match generated results: raw dwell \(-43.045\,\mu\mathrm{s}\), applied bound \(3.000\,\mu\mathrm{s}\), and threshold cycles \(6/20\) (`results/metrics.tex:28–35`).
- Contribution framing avoids first-ever and global claims. The body explicitly credits Patiño et al. and Marcolino et al. as prior foundations (`article.tex:45–47`, `references.bib:13–21`, `references.bib:230–237`).

### Residual risks
- Numerical values were checked against `results/metrics.tex`, but generation scripts/results were not rerun under the strict read-only instruction.
- Prior-art framing was checked against the manuscript and bibliography metadata, not independently against the full cited publications.