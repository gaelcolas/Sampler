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
- Follow DSC Community parameter style: `[Parameter()]` attribute, type, and variable name each on their own line, with a blank line between comma-separated parameter declarations:

```powershell
param
(
    [Parameter(Mandatory = $true)]
    [System.String]
    $ProjectName,

    [Parameter()]
    [System.Management.Automation.SwitchParameter]
    $Force
)
```

## PowerShell style

- Prefer `$null = <expression>` over `<expression> | Out-Null` to suppress output.
- Prefer splatting over backtick-based line continuation for multi-line command calls.
- Never use hardcoded backslash separators inside `Join-Path -ChildPath` strings. Build multi-level paths with chained `Join-Path` calls (one component at a time). Backslashes in a `ChildPath` are not path separators on Linux/macOS.
- Use only ASCII characters in `.ps1` source files. Non-ASCII characters (em-dashes, smart quotes, Unicode arrows, etc.) trigger PSScriptAnalyzer rule `PSUseBOMForUnicodeEncodedFile`. Use `->` not Unicode arrows, `-` not dashes, straight quotes.

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
