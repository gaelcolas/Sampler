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
- Prefer splatting over backtick-based line continuation for multi-line command calls:

```powershell
# Preferred
$params = @{
    Path    = $OutputDirectory
    Recurse = $true
}
Get-ChildItem @params
```

- Use only ASCII characters in `.ps1` source files. Non-ASCII characters (em-dashes, smart quotes, Unicode arrows, etc.) trigger PSScriptAnalyzer rule `PSUseBOMForUnicodeEncodedFile`. Use `->` not Unicode arrows, `-` not dashes, straight quotes.

## Cross-platform path construction

- Never use hardcoded backslash separators inside `Join-Path -ChildPath` strings. On Linux/macOS, backslashes are not path separators; a `ChildPath` containing backslashes is treated as a single filename component, not a multi-level path.
- Build multi-level paths with chained `Join-Path` calls:

```powershell
# Wrong — backslash is not a separator on Linux
Join-Path -Path $root -ChildPath 'output\module\MyModule\*\MyModule.psd1'

# Correct
$p = Join-Path -Path $root -ChildPath 'output'
$p = Join-Path -Path $p    -ChildPath 'module'
$p = Join-Path -Path $p    -ChildPath $ModuleName
$p = Join-Path -Path $p    -ChildPath '*'
$p = Join-Path -Path $p    -ChildPath "$ModuleName.psd1"
```

- Never hard-code `\` in user-facing messages that include paths; use `Join-Path` to build the example path.

## State-changing functions (`SupportsShouldProcess`)

- Functions whose verb implies state change (`New-`, `Remove-`, `Set-`, `Start-`, etc.) must declare `[CmdletBinding(SupportsShouldProcess = $true)]` to satisfy PSScriptAnalyzer rule `PSUseShouldProcessForStateChangingFunctions`.
- Wrap the actual mutation with `if ($PSCmdlet.ShouldProcess($target, $action))`.
- In tests, pass `-Confirm:$false` to bypass the `ShouldProcess` prompt.

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
