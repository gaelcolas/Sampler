# Copilot instructions for Sampler

## Build, test, and quality commands

Use `build.ps1` as the entry point for local work. It bootstraps dependencies into `output/RequiredModules`, prepends the built module path to `PSModulePath`, and then delegates to InvokeBuild workflows defined in `build.yaml`.

### Mandatory rule — never bypass `build.ps1`

- Always build the module with `./build.ps1 -Tasks build`. Never invoke `Build-Module` (or any other ModuleBuilder cmdlet) directly, and never copy files into `output/module/**` by hand. Bypassing the InvokeBuild pipeline produces an incomplete artifact (missing `Templates/`, `en-US/`, `scripts/`, `tasks/`), which silently breaks Plaster-driven commands such as `New-SampleModule` and any test that imports the built module.
- Always run tests with `./build.ps1 -Tasks test ...`. Do not call `Invoke-Pester` directly against `tests/**` from a fresh shell — `build.ps1` is what configures `PSModulePath`, ensures the module is freshly built, and applies the Pester configuration from `build.yaml`. Direct `Invoke-Pester` runs may pick up a stale or partial build and report misleading failures.
- Always set up the environment through `build.ps1`. Do not manually prepend `output/RequiredModules` or `output/module` to `PSModulePath`. Instead, run `./build.ps1 -ResolveDependency -Tasks noop` (or any other `-Tasks <name>` invocation) at the start of a session — it bootstraps dependencies and configures `PSModulePath` for the current shell so subsequent `Import-Module Sampler -Force` calls resolve the freshly built artifact.
- After `./build.ps1 -Tasks build` completes in the current shell, `Import-Module Sampler -Force` is sufficient to load the built module for ad-hoc verification (for example, running `New-SampleModule` against a scratch path). Do not start a separate PowerShell session to test — the path setup performed by `build.ps1` only applies to the shell that ran it.
- The same rule applies inside agents, skills, and CI helpers: every build/test/validation step must go through `./build.ps1`. If a workflow appears to require something `build.ps1` does not expose, extend `build.yaml` (or a `.build/tasks/*.build.ps1` task) instead of working around it.

```powershell
# Restore required modules into output/RequiredModules
./build.ps1 -ResolveDependency -Tasks noop

# Build the module into output/module/Sampler/<version>
./build.ps1 -Tasks build

# Run the default test workflow from build.yaml
./build.ps1 -Tasks test

# Run a single Pester file
./build.ps1 -Tasks test -PesterPath 'tests/Unit/Public/New-SampleModule.tests.ps1' -CodeCoverageThreshold 0

# Run all integration tests
./build.ps1 -Tasks test -PesterPath 'tests/Integration' -CodeCoverageThreshold 0

# Run the repo's HQRM/quality gate
./build.ps1 -Tasks hqrmtest
```

`build.yaml` is the source of truth for workflow aliases (`build`, `test`, `docs`, `pack`, `hqrmtest`, `publish`) and for Pester configuration such as default test paths and coverage thresholds.

### Running build/test commands without hanging the agent shell

Sampler builds and tests are slow (task discovery alone is ~60–120s; a focused integration test pass is 2+ minutes) and emit a lot of progress output. Two pitfalls to avoid:

- **Never wrap the `./build.ps1 ...` invocation in `| Select-Object -Last <N>` (or `| Select-Object -First <N>`, `| Out-String -Stream | Select-Object ...`, etc.) inline.** Those filters force PowerShell to buffer the *entire* output stream before emitting anything, and the wrapping pipeline call appears to hang from the agent's perspective even after the build has finished. Worse, if the build asks for input (it should not, but ResolveDependency prompts can sneak in), the prompt is buried in the buffer and the shell is effectively stuck.
- **Always tee the output to a log file and then inspect that log file separately**, so the build can stream freely and the agent can poll the log without consuming context with the entire output.

Recommended pattern (works in both sync and async modes):

```powershell
if (Test-Path output\validate-test.log) { Remove-Item output\validate-test.log -Force }

./build.ps1 -Tasks test -PesterPath '<paths>' -CodeCoverageThreshold 0 2>&1 |
    Tee-Object -FilePath output\validate-test.log
```

