# Documentation and WikiSource

`DscResource.DocGenerator` supports documentation for general PowerShell
modules. It is not limited to modules that contain DSC resources.

Use it to generate:

- Markdown reference pages for exported PowerShell commands
- External MAML help from generated command pages
- A GitHub wiki sidebar
- A packaged `WikiContent.zip` release asset
- A published GitHub wiki containing generated and hand-authored pages

DSC-specific documentation tasks such as
`Generate_Markdown_For_DSC_Resources` are optional.

## Required modules

Add these modules to `RequiredModules.psd1`:

```powershell
@{
    'DscResource.DocGenerator' = 'latest'
    PlatyPS                    = 'latest'
}
```

`PlatyPS` is required for generated public command pages and external help.

## Import the documentation tasks

Add the task module to `ModuleBuildTasks` in `build.yaml`:

```yaml
ModuleBuildTasks:
  DscResource.DocGenerator:
    - 'Task.*'
```

## Configure documentation workflows

Use an explicit cross-platform workflow rather than the
`Generate_Wiki_Content` meta task:

```yaml
BuildWorkflow:
  docs:
    - Create_Wiki_Output_Folder
    - Generate_Markdown_For_Public_Commands
    - Generate_External_Help_File_For_Public_Commands
    - Clean_Markdown_Of_Public_Commands
    - Copy_Source_Wiki_Folder
    - Generate_Wiki_Sidebar
    - Clean_Markdown_Metadata
    - Package_Wiki_Content

  pack:
    - build
    - docs
    - package_psresource_nupkg

  publish:
    - Publish_GitHub_Wiki_Content
```

Generate external help before copying custom WikiSource pages. PlatyPS scans
Markdown files in the wiki output directory and can otherwise try to interpret
hand-authored pages as command-help documents.

## Add WikiSource pages

Keep hand-authored pages under:

```text
source/
`-- WikiSource/
    |-- Home.md
    |-- Getting-Started.md
    `-- Architecture.md
```

`Copy_Source_Wiki_Folder` copies these pages to `output/WikiContent`. A
`#.#.#` placeholder in `Home.md` is replaced with the built module version.

Use relative `.md` links between committed WikiSource pages:

```markdown
[Getting Started](Getting-Started.md)
```

## Configure generated artifacts

Add the wiki archive to GitHub release assets:

```yaml
GitHubConfig:
  ReleaseAssets:
    - output/WikiContent.zip
```

Configure sidebar and publishing behavior:

```yaml
DscResource.DocGenerator:
  Publish_GitHub_Wiki_Content:
    Debug: false
  Generate_Wiki_Sidebar:
    Debug: false
    AlwaysOverwrite: true
```

The docs workflow produces:

```text
output/
|-- WikiContent/
|   |-- Home.md
|   |-- _Sidebar.md
|   `-- <generated and custom pages>
`-- WikiContent.zip
```

## Copilot template guidance

The `Copilot` Plaster template can scaffold
`.github/instructions/wiki-publishing.instructions.md` when
`HasWikiSource` is enabled. The generated instructions contain the dependency,
workflow, authoring, and validation conventions described on this page.

## Validate

Run the complete packaging workflow:

```powershell
./build.ps1 -Tasks pack
```

Confirm:

- `output/WikiContent` contains generated command pages and custom pages.
- `_Sidebar.md` links to both generated and custom pages.
- `output/WikiContent.zip` exists.
- External help is generated in the built module locale folder.
- `./build.ps1 -Tasks hqrmtest` reports no broken WikiSource links.
