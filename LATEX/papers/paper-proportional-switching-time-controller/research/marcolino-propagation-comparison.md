# Propagation-model comparison with Marcolino

## Conclusion

The paper's switched-affine model is a strict dynamic generalization of Marcolino, Galvão, and Kienitz (2021). Marcolino assumes one constant plant matrix and switches only a piecewise-constant actuator input. The present paper allows every active mode to have its own state matrix and affine term.

This is a valid relative contribution claim. It does not by itself establish global novelty because Patiño, Riedinger, and Ruiz (2010) already derive switching-instant sensitivities for mode-dependent cyclic switched systems. An earlier qualification manuscript by the author also contains the switched-affine extension, but it is unpublished and is not cited as prior literature in the paper.

## Model classes

### Marcolino

Marcolino, Eq. (1), assumes

\[
\dot x=A_cx+B_cu(t),
\]

where `A_c` and `B_c` are constant and the actuator level `u(t)` is piecewise constant. Switching changes the affine forcing `B_c u`; it does not change the state matrix.

For multiple actuators, Eq. (29) retains the same constant state matrix:

\[
\dot x=A_cx+\sum_l B_{c,l}u_l(t).
\]

### Present paper

The present paper, Eq. `plant`, assumes

\[
\dot x=A_{\sigma(t)}x+b_{\sigma(t)}.
\]

Both the state matrix and affine term may change with the active mode. This includes topology-changing converters in which switch configurations alter the capacitor and inductor couplings.

Marcolino's class is recovered by setting

\[
A_i=A_c,\qquad b_i=B_cu_i.
\]

The converse is generally impossible when two modes have different state matrices. Representing `(A_i-A_j)x` through Marcolino's switched input would require a state-dependent or bilinear actuator, outside Marcolino's model.

## One-cycle state transition

### Marcolino

Because the state matrix is constant over the complete cycle, the state-error transition is

\[
\Phi_M=e^{A_cT}.
\]

Marcolino's Eqs. (14), (19), and (28) use this same transition for every cycle.

### Present paper

Let

\[
E_i=e^{A_i\Delta\bar t_i}.
\]

The state-error transition is the ordered product

\[
\Phi=E_N\cdots E_1.
\]

The order matters because mode-dependent state matrices generally do not commute. When every `A_i=A_c`, the product reduces to

\[
E_N\cdots E_1=e^{A_c\sum_i\Delta\bar t_i}=e^{A_cT}=\Phi_M.
\]

## Switching-instant sensitivity

### Marcolino

For an internal switching instant `i`, Marcolino's Eqs. (15)--(19) and (25)--(28) give, subject to the paper's input-jump sign convention,

\[
\Gamma_{M,i}
=e^{A_c(T-\bar t_i)}B_c(u_{i-1}-u_i).
\]

The downstream propagation is a single exponential because `A_c` is constant. The vector-field jump is independent of the state.

### Present paper

The present paper's Eq. `gamma` gives

\[
\Gamma_{\tau,i}
=E_N\cdots E_{i+1}
\left[
(A_i-A_{i+1})\bar x(\bar t_i)+b_i-b_{i+1}
\right].
\]

This sensitivity has two additions relative to Marcolino:

1. downstream propagation uses the ordered transitions of all later modes;
2. the vector-field jump contains the state-dependent term `(A_i-A_{i+1}) x`.

Specializing to `A_i=A_c` and `b_i=B_cu_{i-1}` yields

\[
\Gamma_{\tau,i}
=e^{A_c(T-\bar t_i)}B_c(u_{i-1}-u_i)
=\Gamma_{M,i}.
\]

Therefore Marcolino's timing Jacobian is exactly a special case of the present equation, apart from notation and input-jump sign convention.

## Shared assumptions

Both formulations:

- use a fixed nominal sequence;
- fix the cycle start and end, leaving `N-1` independent interior offsets;
- derive a local first-order timing model;
- assume the switching order does not change;
- use the model cycle to cycle to regulate a periodic trajectory.

The present paper generalizes the active dynamics, not these timing assumptions.

## Defensible wording

> Marcolino et al. derive a cycle model for an LTI plant whose piecewise-constant actuator input changes at prescribed switching instants. Here this construction is extended to a fixed sequence of general affine modes, allowing both the state matrix and affine vector to change with the active mode. The resulting one-cycle transition is an ordered product of mode-dependent flows, and each timing-sensitivity column contains the propagated jump between adjacent affine vector fields. Marcolino's model is recovered when all modes share the same state matrix and differ only through the actuator input.

Avoid claiming that switching-instant sensitivity or mode-dependent switched-system propagation is globally new. Patiño et al. (2010), Proposition 7 and Eqs. (19)--(25), already contain the corresponding vector-field-jump sensitivity for cyclic switched systems and an affine converter augmentation.

## Primary sources

- M. H. Marcolino, R. K. H. Galvão, and K. H. Kienitz, “Predictive Control of Linear Systems with Switched Actuators Subject to Dwell-Time Constraints,” *Journal of Control, Automation and Electrical Systems*, 32(1), 1–17, 2021. DOI: [10.1007/s40313-020-00667-9](https://doi.org/10.1007/s40313-020-00667-9). Relevant equations: (1), (14)--(19), (25)--(34).
- D. Patiño, P. Riedinger, and F. Ruiz, “A Predictive Control Approach for DC–DC Power Converters and Cyclic Switched Systems,” *2010 IEEE International Conference on Industrial Technology*, 1259–1264, 2010. Relevant result: Proposition 7, Eqs. (19)--(25).
Unpublished internal background: D. Vieira, *Predictive Control of Switched Affine Systems Subjected to Dwell Time Constraints*, qualification manuscript, Chapter 4. This item is not a published source and is not cited in the paper.
