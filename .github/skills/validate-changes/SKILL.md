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

Always tee `./build.ps1` output to a log file rather than wrapping the call in `| Select-Object -Last <N>` (or any other buffering filter). Inline `Select-Object` against a long-running pipeline forces full-stream buffering and the agent shell appears to hang — even after the build finishes — and would also swallow any unexpected prompt. Instead, stream freely and read the log:

```powershell
if (Test-Path output\validate-test.log) { Remove-Item output\validate-test.log -Force }

./build.ps1 -Tasks test -PesterPath '<paths>' -CodeCoverageThreshold 0 2>&1 |
    Tee-Object -FilePath output\validate-test.log

# Then poll/inspect the log without re-running:
Get-Content output\validate-test.log -Tail 20
Select-String -Path output\validate-test.log -Pattern 'Build (FAILED|succeeded)'
```

When invoked through the `powershell` tool, prefer `mode="async"` with `Tee-Object` and poll periodically — never tail with `| Select -Last N` against a still-running build.

## Diagnosing failures from XML output

Test failures are recorded in machine-readable XML under `output/testResults/`. Always read those files instead of grepping the build log — they tell you *which* tests failed and *why*.

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
