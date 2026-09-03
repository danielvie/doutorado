# Project knowledge

This directory is a descriptive knowledge base for the paper project. It helps a new thread understand what exists, where it lives, and which source to inspect next.

It is not a decision log and it is not a replacement for the project files. The authoritative content remains in the manuscript, scripts, generated outputs, `CONTEXT.md`, `GOAL.md`, and the research notes identified below.

## Start here

Read this file first. Then choose the smallest path that matches the task.

| Need | Read next |
|---|---|
| Navigate the repository | `project/repository-map.md` |
| Understand the article | `project/manuscript-description.md` |
| Understand the mathematics | `concepts/terminology.md`, then the relevant file in `concepts/` |
| Understand the controller | `concepts/controller-model.md` |
| Understand the numerical evidence | `project/numerical-pipeline.md`, `artifacts/generated-results.md` |
| Rewrite the manuscript | `project/manuscript-description.md`, `artifacts/article-source.md` |
| Study prior work | `references/README.md`, then individual reference summaries |
| Re-evaluate a project relationship or claim | `syntheses/README.md`, then a relevant dated synthesis |

## Directory roles

- `project/` describes the repository, manuscript, numerical pipeline, and related projects.
- `concepts/` explains the domain and mathematical objects used by the project.
- `references/` summarizes what individual external papers say.
- `artifacts/` explains the important source, generated, and visual files.
- `syntheses/` stores question-specific interpretations that must be reconsidered when the question changes.

## Information policy

The knowledge files separate information from interpretation:

- Reference summaries describe an external article's problem, setting, method, contribution, evidence, and limitations.
- Project descriptions describe what the repository files contain and how they connect.
- Concept files explain terms and mathematical relationships.
- Synthesis files discuss relationships, comparisons, novelty, tradeoffs, and conclusions for a particular question.

A conclusion about how a reference relates to this paper should not be treated as a permanent fact merely because it appears in a synthesis.

## Source hierarchy

| Topic | Authoritative source |
|---|---|
| Article text | `latex/main.tex` |
| Domain terminology | `CONTEXT.md` |
| Scientific goal and boundaries | `GOAL.md` |
| Build commands | `Taskfile.yml` |
| Numerical generation | `scripts/generate_results.m` and related scripts |
| Generated numerical values | `results/metrics.csv` and `latex/metrics.tex` |
| Literature and novelty analysis | `research/novelty-review.md` and related research notes |
| Historical work process | `handoff/` |

The files in this directory summarize these sources. If a summary conflicts with a source file, inspect the source file and update the summary when appropriate.

## Scope

The map is centered on the paper at `LATEX/papers/paper-proportional-switching-time-controller/`. It also describes the sibling simulation, thesis, research-material, and embedded projects where they provide context or dependencies.

## Maintenance

Use descriptive filenames and keep summaries traceable to their source paths. Add a dated file under `syntheses/` when a session reaches a question-specific interpretation. Do not add a permanent decision file unless the project later needs one explicitly.
