---
description: 'Private function authoring instructions'
applyTo: 'Sampler/Private/*.ps1'
---

# Private Function Development Guidelines

Private functions follow the same baseline engineering rules as public functions, even though they are not user-facing.

## Baseline structure (same as public functions)

- Use comment-based help with at least:
  - `.SYNOPSIS`
  - `.DESCRIPTION`
  - one `.EXAMPLE`
  - `.PARAMETER` help for every parameter.
- Use `[CmdletBinding()]` and include `[OutputType(...)]`.
- Use explicit .NET parameter types (`[System.String]`, `[System.Boolean]`, etc.).
- Keep parameter names and defaults stable when consumed by public functions/tasks.

## Validation model

- Prefer enums over `ValidateSet` for option lists that are reused or expected to evolve.
- Define enum values once and reuse them across commands/templates/tests to avoid drift.
- Use `ValidateSet` only for narrow, local, non-shared option lists.
- If an option list changes and affects command/template flow, update all three surfaces in the same change:
  - function parameter contract
  - template XML `Condition` logic
  - unit/integration tests that cover those options.

## Private-specific expectations

- Keep private functions focused and composable; avoid embedding user interaction directly in private helpers unless explicitly required by design.
- If a private function feeds user-facing behavior, treat compatibility and test coverage with the same rigor as a public function.

## Testing expectations

- Add or update matching tests under `tests/Unit/Private/<FunctionName>.tests.ps1`.
- Validate both happy path and input validation failures.
- Follow repository test conventions from the test-writing instructions file.
