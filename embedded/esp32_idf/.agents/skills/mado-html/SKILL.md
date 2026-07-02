---
name: mado-html
description: Create, continue, inspect, or modify Mado HTML Tutorial Documents as consistent standalone HTML files. Use when work involves structured tutorial documentation composed of ordered Sessions, especially when agents should edit one region at a time without loading or rewriting the complete document.
---

# Mado HTML

Run commands from the repository root. Use the bundled executable, pass the repository root explicitly with `--workspace .`, and treat its JSON stdout and exit code as the command contract:

```powershell
$mado = "mado-html"
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
Get-Content fragment.html -Raw |
  & $mado --workspace $workspace add-session docs/tutorial.html introduction `
    --title "Introduction" --stdin --expected-revision 0

& $mado --workspace $workspace update-session docs/tutorial.html introduction `
  --title "New Introduction" --expected-revision 1

Get-Content fragment.html -Raw |
  & $mado --workspace $workspace update-session docs/tutorial.html introduction `
    --stdin --expected-revision 2

& $mado --workspace $workspace move-session docs/tutorial.html introduction `
  --position 2 --expected-revision 3
```

Never retry a `revision_conflict` without inspecting the latest state.

4. Add or replace a named Diff Block when the change is best explained as code:

```powershell
& $mado --workspace $workspace set-diff-block docs/tutorial.html introduction model-change `
  --original-file old.rs --changed-file new.rs --language rust `
  --file-label "lib.rs" --path-label "src/" --append `
  --expected-revision 3
```

Use `list-diff-blocks` and `get-diff-block` before replacing one. New Diff Blocks require
`--before-block`, `--after-block`, or `--append`; replacements keep their existing position.
Use `remove-diff-block` with the latest revision to delete one.

5. Render only when a preview or finished document is required:

```powershell
& $mado --workspace $workspace render docs/tutorial.html
```

Rendering leaves the latest debug bundle under `.mado/renders/` with `render.md`, `render.json`, fragments, and a `Taskfile.yml`. To rerender from edited temp files, run `task render` inside that bundle.

## Content Contract

- Supply complete Session fragments through `--content-file` or `--stdin`.
- Use static prose, tables, links, code blocks, and accessible inline SVG.
- Use `<pre><code class="language-rust">...</code></pre>` for code and HTML-escape its text.
- Give SVG a `viewBox`, `role="img"`, and `aria-label` or `<title>`.
- Do not use scripts, event handlers, forms, embedded applications, remote assets, raster images, or Session-level styles.
- Keep Session IDs stable lowercase kebab-case. `header`, `footer`, and `document` are reserved.
- Keep Diff Block IDs unique within a Session and lowercase kebab-case.
- Diff Block source files must be UTF-8, at most 1 MiB each, and use a supported code language.
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
