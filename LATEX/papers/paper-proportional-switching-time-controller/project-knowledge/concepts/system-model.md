# System and one-cycle model

Status: explanatory summary
Source of truth: `latex/main.tex`, Section 2; `docs/study-guide.md`; `research-material/working-notes/linearization/linearization_v2_augmented.tex`
Read when: understanding the derivation behind the controller

## Plant and schedule

The plant has mode-dependent affine dynamics:

`dx/dt = A_sigma x + b_sigma`.

One cycle follows a fixed sequence of N modes between nominal boundaries from zero to the cycle period. The nominal dwell vector contains the elapsed time in each interval. The nominal trajectory returns to its cycle anchor after one complete cycle. The manuscript denotes the anchor by `bar x(0)`, not a starred state.

Only the N minus 1 interior switching instants are free. The first and last cycle boundaries remain fixed.

## Two timing coordinate systems

The controller works with interior switching-instant offsets. The dwell constraints work with changes in all N dwell durations.

The difference matrix D maps the first coordinate system to the second:

`delta_d = D delta_tau`.

Each column of D lengthens one interval and shortens the adjacent interval. The dwell changes sum to zero because the columns of D sum to zero. Therefore every offset vector preserves the cycle period.

## Exact affine propagation

Affine interval dynamics become linear after appending a constant state coordinate:

`X = [x; 1]`.

Each interval has an augmented generator containing its state matrix and affine vector. The exact transition is the matrix exponential of that generator multiplied by the interval duration. One exact cycle is the ordered product of the N interval exponentials.

No approximation is used in this propagation step. Section 2 uses the working note's calligraphic `X(t)` and nominal state `bar X(t)`. For a representative cycle, `Delta t_i = d_{k,i}`, `Delta bar t_i = bar d_i`, and `delta t_i = delta d_{k,i}`. The last quantity is a duration change, not a switching-instant offset. The cycle endpoints stay fixed so actual and nominal terminal states are compared at the same time.

## First-order model

The derivation follows `linearization_v2_augmented.tex`. It first subtracts the nominal propagation to form the exact terminal error. It then expands one exponential, shows the product of expanded factors, and expands that ordered product explicitly. Substitution into the error equation cancels the nominal term. The expansion is joint in the initial error and duration changes, so products of two duration changes and products of an initial error with a duration change are second order.

The explicit terminal-error sum appears before its coefficients are collected into `Gamma`. Only then is the complete nominal product named `Phi`, giving the compact augmented model. The augmented quantities use no tildes: `e(t)` has `n+1` components, `Phi` is `(n+1) x (n+1)`, and `Gamma` is `(n+1) x N`. After projection, `e_k`, or `e` without the cycle index, denotes the physical error with `n` components.

A separate subsection projects back to the physical state, giving:

`e_next = Phi_x e + G_d delta_d + higher-order terms`.

Substitution of the difference-matrix relation gives the controller coordinates:

`e_next = Phi_x e + Gamma_tau delta_tau + higher-order terms`.

Here `Phi_x = Pi Phi iota` is the physical nominal cycle matrix, `G_d = Pi Gamma` contains physical dwell sensitivities, and `Gamma_tau = G_d D` is the switching-instant sensitivity matrix. The full augmented nominal product `Phi` has an auxiliary unit eigenvalue; stability is tested on the physical error dynamics using `Phi_x`.

Numerical code and saved results retain the field names `Phi` and `Gamma` for the physical matrices denoted `Phi_x` and `Gamma_tau` in the manuscript. This publication notation change does not rename numerical fields or alter their values.

## Timing sensitivity

The column associated with an interior switching instant is the downstream nominal propagation of the jump between the two adjacent affine vector fields at the switching state.

This explains why a timing displacement affects the next cycle state: it trades a small amount of time between adjacent modes. The state at the switching point is unchanged to first order, while the vector-field difference is propagated through the remaining intervals.

When all intervals share one state matrix and differ only in their actuator forcing, the model reduces to the switched-actuator formulation used by Marcolino et al. For mode-dependent state matrices, the ordered downstream product and state-dependent vector-field jump are required.
