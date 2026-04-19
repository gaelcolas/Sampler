# Copilot instructions for Sampler

## Build, test, and quality commands

Use `build.ps1` as the entry point for local work. It bootstraps dependencies into `output/RequiredModules`, prepends the built module path to `PSModulePath`, and then delegates to InvokeBuild workflows defined in `build.yaml`.

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
