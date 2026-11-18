# Gain-strategy experiment tasks

- [x] Author approval of SPEC.md and implementation.
- [x] Shared Julia numerical contract reproduces saved baselines.
- [x] strategy-1 implemented, executed and checked.
- [x] strategy-2 implemented, executed and checked.
- [x] strategy-3 implemented, executed and checked.
- [x] strategy-4 implemented, executed and checked.
- [x] strategy-5 implemented, executed and checked.
- [x] Frozen gains evaluated on training, withheld and historical cases.
- [x] Independent saved-evidence and rejection checks pass.
- [x] Comparison report and figures built and inspected.
- [x] Final scope and unchanged publication evidence verified.

## Initial five-strategy verification record

- Shared Julia checks: 41 assertions passed, including six saved MATLAB baseline trajectories and independent Riccati gain recovery.
- Each strategy ran in its own parallel worker, exercised its focused self-test and wrote a matching final source-hashed JSON record.
- Frozen evaluation: seven gains, 20 initial conditions, 140 trajectories, 14,000 exact cycles.
- Independent Python verifier: 37,858 checks passed; maximum absolute one-cycle state discrepancy 1.7763568394002505e-14.
- Independent rejection/unit checks: 27 passed, no skips.
- Study Taskfile listing and saved-input report build passed. The report is seven pages, with no LaTeX overflow warnings; representative rendered pages were inspected.
- Only the new study was implemented. Existing manuscript, gains, certificates and publication evidence were not rewritten. Unrelated working-tree files were left untouched.

## Initial five-strategy outcome

Strategy-5 has the lowest mean withheld cost, 0.327% below current LQR, but six withheld cases regress. Strategy-4 gives faster mean withheld settling, 3.42 versus 5.33 cycles, while mean withheld cost is 7.04% higher. Its original 1x/2x/3x cost improvements do not establish general superiority. Strategy-2 retained current LQR after its synthesized candidates failed to improve training cost. Keep current LQR as the general-purpose baseline; use the report to choose any narrower follow-up objective.

## Marcolino addition

- [x] Add strategy-marcolino with unchanged current LQR and the exact sequential-delay rule.
- [x] Preserve all five optimization records and common.jl/SPEC.md; no gain-search reruns.
- [x] Reproduce saved 1x/2x/3x MATLAB times, anchor errors and phase-sensitive errors in Julia.
- [x] Evaluate all eight policies on the 20 declared cases, including exact common-clock sampling.
- [x] Independently verify timing, phase, every saved cycle and explicit absence of Marcolino common-P coverage.
- [x] Add corruption tests for truncation, fake beta/certificate, phase reset, changed clock samples and changed gain.
- [x] Regenerate and inspect the expanded Markdown/PDF report and update study commands.

Julia policy/timing checks: 56 passed; maximum historical reference-error discrepancy 4.6629367034256575e-15. Independent Python checks passed for 160 trajectories and 16,000 exact cycles, with maximum one-cycle discrepancy 1.7763568394002505e-14. All 39 focused Python tests passed. The updated report is 12 pages with no LaTeX overflow warnings. Representative common-clock, phase and historical tables were visually inspected.

Marcolino is a variable-period conditioning reference, not a sixth certified gain optimization. It has no sustained common-clock threshold crossing in two of 12 withheld cases and all three historical cases. Its cycle-start reference error and common-grid error are reported separately because their sampling phases differ. Original external studies and article outputs remain unchanged.

## Separate focused comparison document

- [x] Create five-method-comparison.md/.tex/.pdf with current LQR common-P, original joint Common-P gain, Marcolino and MPC-5.
- [x] Remove strategy-4 and its selection discussion at the author's request, retaining the original filenames and leaving the full analysis unchanged.
- [x] Restrict the matched comparison to 1x/2x/3x, where saved MPC-5 evidence exists.
- [x] Check saved MPC times, normalized errors, stage cost and thresholds before presenting it on the common grid.
- [x] Retain the distinction between anchor J100 and common-clock tracking, and label guarantee scope.
- [x] Build and visually inspect the four-page document; after the requested removal it contains exactly 12 method/case rows.
- [x] Confirm the existing full report is unchanged and record the new document's input hashes.

Rebuild with task five-method-report from the study directory. No optimization, plant simulation or unrelated full-suite tests were rerun for this presentation-only filtered document.

