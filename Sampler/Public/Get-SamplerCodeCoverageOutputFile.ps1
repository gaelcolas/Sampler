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

    if ($BuildInfo.ContainsKey('Pester') -and $BuildInfo.Pester.ContainsKey('CodeCoverageOutputFile'))
    {
        $codeCoverageOutputFile = $executioncontext.invokecommand.expandstring($BuildInfo.Pester.CodeCoverageOutputFile)

        if (-not (Split-Path -IsAbsolute $codeCoverageOutputFile))
        {
            $codeCoverageOutputFile = Join-Path -Path $PesterOutputFolder -ChildPath $codeCoverageOutputFile

            Write-Debug -Message "Absolute path to code coverage output file is $codeCoverageOutputFile."
        }
    }
    else
    {
        $codeCoverageOutputFile = $null
    }

    return $codeCoverageOutputFile
}
