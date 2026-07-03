---
description: 'Module class export and type accelerator instructions'
applyTo: '{source/suffix.ps1,source/Classes/*.ps1,source/Enum/*.ps1,source/synio.process.psm1}'
---

# Classes and Type Accelerators Guidelines

## Purpose

- This repository uses the `source\suffix.ps1` type-accelerator pattern to expose selected PowerShell classes after module import.
- This is a deliberate workaround for PowerShell modules not being able to export classes directly.

## Registration rules

- Keep type-accelerator registration in `source\suffix.ps1`, after classes are available.
- Naming: class properties use PascalCase. Top-level `suffix.ps1` variables holding persistent export-list state (for example the exportable-types lists, the resolved module name) use PascalCase; transient loop/computation variables within `suffix.ps1` use camelCase.
- Use module-qualified accelerators when possible to reduce name collisions.
- Resolve the module name dynamically rather than hard-coding it.
- Validate that each type exists before registering its accelerator.
- Warn when overriding an existing accelerator and fail when the target type cannot be found.

## Cleanup rules

- Remove namespaced accelerators in the module `OnRemove` handler.
- Keep cleanup logic aligned with the accelerators registered during import.

## Usage implications

- Module consumers must import the module before invoking code paths that depend on exported type accelerators.
- Dependent modules should rely on manifest `RequiredModules` when they need these accelerators available before command invocation.
- Keep this pattern compatible with Windows PowerShell 5.1 and PowerShell 7.

## Change safety

- When adding, removing, or renaming exported classes, update:
  - `source\suffix.ps1`
  - the relevant class files under `source\Classes\`
  - any tests that instantiate or reference those classes
- Preserve the current collision-avoidance behavior unless intentionally redesigning the class consumption model.
