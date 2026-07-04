---
name: mado-html
description: Create, continue, inspect, or modify Mado HTML Tutorial Documents as consistent standalone HTML files. Use when work involves structured tutorial documentation composed of ordered Sessions, especially when agents should edit one region at a time without loading or rewriting the complete document.
---

# Mado HTML

Run commands from the repository root. Use the bundled executable, pass the repository root explicitly with `--workspace .`, and treat its JSON stdout and exit code as the command contract. Keep scratch fragments, diagram sources, and other intermediary files under `.mado-html/work/`; do not create temporary authoring files in `docs/` or beside the final document.

```powershell
$mado = "mado-html.exe"
$workspace = "."
```

## Workflow

1. Open or resume the Tutorial Document:

```powershell
& $mado --workspace $workspace open docs/tutorial.html --title "Tutorial Title"
```

`--title` is required only when neither a checkpoint nor document exists.

2. Inspect before changing:

```powershell
& $mado --workspace $workspace metadata docs/tutorial.html
& $mado --workspace $workspace list-sessions docs/tutorial.html
& $mado --workspace $workspace get-session docs/tutorial.html session-id
```

Read only the Session being changed. Use `--content-only` when raw HTML is more useful than JSON.

3. Mutate with the latest returned revision:

```powershell
Get-Content .mado-html/work/tutorial/introduction.html -Raw |
  & $mado --workspace $workspace add-session docs/tutorial.html introduction `
    --title "Introduction" --stdin --expected-revision 0

& $mado --workspace $workspace update-session docs/tutorial.html introduction `
  --title "New Introduction" --expected-revision 1

Get-Content .mado-html/work/tutorial/introduction.html -Raw |
  & $mado --workspace $workspace update-session docs/tutorial.html introduction `
    --stdin --expected-revision 2

& $mado --workspace $workspace move-session docs/tutorial.html introduction `
  --position 2 --expected-revision 3
```

Never retry a `revision_conflict` without inspecting the latest state.

4. Inspect or replace a named code block or inline SVG component inside a Session:

```powershell
& $mado --workspace $workspace list-components docs/tutorial.html introduction
& $mado --workspace $workspace get-component docs/tutorial.html introduction code-1 --content

Get-Content .mado-html/work/tutorial/code-1.html -Raw |
  & $mado --workspace $workspace set-component docs/tutorial.html introduction code-1 `
    --stdin --expected-revision 3
```

`set-component` replaces existing code blocks or inline SVG only. Use `get-component` first,
edit the returned `content_html`, and keep the same `component_id` argument.

5. Generate, set, or remove a source-backed diagram Component:

```powershell
& $mado --workspace $workspace validate-diagram `
  --diagram-type sequence --diagram-format plantuml --source-file .mado-html/work/tutorial/flow.puml

& $mado --workspace $workspace render-diagram `
  --diagram-type sequence --diagram-format plantuml --source-file .mado-html/work/tutorial/flow.puml --output .mado-html/work/tutorial/flow.svg

& $mado --workspace $workspace set-diagram-component docs/tutorial.html introduction login-flow `
  --diagram-type sequence --diagram-format plantuml --source-file .mado-html/work/tutorial/flow.puml `
  --append --expected-revision 3

& $mado --workspace $workspace remove-diagram-component docs/tutorial.html introduction login-flow `
  --expected-revision 4
```

Supported v1 diagram types are `sequence`, `state`, and `timeline`. The only v1 diagram format is `plantuml`, meaning Mado's strict PlantUML-like subset, not full PlantUML compatibility. Unsupported syntax is rejected with line-specific errors. New diagram Components require `--append`, `--before-component`, or `--after-component`; before/after anchors target inline Components, not Diff Blocks. Replacements keep their existing position and must not include placement flags. `get-component --content` returns both `source` and `rendered_svg` for Generated Diagrams.

Diagram type chooser:

- `sequence`: ordered message flow between participants.
- `state`: state transitions.
- `timeline`: duration of work across lanes over time, such as cores, threads, hardware resources, or subsystems.

For a Generated Diagram, write and edit only the `.puml` source under `.mado-html/work/`, run `validate-diagram`, then use `set-diagram-component`. Do not manually edit rendered SVG unless debugging renderer output.

Timeline syntax:

