---
description: 'Build task authoring instructions'
applyTo: '.build/tasks/*.build.ps1'
---

# Build Task Development Guidelines

## File naming and location

- All build task files live under `.build/tasks/` and follow the pattern `<Purpose>.<Subsystem>.build.ps1` (e.g., `Invoke-Pester.pester.build.ps1`, `Build-Module.ModuleBuilder.build.ps1`).
- The file naming determines the alias that `suffix.ps1` auto-registers for InvokeBuild: `<BaseName>.Sampler.ib.tasks`. Do not register aliases manually inside task files.
- Task files in `.build/tasks/` are copied into the built module (`output/module/Sampler/<version>/tasks/`) via the `CopyPaths` entry in `build.yaml`. If you add a new task file, add any required module imports or workflow entries to `build.yaml` — not to `build.ps1`.

## Parameter block

Every task file must open with a `param` block that declares all variables the tasks consume. Use InvokeBuild's `property` helper to set defaults — never hard-code paths:

```powershell
param
(
    [Parameter()]
    [System.String]
    $ProjectName = (property ProjectName ''),

    [Parameter()]
    [System.String]
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

    [Parameter()]
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)
```

- Always include `$BuildInfo` as a `[System.Collections.Hashtable]` parameter — tasks read per-workflow configuration from it.
- Use fully-qualified .NET types (e.g., `[System.String]`, `[System.Management.Automation.SwitchParameter]`) for all parameters.

## Shared task variables

At the start of every task body, dot-source `Set-SamplerTaskVariable` to populate the standard shared variables (`$ProjectName`, `$SourcePath`, `$BuildModuleOutput`, `$ModuleVersion`, etc.):

```powershell
task My_Task {
    # Get the values for task variables, see https://github.com/gaelcolas/Sampler?tab=readme-ov-file#build-task-variables.
    . Set-SamplerTaskVariable

    # ... task body
}
```

Use `-AsNewBuild` only for tasks that represent the start of a new build (e.g., tasks that derive the version fresh):

```powershell
    . Set-SamplerTaskVariable -AsNewBuild
```

**Never re-derive** `$ProjectName`, `$SourcePath`, or version information independently inside a task. Always rely on `Set-SamplerTaskVariable`.

## Task definitions

- Prefix every task definition with a `# Synopsis:` comment — InvokeBuild surfaces this as the task description:
  ```powershell
  # Synopsis: Build the module output using ModuleBuilder.
  task Build_ModuleOutput_ModuleBuilder {
      . Set-SamplerTaskVariable -AsNewBuild
      # ...
  }
  ```
- Compound tasks (tasks that only sequence other tasks) do not need a body — list dependencies inline:
  ```powershell
  task Build_Module_ModuleBuilder Build_ModuleOutput_ModuleBuilder, Build_DscResourcesToExport_ModuleBuilder
  ```
- Prefer exposing workflows through compound tasks instead of having downstream projects call low-level implementation tasks directly. Treat compound tasks as the stable public surface so internal task composition can change in Sampler without requiring updates in projects that consume it.
- Use `Write-Build -Color <Color> -Text <message>` for task output, not `Write-Host`. Prefer `Green` for success, `Yellow` for warnings, `DarkGray` for verbose detail.
- Resolve all paths through `Get-SamplerAbsolutePath -Path <path> -RelativeTo $BuildRoot` (or `$OutputDirectory`) rather than with `Join-Path` alone, so relative paths in `build.yaml` resolve correctly.
