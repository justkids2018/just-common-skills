# 08 HTML Output Standard

## Purpose

Define a unified HTML output contract for documentation publishing.

Markdown remains the single source of truth. HTML is a presentation artifact.

## Scope

Applies to:

1. `just-feature-doc-generator` HTML outputs
2. `just-document-release` HTML publishing package

## Source Of Truth Rule

1. `*.md` is canonical.
2. `*.html` must be generated from corresponding Markdown content.
3. Field semantics must remain consistent between Markdown and HTML.

## Output Location

For feature documents:

- Markdown: `doc/feature-docs/<feature>/`
- HTML: `doc/feature-docs/<feature>/html/`

Recommended HTML file names:

1. `01-requirement.html`
2. `02-logic.html`
3. `03-api.html`

## Minimal HTML Structure

Each HTML document should include:

1. Header: title, document type, feature name, version/date.
2. TOC: anchor navigation for all `h2/h3` sections.
3. Main content: semantic sections (`section`, `article`).
4. Footer: source markdown path, generated timestamp.

## Readability Rules

1. Max content width should be controlled for readability.
2. Heading hierarchy must be clear and consistent.
3. Tables and code-like blocks (if any) should support horizontal scrolling.
4. Mobile view should remain readable without layout breakage.

## Accessibility Rules

1. Use semantic tags and valid heading levels.
2. Images must have meaningful `alt` text.
3. Sufficient text/background contrast.
4. Interactive controls (if present) must be keyboard accessible.

## Consistency Rules

1. Shared typography and spacing scale across all exported docs.
2. Shared color tokens for status/severity labels.
3. Keep visual style stable across versions.

## Validation Checklist

Before publishing HTML package:

1. Markdown and HTML section list are aligned.
2. Required fields in API/requirement docs are not missing.
3. Links and anchors are valid.
4. No content drift from source Markdown.

## Ownership

1. Standard owner: `system-platform`
2. Execution owner: document-related skills