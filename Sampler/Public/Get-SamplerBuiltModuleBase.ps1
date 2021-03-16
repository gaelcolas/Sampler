<#
.SYNOPSIS
Get the ModuleBase of a module built with Sampler (directory where the module
manifest is).

.DESCRIPTION
Based on a project's configuration of OutputDirectory, BuiltModuleSubdirectory,
ModuleName and whether the built module is within a VersionedOutputDirectory;
this function will resolve the expected ModuleBase of that Module.

.PARAMETER OutputDirectory
Output directory (usually as defined by the Project).
By default it is set to 'output' in a Sampler project.

.PARAMETER BuiltModuleSubdirectory
Sub folder where you want to build the Module to (instead of $OutputDirectory/$ModuleName).
This is especially useful when you want to build DSC Resources, but you don't want the
`Get-DscResource` command to find several instances of the same DSC Resources because
of the overlapping $Env:PSmodulePath (`$buildRoot/output` for the built module and `$buildRoot/output/RequiredModules`).

In most cases I would recommend against setting $BuiltModuleSubdirectory.

.PARAMETER ModuleName
Name of the Module to retrieve the version from its manifest (See Get-SamplerProjectName).

.PARAMETER VersionedOutputDirectory
Whether the Module is built with its versioned Subdirectory, as you would see it on a System.
For instance, if VersionedOutputDirectory is $true, the built module's ModuleBase would be: `output/MyModuleName/2.0.1/`

.PARAMETER ModuleVersion
Allows to specify a specific ModuleVersion to search the ModuleBase if known.
If the ModuleVersion is not known but the VersionedOutputDirectory is set to $true,
a wildcard (*) will be used so that the path can be resolved by Get-Item or similar commands.

.EXAMPLE
Get-SamplerBuiltModuleBase -OutputDirectory C:\src\output -BuiltModuleSubdirectory 'Module' -ModuleName 'stuff' -ModuleVersion 3.1.2-preview001
# C:\src\output\Module\stuff\3.1.2

#>
function Get-SamplerBuiltModuleBase
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.String]
        $OutputDirectory,

        [Parameter()]
        [AllowNull()]
        [System.String]
        $BuiltModuleSubdirectory,

        [Parameter(Mandatory = $true)]
        [Alias('ProjectName')]
        [ValidateNotNull()]
        [System.String]
        $ModuleName,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $VersionedOutputDirectory,

        [Parameter()]
        [System.String]
        $ModuleVersion = '*'
    )

    $BuiltModuleOutputPath = Get-SamplerAbsolutePath -Path $BuiltModuleSubdirectory -RelativeTo $OutputDirectory
    $BuiltModulePath = Get-SamplerAbsolutePath -Path $ModuleName -RelativeTo $BuiltModuleOutputPath

    if ($VersionedOutputDirectory -or ($PSBoundParameters.ContainsKey('ModuleVersion') -and $ModuleVersion -ne '*'))
    {
        if ($ModuleVersion -eq '*' -or [System.String]::IsNullOrEmpty($ModuleVersion))
        {
            $ModuleVersion = '*'
        }
        else
        {
            $ModuleVersion = (Split-ModuleVersion -ModuleVersion $ModuleVersion).Version
        }

        $BuiltModuleBase = Get-SamplerAbsolutePath -Path $ModuleVersion -RelativeTo $BuiltModulePath
    }
    else
    {
        $BuiltModuleBase = $BuiltModulePath
    }

    return $BuiltModuleBase
}
