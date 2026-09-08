# Handoff: create the project-knowledge skill

## Next-session objective

Create a reusable Zed agent skill named `project-knowledge` for building a navigable knowledge base for a dense project. The skill should generalize the process used in this paper project without hard-coding this project's scientific decisions.

Recommended scope:

- make the skill global at `~/.agents/skills/project-knowledge/SKILL.md`;
- create the knowledge it produces inside the target project at `project-knowledge/`;
- use the existing project files as sources of truth;
- support progressive disclosure, so a new thread reads a short index first and deeper material only when needed.

No skill has been created yet. This handoff is the implementation brief for the next thread.

## Existing example

The paper project now contains an implemented example under:

`project-knowledge/`

Its structure and content are the concrete reference for the workflow. Read these files rather than copying their full contents into the skill:

- `project-knowledge/README.md`
- `project-knowledge/project/`
- `project-knowledge/concepts/`
- `project-knowledge/references/`
- `project-knowledge/artifacts/`
- `project-knowledge/syntheses/`

The project also has a minimal navigation pointer in `AGENTS.md`:

> For project orientation and navigation, read `project-knowledge/README.md` before inspecting project files.

The skill should make this integration optional and minimal. It should not silently rewrite project instructions.

## Desired knowledge model

The skill must distinguish four kinds of content:

1. **Project descriptions** — what files, directories, systems, and pipelines contain.
2. **Concept explanations** — what domain terms, models, and mechanisms mean.
3. **Reference summaries** — what each external source says: problem, setting, approach, contribution, evidence, and limitations.
4. **Provisional syntheses** — how information may relate to the project for a particular question, including comparisons, novelty assessments, tradeoffs, and conclusions.

The first three are descriptive and should be traceable to sources. The fourth is question-specific and must not be treated as settled truth.

Do not put “relation to this project,” novelty judgments, rewrite recommendations, or other conclusions into neutral reference summaries. Put them in a dated file under `project-knowledge/syntheses/`.

## Recommended workflow for the skill

1. Read applicable `AGENTS.md` files and identify project roots.
2. Read existing orientation artifacts such as `README.md`, `CONTEXT.md`, `GOAL.md`, and build manifests when present.
3. Inventory the project before writing. Identify source files, generated files, external dependencies, research material, and existing documentation.
4. Check whether `project-knowledge/` already exists. Preserve existing files and update rather than overwrite them.
5. Create only the directories and files for which there is verified information. Do not create empty placeholder trees.
6. Write or update a short root `project-knowledge/README.md` that routes a new thread to the relevant deeper files.
7. Add descriptive project, concept, artifact, and reference summaries as needed.
8. Use one reference file per inspected source when a literature summary is requested. Do not invent details from titles or metadata.
9. Create a dated synthesis only when the user asks for analysis, comparison, project relevance, novelty, or a recommendation.
10. Verify the resulting inventory and report files changed. Do not run expensive project builds unless the knowledge work changes build inputs or the user asks for validation.

## Suggested default structure

Use this as a default, not a rigid requirement:

```text
project-knowledge/
├── README.md
├── project/
├── concepts/
├── references/
├── artifacts/
└── syntheses/
```

The skill should choose fewer files for a small project and add depth only when the project or user request requires it.

## README requirements

The root README should:

- explain the purpose of the knowledge folder;
- provide task-oriented navigation;
- identify authoritative source files;
- explain the distinction between descriptions and provisional syntheses;
- tell the agent to read only relevant deeper files;
- state the project scope represented by the map.

It should be an index, not a detailed snapshot of project decisions.

## Reference-summary requirements

A reference summary should normally contain:

- bibliographic identity;
- problem;
- system or setting;
- approach;
- main contribution;
- evidence;
- assumptions and limitations;
- useful concepts or equations;
- source pointers.

The summary must describe the source before discussing its relationship to the project. The latter belongs in a synthesis.

## Maintenance rules

- Keep authoritative domain terminology in the project's existing `CONTEXT.md` when one exists.
- Treat `project-knowledge/concepts/` as explanatory material or a mirror, not a replacement glossary.
- Keep project-specific implementation details out of `CONTEXT.md`.
- Treat `syntheses/` as provisional and dated.
- Never overwrite user-authored knowledge files without inspecting them first.
- Prefer links and source paths over duplicating large source contents.
- Mark uncertain or unverified information instead of filling gaps by inference.
- If the skill updates an existing knowledge map, preserve its established vocabulary and structure unless the user asks for a redesign.

## Open implementation choices

The next thread should decide while implementing:

- whether the skill should create all default subdirectories or only those needed;
- whether it should automatically add the one-line `AGENTS.md` pointer or only offer that change;
- how much literature should be summarized in one invocation;
- whether a project-specific `AGENTS.md` should be updated with the knowledge-map route.

Recommended defaults are lazy directory creation, an optional AGENTS update, and summaries only for sources actually inspected.

## Relevant project artifacts

- `project-knowledge/README.md` — implemented information-policy and navigation example.
- `CONTEXT.md` — current domain glossary.
- `GOAL.md` — current scientific scope and boundaries.
- `AGENTS.md` — project orientation rules and knowledge-map pointer.
- `handoff/handoff-9-create-project-knowledge-skill.md` — this document.

## Suggested skills

- `create-skill` — create and validate the Zed skill structure and frontmatter.
- `research` — summarize external references from primary sources.
- `domain-modeling` — update canonical terminology when the project model genuinely changes.
- `shared-understanding` — resolve scope and information-policy choices before writing conclusions.
- `handoff` — record the implementation result for a later thread.
