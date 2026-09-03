# System and one-cycle model

Status: explanatory summary
Source of truth: `latex/article.tex`, Section 2; `study-guide.md`; `research-material/working-notes/linearization/linearization_v2_augmented.tex`
Read when: understanding the derivation behind the controller

## Plant and schedule

The plant has mode-dependent affine dynamics:

`dx/dt = A_sigma x + b_sigma`.

One cycle follows a fixed sequence of N modes between nominal boundaries from zero to the cycle period. The nominal dwell vector contains the elapsed time in each interval. The nominal trajectory returns to its cycle anchor after one complete cycle.

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

No approximation is used in this propagation step.

## First-order model

The interval durations are expanded around their nominal values. The ordered product is expanded while retaining terms with at most one dwell perturbation. Terms that multiply a state error by a dwell change are second order and are discarded.

After subtracting the nominal periodic cycle and projecting back to the physical state, the local cycle model is:

`e_next = Phi e + G_d delta_d + higher-order terms`.

Substitution of the difference-matrix relation gives the controller coordinates:

`e_next = Phi e + Gamma_tau delta_tau + higher-order terms`.

Here `Phi` is the nominal cycle matrix and `Gamma_tau` is the switching-instant sensitivity matrix.

## Timing sensitivity

The column associated with an interior switching instant is the downstream nominal propagation of the jump between the two adjacent affine vector fields at the switching state.

This explains why a timing displacement affects the next cycle state: it trades a small amount of time between adjacent modes. The state at the switching point is unchanged to first order, while the vector-field difference is propagated through the remaining intervals.

When all intervals share one state matrix and differ only in their actuator forcing, the model reduces to the switched-actuator formulation used by Marcolino et al. For mode-dependent state matrices, the ordered downstream product and state-dependent vector-field jump are required.
