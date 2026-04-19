---
description: 'Plaster template change safety instructions'
applyTo: 'Sampler/Templates/**'
---

# Plaster Template Development Guidelines

Templates under `Sampler/Templates/` are product code. Any change must preserve scaffold behavior for users and CI.

## Required test updates

- Every template change must include updates to the matching integration tests under `tests/Integration/PlasterTemplates/**`.
- Do not ship template-only changes without validating and updating expected scaffold outputs.
- For changes that affect generated file trees, update the corresponding `$listOfExpectedFilesAndFolders` arrays.

## Parameter compatibility

- Treat template parameters as a public contract consumed by `Invoke-Plaster` and Sampler public commands.
- Do not rename, remove, or change semantics of existing parameters unless intentionally making a breaking change.
- Keep function `ValidateSet` definitions aligned with template-supported values. Any option available in templates must be represented in the corresponding command parameter `ValidateSet`, and stale values must be removed when template support is removed.
- When template choices change, update and verify `ValidateSet` coverage in public commands, especially `Add-Sample` and `New-SampleModule`.
- Keep Plaster XML `Condition` composition aligned with command parameters and `ValidateSet` values. When adding, removing, or renaming options, update the related template `Condition` expressions so generated content is gated by the same logic users select through Sampler commands.
- Treat command `ValidateSet` values and template XML `Condition` expressions as a single contract: they must evolve together in the same change.
- `Add-Sample` and `New-SampleModule` must support both usage modes:
  - Non-interactive: users can pass enough parameters to avoid prompts entirely.
  - Interactive: when required details are omitted, Sampler prompts for the missing information.
- If a parameter contract changes, update:
  - Integration tests that call `Invoke-Plaster`.
  - Public command tests that validate template invocation (for example, tests for `Add-Sample`, `New-SampleModule`, `New-SamplerPipeline`).
  - `CHANGELOG.md` with an `Unreleased` entry.

## Cross-instruction alignment

- When template changes affect command parameters, validation, or prompting behavior, also follow the function authoring instructions for:
  - `Sampler/Public/*.ps1`
  - `Sampler/Private/*.ps1`
- Keep template changes and function-surface changes in the same pull request so contract alignment can be reviewed atomically.

## Integration test pattern to follow

- Use `Invoke-Plaster` inside a throwing assertion:
  - `{ Invoke-Plaster @invokePlasterParameters } | Should -Not -Throw`
- Validate generated structure by comparing relative paths from `$TestDrive` output with expected paths.
- Normalize path separators when comparing expected trees:
  - Convert `\` to `/` for cross-platform consistency.
- When structure mismatches occur, emit directory tree diagnostics (via integration helpers) to make failures actionable.

## Scope and coverage

- Add or update test contexts for each meaningful feature toggle combination impacted by the change (for example `UseGitVersion`, `UseAzurePipelines`, optional sub-features).
- Prefer extending existing template integration tests in `tests/Integration/PlasterTemplates/` over creating duplicate coverage.
- Keep expected file lists explicit; avoid wildcard assertions that hide regressions.

## Backward compatibility principle

- Prefer additive template changes (new optional files/parameters) over destructive changes.
- If behavior must change, preserve compatibility through defaults where possible and document migration impact in changelog notes.
