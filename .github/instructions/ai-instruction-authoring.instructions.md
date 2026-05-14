---
applyTo: "{.github/instructions/*.md,.github/prompts/*.md,.github/skills/*.md,**/AGENTS.md,.github/copilot-instructions.md}"
---

# AI Instruction Authoring

These files are AI-only. No human-facing prose, tutorials, or rationale. Meant to
reduce token usage, eliminate conflicting information and ensure precise, clear,
concise guidance.

## Rules

- Write short imperative directives. Bullet lists over prose.
- Remove filler words, redundant qualifiers, repeated context.
- Omit *why* unless the reason changes behaviour.
- Check existing instructions before adding rules. Update existing rules on conflict; never duplicate.
- Use narrowest `applyTo` glob possible. Never `**/*` when a specific
  path suffices. `ApplyTo` attribute must be a string, never an array.
- Start each file, except copilot-instructions.md and **/AGENTS.md, with YAML
  frontmatter `applyTo`
- Use `##`/`###` headings, `-` bullets, backticks for code tokens, fenced blocks for multi-line examples.
- No bold/italic emphasis, conversational tone, or verbose examples.
