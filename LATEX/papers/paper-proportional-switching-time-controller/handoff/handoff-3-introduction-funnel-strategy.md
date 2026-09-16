# Introduction funnel strategy

## Purpose

Continue refining the Introduction in `latex/main.tex` while preserving the user's broad-to-specific structure. The user wants minimal, local edits that preserve existing prose, not a wholesale rewrite.

Read `project-knowledge/README.md` for orientation before inspecting project files. The manuscript is the authoritative source for current wording.

## Agreed layers

The Introduction should narrow through these layers, in this order:

1. **Power electronics.** Start with converter operation and practical switching constraints.
2. **Switched-affine periodic systems.** Explain the explicit switching model and why the control objective is a periodic trajectory rather than a constant state.
3. **Switching-time control.** Narrow to retaining the mode sequence and period while adjusting interior switching instants. Discuss the relevant prior work and introduce the cycle-specific regulation point here.
4. **Dwell-time feasibility and conditioning.** Explain the coupling between adjacent dwell durations, limitations of existing approaches, and the specific problem addressed by the proposed conditioner.

These are conceptual layers, not a requirement for exactly four paragraphs. Broad constraints can appear in the opening motivation; their mathematical coupling and conditioning belong later.

## Placement decisions

- The first paragraph should establish periodic-trajectory regulation, not explain cycle-start feedback or introduce the term `cycle anchor`.
- The existing sentence contrasting a periodic trajectory with a constant state already conveys the desired objective. No replacement explanation was needed after removing the former two closing sentences.
- Marcolino's work belongs in the narrower switching-time-control discussion, not the opening paragraph.
- Introduce `cycle anchor` alongside Marcolino's `target point`. This connects the concepts without attributing this paper's terminology to Marcolino.
- The user chose the phrase `called the cycle anchor in this paper.` over `which we call the cycle anchor.`

The agreed edits are already applied in `latex/main.tex`. Consult the current source and diff rather than reapplying them.

## Verified source evidence

Local primary source:
`research/articles/01-marcolino-2021-dwell-constrained-predictive-control.pdf`

At the opening of Section 4, Marcolino et al. state that the sampled state will be driven to the **target point** \(x_r(t_0)=x_r(t_N)\). This is the reference trajectory's common cycle-start/end point and supports the connection to this manuscript's cycle anchor. The terminology was checked directly in text extracted from the PDF, not inferred solely from repository summaries.

The existing citation key is `marcolino2021`. The following sentence about discrete LQR and dwell-constrained predictive control retains that citation.

## Editing boundaries and status

- Preserve the funnel when proposing further edits. Do not move specialized prior work or cycle-specific terminology into the opening just to establish a citation connection.
- Keep the distinction between regulating a periodic trajectory and regulating a constant state.
- Preserve the distinction between Marcolino's terminology and this paper's terminology.
- No numerical, mathematical, or controller changes were requested or made.
- The manuscript edits are uncommitted. A whitespace diff check passed after the initial two edits; the final phrase replacement was subsequently applied. No LaTeX build was run for these prose-only changes.
- No additional manuscript change is pending from this conversation.

## Suggested skills

- `unslop`: required for prose edits; preserve the manuscript's technical tone and avoid unnecessary wording.
- `handoff`: use when updating or extending this continuation note.
