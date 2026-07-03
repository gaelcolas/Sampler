---
name: validate-changes
description: Run targeted Sampler test scopes to validate changes quickly and safely, then run the full test suite when needed for confidence before PRs.
argument-hint: What files or areas did you change, and how much validation do you want?
---

# Validate Changes with Sampler Tests

## Purpose

Run the right Sampler test scope for a change, fast first and broad only when needed.

## Use this skill when

- You changed PowerShell functions under `Sampler/Public` or `Sampler/Private`.
- You changed PowerShell classes and enums under `Sampler/Classes` or `Sampler/Enum`.
- You changed templates under `Sampler/Templates`.
- You changed build logic under `.build/tasks` or `build.yaml`.
- You need a confidence check before opening or updating a PR.

## Inputs

- `changed_paths`: list of changed files or folders.
- `target_test`: optional single test file path for focused validation.
- `run_quality_gate`: optional boolean to run HQRM checks.

## Decision flow

> **Mandatory:** every command in this skill must be invoked through `./build.ps1`. Do not run `Invoke-Pester` directly, do not call `Build-Module` directly, and do not manually prepend anything to `PSModulePath`. Running `./build.ps1 -ResolveDependency -Tasks noop` (or any other `-Tasks` invocation) is what bootstraps dependencies and wires `PSModulePath` for the current shell so the freshly built module is the one being tested. Direct test/build invocations bypass that setup and may report false results against a stale or incomplete artifact.

1. Bootstrap dependencies if needed.
- Command:
```powershell
./build.ps1 -ResolveDependency -Tasks noop
```

2. Pick the smallest useful test scope first.
- If `target_test` is provided, run only that test file:
```powershell
./build.ps1 -Tasks test -PesterPath '<target_test>' -CodeCoverageThreshold 0
```
- Else if changes are only in a specific function area, run a focused unit test file in `tests/Unit/**`.

3. Expand based on change type.
- If any file under `Sampler/Templates/**` changed: run template integration tests:
```powershell
./build.ps1 -Tasks test -PesterPath 'tests/Integration/PlasterTemplates' -CodeCoverageThreshold 0
```
- If build/task wiring changed (`.build/tasks/**`, `build.yaml`, `build.ps1`): run default test workflow:
```powershell
./build.ps1 -Tasks test
```

4. Run broad integration only when needed.
- For cross-template or workflow-impacting changes:
```powershell
./build.ps1 -Tasks test -PesterPath 'tests/Integration' -CodeCoverageThreshold 0
```

5. Optional release-quality gate.
- If `run_quality_gate` is true, run:
```powershell
./build.ps1 -Tasks hqrmtest
```

## Running these commands without hanging

Always tee `./build.ps1` output to `output\agentic\` — this subfolder is excluded from the `Clean` task so logs survive between builds. Create it first, then stream:

```powershell
$null = New-Item -Path 'output\agentic' -ItemType Directory -Force

./build.ps1 -Tasks test -PesterPath '<paths>' -CodeCoverageThreshold 0 2>&1 |
    Tee-Object -FilePath 'output\agentic\test.log'

# Then poll/inspect the log without re-running:
Get-Content output\agentic\test.log -Tail 20
Select-String -Path output\agentic\test.log -Pattern 'Build (FAILED|succeeded)'
```

**Clean up when done:** Remove `output\agentic` once investigation is complete:

```powershell
Remove-Item -Path 'output\agentic' -Recurse -Force -ErrorAction 'Ignore'
```

When invoked through the `powershell` tool, prefer `mode="async"` with `Tee-Object` and poll periodically — never tail with `| Select -Last N` against a still-running build.

## Diagnosing failures from XML output

Test failures are recorded in machine-readable XML under `output/testResults/`. Always read those files instead of grepping the build log — they tell you *which* tests failed and *why*.

- **The build summary's "N errors" count is not a reliable pass/fail signal.** `./build.ps1` prints a final line like `Build completed with errors. 98 tasks, 8 errors, 3 warnings`, but this count reflects everything written to the PowerShell error stream during the run — including caught/non-terminating errors that scripts intentionally handle (for example, `Add-Sample` and `New-SamplerPipeline` write to `$Error` internally while probing dynamic parameters, even though they catch and continue). A non-zero error count here does not mean any test failed. Always confirm actual failures via the NUnit/HQRM result files below before reporting a failure to the user.

- **Pester (`-Tasks test`)** writes NUnit XML at `output/testResults/NUnitXml_<ProjectName>_<Version>.<OS>.PSv.<PSVersion>.xml`. Each failing assertion is a `<test-case result="Failure">` node with the assertion message under `<failure><message>`:

  ```powershell
  $latest = Get-ChildItem output\testResults\NUnitXml_*.xml |
      Sort-Object LastWriteTime -Descending | Select-Object -First 1
  [xml]$x = Get-Content $latest.FullName
  $x.SelectNodes('//test-case[@result="Failure"]') | ForEach-Object {
      "==FAIL==`n$($_.name)`n$($_.failure.message)`n"
  }
  ```

- **HQRM (`-Tasks hqrmtest`)** writes a CliXml-serialized Pester run object at `output/testResults/DscTestObject_DscTest_<ProjectName>_<Version>.<OS>.PSv.<PSVersion>.xml`. This is **not** NUnit XML — XPath against `<test-case>` returns nothing. Look for `<S N="Result">Failed</S>` and read surrounding context, or grep `DisplayErrorMessage` for the assertion text:

  ```powershell
  $f = Get-ChildItem output\testResults\DscTestObject_DscTest_*.xml |
      Sort-Object LastWriteTime -Descending | Select-Object -First 1
  $lines = Get-Content $f.FullName
  foreach ($h in Select-String -Path $f.FullName -Pattern '"Result">Failed')
  {
      "===line $($h.LineNumber)==="
      $lines[($h.LineNumber - 1)..($h.LineNumber + 20)] -join "`n"
  }
  Select-String -Path $f.FullName -Pattern 'DisplayErrorMessage'
  ```

  Skip aggregate `Result=Failed` nodes (run/container totals) — real test failures sit alongside an `<S N="ItemType">Test</S>`, an `ErrorRecord`, and a `ScriptBlock`.

- Always pick the **latest** result file (`Sort-Object LastWriteTime -Descending`); each invocation rewrites these XML files.
- When reporting a failure to the user, quote the XML's assertion message — do not paraphrase the build-log tail.

## Completion checks

- All selected test commands exit successfully.
- For template changes: corresponding integration tests pass.
- For public/private function changes: relevant unit tests pass.
- If behavior is user-visible: ensure `CHANGELOG.md` has an `Unreleased` entry.
- **Before declaring work complete on any PR-bound change, run the full `./build.ps1 -Tasks test` suite** (not just focused tests). Focused tests validate the changed scope; the full suite catches HQRM, ScriptAnalyzer, help quality, and test-coverage regressions that focused runs skip. A focused run passing is a necessary but not sufficient condition for readiness.

## Report format

Return a short summary with:
- Commands run
- Pass/fail per scope
- Any failing test file paths
- Suggested next command (if failures occurred)

## Example prompts

- "Validate my edits in `Sampler/Public/New-SampleModule.ps1` quickly."
- "I changed `Sampler/Templates/Sampler/plasterManifest.xml`; run the right tests."
- "Run full validation for my current branch, including HQRM."
