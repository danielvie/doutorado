# Handoff: project context and organization

## Purpose of the next thread

Orient a fresh agent before starting a new task in this paper workspace. The user requested and approved the organization and refactoring completed in this conversation. No further implementation task has been specified for the next thread.

The user plans to incorporate the latest Lyapunov analysis into the article later. Do not assume that incorporation is already authorized as the next task or that its conclusions are already manuscript claims.

## Read first

All paths below are relative to the paper workspace unless stated otherwise.

1. `AGENTS.md` and `project-knowledge/README.md` for navigation and source authority.
2. `README.md` for current organization, entry points, commands, and dependencies.
3. `GOAL.md` for scientific scope and accepted limitations; `CONTEXT.md` for terminology.
4. For numerical work, `scripts/README.md`.
5. For the latest Lyapunov work, `studies/lyapunov/README.md` and `studies/lyapunov/analysis.jl`.

Do not reconstruct the folder map from older handoffs. The current map is `project-knowledge/project/repository-map.md`; former locations are documented in `archive/README.md`.

## Decisions carried forward

The workspace retains both the publication and active research, with separate ownership of their code and evidence.

The two user priorities were completed:

- The latest Julia analysis has a stable, prominent entry point, `studies/lyapunov/analysis.jl`, invoked from the paper root with `task lyapunov`. Its environment, Python/MATLAB cross-checks, certificates, and tutorial are grouped in the same study.
- `scripts/generate_results.m` is now a thin entry script. `scripts/+paper/run_pipeline.m` orchestrates named stages with explicit struct inputs and outputs. Read `scripts/README.md` rather than treating the old monolithic script as the current architecture.

The older teaching bundle previously called `studies/lyapunov/` is now `studies/lyapunov-background/`. It is not the latest certificate workflow. Current article evidence is separated from archived gains and experiments; use `results/README.md` to identify the correct data.

## Scientific boundary

`latex/main.tex`, `GOAL.md`, `CONTEXT.md`, the online conditioner, and the sibling simulation sources were not changed by this work.

The Julia study solves a common-P SDP using endpoint matrices from the Python physical reconstruction. Julia is an optimization cross-check, not an independent converter reconstruction. The MATLAB comparison reconstructs the model independently.

The common-P result concerns the conditioned linearized family. It must not be described as global nonlinear stability. The study README records the limits and the work required before article integration.

## Working-tree state and preservation

Work remains uncommitted on branch `main`, with nothing staged at handoff creation. Many deletions shown by Git are file moves whose destinations are still untracked. Do not reset, clean, or discard them. Inspect both tracked changes and untracked destinations before committing or modifying the organization further.

Previously untracked Lyapunov files were preserved. All 96 relocated files were accounted for in the final audit. Unrelated untracked work under the repository's embedded and research-material areas was left alone.

A pre-change workspace copy and fresh original-generator baseline are available locally under `%LOCALAPPDATA%/Temp/paper-organization-_o8mp1no/`, in `before/` and `baseline/`. This is a temporary recovery aid, not a portable project dependency.

Old root handoffs were moved to `archive/handoffs/`. This new `handoff/` folder was created explicitly for the user's thread transfer request; its numbering starts at 1 because it contained no existing handoff files.

## Validation already completed

See `tests/README.md` for the checks and their scope. Full regression passed against both the original stored evidence and the freshly generated pre-refactor baseline. Unit tests, article verification/build, Python-to-Julia reproduction, the independent MATLAB comparison, the relocated trajectory study, and local-link checks passed. Numerical evidence and LaTeX metrics were preserved.

For subsequent numerical changes, run the regression before replacing stored evidence. Generated PDF/MAT byte differences alone are not proof of numerical changes because export metadata can differ.

## Execution notes

The paper is located at `LATEX/papers/paper-proportional-switching-time-controller/` within the larger repository. In this session, Bash started at the repository root despite the harness reporting the paper as its working directory. Explicitly change into the paper directory before running tasks.

Do not run expensive regeneration just for orientation. Use the README's command table after identifying the new task. The article pipeline and the Lyapunov study remain separate workflows.

## Suggested skills

- `unslop`: apply to documentation and manuscript prose.
- `shared-understanding`: clarify the next task's scope or decide which study result the article should adopt.
- `how`: explain a numerical stage or its ownership before changing it.
- `domain-modeling`: use if terminology or scientific boundaries need revision.
- `mado-html`: use if the new task modifies a Mado-owned tutorial, not merely numerical code.
- `handoff`: use for another thread transfer.

Start the next thread by establishing its actual task, then read the smallest relevant source set above. Do not repeat the completed organization pass.
