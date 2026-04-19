---
description: 'Public function authoring instructions'
applyTo: 'Sampler/Public/*.ps1'
---

# Public Function Development Guidelines

Public functions are user-facing and are the most critical API surface of Sampler.

## Baseline structure (same as private functions)

- Use comment-based help with at least:
  - `.SYNOPSIS`
  - `.DESCRIPTION`
  - one `.EXAMPLE`
  - `.PARAMETER` help for every parameter.
- Use `[CmdletBinding()]` and include `[OutputType(...)]`.
- Use explicit .NET parameter types (`[System.String]`, `[System.Boolean]`, etc.).
- Keep parameter names and defaults stable unless intentionally introducing a breaking change.

## Validation model

- Prefer enums over `ValidateSet` for option lists that are reused or expected to evolve.
- Define enum values once and reuse them across commands/templates/tests to avoid drift.
- Use `ValidateSet` only for narrow, local, non-shared option lists.
- If an option list changes, update all three surfaces in the same change:
  - function parameter contract
  - template XML `Condition` logic
  - unit/integration tests that cover those options.

## Public-critical requirements

- Preserve backward compatibility by default; avoid parameter renames/removals.
- Any user-visible behavior change must include:
  - unit tests under `tests/Unit/Public/`
  - integration test updates if scaffolding/template behavior is affected
  - an `Unreleased` entry in `CHANGELOG.md`.
- Prefer non-interactive usability: users should be able to pass sufficient parameters to avoid prompts.
- If parameters are omitted and prompting is supported, prompts must be deterministic and covered by tests.

## Testing expectations

- Add or update a matching test file under `tests/Unit/Public/<FunctionName>.tests.ps1`.
- Validate both happy path and input validation failures.
- When commands support both non-interactive and prompted flows, cover both modes.
- Follow repository test conventions from the test-writing instructions file.
