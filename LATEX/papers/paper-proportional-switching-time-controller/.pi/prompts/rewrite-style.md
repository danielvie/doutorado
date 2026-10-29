---
description: Rewrite manuscript text using the local language and style guidelines
argument-hint: "<section name or pasted text>"
---
Rewrite the following section or text according to "Manuscript language and style" in the paper-root AGENTS.md. Read that file before rewriting.

Target:
$ARGUMENTS

Identify the intended message first. Then draft a connected argument, combining closely related ideas and varying sentence length. The preliminary statements are a content checklist, not a template for the paragraph.

Preserve the mathematics, notation, citations, and scientific claims, including their scope and qualifications. Keep the changes confined to the requested text. Read the surrounding passage when working in the manuscript, and respect protected text.

For a named manuscript section, apply the rewrite in latex/main.tex and run `task build` from the paper root. For pasted text, return the proposed rewrite without editing files.

If the target is missing or ambiguous, ask which passage to rewrite.
