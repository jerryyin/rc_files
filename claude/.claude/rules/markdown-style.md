# Markdown / Prose Output Style

## No hard line breaks in prose (proseWrap: never)

When you write or edit Markdown or long-form text — docs, READMEs, reports, tickets, design notes, PR/commit bodies, and prose comments — do NOT insert hard line breaks inside a block. Write each paragraph as one continuous physical line and let the editor soft-wrap it. This applies generically to any Markdown you produce, in any project. Do not wrap prose at 80/100 columns.

- One paragraph = one physical line. Likewise, each list item, each table row, each blockquote line, and each footnote is a single line, however long.
- "No line break" means no break *within* a block, not merging blocks. Keep the blank line between paragraphs, and keep list items as separate lines/items.
- Never force a mid-paragraph break with two trailing spaces or a backslash.
- Scope is text you populate or rewrite. Do not reflow prose you are otherwise leaving untouched (avoid noisy whitespace-only diffs).
- Consistency exception: when editing an existing file that is already hard-wrapped, match that file's convention rather than introducing a mixed style; unwrapped-by-default is for new files and freshly written sections.
- Real newlines are preserved (never collapsed) in: fenced/indented code blocks, YAML/TOML frontmatter, and ASCII tables or diagrams where column alignment matters.
- Mechanical equivalent, if a formatter is in play: Prettier `proseWrap: "never"`, or `mdformat --wrap no`.