```plantuml
@startuml
title Expected 280 us Control Cycle
scale 0 to 280 us
ticks 0 70 140 210 280

lane adc: ADC hardware
task hardware 0 64: AN3/AN5/AN6 triple

lane core0: Core 0 acquisition
task 60 12: parse + LUT + publish

lane core1: Core 1 signal/control
task critical 0 210: deterministic playback
task 210 36: read snapshot

marker 210: control update point
note: latest complete snapshot age < half-cycle
@enduml
```

Timeline contract:

- `scale <start> to <end> <unit>` defines one numeric time scale.
- Optional `ticks <time> ...` pins timestamp guides; otherwise ticks are automatic.
- `lane <id>: <label>` creates an ordered lane.
- `task [work|hardware|critical|wait|io] <start> <duration>: <label>` adds a task to the current lane; category defaults to `work`.
- `marker <time>: <label>` adds a global timestamp marker.
- `note: <text>` and `note lane <lane-id>: <text>` add annotations.
- Tasks, ticks, and markers must fit inside the scale; tasks in the same lane must not overlap.
- Use `hardware` for hardware-paced work, `critical` for critical-path work, `wait` for idle/no-work regions, and `io` for communication/status work.

6. Add or replace a named Diff Block when the change is best explained as code:

```powershell
& $mado --workspace $workspace set-diff-block docs/tutorial.html introduction model-change `
  --original-file old.rs --changed-file new.rs --language rust `
  --file-label "lib.rs" --path-label "src/" --append `
  --expected-revision 3
```

Use `list-components` or `get-component` to discover Diff Block ids before replacing one.
New Diff Blocks require `--before-block`, `--after-block`, or `--append`; replacements keep
their existing position. Use `remove-diff-block` with the latest revision to delete one.

7. Render only when a preview or finished document is required:

```powershell
& $mado --workspace $workspace render docs/tutorial.html
```

Rendering leaves the latest debug bundle under `.mado-html/renders/` with `render.md`, `render.json`, fragments, and a `Taskfile.yml`. To rerender from edited temp files, run `task render` inside that bundle.

## Content Contract

- Supply complete Session fragments through `--content-file` or `--stdin`; store intermediary authoring files under `.mado-html/work/`, not `docs/`.
- Use static prose, tables, links, code blocks, and accessible inline SVG.
- Use `<pre><code class="language-rust">...</code></pre>` for code and HTML-escape its text.
- Code blocks, inline SVG, and Generated Diagrams use session-local `data-mado-component-id` values.
- Give manual SVG a `viewBox`, `role="img"`, and `aria-label` or `<title>`.
- Use the approved SVG palette classes such as `.chart-level-*`, `.chart-muted`, `.chart-warn`, `.arrow`, `.arrow-head`, `.label`, `.small`, and `.lane` instead of literal `fill`/`stroke` colors.
- Do not use scripts, event handlers, forms, embedded applications, remote assets, raster images, or Session-level styles.
- Keep Session IDs stable lowercase kebab-case. `header`, `footer`, and `document` are reserved.
- Keep Diff Block and diagram Component IDs unique within a Session and lowercase kebab-case.
- Diff Block source files must be UTF-8, at most 1 MiB each, and use a supported code language.
- Diagram source files must be UTF-8, at most 256 KiB each, and use the supported `plantuml` subset for `sequence`, `state`, or `timeline` diagrams.
- Split Sessions when practical if `list-sessions` reports large content.

## Other Commands

```powershell
& $mado --workspace $workspace set-metadata docs/tutorial.html `
  --technology-stack "Rust, Tree-sitter" `
  --key-concepts "Sessions, checkpoints, recovery" `
  --domain "Technical documentation" `
  --core-question "How can agents edit a document without rewriting it?" `
  --expected-revision 4

& $mado --workspace $workspace set-metadata docs/tutorial.html --title "Title" --expected-revision 5
& $mado --workspace $workspace clear-content docs/tutorial.html header --expected-revision 6
& $mado --workspace $workspace remove-session docs/tutorial.html obsolete --expected-revision 7
```

For header/footer HTML, use `--header-file`, `--header-stdin`, `--footer-file`, or `--footer-stdin`.
Use the four semantic metadata fields for short concepts that help readers understand the subject. Omit fields that add no value; the aside is hidden when all are empty.

When a command returns `rewrite_required`, do not overwrite the existing file. Report that it is not valid recoverable Mado HTML and request explicit rewrite approval.
