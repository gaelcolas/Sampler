
<#
    .SYNOPSIS
        Resolves the CodeCoverage output file path from the project's BuildInfo.

    .DESCRIPTION
        When the Pester CodeCoverageOutputFile is configured in the
        buildinfo (aka Build.yml), this function will expand the path
        (if it contains variables), and resolve to it's absolute path if needed.

    .PARAMETER BuildInfo
        The BuildInfo object represented in the Build.yml.

    .PARAMETER PesterOutputFolder
        The Pester output folder (that can be overridden at runtime).

    .EXAMPLE
        Get-SamplerCodeCoverageOutputFile -BuildInfo $buildInfo -PesterOuputFolder 'C:\src\MyModule\Output\testResults

#>
function Get-SamplerCodeCoverageOutputFile
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [PSObject]
        $BuildInfo,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PesterOutputFolder
    )

    $codeCoverageOutputFile = $null

    if ($BuildInfo.ContainsKey('Pester') -and $BuildInfo.Pester.ContainsKey('CodeCoverageOutputFile'))
    {
        $codeCoverageOutputFile = $ExecutionContext.InvokeCommand.ExpandString($BuildInfo.Pester.CodeCoverageOutputFile)
    }
    elseif ($BuildInfo.ContainsKey('Pester') -and $BuildInfo.Pester.ContainsKey('Configuration') -and $BuildInfo.Pester.Configuration.CodeCoverage.OutputPath)
    {
        $codeCoverageOutputFile = $ExecutionContext.InvokeCommand.ExpandString($BuildInfo.Pester.Configuration.CodeCoverage.OutputPath)
    }

    if (-not [System.String]::IsNullOrEmpty($codeCoverageOutputFile))
    {
        if (-not (Split-Path -Path $codeCoverageOutputFile -IsAbsolute))
        {
            $codeCoverageOutputFile = Join-Path -Path $PesterOutputFolder -ChildPath $codeCoverageOutputFile

            Write-Debug -Message "Absolute path to code coverage output file is $codeCoverageOutputFile."
        }
    }
    else
    {
        # Make sure to return the value as $null if it for some reason was set to an empty string.
        $codeCoverageOutputFile = $null
    }

    return $codeCoverageOutputFile
}
