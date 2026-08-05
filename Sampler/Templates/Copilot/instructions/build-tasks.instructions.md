---
description: "Build and workflow authoring instructions"
applyTo: "{build.ps1,build.yaml,.build/*.ps1,.github/workflows/*.yml,.github/workflows/*.yaml}"
---

# Build and Workflow Development Guidelines

## Entry points

- Use `build.ps1` as the only bootstrap, build, and test entrypoint.
- Keep `build.ps1` focused on bootstrap and runtime parameters.
- Prefer changing `build.yaml` when altering workflow composition, copied assets, default test paths, code coverage behavior, or publish workflow ordering.

## Dependency and artifact rules

- Restore dependencies with `./build.ps1 -ResolveDependency -Tasks noop`.
- Do not manually edit `PSModulePath`; let `build.ps1` manage it.
- Keep required modules resolving into `output\RequiredModules`.
- Treat `output\module` as the validation target and disposable build output.
- Keep `CopyPaths` in `build.yaml` aligned with the shipped runtime assets under `source\`.

## Custom task rules

- See `build-task-files.instructions.md` for `.build/tasks/*.build.ps1` authoring rules (parameters, `Set-SamplerTaskVariable`, task definitions).
- Keep PowerShell Universal publish logic aligned with the built package path and `BuildInfo.UniversalServer` settings rather than re-deriving that state elsewhere.

## Purpose-built task modules

- Keep shipped InvokeBuild task files under the module source `Tasks` directory and include that directory in `CopyPaths`.
- Declare exported `Task.*` aliases in an always-enabled module `prefix.ps1`.
- Point aliases at task files under the built module's `Tasks` directory.
- List task aliases under `AliasesToExport` in `build.yaml`.
- Keep `prefix: prefix.ps1` enabled in `build.yaml`.
- Do not place alias-only scripts under `Public`; ModuleBuilder can incorrectly add their basenames to `FunctionsToExport`.
- Keep type-accelerator logic in `suffix.ps1`; do not require the suffix solely for task alias registration.

## Validation

- Treat changes to `build.ps1`, `build.yaml`, `.build\`, or workflow files as validation-impacting changes.
- Run at least `./build.ps1 -Tasks test` after workflow wiring changes.
