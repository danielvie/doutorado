## Review

### Correct
- `article.tex`, section **Fixed-period one-cycle model**: the four-subsection progression is coherent and matches `GOAL.md`.
- `eq:exact-augmented-cycle` correctly represents affine propagation using augmented matrix exponentials.
- `eq:ordered-product-first-order` and `eq:augmented-dwell-linearization` explicitly retain first-order terms and discard mixed error–dwell terms.
- `eq:incidence-map` correctly maps the \(N-1\) interior offsets to zero-sum dwell changes.
- `eq:timing-jacobian` correctly recovers the propagated affine vector-field difference.
- The credits to Patiño and Marcolino, and the specialization in `eq:marcolino-specialization`, align with `research/novelty-review.md`.

### Blocker
- **Incorrect explanatory claim**, paragraph beginning “The bracket is the jump…” after `eq:timing-jacobian`: moving an instant later does change the state at the delayed switching instant by \(f_i\delta\tau_i+O(\delta\tau_i^2)\). The derivation’s bracket is instead the pre-switch minus post-switch vector-field difference. This should be corrected to avoid misunderstanding the central sensitivity result.

- **Physical-domain assumption is unstated**, `eq:exact-augmented-cycle`: the map is called an exact plant propagation, but no condition \(d_{k,i}=\bar d_i+\delta d_{k,i}>0\) is given. Matrix exponentials remain formally defined for negative durations, but such schedules are not physical. This matters because the later case study explicitly reports negative raw dwells.

### Changes worth making now
- Define \(\bar{\vect d}=(\bar d_1,\ldots,\bar d_N)^{\mathsf T}\), \(D\in\mathbb R^{N\times(N-1)}\), and the dimension of \(\vect 1\) near `eq:incidence-map`.
- State explicitly that \(\sigma(t)=\omega_i\) on interval \(i\), and clarify that \(\omega_i\) is a dynamics index rather than necessarily a physical switch-state ID.
- Define \(\mathcal X_k=[\vect{x}_k^{\mathsf T}\ 1]^{\mathsf T}\) and \(\bar{\mathcal X}_0=[(\vect{x}^{\star})^{\mathsf T}\ 1]^{\mathsf T}\) before `eq:exact-augmented-cycle`.
- Add one sentence that `eq:cycle-model` is a local first-order approximation as \((\vect e_k,\dtau_k)\to0\); this prevents readers from applying it to the large-error simulation as an exact model.

### Optional polish
- Explain directly that \(\bar{\vect{x}}(\bar t_i)=\Pi\bar{\mathcal X}_i\) before `eq:timing-jacobian`.
- Briefly distinguish \(\widetilde\Phi\) (augmented matrix) from \(\Phi\) (physical-state Jacobian).
- Replace “jump from mode \(\omega_i\) to mode \(\omega_{i+1}\)” with “pre-switch minus post-switch vector-field difference,” or explicitly state the sign convention.

### Questions requiring author input
- Is the exact map intentionally extended formally to negative durations for analysis, or should its domain be restricted to positive dwells?
- Should the sign convention in `eq:timing-jacobian` be explicitly matched to the convention used by Marcolino?
- Are the \(\omega_i\) labels intended as dynamics indices throughout, including the converter specialization?

### Residual risks
- Without the sign and physical-domain clarifications, a first-time control reader may believe the switching state is unchanged under timing displacement and may interpret negative-duration propagation as physically valid.