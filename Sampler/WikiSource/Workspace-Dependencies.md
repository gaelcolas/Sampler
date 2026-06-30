# Workspace Dependencies

The `Link_Local_Workspace_Dependencies` build task and its supporting public
functions let you wire together related Sampler-based repositories in a local
multi-repo workspace without publishing any of them to a PowerShell feed.

## When to use this

Use this when you are working across several related module repositories at
once (for example in a VSCode workspace) and you want one repo's build and
test pipeline to consume the locally built output of its siblings rather than
a version fetched from a gallery.

Typical scenarios:

- You are iterating on a shared helper module and a consuming module
  simultaneously.
- You want to validate an unpublished breaking change across several repos
  before committing.
- You are running the full test suite of a composition-root module that imports
  several sibling modules.

## Prerequisites

- All repositories involved must be siblings under the same parent directory
  (the _workspace root_).
- Each sibling module must have been built at least once
  (`./build.ps1 -Tasks build` in that repo) so its output exists.
- To create symbolic links on Windows, the process must either run elevated or
  Developer Mode must be enabled. If neither is available, the task falls back
  to a directory junction automatically.

## Workspace layout

```
WorkspaceRoot\
├── MyModule\          ← the repo you are working in
│   ├── build.ps1
│   ├── build.yaml
│   └── output\
│       └── module\
│           ├── MyModule\        ← built by ModuleBuilder
│           ├── SiblingA\        ← symlink created by this task
│           └── SiblingB\        ← symlink created by this task
├── SiblingA\
│   └── output\
│       └── module\
│           └── SiblingA\
│               └── 1.2.3\
└── SiblingB\
    └── output\
        └── module\
            └── SiblingB\
                └── 0.9.0\
```

Because `output\module` is prepended to `PSModulePath` by `build.ps1`, all
three modules (`MyModule`, `SiblingA`, `SiblingB`) are discoverable after the
task runs.

## Configuration

Add `WorkspaceModules` to your `build.yaml` and include the task in the
workflows where the sibling modules need to be available.

```yaml
####################################################
#       Workspace Dependencies Configuration       #
####################################################
WorkspaceModules:
  - SiblingA
  - SiblingB

BuildWorkflow:
  build:
    - Clean
    - Build_Module_ModuleBuilder
    - Build_NestedModules_ModuleBuilder
    - Link_Local_Workspace_Dependencies   # runs after the local build

  test:
    - Link_Local_Workspace_Dependencies   # re-link before tests in case siblings were rebuilt
    - Pester_Tests_Stop_On_Fail
    - Pester_If_Code_Coverage_Under_Threshold
```

### `WorkspaceModules` property

| Type | Default | Required |
|------|---------|----------|
| `String[]` | `@()` (empty) | No |

A list of sibling module names to link. Each entry must match the folder name
of the sibling repository under the shared workspace root. If the list is
empty or absent the task exits silently without error.

## How it works

For each module name in `WorkspaceModules` the task:

1. Resolves `<workspaceRoot>\<ModuleName>` and fails fast if the directory does
   not exist.
2. Searches `output\module\<ModuleName>\*\<ModuleName>.psd1` (and a fallback
   `output\<ModuleName>\*\<ModuleName>.psd1`) inside the sibling repo.
3. Returns `$manifestPath.Directory.Parent.FullName` — the folder that contains
   the versioned sub-folder. This is the link target.
4. Creates a symbolic link (Windows: falls back to a junction) at
   `<localOutputModule>\<ModuleName>` pointing at that target.

If the link already exists it is removed and recreated so it always points at
the current build output.

## Supporting public functions

These functions are exposed by Sampler and can be called directly in custom
build tasks or scripts.

### `Get-SamplerWorkspaceBuiltModulePath`

Finds the built module root directory (`output\module\<name>`) for a named
module inside a sibling workspace repository.

```powershell
$path = Get-SamplerWorkspaceBuiltModulePath -ModuleName 'SiblingA' -WorkspaceRoot 'C:\src'
# Returns e.g. C:\src\SiblingA\output\module\SiblingA
```

Throws if the sibling repo directory does not exist or if no built manifest
is found. The error message includes the `build.ps1` command to run.

### `New-SamplerWorkspaceModuleLink`

Creates a filesystem link from `LinkPath` to `TargetPath`. Returns the string
`'SymbolicLink'` or `'Junction'` depending on which type was created.

```powershell
$linkType = New-SamplerWorkspaceModuleLink `
    -LinkPath 'C:\src\MyModule\output\module\SiblingA' `
    -TargetPath 'C:\src\SiblingA\output\module\SiblingA'
```

On non-Windows platforms, symbolic link failure is fatal. On Windows, the task
falls back to a directory junction and the task logs a yellow warning.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `Unable to find the sibling repository root` | The sibling folder name in `WorkspaceModules` does not match the actual directory name | Check spelling and that the repo is checked out under the same workspace root |
| `Unable to find a built module output` | The sibling repo has not been built yet | Run `./build.ps1 -Tasks build` in the sibling repo |
| Symbolic link creation fails with access denied | Windows requires elevation or Developer Mode for symlinks | Enable Developer Mode, or run the terminal elevated; the task will fall back to a junction automatically |
| Stale module version loaded during tests | The symlink exists but points at an old build | Re-run the sibling's build, then re-run `Link_Local_Workspace_Dependencies` |
