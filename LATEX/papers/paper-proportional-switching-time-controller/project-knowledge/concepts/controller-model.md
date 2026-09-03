# Controller and dwell conditioning

Status: explanatory summary
Source of truth: `latex/article.tex`, Section 3; `scripts/condition_dwell_times.m`; `GOAL.md`
Read when: understanding what the proposed control layer does

## Raw action

The static feedback law maps the cycle-start error to a complete vector of interior switching-instant offsets:

`delta_tau_raw = -K e`.

The corresponding raw linearized cycle matrix is:

`Acl = Phi - Gamma_tau K`.

The feedback law itself is a standard static state-feedback or LQR law. The conditioning layer operates after this raw action has been computed.

## Feasibility calculation

Let the nominal dwell margin be the nominal dwell vector minus the required minimum dwell duration. For a raw offset, compute the requested dwell changes:

`q = D delta_tau_raw`.

Only negative entries of q can violate a lower dwell bound. Each such entry produces an upper bound on the common scalar factor. The conditioner chooses the smallest of those bounds and one.

The applied action is:

`delta_tau_applied = beta delta_tau_raw`.

If the raw action is already feasible, beta equals one.

## Properties of uniform scaling

Scaling the complete vector by one nonnegative scalar:

- leaves the action on the same ray, so its direction is preserved;
- preserves the fixed period because the dwell changes remain zero-sum;
- preserves the mode order when all applied dwells meet a positive lower bound;
- reaches the boundary of at least one active dwell constraint when conditioning is required;
- needs one scan over the N dwell changes.

The conditioner changes magnitude, not direction. It cannot choose a different feasible timing direction when the requested direction is poorly aligned with the constraints.

## Invariant raw-action region

The Raw-Action Admissible Region contains errors for which beta equals one in the current cycle. It need not be invariant. For a specified beta below one, the Fixed-Conditioning-Factor Feasible Region contains errors whose scaled action satisfies the current dwell constraints. This comparison set describes a deliberately fixed factor, not the state-dependent factor selected by the conditioner.

Offline preimage intersection computes its maximal positively invariant subset under `Acl`. Within that subset, the raw action remains feasible at every future cycle, beta remains one, and a Schur `Acl` gives convergence for the linearized raw closed loop.

Outside the invariant subset, the conditioner still makes the current schedule feasible. The set argument does not prove convergence while conditioning is active.

## Online and offline work

Online work consists of the raw feedback multiplication, the dwell-change calculation, and the scalar scan. LQR synthesis and invariant-region computation are offline operations.

The region computation is not an online optimization procedure. The conditioner is solver-free, but the overall controller still uses the chosen feedback gain and any state/model information needed to evaluate it.
