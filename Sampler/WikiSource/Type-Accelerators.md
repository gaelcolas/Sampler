# Exporting Classes as Type Accelerators

PowerShell modules cannot **export** classes. There is no `Export-ModuleMember`
option, and nothing in the module manifest, for PSv5+ classes. Consumers are
normally forced to add a `using module <path>` statement to their own scripts
before they can reference a class defined in your module - which is easy to
forget and awkward to discover.

The `TypeAccelerators` Plaster template scaffolds the workaround for this: a
`suffix.ps1` file that registers your module's classes as
[type accelerators](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_classes?view=powershell-7.5#exporting-classes-with-type-accelerators)
when the module is imported, so callers can use `[YourModule.YourClass]`
directly without a `using module` statement.

For the full background on why this is needed, how type accelerators work,
and the trade-offs of the approach, see the blog post
[PowerShell Modules: Exporting Classes](https://synedgy.com/powershell-modules-exporting-classes/),
which this template is based on.

## What it scaffolds

| File | Condition | Purpose |
|---|---|---|
| `<SourceDirectory>/suffix.ps1` | Always (when using the `TypeAccelerators` sample) | Registers the listed classes as type accelerators on import, and removes them again on `Remove-Module` |

`suffix.ps1` is merged onto the end of the built root module script by
`ModuleBuilder` (see the `suffix` setting in `build.yaml`), so it must be
placed in the source folder root, after the `Classes` are already declared
elsewhere in the module.

> **Important:** for `suffix.ps1` to actually be merged in, your `build.yaml`
> must have `suffix: suffix.ps1` uncommented (it is commented out by default
> in a plain scaffolded `build.yaml`). When using `Add-Sample -Sample
> TypeAccelerators` on an existing module, check/update `build.yaml` yourself.
> When using `New-SampleModule` with the `TypeAccelerators` feature (or
> `CompleteSample`), this is wired up for you automatically.

## Usage

### Add to an existing module

Run from the module root (where `build.ps1` lives):

```powershell
Add-Sample -Sample TypeAccelerators -DestinationPath . -SourceDirectory source -ExportableTypeName MyClass
```

This scaffolds (or overwrites) `source/suffix.ps1` exporting `MyClass` under a
module-qualified name (`YourModule.MyClass`). Edit the generated file's
`$TypesToExportAsIs` / `$TypesToExportWithNamespace` lists to add further
classes, or move `MyClass` to `$TypesToExportAsIs` if you want it exported
under its bare name instead - see below.

### Include when scaffolding a new module

Pass `TypeAccelerators` in the `Features` array when calling
`New-SampleModule` (it also requires `Classes`, and `SampleScripts` unless you
select `All`):

```powershell
New-SampleModule -DestinationPath 'C:\source' `
    -ModuleType 'CustomModule' `
    -ModuleName 'MyModule' `
    -ModuleAuthor 'Your Name' `
    -ModuleDescription 'My module description' `
    -SourceDirectory 'source' `
    -MainGitBranch 'main' `
    -Features @('git', 'UnitTests', 'Build', 'Classes', 'SampleScripts', 'TypeAccelerators')
```

The `CompleteSample` module type includes `TypeAccelerators` automatically
(exporting the sample `Class1` scaffolded by the `Classes` feature).

## What the generated `suffix.ps1` does

- **Two author-controlled lists** let you decide, per class, how it should be
  exported:
  - `$TypesToExportAsIs`: exported under its bare class name (for example
    `MyClass`). Be careful of collisions - if another module also exports a
    class with the same bare name, whichever module imports last wins.
  - `$TypesToExportWithNamespace`: exported as `<ModuleName>.<ClassName>` (for
    example `MyModule.MyClass`), to reduce the risk of colliding with an
    accelerator of the same bare name registered by another module. The
    scaffolded example type is placed here by default.
- Resolves the module name dynamically (`$MyInvocation.MyCommand.ScriptBlock.Module.Name`)
  rather than hard-coding it, so the same pattern keeps working if the module
  is renamed.
- Resolves each class **by name** (a string, looked up with `-as [System.Type]`)
  rather than by type literal (for example `[MyClass]`). A type literal is
  resolved against the type accelerator table at parse time, so if an
  accelerator with that same name already exists, the literal would silently
  bind to the *old* type instead of the class just declared - looking the type
  up by name at runtime avoids that trap. A class actually declared earlier in
  the same module still correctly shadows any stale accelerator of the same
  name, so the freshly declared class is always the one exported.
- **Brute-force overrides on import**: if an accelerator with the same name
  already exists (whether from a previous import of the same module during
  development, or from another module), it is removed and re-registered
  pointing at this module's type. PowerShell classes have no namespace, so
  there is no reliable way to tell a stale type from the same module (for
  example after a `-Force` re-import during development) apart from a genuine
  name collision with an unrelated module - trying to distinguish the two and
  throwing on the latter case (as an earlier version of this template did)
  just breaks the common re-import-during-development workflow. A
  `Write-Verbose` message is emitted whenever an existing accelerator is
  overridden, so you can see it happening without it interrupting anything.
- Removes the accelerators it registered in the module's `OnRemove` handler,
  so `Remove-Module` leaves the session clean.

## Consuming exported types from another module

Because the type accelerators are only registered when `suffix.ps1` runs
(that is, when the module is imported), a **consumer module** that references
`[YourModule.YourClass]` in its own code must ensure `YourModule` is imported
first:

- Add `YourModule` to the consumer's `RequiredModules` in its module manifest.
- Make sure `YourModule` is discoverable on `$Env:PSModulePath` (or otherwise
  already imported) before the consumer module is imported - `RequiredModules`
  only helps once PowerShell can actually find the module.

See the [blog post](https://synedgy.com/powershell-modules-exporting-classes/)
for a worked example of this failure mode and how to fix it.
