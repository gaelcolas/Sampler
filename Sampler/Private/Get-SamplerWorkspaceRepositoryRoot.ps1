
<#
    .SYNOPSIS
        Gets the absolute path of a sibling repository root in the workspace.

    .DESCRIPTION
        Validates that a sibling repository directory exists at
        `<WorkspaceRoot>\<ModuleName>`. Throws with a clear message if the
        directory is not found. Returns the absolute path string when successful.

    .PARAMETER ModuleName
        The name of the sibling module whose repository root to locate.

    .PARAMETER WorkspaceRoot
        The root directory of the multi-repo workspace, typically the parent
        directory of the current build root.

    .EXAMPLE
        Get-SamplerWorkspaceRepositoryRoot -ModuleName 'MyModule' -WorkspaceRoot 'C:\src'
        # C:\src\MyModule
#>
function Get-SamplerWorkspaceRepositoryRoot
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

    $moduleRepositoryRoot = Join-Path -Path $WorkspaceRoot -ChildPath $ModuleName

    if (-not (Test-Path -Path $moduleRepositoryRoot))
    {
        throw ("Unable to find the sibling repository root '{0}'." -f $moduleRepositoryRoot)
    }

    return $moduleRepositoryRoot
}
