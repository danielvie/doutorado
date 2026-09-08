# Handoff: verify and integrate six additional references

## Next-session objective

Verify six proposed references from lawful, downloadable full text, then add only the references that support a specific claim in the current manuscript. The target is approximately 15 distinct cited references, up from the current 9. Keep the four-layer introduction and avoid restoring the former broad literature survey.

Do not implement citations before checking the primary sources. The integration should make small additions to existing sentences or add short supporting sentences in the model, conditioning, and case-study sections. It should not change the contribution hierarchy or the paper's conservative novelty claims.

## Existing project state

- Current manuscript: `article.tex`
- BibTeX records: `references.bib`
- Current reference inventory and explanation of the 16 uncited records: `handoff/reference-usage-review.md`
- Current scope and non-goals: `GOAL.md`
- Terminology: `CONTEXT.md`
- Novelty boundary: `research/novelty-review.md`
- Citation strategy: `handoff/handoff-3-specialization-funnel-and-citation-integration.md`
- Build task: `task build` from the project root

The current manuscript cites 9 distinct records 15 times. `references.bib` contains 25 records, but the 16 uncited records should not be activated merely to increase the count. Many are outside the final fixed-period, fixed-mode-order timing-feedback problem.

## Proposed candidates

These candidates were identified as distinct from the existing 25 records. The URLs below are for audit. Verify the publication metadata and the relevant claim from the primary PDF before adding a BibTeX entry.

