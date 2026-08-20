## Review

### Correct
- The four-subsection order is coherent: timing coordinates → exact augmented propagation → dwell linearization → independent switching-instant model.
- Equations `eq:incidence-map`, `eq:exact-augmented-cycle`, `eq:ordered-product-first-order`, and `eq:cycle-model` correctly connect offsets, dwell changes, propagation, and the first-order cycle model.
- The remainder terms in `eq:augmented-dwell-linearization` and `eq:cycle-model` correctly account for discarded dwell-squared and error–dwell cross terms.
- Equation `eq:timing-jacobian` correctly exposes the propagated affine vector-field difference. The Marcolino reduction in `eq:marcolino-specialization` is consistent with `research/marcolino-propagation-comparison.md` and the novelty positioning in `research/novelty-review.md`.

### Fixed
- None; this was a read-only review.

### Blocker
- None identified.

### Changes worth making now
- **Medium — domain qualification:** In `article.tex`, subsection **“Switched-affine cycle and timing coordinates,”** state that the physical exact map assumes all applied dwells remain positive and preserve the fixed mode order. Otherwise `eq:exact-augmented-cycle` is formally evaluable for negative durations, although such schedules are not physical. This matters because the later case study intentionally reports negative raw dwells.
- **Medium — switching-jump sign/meaning:** In the paragraph beginning **“The bracket is the jump…”**, identify the bracket explicitly as \(f_{\omega_i}(\bar x(\bar t_i))-f_{\omega_{i+1}}(\bar x(\bar t_i))\), i.e. pre-switch minus post-switch under the convention that a positive offset delays the switch. “Jump from mode \(\omega_i\) to mode \(\omega_{i+1}\)” is directionally ambiguous.
- **Medium — algebraic bridge:** Between `eq:cycle-model` and `eq:timing-jacobian`, show the intermediate augmented identity
  \[
  \widetilde g_i-\widetilde g_{i+1}
  =\phi_N\cdots\phi_{i+1}(F_i-F_{i+1})\bar{\mathcal X}_i.
  \]
  The current phrase **“factoring the adjacent terms yields”** makes the key switching-jump step unnecessarily implicit.
- **Low — hidden initial condition:** When defining \(\bar{\mathcal X}_i\), state explicitly that \(\bar{\mathcal X}_0=[(\vect{x}^{\star})^{\mathsf T}\ 1]^{\mathsf T}\). This removes a small notation gap in `eq:augmented-dwell-sensitivity`.
- **Low — remainder interpretation:** Consider writing the remainder as \(\mathcal O(\|\ddwell_k\|^2+\|\vect e_k\|\,\|\ddwell_k\|)\), and similarly after substitution by \(D\). This makes clear that the exact map is affine in the initial state and contains no \(e_k^2\) term.

### Optional polish
- Replace **“Affine dynamics do not compose as a product of transition matrices”** with “ordinary state-transition matrices alone are insufficient to compose affine flows”; affine maps themselves do compose.
- Replace **“switching state”** in the paragraph after `eq:timing-jacobian` with **“state at the switching instant”**, consistent with `CONTEXT.md`.
- Expand the Marcolino paragraph to state the source indexing/sign convention explicitly instead of only saying **“apart from the sign convention.”**

### Questions requiring author input
- Should the exact map’s stated domain be strictly positive dwells, or the stronger applied bound \(d_i\ge d_{\min}\)?
- Should the Marcolino comparison retain the current sign-convention wording, or explicitly map the paper’s \(u_{i-1},u_i\) indexing to Marcolino’s notation?

### Residual risks
- The derivation remains local in timing perturbations; it does not justify physical propagation after dwell-order inversion.
- The nonlinear stability limitation is correctly deferred to the conditioning section, but the domain caveat should be made explicit in this model section.