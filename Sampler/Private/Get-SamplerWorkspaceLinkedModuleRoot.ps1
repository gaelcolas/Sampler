
<#
    .SYNOPSIS
        Resolves the directory where workspace module symlinks will be created.

    .DESCRIPTION
        Determines the linked module root path based on the output directory and
        the built module subdirectory. The logic is:

        - If `OutputDirectory` is absolute, use it directly; otherwise join it
          with `BuildRoot`.
        - If `BuiltModuleSubdirectory` is null or whitespace, return the output
          root as-is.
        - If `BuiltModuleSubdirectory` is absolute, return it directly.
        - Otherwise join the output root with `BuiltModuleSubdirectory`.

    .PARAMETER BuildRoot
        The root directory of the current build (typically `$BuildRoot` in
        InvokeBuild context).

    .PARAMETER OutputDirectory
        The output directory path. May be absolute or relative to `BuildRoot`.

    .PARAMETER BuiltModuleSubdirectory
        The subdirectory under the output root where modules are placed.
        Defaults to `module`. May be empty, absolute, or relative.

    .EXAMPLE
        Get-SamplerWorkspaceLinkedModuleRoot -BuildRoot 'C:\src\MyRepo' -OutputDirectory 'output' -BuiltModuleSubdirectory 'module'
        # C:\src\MyRepo\output\module
#>
function Get-SamplerWorkspaceLinkedModuleRoot
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $BuildRoot,

        [Parameter(Mandatory = $true)]
        [System.String]
        $OutputDirectory,

        [Parameter()]
        [AllowEmptyString()]
        [System.String]
        $BuiltModuleSubdirectory = 'module'
    )

    $outputRoot = if ([System.IO.Path]::IsPathRooted($OutputDirectory))
    {
        $OutputDirectory
    }
    else
    {
        Join-Path -Path $BuildRoot -ChildPath $OutputDirectory
    }

    if ([System.String]::IsNullOrWhiteSpace($BuiltModuleSubdirectory))
    {
        return $outputRoot
    }

    if ([System.IO.Path]::IsPathRooted($BuiltModuleSubdirectory))
    {
        return $BuiltModuleSubdirectory
    }

    return (Join-Path -Path $outputRoot -ChildPath $BuiltModuleSubdirectory)
}
