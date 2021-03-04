<#
.SYNOPSIS
Gets a descriptive file name to be used as Pester Output file name.

.DESCRIPTION
Creates a file name to be used as Pester Output xml file composed like so:
"${ProjectName}_v${ModuleVersion}.${OsShortName}.${PowerShellVersion}.xml"

.PARAMETER ProjectName
Name of the Project or module being built.

.PARAMETER ModuleVersion
Module Version currently defined (including pre-release but without the metadata).

.PARAMETER OsShortName
Platform name either Windows, Linux, or MacOS.

.PARAMETER PowerShellVersion
Version of PowerShell the tests have been running on.

.EXAMPLE
Get-PesterOutputFileFileName -ProjectName 'Sampler' -ModuleVersion 0.110.4-preview001 -OsShortName Windows -PowerShellVersion 5.1

.NOTES
General notes
#>
function Get-PesterOutputFileFileName
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ProjectName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ModuleVersion,

        [Parameter(Mandatory = $true)]
        [System.String]
        $OsShortName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PowerShellVersion
    )

    return '{0}_v{1}.{2}.{3}.xml' -f $ProjectName, $ModuleVersion, $OsShortName, $PowerShellVersion
}
