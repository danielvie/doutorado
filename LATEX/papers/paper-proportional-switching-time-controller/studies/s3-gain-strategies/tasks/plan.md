# Approved implementation plan

Status: implemented, executed and independently verified. See todo.md and ../report.md for outcomes.

The author approved SPEC.md and requested implementation. Keep all work in this study, without replacing article gains or evidence.

1. Coordinator implements and checks the shared Julia model, conditioner, exact simulator, training objective, certificate solver and JSON contract. Reproduce existing baseline costs and trajectories before gain searches.
2. Five workers implement and execute strategy-1 through strategy-5 concurrently. Each owns only its strategy source and corresponding results. No shared-file edits.
3. Coordinator evaluates frozen gains on all training/withheld/historical cases. An independent Python verifier checks certificates, exact cycles, costs, conditioner arithmetic and provenance.
4. Export comparisons and a readable Markdown/PDF report. Include every failure, search limit and regression. Run focused study checks and inspect the resulting report.

Dependencies: shared contract/checks precede strategy execution; frozen strategy results precede comparison; successful independent checks precede the final recommendation.

Acceptance criteria for the five gain optimizations are in SPEC.md. The author-requested Marcolino addition is specified separately in MARCOLINO.md so the original optimization provenance stays frozen. It adds an unchanged-gain sequential-delay reference without common-P coverage, exact common-clock sampling and phase-aware comparisons. Verification uses only this study and the saved source evidence. Paper-root tasks retain their existing MPC author-review checklist.
