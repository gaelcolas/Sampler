<#
    .SYNOPSIS
        Links sibling workspace module build outputs into the local output module path.

    .DESCRIPTION
        When working in a multi-repo VSCode workspace, this task walks the parent
        directory (the workspace root), finds each sibling repo's built module
        output, and creates a symlink (or Windows junction fallback) in the local
        `output\module\` path so that `PSModulePath` resolution works seamlessly
        during tests.

        Configure the list of sibling modules via `WorkspaceModules` in `build.yaml`:

        ```yaml
        WorkspaceModules:
          - OtherModule
          - AnotherModule
        ```

    .PARAMETER OutputDirectory
        The base directory of all output. Defaults to folder `output` relative to
        `$BuildRoot`.

    .PARAMETER BuiltModuleSubdirectory
        The parent path of the module to be built. Defaults to `module`.

    .PARAMETER WorkspaceModules
        The sibling workspace modules to link into the local output module path.
        Can also be read from `$BuildInfo['WorkspaceModules']`.

    .PARAMETER BuildInfo
        The build information hashtable, typically populated from `build.yaml`.
        Used to read `WorkspaceModules` when not supplied as a parameter.
#>

param
(
    [Parameter()]
    [System.String]
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

    [Parameter()]
    [System.String]
    $BuiltModuleSubdirectory = (property BuiltModuleSubdirectory 'module'),

    [Parameter()]
    [System.String[]]
    $WorkspaceModules = (property WorkspaceModules @()),

    [Parameter()]
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)

# Synopsis: Links sibling workspace module build outputs into the local output module path.
task Link_Local_Workspace_Dependencies {
    # Get the values for task variables, see https://github.com/gaelcolas/Sampler?tab=readme-ov-file#build-task-variables.
    . Set-SamplerTaskVariable -AsNewBuild

    if ($WorkspaceModules.Count -eq 0 -and $BuildInfo.ContainsKey('WorkspaceModules'))
    {
        $WorkspaceModules = [System.String[]] $BuildInfo['WorkspaceModules']
    }

    if ($WorkspaceModules.Count -eq 0)
    {
        Write-Build -Color 'DarkGray' -Text 'No WorkspaceModules configured. Skipping.'
        return
    }

    $workspaceRoot = Split-Path -Path $BuildRoot -Parent

    $linkedModuleRootParams = @{
        BuildRoot               = $BuildRoot
        OutputDirectory         = $OutputDirectory
        BuiltModuleSubdirectory = $BuiltModuleSubdirectory
    }

    $linkedModuleRoot = Get-SamplerWorkspaceLinkedModuleRoot @linkedModuleRootParams

    if (-not (Test-Path -Path $linkedModuleRoot))
    {
        $null = New-Item -Path $linkedModuleRoot -ItemType Directory -Force
    }

    foreach ($workspaceModule in $WorkspaceModules)
    {
        $builtModulePathParams = @{
            ModuleName    = $workspaceModule
            WorkspaceRoot = $workspaceRoot
        }

        $builtModulePath = Get-SamplerWorkspaceBuiltModulePath @builtModulePathParams

        $linkPath = Join-Path -Path $linkedModuleRoot -ChildPath $workspaceModule

        $moduleLinkParams = @{
            LinkPath   = $linkPath
            TargetPath = $builtModulePath
        }

        Write-Build Green ("Linking local workspace dependency '{0}' to '{1}'." -f $workspaceModule, $builtModulePath)

        $linkType = New-SamplerWorkspaceModuleLink @moduleLinkParams

        if ($linkType -eq 'Junction')
        {
            Write-Build Yellow ("Symbolic link creation failed for '{0}'. Falling back to a directory junction." -f $workspaceModule)
        }
    }
}
