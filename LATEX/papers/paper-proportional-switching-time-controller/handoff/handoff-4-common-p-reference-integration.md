# Handoff: integrate common-P references

## Goal

Add concise references for the manuscript's existing common-\(P\) stability analysis. Make the smallest defensible change. Preserve the manuscript's writing style and do not change the theorem, proof, claims, notation, or numerical analysis.

## Start here

Read, in order:

1. `project-knowledge/README.md`
2. `README.md`
3. `latex/main.tex`, especially `\section{Lyapunov stability and convex optimization}`
4. `latex/references.bib`
5. The three retained articles listed below

## Retained primary sources

### Mason and Shorten (2004)

Path: `research/articles/29-mason-shorten-2004-common-quadratic-lyapunov.pdf`

O. Mason and R. Shorten, “On common quadratic Lyapunov functions for stable discrete-time LTI systems,” *IMA Journal of Applied Mathematics*, 69(3), 271–283, 2004. DOI: `10.1093/imamat/69.3.271`.

Use for: the discrete-time common quadratic Lyapunov function terminology and the simultaneous inequalities for a finite matrix family.

Exact location: p. 272, equations (3)–(4), where one `P=P^T>0` satisfies `A_i^T P A_i-P=-Q_i` for every system.

Do not claim that this article develops the manuscript's convex-segment endpoint SDP. Its focus is CQLF existence for pairs of systems.

### de Oliveira, Geromel, and Hsu (1999)

Path: `research/articles/30-de-oliveira-geromel-hsu-1999-discrete-time-robust-stability.pdf`

M. C. de Oliveira, J. C. Geromel, and L. Hsu, “LMI characterization of structural and robust stability: the discrete-time case,” *Linear Algebra and its Applications*, 296, 27–38, 1999. DOI: `10.1016/S0024-3795(99)00086-5`.

Use for: discrete-time simultaneous stability over a convex matrix family and finite vertex LMIs.

Exact locations:

- equations (2)–(3), pp. 29–30: convex matrix family;
- Theorem 2(i), pp. 31–32: one constant positive-definite matrix for the complete family;
- Theorem 2(ii), equation (11), p. 32: equivalent LMIs at the vertices.

For the manuscript's two-vertex family, set the paper's fixed left factor to the identity, its vertices to `A_0` and `A_1`, and its convex weights to `1-beta` and `beta`.

Do not use the later parameter-dependent Lyapunov result as support for arbitrary `beta_k`. Cite only the simultaneous/common-matrix result. Do not say equation (11) is identical to the manuscript's SDP; it is a related equivalent LMI formulation with auxiliary variables.

### Olalla et al. (2009)

Path: `research/articles/31-olalla-2009-robust-lqr-pwm-converters.pdf`

C. Olalla, R. Leyva, A. El Aroudi, and I. Queinnec, “Robust LQR Control for PWM Converters: An LMI Approach,” *IEEE Transactions on Industrial Electronics*, 56(7), 2548–2558, 2009. DOI: `10.1109/TIE.2009.2017556`.

Use for: an applied converter precedent combining a polytopic family, one common quadratic certificate, and convex LMI optimization.

Exact locations:

- equation (8), p. 2550: polytopic converter model;
- equations (15)–(17), p. 2551: one `P` imposed at every vertex;
- equations (23)–(26), p. 2552: convex LMI formulation;
- text after equation (26), p. 2552: quadratic stability under arbitrarily fast parameter changes.

Qualify this source as a continuous-time averaged-model application. Do not imply that it treats a discrete-time cycle map, switching-time feedback, dwell conditioning, or the manuscript's exact theorem.

## Minimal manuscript change

Add exactly the amount of context needed to establish provenance. A good target is two short sentences total:

1. Near the beginning of `\subsection{Common quadratic Lyapunov certificate}`, identify the use of one quadratic function for a discrete-time matrix family as the common quadratic Lyapunov function approach and cite Mason–Shorten.
2. Near the beginning of `\subsection{Offline semidefinite program}`, state that related common-matrix vertex LMIs appear in discrete-time robust stability and in robust polytopic PWM converter control; cite de Oliveira–Geromel–Hsu and Olalla et al.

Use restrained wording such as “related vertex-LMI formulations” and “continuous-time converter application.” Do not add a literature-review paragraph.

Do not:

- change the abstract, Introduction, theorem, proof, SDP, Discussion, or Conclusion unless a citation cannot be placed cleanly otherwise;
- claim the references prove the manuscript's state-dependent `beta_k` result;
- blur the boundary between the conditioned linearized family and the exact nonlinear plant;
- imply that the manuscript proposes a new general Lyapunov theorem;
- introduce additional references;
- rewrite neighboring prose for style.

## Bibliography work

Add exactly three BibTeX records to `latex/references.bib`, using metadata from the PDFs and DOI records. Choose clear keys and use them consistently. The provisional archive keys in `research/articles/README.md` are:

- `mason2004commonQuadratic`
- `deOliveira1999lmiDiscrete`
- `olalla2009robustLqrPwm`

Changing these keys is acceptable only if the bibliography already has a stronger naming convention. Do not alter existing records.

## Validation

From the paper directory:

1. Run `task build`.
2. Check the LaTeX log for undefined citations and multiply defined bibliography entries.
3. Inspect the diff and confirm that changes are limited to `latex/main.tex` and `latex/references.bib`, apart from this handoff and the already pending article-archive changes.

## Current working-tree context

The common-P archive changes are present but not committed:

- modified `research/articles/README.md`;
- new PDFs 29–31 under `research/articles/`.

Do not delete or rename them. The manuscript and bibliography have not yet been changed.

## Suggested skills

- `unslop`: mandatory for keeping the added prose plain and consistent with the manuscript.
- `research`: use only if a bibliographic field remains ambiguous after reading the local PDFs. Do not start a new literature search.
