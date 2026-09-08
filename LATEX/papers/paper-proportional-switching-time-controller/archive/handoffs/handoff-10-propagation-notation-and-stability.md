# Propagation notation and Lyapunov stability

## Purpose

Continue the discussion about the one-cycle propagation equation and its use in the Lyapunov proof. The immediate issue is clarity: the latest HTML explanation introduced `Psi_i` and `c_i`, which do not appear in the reference derivation and made the user more confused.

## User requirements

- Treat `linearization-reference.tex` and `linearization-reference.pdf` as the source for the propagation derivation.
- Favor the reference notation and matrix order. Do not introduce intermediate symbols unless they are necessary and derived before use.
- If an answer contains equations, create a new standalone HTML document with properly rendered equations. Keep the chat response to a short summary and the document path.
- Use native MathML in these HTML documents. Do not emit multiline raw LaTeX in Zed chat.
- Use explicit MathML matrix delimiters such as `<mo stretchy="true">[</mo>` and `<mo stretchy="true">]</mo>`. Chromium dropped brackets written with the deprecated `<mfenced>` element.

## Source material

- Reference source: `linearization-reference.tex`
- Rendered reference: `linearization-reference.pdf`
- Article: `article.tex`
- Existing stability study: `studies/signal-conditioning-stability/`

Do not duplicate or replace the reference derivation. Use it directly when checking symbols and matrix order.

## Article state

The propagation section of `article.tex` was rewritten around the reference derivation. It now uses:

- augmented state `chi(t)`;
- interval mode `q_i`;
- augmented generator `F_i = tilde A_{q_i}`;
- actual and nominal durations `Delta t_i` and `Delta bar t_i`;
- interval transition `phi_i = exp(F_i Delta bar t_i)`;
- ordered product from interval `N` down to interval `1`;
- ordered sensitivity columns `Gamma = [gamma_1 ... gamma_N]` matching `delta boldsymbol t`;
- physical projection through `Pi` and `iota`;
- physical matrices `Phi` and `G_d`;
- switching-offset map `delta boldsymbol t_k = D delta boldsymbol tau_k`.

The augmented nominal product was initially named `bar Phi`, then renamed `tilde Phi` after discussion. The intent was to reserve bare `Phi` for the physical `n x n` propagation matrix used in the controller and Lyapunov analysis.

The article and tracked `article.pdf` were rebuilt successfully. `latexmk` passed, no overfull equations remained, and `git diff --check` passed. Only underfull column warnings remained.

## Mathematical point reached

The reference defines the augmented state from the physical affine system. Therefore:

1. `x(t)` is in `R^n`.
2. `chi(t) = [x(t); 1]` is in `R^(n+1)`.
3. `F_i = tilde A_{q_i}` is `(n+1) x (n+1)`.
4. `phi_i = exp(F_i Delta bar t_i)` is also `(n+1) x (n+1)`.
5. The product `phi_N ... phi_1` is therefore already augmented.

The reference may display that product as `Phi` while the article currently calls the same product `tilde Phi`. This is a notation distinction, not a second propagation process.

The full augmented product has a lower-right entry equal to one. For a periodic anchor, the augmented fixed point is an eigenvector associated with eigenvalue one. This does not obstruct physical-error stability because subtracting two augmented states removes the homogeneous coordinate: the augmented error has last coordinate zero. The Lyapunov analysis should therefore use the projected physical closed-loop map, not demand strict contraction on all of `R^(n+1)`.

## Immediate correction required

The latest user objection is valid: `studies/signal-conditioning-stability/what-is-augmented-phi.html` introduced `Psi_i` and `c_i` in the displayed interval-transition block without deriving them from the reference. The user said these terms appeared "from nowhere."

Next action:

1. Revise `what-is-augmented-phi.html` through the Mado CLI.
2. Remove every use of `Psi_i` and `c_i`.
3. Explain the augmented dimension using only the reference symbols `chi`, `F_i`, `phi_i`, and the ordered product.
4. If a block decomposition is still needed, introduce it only for the complete product and explain every block immediately, or avoid the block decomposition and use `Pi (phi_N ... phi_1) iota` for the physical matrix.
5. Keep the distinction between the augmented state map and the augmented error map explicit.
6. Do not change the article until the notation is agreed with the user.

The safest explanation is short: because each `F_i` is augmented, each `phi_i` and their product are augmented. The physical propagation matrix is obtained by projection. No new interval symbols are needed.

## HTML studies

### `prediction-equation-lyapunov.html`

Path: `studies/signal-conditioning-stability/prediction-equation-lyapunov.html`

Seven Mado sessions currently cover:

1. augmented prediction equation;
2. meaning of the eigenvalue at one;
3. projection to the closed-loop map;
4. proof strategy;
5. common-`P` endpoint argument;
6. Lyapunov criterion and claim limits;
7. normalized certificate and nonlinear interpretation.

The document uses native MathML and explicit brackets. Mado inspection and editor diagnostics passed.

### `what-is-augmented-phi.html`

Path: `studies/signal-conditioning-stability/what-is-augmented-phi.html`

This is the latest answer document. It has four sessions, but session 2 is now considered misleading because it introduces `Psi_i` and `c_i`. Correct this document before relying on it.

Use the Mado executable:

`C:/Users/daniel/.agents/skills/mado-html/bin/mado-html.exe`

Run it from the paper root with `--workspace .`. Inspect and retrieve a session before changing it. Do not edit a Mado HTML document directly.

## Stability study

Existing files:

- `studies/signal-conditioning-stability/prove_beta_0.m`
- `studies/signal-conditioning-stability/prove_beta_1.m`
- `studies/signal-conditioning-stability/prove_beta_interval.m`
- `studies/signal-conditioning-stability/tutorial.md`
- `studies/signal-conditioning-stability/deriving-a0-a1.html`

`task stability-proof` previously passed all three MATLAB/YALMIP/SeDuMi checks. The study distinguishes:

- physical propagation `Phi`;
- normalized open-loop endpoint `A_0 = S_x^{-1} Phi S_x`;
- normalized closed-loop endpoint `A_1`;
- the common Lyapunov matrix `P` from the LQR Riccati matrix.

Do not reproduce numerical matrices in a new handoff or explanation unless needed. They are already recorded in the study files.

## Stability claim boundaries

- A common `P` for the physical endpoint matrices certifies the complete linearized conditioned family for arbitrary `beta_k` in `[0,1]`.
- If `beta = 0` is admissible, the physical open-loop endpoint must also contract.
- The exact nonlinear cycle map receives only a local exponential-stability conclusion near the periodic orbit, under differentiability, preserved mode order, strict nominal dwell margin, and a Schur closed-loop Jacobian.
- The common-`P` linear result does not establish global nonlinear stability while conditioning is active.

## Repository status and unrelated work

Expected project changes include `Taskfile.yml`, `article.tex`, `article.pdf`, and the untracked stability-study directory. The Mado workflow also created an untracked `.mado-html/` directory and the two HTML explanation documents.

Several files under `research-material/working-notes/linearization/` are staged as moves into `archive/pre-augmented/`. These moves and the untracked `linearization-reference.tex` and `linearization-reference.pdf` are user work. Do not revert, move, or delete them.

## Suggested skills

- `mado-html`: required for correcting or extending the standalone HTML explanations.
- `shared-understanding`: use before choosing another notation or adding intermediate matrices.
- `how`: use for a concise derivation of the augmented-to-physical propagation flow.
- `unslop`: keep explanations direct and remove unnecessary notation or prose.
