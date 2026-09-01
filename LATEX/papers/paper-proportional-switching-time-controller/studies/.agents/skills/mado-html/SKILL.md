---
name: mado-html
description: Create, inspect, and modify standalone Mado HTML Tutorial Documents one Session or Component at a time. Use for structured tutorials whose complete document structure and presentation must remain owned by Mado HTML.
---

# Mado HTML

Run commands from the repository root with the bundled executable. Pass the repository root through `--workspace .` and use normalized workspace-relative `.html` document paths.

```powershell
$mado = "skill/bin/mado-html.exe"
$workspace = "."
$document = "docs/tutorial.html"
```

The format 2 HTML file is canonical. Do not create or depend on companion JSON files, checkpoints, client-managed revisions, or separate `open` and `render` steps. Every accepted mutation locks, extracts, validates, renders, and atomically replaces the Tutorial Document. JSON stdout and the exit code are the CLI contract, except `--content-only`, which returns raw HTML.

## Workflow

1. Create a Tutorial Document only when the target does not exist:

```powershell
& $mado --workspace $workspace create $document --title "Tutorial title"
```

2. Inspect before changing anything:

```powershell
& $mado --workspace $workspace inspect $document
```

`inspect` returns the title, format version, ordered Session summaries, and nested Component summaries without Session content. Session summaries contain ID, title, position, content byte count, and Components. Component summaries contain ID, kind, parent ID, and content byte count.

3. Read only the Editable Region needed for the task:

```powershell
& $mado --workspace $workspace get-session $document introduction
& $mado --workspace $workspace get-session $document introduction --content-only

& $mado --workspace $workspace get-component $document introduction retry-flow
& $mado --workspace $workspace get-component $document introduction retry-flow --content-only
```

4. Prefer stdin so no intermediary fragment remains. Use `--content-file` only for a caller-owned file, and delete scratch files after use:

```powershell
@'
<p>Introduction content.</p>
'@ | & $mado --workspace $workspace add-session $document introduction `
  --title "Introduction" --stdin

Get-Content $env:TEMP\mado-introduction.html -Raw |
  & $mado --workspace $workspace set-session $document introduction --stdin
```

`add-session` requires content and creates a new Session. `set-session` changes an existing Session's optional `--title`, content, or both. Never use `set-session` when the intended ID is absent.

5. Use the remaining Session commands as needed:

```powershell
& $mado --workspace $workspace set-title $document --title "New title"
& $mado --workspace $workspace move-session $document introduction --position 2
& $mado --workspace $workspace remove-session $document obsolete
```

Positions are one-based. `add-session` accepts optional `--position`; without it, the Session is appended.

6. Replace an existing Component without rewriting its Session:

```powershell
Get-Content $env:TEMP\mado-retry-flow.html -Raw |
  & $mado --workspace $workspace set-component $document introduction retry-flow --stdin
```

The replacement root must carry `data-mado-component-id="retry-flow"`. `get-component` and `set-component` work only with existing Components. Add, remove, or move a Component by replacing its containing Session.

## Content contract

Ordinary authored content is static validated HTML or accessible inline SVG.

- Keep Session IDs stable, unique within the Tutorial Document, and lowercase kebab-case.
- Mark a generic Component with `data-mado-component-id="component-id"`.
- Keep Component IDs stable, unique within their Session, and lowercase kebab-case.
- Components may be nested in ordinary Session content. Replacing a parent replaces its complete subtree, including nested Components.
- Do not mark Laboratory internals as parent-document Components; replace the Laboratory to edit its internal source.
- A replacement cannot introduce an ID that conflicts with a Component outside the replaced subtree.
- Use semantic HTML, links, tables, lists, code, native disclosure controls, and accessible inline SVG.
- Give inline SVG a `viewBox`, `role="img"`, and either `aria-label` or `<title>`.
- HTML-escape code text inside `<pre><code class="language-rust">...</code></pre>`.
- Do not use scripts, styles, event handlers, interactive controls, embedded applications, document-level elements, unsafe URLs, raster images, or external assets outside a Laboratory.

Malformed, unsafe, duplicate-ID, and unsupported-format mutations must fail without changing the Tutorial Document.

## Laboratories

A Laboratory is the only executable authored content. Static instructions alone are not a Laboratory. Author it as an inert template with local HTML, CSS, and JavaScript:

```html
<template
  data-mado-component-id="retry-laboratory"
  data-mado-component-kind="laboratory"
  data-mado-title="Retry behavior"
>
  <style>output { display: block; }</style>
  <button id="retry" type="button">Retry</button>
  <output id="result"></output>
  <script>
    document.querySelector("#retry").addEventListener("click", () => {
      document.querySelector("#result").textContent = "Retried";
    });
  </script>
</template>
```

Mado HTML validates and normalizes this source, then runs it in a sandboxed inline frame without parent-document or same-origin access. Its policies block storage, fetches, subresources, forms, child frames, workers, popups, and top-level navigation. Absolute network isolation is not guaranteed because arbitrary JavaScript may navigate its own frame in some browsers. `get-component` recovers the inert template source. `set-component` accepts the same form. Use no Laboratory-specific command.

## Commands

Use only:

- `create`
- `inspect`
- `set-title`
- `get-session`
- `add-session`
- `set-session`
- `move-session`
- `remove-session`
- `get-component`
- `set-component`

Do not use or propose `mado-diagram`, Generated Diagrams, structured Diff Blocks, Tree-sitter syntax highlighting, raster images, external assets, checkpoints, revisions, `open`, or explicit `render` operations.
