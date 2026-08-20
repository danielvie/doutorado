## Review

### Blockers

- **None found.** The four-subsection derivation is mathematically coherent; no sign, dimensional, or first-order-expansion error was identified.

### Changes worth making now

- **Minor — misleading switching-state explanation:** `article.tex:198`, paragraph beginning “The bracket is the jump…,” says moving an instant trades dwell “without changing the state at that instant to first order.” The state has no reset and remains continuous, but the state reached at the displaced instant generally changes by \(f_{\omega_i}(\bar x(\bar t_i))\delta\tau_i+O(\delta\tau_i^2)\). The correct terminal sensitivity is nevertheless the propagated difference \(f_{\omega_i}-f_{\omega_{i+1}}\) in `eq:timing-jacobian`. Replace the quoted claim with a continuity/no-reset statement.

- **Minor — state the admissible neighborhood for the “exact” schedule:** `article.tex:87`, after `eq:incidence-map`, says every offset vector preserves \(T\), and `eq:exact-augmented-cycle` then calls the propagation exact. Algebraically the zero-sum statement is correct, but arbitrary offsets can make a duration nonpositive or reorder boundaries. Qualify the physical one-cycle map and local expansion by requiring
  \[
  \bar d_i+(D\delta\tau)_i>0
  \]
  (or the applicable dwell bound) for every interval. This does not alter the derivation.

- **Minor — make the Marcolino sign crosswalk auditable:** `article.tex:206`, paragraph following `eq:marcolino-specialization`, says “apart from the sign convention for the input jump” without identifying the two conventions. Under this paper’s positive-later offset convention and \(b_i=B_cu_{i-1}\), the displayed \(B_c(u_{i-1}-u_i)\) sign is correct. State Marcolino’s corresponding symbol/equation and whether the reversed sign belongs to the input-jump definition or timing-offset definition.

### Correct

- **Timing coordinates and signs:** `article.tex:69–87`, especially `eq:incidence-map`, correctly gives \(D\in\mathbb R^{N\times(N-1)}\), with
  \(\delta d_i=\delta\tau_i-\delta\tau_{i-1}\). Thus a positive offset lengthens interval \(i\), shortens \(i+1\), and satisfies \(\mathbf1^\mathsf TD=0\).

- **Exact augmented propagation:** `article.tex:89–122`, `eq:augmented-generator` through `eq:exact-augmented-error`, has the correct right-to-left product order and correctly represents each affine interval by an augmented exponential. The terminal nominal term cancels because the augmented anchor is fixed by the nominal product.

- **First-order remainder accounting:** `article.tex:127–168`, `eq:interval-first-order` through `eq:dwell-linearization`, correctly differentiates \(e^{F_is}\), inserts one duration derivative at each position of the ordered product, and discards the mixed \(\delta d_i\widetilde e_k\) terms. Collecting these and the quadratic duration terms as
  \(O(\|[e_k^\mathsf T\ \delta d_k^\mathsf T]\|^2)\) is valid locally. This agrees with the authority derivation in `../../../research-material/working-notes/linearization/linearization_v2_augmented.tex:146–158`.

- **Switching-jump sensitivity:** `article.tex:177–198`, `eq:cycle-model` and `eq:timing-jacobian`, has the correct sign:
  delaying instant \(i\) contributes \(f_{\omega_i}(\bar x(\bar t_i))-f_{\omega_{i+1}}(\bar x(\bar t_i))\), propagated through intervals \(i+1,\ldots,N\). The factorization correctly uses the commutation of \(F_{i+1}\) with \(e^{F_{i+1}\bar d_{i+1}}\). This matches the prior-art characterization in `research/novelty-review.md:35,70`.

- **Marcolino specialization:** `article.tex:200–206`, `eq:marcolino-specialization`, follows algebraically from common \(A_c\): all remaining transitions collapse to \(e^{A_c(T-\bar t_i)}\), and the affine jump becomes \(B_c(u_{i-1}-u_i)\). The section presents this as a specialization rather than novel switching-sensitivity theory, consistent with `GOAL.md:9,16–18` and `research/novelty-review.md:5,34–38,84–93`.

- **Independent numerical corroboration exists:** `results/metrics.tex:13–15` reports relative finite-difference errors \(8.518\times10^{-12}\) for \(\Phi\), \(8.344\times10^{-11}\) for \(\Gamma_\tau\), and residual slope \(2.000\). `results/jacobian_checks.csv` contains elementwise analytical/central-difference comparisons, supporting the textual signs and first-order remainder.

### Optional polish

- `article.tex:91`, paragraph beginning “Affine dynamics do not compose…,” could say that they do not compose using the physical-state homogeneous transition matrices *alone*; affine maps themselves do compose.
- Explicitly stating that the switched ODE has no state resets would make the use of one common switching state in `eq:timing-jacobian` fully explicit.
- Giving \(D\)’s dimensions and full-column-rank property would strengthen the statement that the \(N-1\) offsets are independent, although the indexed definition already implies it.

### Questions requiring author input

- Which exact Marcolino equation and symbol define the opposite “input jump” convention referenced after `eq:marcolino-specialization`? The displayed specialization is correct, but the citation comparison should identify that convention explicitly.

### Residual risks

- The available reader did not provide searchable text extraction from the Patiño and Marcolino PDFs. Their equation-level support was checked through `references.bib` and the source audit in `research/novelty-review.md`, which identifies Patiño Proposition 7, equations (19)–(24), and Marcolino equations (19), (27), and (28).
- MATLAB generation and LaTeX compilation were not rerun in this read-only review; generated Jacobian and residual artifacts were inspected directly.