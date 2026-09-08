# Handoff: scientific writing and readability

## Purpose

Improve the article's text and writing strategy in a new thread. The goal is a scientific article that a control or power-electronics reader can digest without repeatedly unpacking long sentences, shifting terminology, or an oversized literature funnel. Use clear, concise language while preserving the mathematics, evidence, and conservative novelty boundary.

## Article in one paragraph

The paper studies fixed-period cycle-to-cycle switching-time feedback for a prescribed sequence of affine modes. A static controller produces offsets for the interior switching instants, but the raw offsets can violate minimum dwell durations. The proposed conditioner multiplies the complete raw timing vector by the largest feasible scalar in $[0,1]$. This preserves the action direction, mode order, and cycle period and requires an $O(N)$ scan rather than an online solver. In the linearized cycle model, conditioning produces the matrix segment $A(\beta)=(1-\beta)\Phi+\beta A_{\mathrm{cl}}$; a common quadratic Lyapunov function for the endpoints certifies contraction for arbitrary conditioning-factor sequences. An augmented-state derivation, numerical Jacobian checks, and an exact nonlinear simulation of a nine-interval DC--DC converter support the method. The nonlinear guarantee remains local, and validation is simulation-based.

## Scientific goal and audience

Write for readers who know control systems but may not already know this timing-coordinate formulation. The paper should let them answer five questions in order:

1. What implementation problem occurs with raw switching-time feedback?
2. What schedule and control variables are fixed, and what may change?
3. What did Pati\~no and Marcolino already establish?
4. What does the scalar conditioner add?
5. What is proved, and what is only shown in simulation?

A reader should not need to infer the novelty from equations or reconstruct the control architecture from several sections.

## Current article structure

The source is `article.tex`. Its main sections are:

- abstract;
- introduction;
- fixed-period one-cycle model;
- solver-free dwell-time conditioning;
- converter case study;
- discussion;
- conclusion.

The introduction now follows four layers:

1. implementation pressure from converter constraints and online computation;
2. the exact fixed-period, fixed-mode-order control setting;
3. the closest prior work and unresolved feasibility gap;
4. maximal scalar conditioning, certification, and supporting evidence.

Do not restore the former seven-layer funnel. The current citation strategy is documented in `handoff/handoff-3-specialization-funnel-and-citation-integration.md`.

## Main contribution hierarchy

Present two main results:

1. the maximal direction-preserving scalar conditioner, including its $O(N)$ implementation and admissible raw-action characterization;
2. the common-quadratic certificate for the conditioned linearized matrix family.

Treat the following as supporting derivation or evidence, not equal novelty claims:

- augmented switched-affine one-cycle derivation;
- reduction to the known switched-actuator model;
- numerical differentiation and residual checks;
- converter simulation;
- LQR comparison laws.

The canonical novelty boundary is in `research/novelty-review.md`. The project goal and accepted limitations are in `GOAL.md`.

## Writing strategy

### Make each paragraph do one job

Use this sequence where possible:

```text
claim -> necessary explanation or evidence -> consequence
```

Do not mix background, derivation, result interpretation, and limitations in one paragraph. Put citations immediately after the factual claim they support.

### Introduce notation only when needed

Before an equation, state what question it answers. After the equation, explain the operational meaning of the result. Avoid repeating every symbol in prose. Keep one name per concept, especially for:

- raw switching-instant offset;
- conditioning factor;
- applied switching-instant offset;
- dwell change;
- nominal cycle map;
- raw closed-loop matrix;
- conditioned matrix family.

### Prefer direct sentences

Use active voice and concrete verbs. Split sentences that contain several independent claims. Remove throat-clearing phrases and broad statements about industrial importance unless they lead directly to the timing-feasibility problem.

Prefer:

> The conditioner scans the $N$ dwell changes and returns the largest feasible factor.

Avoid:

> It is important to note that the proposed approach is able to provide an efficient mechanism for obtaining a feasible value.

### Separate proof from interpretation

Proofs should state assumptions and logical steps without promotional language. Follow each main proposition with a short interpretation that says what it guarantees, for which model, and under which conditions.

### State limitations once, precisely

Keep the distinctions clear:

- the common-Lyapunov result certifies the linearized family;
- exact nonlinear stability is local near the cycle where conditioning is inactive;
- the large-error nonlinear simulation is benchmark evidence, not a global guarantee;
- the assumed minimum dwell is not hardware-calibrated;
- there are no experiments.

Avoid repeating the full limitation list in the abstract, introduction, discussion, and conclusion. Each section needs only the limitation relevant to its claim.

## Recommended next-session pass

1. Read `article.tex` from abstract through conclusion and mark paragraphs with more than one rhetorical job.
2. Simplify the abstract first. Preserve the problem, method, proof, strongest numerical evidence, and scope, but reduce the density of implementation details and macro-generated metrics.
3. Review transitions between the model, conditioner, and case study. Each section should begin by explaining why the reader needs it.
4. Standardize terminology and remove repeated definitions.
5. Shorten dense sentences and remove repeated novelty disclaimers without weakening the boundary.
6. Check every changed factual statement against `research/novelty-review.md`, `research/recent-literature-2021-2026.md`, or the cited source.
7. Run `task build` and inspect the PDF for page breaks, equation placement, and paragraph density.

## Success criteria

- The problem and contribution are clear on the first page.
- The paper consistently distinguishes fixed items from controlled variables.
- Pati\~no and Marcolino receive more attention than distant literature.
- The two main contributions remain visually and verbally dominant.
- Equations have enough interpretation but no redundant narration.
- Claims distinguish theorem, numerical verification, simulation evidence, and limitation.
- Language is concise without becoming cryptic.
- The compiled paper has no citation or LaTeX warnings.
- The paper moves toward the `GOAL.md` target of 8--10 pages. The latest build produced 11 pages.

## Files to consult

- `article.tex`: paper source.
- `GOAL.md`: canonical goal, success criteria, and limitations.
- `research/novelty-review.md`: prior-art boundary and defensible claims.
- `research/recent-literature-2021-2026.md`: reviewed evidence for literature statements.
- `handoff/handoff-3-specialization-funnel-and-citation-integration.md`: four-layer introduction and citation strategy.
- `references.bib`: citation records.
- `Taskfile.yml`: build commands.

## Suggested skills

- `unslop` for direct, natural scientific prose.
- `shared-understanding` if a paragraph's purpose or contribution hierarchy is unclear.
- `research` before strengthening a literature or priority claim.
- `how` for explaining the mathematical flow or deciding where an explanation belongs.
- `handoff` when passing the revised writing strategy to another thread.
