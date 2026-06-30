
<#
    .SYNOPSIS
        Finds the built module root for a sibling workspace module.

    .DESCRIPTION
        Searches the sibling repository's output directories for a built module
        manifest matching the given module name. The function checks these glob
        patterns in order:

        1. `<repoRoot>\output\module\<ModuleName>\*\<ModuleName>.psd1`
        2. `<repoRoot>\output\<ModuleName>\*\<ModuleName>.psd1`

        Returns the parent of the version subfolder
        (`$manifestPath.Directory.Parent.FullName`), which is the path suitable
        for symlinking into the local module output.

        Throws with a helpful message including the sibling build command if no
        manifest is found.

    .PARAMETER ModuleName
        The name of the sibling module to locate the built output for.

    .PARAMETER WorkspaceRoot
        The root directory of the multi-repo workspace, typically the parent
        directory of the current build root.

    .EXAMPLE
        Get-SamplerWorkspaceBuiltModulePath -ModuleName 'MyModule' -WorkspaceRoot 'C:\src'
        # C:\src\MyModule\output\module\MyModule
#>
function Get-SamplerWorkspaceBuiltModulePath
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ModuleName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $WorkspaceRoot
    )

    $moduleRepositoryRoot = Get-SamplerWorkspaceRepositoryRoot -ModuleName $ModuleName -WorkspaceRoot $WorkspaceRoot

    $manifestSearchPatterns = @(
        (Join-Path -Path $moduleRepositoryRoot -ChildPath ('output\module\{0}\*\{0}.psd1' -f $ModuleName))
        (Join-Path -Path $moduleRepositoryRoot -ChildPath ('output\{0}\*\{0}.psd1' -f $ModuleName))
    )

    foreach ($manifestSearchPattern in $manifestSearchPatterns)
    {
        $getChildItemParams = @{
            Path        = $manifestSearchPattern
            File        = $true
            ErrorAction = 'Ignore'
        }

        $manifestPath = Get-ChildItem @getChildItemParams |
            Sort-Object -Property FullName -Descending |
            Select-Object -First 1

        if ($manifestPath)
        {
            return $manifestPath.Directory.Parent.FullName
        }
    }

    throw ("Unable to find a built module output for '{0}'. Build the sibling repository first, for example: {1}\build.ps1 -Tasks build" -f $ModuleName, $moduleRepositoryRoot)
}
