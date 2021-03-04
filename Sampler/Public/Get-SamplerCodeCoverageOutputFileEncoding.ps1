<#
.SYNOPSIS
Returns the Configured encoding for Pester code coverage file from BuildInfo.

.DESCRIPTION
This function returns the CodeCoverageOutputFileEncoding (Pester v5+) as
configured in the BuildInfo (build.yml).

.PARAMETER BuildInfo
Build Configuration object as defined in the Build.yml.

.EXAMPLE
Get-SamplerCodeCoverageOutputFileEncoding -BuildInfo $buildInfo

#>
function Get-SamplerCodeCoverageOutputFileEncoding
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [PSObject]
        $BuildInfo
    )

    if ($BuildInfo.ContainsKey('Pester') -and $BuildInfo.Pester.ContainsKey('CodeCoverageOutputFileEncoding'))
    {
        $codeCoverageOutputFileEncoding = $BuildInfo.Pester.CodeCoverageOutputFileEncoding
    }
    else
    {
        $codeCoverageOutputFileEncoding = $null
    }

    return $codeCoverageOutputFileEncoding
}