| Proposed key | Reference | Landing page | Downloadable full text | Intended role |
|---|---|---|---|---|
| `flieller2006limitCycles` | Damien Flieller, Pierre Riedinger, and Jean-Paul Louis, "Computation and Stability of Limit Cycles in Hybrid Systems," *Nonlinear Analysis: Theory, Methods & Applications*, 64(2), 352--367, 2006. | [DOI](https://doi.org/10.1016/j.na.2005.06.054) | [HAL PDF](https://hal.science/hal-00119807v1/document) | Prior use of switching-time sensitivities, periodic-orbit computation, and sampled-time local stability. |
| `repecho2017switchingFrequency` | Víctor Repecho, Domingo Biel, Josep M. Olm, and Enric Fossas Colet, "Switching Frequency Regulation in Sliding Mode Control by a Hysteresis Band Controller," *IEEE Transactions on Power Electronics*, 32(2), 1557--1569, 2017. | [DOI](https://doi.org/10.1109/TPEL.2016.2546382) | [UPCommons PDF](https://upcommons.upc.edu/bitstream/2117/99560/1/paper_double_column_final.pdf) | Adjacent example of feedback that regulates switching timing, with a different actuator from the present switching-instant offsets. |
| `stellato2017fcsMpc` | Bartolomeo Stellato, Tobias Geyer, and Paul J. Goulart, "High-Speed Finite Control Set Model Predictive Control for Power Electronics," *IEEE Transactions on Power Electronics*, 32(5), 4007--4020, 2017. | [DOI](https://doi.org/10.1109/TPEL.2016.2584678) | [arXiv PDF](https://arxiv.org/pdf/1510.05578) | Predictable, bounded online computation in power-electronics MPC. |
| `albea2021hybridAffinePwm` | Carolina Albea-Sanchez, Antonino Sferlazza, Fabio Gómez-Estern, and Francisco Gordillo, "Control of Power Converters With Hybrid Affine Models and Pulse-Width Modulated Inputs," *IEEE Transactions on Circuits and Systems I: Regular Papers*, 68(8), 3485--3494, 2021. | [DOI](https://doi.org/10.1109/TCSI.2021.3083900) | [HAL PDF](https://laas.hal.science/hal-03326994v1/file/PWM_ST19.pdf) | Hybrid-affine converter modeling with PWM and Lyapunov analysis, relevant to the paper's exact converter model. |
| `briat2013dwellTimes` | Corentin Briat and Alexandre Seuret, "Affine Characterizations of Minimal and Mode-Dependent Dwell-Times for Uncertain Linear Switched Systems," *IEEE Transactions on Automatic Control*, 58(5), 1304--1310, 2013. | [DOI](https://doi.org/10.1109/TAC.2012.2220031) | [arXiv PDF](https://arxiv.org/pdf/1209.0444) | Broader dwell-time feasibility and stability characterization. It must not be presented as prior art for the proposed scalar conditioner. |
| `fiore2016contraction` | Davide Fiore, S. John Hogan, and Mario di Bernardo, "Contraction Analysis of Switched Systems via Regularization," *Automatica*, 73, 279--288, 2016. | [DOI](https://doi.org/10.1016/j.automatica.2016.06.028) | [arXiv PDF](https://arxiv.org/pdf/1507.07126) | General contraction context for the common-Lyapunov paragraph. Use only if the paragraph needs that context. |

Two reserve candidates were not accepted for this pass because their primary full text was not verified:

- Deaecto, Souza, and Geromel, "Chattering Free Control of Continuous-Time Switched Linear Systems." The publisher PDF returned HTTP 403.
- Zhuang, Gao, and Shi, "Model Predictive Control of Switched Linear Systems With Persistent Dwell-Time Constraints: Recursive Feasibility and Stability." Metadata was available, but no lawful downloadable PDF was located.

Do not add the reserve candidates without a later source-verification step.

## Verification plan

### 1. Check identity and duplication

For each candidate:

1. Open the DOI or stable landing page.
2. Confirm authors, exact title, venue, volume, issue, pages, year, and DOI.
3. Search `references.bib` for the title, DOI, and author names. Confirm that the candidate is not already present under another key.
4. Check whether the downloadable file is the published paper, an author manuscript, or a preprint. Record the source type in the audit notes.

Use a stable proposed key only after the identity check. Do not silently replace a published year with an arXiv submission year when the BibTeX record is for the journal article.

### 2. Audit the primary PDF

For each candidate, download the PDF manually or with a lawful public URL and check:

- the first page matches the landing-page metadata;
- the paper contains the method or result assigned to it above;
- the intended statement is supported by the paper itself, not only by an abstract or search-result snippet;
- the result is genuinely distinct from Patiño, Marcolino, Saeed, Yang, Augustine, Sakha/Kamalapurkar, Egidio, Russo, and Boyd;
- the paper does not force a broader novelty claim than the current article can support.

If a source cannot be downloaded or the relevant claim cannot be verified, leave it out. A reference count of 14 is preferable to an unverifiable reference count of 15.

### 3. Record the claim before writing

For every accepted paper, write one sentence in the working notes with this form:

> This paper supports [specific factual claim]. It does not establish [claim that must remain outside the present paper].

This prevents citations from becoming general name-dropping. Keep the full source notes outside the article unless they are needed for a factual statement.

## Minimal integration plan

The article's current prose should remain recognizable. Add at most one short sentence or clause per accepted reference, and cite the source immediately after the claim it supports.

### Introduction, implementation pressure

Use `stellato2017fcsMpc` in the first paragraph, after the existing fixed-frequency MPC sentence. The sentence should say that high-speed FCS-MPC uses implementation-specific approximations or short horizons to meet tight execution budgets. Then return to the paper's contrast: the proposed conditioner performs a scalar feasibility scan after static feedback, rather than solving an online predictive problem.

Do not add another paragraph about converter MPC. The current Saeed, Yang, Augustine, and Sakha/Kamalapurkar citations already establish the computation-pressure point.

### Introduction, timing-feedback contrast

Use `repecho2017switchingFrequency` only if the paragraph explicitly says that other controllers regulate switching timing. State that its mechanism changes a hysteresis band or switching-frequency behavior, whereas the present actuator shifts the interior instants of a prescribed cycle. If this distinction requires too much explanation, omit the reference.

### One-cycle model, switching sensitivity

Use `flieller2006limitCycles` near the existing sentence at `article.tex:198`. The citation should support the broader historical point that hybrid limit-cycle computation and switching-time sensitivity have been studied. Keep Patiño as the power-converter and mode-dependent sensitivity reference. Do not claim that the present paper introduces switching-time sensitivity for the first time.

### Dwell-time conditioning

Use `briat2013dwellTimes` at the first discussion of dwell constraints or near the offline certificate. Phrase it as broader dwell-time stability or feasibility context. Do not imply that Briat and Seuret use the proposed radial contraction or that their result proves the current conditioned matrix family.

### Common-Lyapunov paragraph

Use `fiore2016contraction` only if it improves the explanation of contraction-based switched-system analysis. A safe use would distinguish general contraction criteria from this paper's elementary endpoint-norm argument. If the paragraph reads cleanly with Boyd alone, do not force this citation. The target count is approximate.

### Converter case study

Use `albea2021hybridAffinePwm` near the converter model at `article.tex:287`. Say that hybrid-affine converter models with explicit switching or PWM behavior have been studied, then explain that this case study uses exact augmented propagation for a prescribed nine-interval sequence. Do not imply that the cited paper uses the same converter, timing coordinates, or conditioner.

## Writing constraints

- Keep the introduction's four paragraphs and their current order.
- Do not create a related-work section solely to house the six references.
- Do not add a paper-by-paper list.
- Keep Patiño and Marcolino as the closest prior work.
- Do not cite any paper as support for the article's own conditioner or common-Lyapunov theorem.
- Preserve the current novelty boundary. The contribution remains a direction-preserving feasible scalar correction and its conditioned-family certificate.
- Keep the local nonlinear stability and simulation limitations unchanged.
- Use plain, direct prose. Avoid inflated claims such as "comprehensive," "groundbreaking," or "first-ever."

## Implementation and validation sequence

1. Verify all six PDFs and record the accepted/rejected status.
2. Add only accepted BibTeX records to `references.bib`, matching the existing `sn-mathphys-ay` style.
3. Insert the smallest prose changes needed for accepted citations.
4. Run a source-level citation count and confirm the target is 14 or 15 distinct keys.
5. Run `task build`.
6. Check the LaTeX log for undefined citations, duplicate keys, missing bibliography entries, or overfull boxes introduced by the new prose.
7. Inspect the resulting PDF for paragraph density and page count. The additions should not recreate the earlier oversized literature funnel.
8. Re-read the modified paragraphs against `research/novelty-review.md` and the verified PDFs.
9. Update `handoff/reference-usage-review.md` only after the final citation set is known.

Success means that every new citation has a verified public full text, a specific job in the article, and no material change to the paper's central argument.

## Suggested skills

- `research` for primary-source and downloadable-PDF verification.
- `unslop` for the small prose edits in `article.tex`.
- `domain-modeling` only if a new source creates terminology conflicts around dwell time, switching instants, or limit cycles.
- `handoff` after implementation to record the final verified citation set and any rejected candidates.
