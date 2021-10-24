
<#
    .SYNOPSIS
        Gets the project's source Path based on the ModuleManifest location.

    .DESCRIPTION
        By finding the ModuleManifest of the project using `Get-SamplerProjectModuleManifest`
        this function assumes that the source folder is the parent folder of
        that module manifest.
        This allows the source folder to be src, source, or the Module name's, without
        hardcoding the name.

    .PARAMETER BuildRoot
        BuildRoot of the Sampler project to search the Module manifest from.

    .EXAMPLE
        Get-SamplerSourcePath -BuildRoot 'C:\src\MyModule'

#>
function Get-SamplerSourcePath
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $BuildRoot
    )

    $SamplerProjectModuleManifest = Get-SamplerProjectModuleManifest -BuildRoot $BuildRoot
    $samplerSrcPathToTest = Join-Path -Path $BuildRoot -ChildPath 'src'
    $samplerSourcePathToTest = Join-Path -Path $BuildRoot -ChildPath 'source'

    if ($null -ne $SamplerProjectModuleManifest)
    {
        return $SamplerProjectModuleManifest.Directory.FullName
    }
    elseif ($null -eq $SamplerProjectModuleManifest -and (Test-Path -Path  $samplerSourcePathToTest))
    {
        Write-Debug -Message ('The ''source'' path ''{0}'' was found.' -f $samplerSourcePathToTest)
        return $samplerSourcePathToTest
    }
    elseif ($null -eq $SamplerProjectModuleManifest -and (Test-Path -Path $samplerSrcPathToTest))
    {
        Write-Debug -Message ('The ''src'' path ''{0}'' was found.' -f $samplerSrcPathToTest)
        return $samplerSrcPathToTest
    }
    else
    {
        throw 'Module Source Path not found.'
    }
}
