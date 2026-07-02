# Copilot Instructions Template

The `Copilot` Plaster template scaffolds a ready-to-use set of GitHub Copilot
instruction files and a `validate-changes` skill into any Sampler-based
PowerShell module.

## What it scaffolds

| File | Condition | Purpose |
|---|---|---|
| `.github/copilot-instructions.md` | Always | Root instructions: git workflow, build entry point, conventions |
| `.github/instructions/ai-instruction-authoring.instructions.md` | Always | Rules for authoring further instruction files |
| `.github/instructions/public-functions.instructions.md` | Always | Public function style and testing conventions |
| `.github/instructions/private-functions.instructions.md` | Always | Private function conventions |
| `.github/instructions/test-writing.instructions.md` | Always | Pester test authoring conventions |
| `.github/instructions/build-tasks.instructions.md` | Always | InvokeBuild/Sampler task authoring conventions |
| `.github/skills/validate-changes/SKILL.md` | Always | Targeted test-scope selection skill for Copilot |
| `.github/instructions/classes-and-type-accelerators.instructions.md` | `HasClasses = Yes` | PSv5+ class export and type-accelerator conventions |
| `.github/instructions/build-task-files.instructions.md` | `HasCustomBuildTasks = Yes` | Custom `.build/tasks/` file conventions |
| `.github/instructions/wiki-publishing.instructions.md` | `HasWikiSource = Yes` | WikiSource authoring and publish conventions |

## Usage

### Add to an existing module

Run from the module root (where `build.ps1` lives):

```powershell
Add-Sample -Sample Copilot -DestinationPath .
```

Plaster will prompt for:

| Prompt | Default | Notes |
|---|---|---|
| Module name | _(none)_ | The name of your module (e.g. `MyModule`) |
| Source folder name | `source` | Usually `source` or `src` |
| Does the module use PSv5+ Classes? | No | Adds `classes-and-type-accelerators.instructions.md` |
| Does the module have custom build task files? | No | Adds `build-task-files.instructions.md` |
| Does the module publish a GitHub wiki? | No | Adds `wiki-publishing.instructions.md` |

### Include when scaffolding a new module

Pass `copilot` in the `Features` array when calling `New-SampleModule`:

```powershell
New-SampleModule -DestinationPath 'C:\source' `
    -ModuleType 'CustomModule' `
    -ModuleName 'MyModule' `
    -ModuleAuthor 'Your Name' `
    -ModuleDescription 'My module description' `
    -SourceDirectory 'source' `
    -MainGitBranch 'main' `
    -Features @('git', 'github', 'UnitTests', 'Build', 'copilot')
```

The `CompleteSample` module type includes Copilot instructions automatically.

## What the files cover

### `copilot-instructions.md`

The root instructions file that GitHub Copilot loads for every conversation
in the repository. It covers:

- Git workflow: never commit or push; leave all commits to the owner
- Build entry point: always use `./build.ps1`; never call `Invoke-Pester` or
  `Build-Module` directly
- Repository layout: source folder, do not edit the root `.psm1` directly
- Key conventions: `$null =` over `| Out-Null`; splatting over backticks;
  ASCII-only in `.ps1` files and `CHANGELOG.md`
- Changelog policy: update only for user-visible module changes

### `instructions/test-writing.instructions.md`

Pester test conventions tuned for the module:

- Required `BeforeAll`/`AfterAll` blueprint (with the correct module name)
- `It` block naming: always start with `Should`
- Assertion style table
- Cross-platform path rules (`$TestDrive`, no `C:\` literals)
- `InModuleScope` usage rules
- WinPS 5.1 `@()` wrapping

### `skills/validate-changes/SKILL.md`

A Copilot skill that selects the correct test scope based on what changed:

- Public/private function change -> focused unit test
- Template change -> integration tests
- Build task change -> full default test workflow
- Completion check: always run the full suite before PR

## Customization

The scaffolded files are plain Markdown - edit them freely after scaffolding to
reflect project-specific conventions. The instruction files under
`.github/instructions/` apply automatically to the file patterns listed in
their `applyTo` YAML frontmatter.

To add further instruction files over time, use
`.github/instructions/ai-instruction-authoring.instructions.md` as your style
guide.
