# Handoff: Lyapunov focus study

## Focus

`lyapunov_focus/computing-v-with-cvx.html` is a standalone teaching page about finding and checking a quadratic Lyapunov function for a damped mass-spring oscillator with MATLAB CVX. It explains why a natural physical-energy candidate almost works, why it fails the strict decrease test, and how a semidefinite solver finds a valid certificate instead.

The page is intended to be opened directly in a browser. It has no external scripts, stylesheets, fonts, or data files.

## Mathematical content

The example uses the continuous-time linear system

\[
\dot{x} = Ax, \qquad A = \begin{bmatrix}0 & 1 \\ -4 & -0.4\end{bmatrix},
\]

with mass `m = 1`, damping `c = 0.4`, and spring stiffness `k = 4`. Its eigenvalues are approximately `-0.2 +/- 1.99i`, so the origin is asymptotically stable. The page deliberately avoids using the eigenvalue test as the main proof so it can teach the Lyapunov method.

The argument proceeds as follows:

1. Rewrite the second-order oscillator as two first-order state equations.
2. Choose a quadratic candidate `V(x) = x^T P x`.
3. Derive
   `Vdot = x^T (A^T P + P A) x`.
4. Require `P` to be positive definite and `A^T P + P A` to be negative definite.
5. Test the mechanical energy candidate:
   `E(x) = 2 x_1^2 + 0.5 x_2^2`, with `P_energy = diag(2, 0.5)`.
6. Show that its derivative matrix has eigenvalues `0` and `-0.4`, so energy is only negative semidefinite. The page explains the zero physically: the damper removes energy only while the mass is moving.
7. Ask CVX for a certificate using the stronger, numerically usable constraints `P >= I` and `A^T P + P A <= -I`.
8. Verify the returned matrix independently with eigenvalue checks.
9. Extend the certificate to a decay-rate condition `A^T P + P A <= -2 alpha P`, with `alpha` found by bisection.

The page reports a representative solver result near

```text
P = [14.5465  0.6097
      0.6097  3.7280]
```

and a certified rate near `alpha = 0.2`, giving a bound of approximately
`||x(t)|| <= 2.017 exp(-0.2 t) ||x(0)||`.

## Interactive content

The inline JavaScript contains the numerical demonstration:

- A time-domain canvas plot shows position and velocity for an initial state `[1, 0]`.
- The laboratory canvas shows the state-plane trajectory, level sets of the selected `V`, and `Vdot` along the trajectory.
- The selector switches between the CVX certificate and mechanical energy.
- The starting point can be dragged in the state plane.
- `play`, `pause`, and `reset` control the animation.
- The browser integrates `xdot = Ax` with a classical RK4 stepper and computes quadratic forms directly from hard-coded matrices.

## Current equation rendering

The display equations were changed from hand-spaced Unicode text to native MathML. This gives the equations real structure for fractions, superscripts, over-dots, aligned derivations, and matrices while preserving the page's offline/self-contained requirement. No KaTeX or MathJax dependency was added.

The large display blocks now contain 12 `<math>` elements. The prose still contains older inline HTML entities for some symbols such as transpose marks, norms, and dotted variables. If visual consistency is needed later, those inline expressions should also be converted to MathML or replaced with a consistent rendering strategy.