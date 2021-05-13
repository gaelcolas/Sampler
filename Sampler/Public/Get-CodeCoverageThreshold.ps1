
<#
    .SYNOPSIS
        Gets the CodeCoverageThreshod from Runtime parameter or from BuildInfo.

    .DESCRIPTION
        This function will override the CodeCoverageThreshold by the value
        provided at runtime if any.

    .PARAMETER RuntimeCodeCoverageThreshold
        Runtime value for the Pester CodeCoverageThreshold (can be $null).

    .PARAMETER BuildInfo
        BuildInfo object as defined by the Build.yml.

    .EXAMPLE
        Get-CodeCoverageThreshold -RuntimeCodeCoverageThreshold 0

#>
function Get-CodeCoverageThreshold
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.String]
        [AllowNull()]
        $RuntimeCodeCoverageThreshold,

        [Parameter()]
        [PSObject]
        $BuildInfo
    )

    # If no codeCoverageThreshold configured at runtime, look for BuildInfo settings.
    if ([String]::IsNullOrEmpty($RuntimeCodeCoverageThreshold))
    {
        if ($BuildInfo -and $BuildInfo.ContainsKey('Pester') -and $BuildInfo.Pester.ContainsKey('CodeCoverageThreshold'))
        {
            $codeCoverageThreshold = $BuildInfo.Pester.CodeCoverageThreshold

            Write-Debug -Message "Loaded Code Coverage Threshold from Config file: $codeCoverageThreshold %."
        }
        elseif ($BuildInfo -and $BuildInfo.ContainsKey('Pester') -and $BuildInfo.Pester.ContainsKey('Configuration') -and $BuildInfo.Pester.Configuration.CodeCoverage.CoveragePercentTarget)
        {
            $codeCoverageThreshold = $BuildInfo.Pester.Configuration.CodeCoverage.CoveragePercentTarget

            Write-Debug -Message "Loaded Code Coverage Threshold from Config file in Pester advanced configuration: $codeCoverageThreshold %."
        }
        else
        {
            $codeCoverageThreshold = 0

            Write-Debug -Message "No code coverage threshold value found (param nor config), using the default value."
        }
    }
    else
    {
        $codeCoverageThreshold = [int] $RuntimeCodeCoverageThreshold

        Write-Debug -Message "Loading CodeCoverage Threshold from Parameter ($codeCoverageThreshold %)."
    }

    return $codeCoverageThreshold
}