Then, while the build runs (or after it completes), inspect the log without re-running anything:

```powershell
# Quick status / tail
Get-Item   output\validate-test.log | Select-Object Length, LastWriteTime
Get-Content output\validate-test.log -Tail 20

# Look for the conventional "Build FAILED" / "Build succeeded" terminator
Select-String -Path output\validate-test.log -Pattern 'Build (FAILED|succeeded)'
```

When running long commands through the `powershell` tool, prefer `mode="async"` with `Tee-Object`, then poll with short `read_powershell` reads or by reading the log file directly. Do not pass `| Select-Object -Last N` as a workaround for wanting a short response — read the log file with `Get-Content -Tail` instead.

### Diagnosing test failures from XML output

`build.ps1 -Tasks test` and `-Tasks hqrmtest` both write structured XML test results under `output/testResults/`. Always go to those files first — they tell you exactly which tests failed and why, instead of having to scroll through thousands of lines of build log.

- **Pester results (NUnit XML)** — written by the regular `test` workflow:
  - `output/testResults/NUnitXml_<ProjectName>_<Version>.<OS>.PSv.<PSVersion>.xml`
  - Each failing test case is a `<test-case result="Failure" ...>` node whose `<failure><message>` element contains the assertion message (e.g. the `-Because` text from `Should -BeTrue -Because ...`). Use this XPath to enumerate failures:

    ```powershell
    $latest = Get-ChildItem output\testResults\NUnitXml_*.xml |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    [xml]$x = Get-Content $latest.FullName
    $x.SelectNodes('//test-case[@result="Failure"]') | ForEach-Object {
        "==FAIL==`n$($_.name)`n$($_.failure.message)`n"
    }
    ```

- **HQRM / DscResource.Test results (Pester object XML, CliXml)** — written by the `hqrmtest` workflow, and also by the `test` workflow when HQRM tasks are wired in:
  - `output/testResults/DscTestObject_DscTest_<ProjectName>_<Version>.<OS>.PSv.<PSVersion>.xml`
  - This file is a CliXml-serialized Pester run object, **not** NUnit XML — XPath against `<test-case>` will return nothing. Search for `<S N="Result">Failed</S>` and read the surrounding context, or look for `<S N="DisplayErrorMessage">` for the human-readable assertion text:

    ```powershell
    $hqrm = 'output\testResults\DscTestObject_DscTest_<ProjectName>_*.xml'
    $f = Get-ChildItem $hqrm | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $lines = Get-Content $f.FullName
    $hits  = Select-String -Path $f.FullName -Pattern '"Result">Failed'
    foreach ($h in $hits)
    {
        "===line $($h.LineNumber)==="
        $lines[($h.LineNumber - 1)..($h.LineNumber + 20)] -join "`n"
    }

    # Or jump straight to the assertion messages
    Select-String -Path $f.FullName -Pattern 'DisplayErrorMessage'
    ```

  - The first `<S N="Result">Failed</S>` you encounter is usually a *summary* node (e.g. a `Run` or `Container` total) rather than a real test — ignore those and look for ones whose surrounding context contains `<S N="ItemType">Test</S>`, an `ErrorRecord`, or a `ScriptBlock`.

- **Always look at the *latest* result file**: every test invocation rewrites these XML files, so sort by `LastWriteTime` descending instead of relying on a hard-coded path.
- The failing-test summary written to the log file (e.g. `Build FAILED. N tasks, 1 errors, ...`) tells you *that* something failed; only the XML tells you *what* failed. Quote the XML message in any report back to the user — do not paraphrase the build-log tail.

## High-level architecture

- `Sampler/` is the module source. `Sampler.psm1` dot-sources everything under `Public/` and `Private/` and exports public function basenames but is rarely used as it's overridden during build by the built artifact under `output/module/`. The module is designed to be imported and used directly from the source tree for development when necessary, but the built artifact is the intended consumption method for users and CI.
- `Sampler/Templates/` is a major part of the product, not just support data. `New-SampleModule` and `New-SamplerPipeline` drive Plaster templates from this tree to scaffold new module and pipeline layouts. `Add-Sample` lets users add new sample scripts to existing modules, and it also relies on templates under `Sampler/Templates/`.
- `build.ps1` is the bootstrap/entry script; `.build/tasks/*.build.ps1` contains the local InvokeBuild task implementations; `build.yaml` composes those tasks into workflows and also imports extra tasks from required modules such as `DscResource.Test`, `DscResource.DocGenerator`, and `Sampler.GitHubTasks`.
- The build output is versioned under `output/module/<ProjectName>/<Version>`. Many tasks and tests work against that built artifact rather than the source tree.
- Tests are intentionally split by purpose:
  - `tests/Unit/` covers unit tests for public functions, private functions, scripts, and build tasks.
  - `tests/Integration/` validates generated projects and Plaster templates end to end.
  - `tests/QA/module.tests.ps1` adds repository-level quality rules such as changelog, ScriptAnalyzer, help, and test coverage expectations.

## Key conventions

- Prefer changing `build.yaml` when you need to alter workflow composition, default test paths, coverage behavior, copied build assets, or imported task modules. Keep `build.ps1` focused on bootstrap/runtime parameters.
- Build task scripts rely on dot-sourcing `Sampler/scripts/Set-SamplerTaskVariable.ps1` to populate shared variables like `ProjectName`, `SourcePath`, built module paths, and resolved version information. Reuse that pattern instead of re-deriving those values per task.
- Treat template changes as product changes. If you modify anything under `Sampler/Templates/`, update the matching integration tests under `tests/Integration/PlasterTemplates/` and preserve expected scaffolded file trees.
- The repo enforces changelog discipline through QA tests. For behavior changes that would ship, update `CHANGELOG.md` with an Unreleased entry.
- Public and private functions are expected to have comment-based help and corresponding unit tests; QA tests inspect `.SYNOPSIS`, `.DESCRIPTION`, examples, and parameter help for every exported function.
- Prefer `-ErrorAction 'Ignore'` over `-ErrorAction 'SilentlyContinue'` for cmdlet calls whose failure is *expected* (probes such as `Get-Command`, `Get-Module`, `Get-Item`, `Test-Path`-style lookups). `Ignore` does not append to `$Error`, keeping the error history clean for real diagnostics. Reserve `SilentlyContinue` for cases where you intentionally want the error recorded but not surfaced.
- Code must run on **both Windows PowerShell 5.1 (Desktop) and PowerShell 7+ (Core)**, and must work cross-platform on Windows, Linux, and macOS, unless the module manifest of the module under development declares otherwise (i.e. `PowerShellVersion` is `'7.0'` or higher and/or `CompatiblePSEditions` is restricted to `@('Core')`). Sampler itself targets `PowerShellVersion = '5.0'` with no `CompatiblePSEditions` restriction (see `Sampler/Sampler.psd1`), so any change to Sampler source, templates, build tasks, or scripts must:
  - Avoid PowerShell 7-only language features (ternary operator `? :`, null-coalescing `??`/`??=`, pipeline chain operators `&&`/`||`, `clean { }` block, `-Parallel` on `ForEach-Object`, etc.) and 7-only cmdlets/parameters.
  - Avoid Windows-only assumptions: do not hard-code path separators (use `Join-Path` / `[System.IO.Path]::Combine`), do not assume drive letters, do not call Windows-only modules (`Microsoft.PowerShell.Management`'s registry providers, `Get-WmiObject`, etc.), and gate any Windows-only code with `$IsWindows`.
  - Avoid case-sensitive filesystem assumptions; macOS/Linux paths are case-sensitive while Windows is not.
  - Use `[System.Environment]::NewLine` or explicit `"`n"` rather than relying on platform line endings when generating files.
  - When a feature genuinely requires PowerShell 7 or a specific platform, gate it with `if ($PSVersionTable.PSVersion.Major -ge 7)` / `if ($IsWindows)` and provide a Desktop/cross-platform fallback or a clear error.
  - For Pester tests, use `-Skip:(-not $IsWindows)` (or the equivalent platform/version guard) for platform- or version-specific tests rather than removing them.
  - When changes target a *generated* module whose template manifest declares a stricter floor (e.g. a CustomModule scaffolded with `PowerShellVersion = '7.0'`), the same rule applies in reverse: that generated code may use 7-only features, but Sampler's own scaffolding logic that produces it must still run on 5.1.
