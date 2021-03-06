param (
    # Project path
    [Parameter()]
    [string]
    $ProjectPath = (property ProjectPath $BuildRoot),

    [Parameter()]
    # Base directory of all output (default to 'output')
    [string]
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

    # Build Configuration object
    [Parameter()]
    $BuildInfo = (property BuildInfo @{ })
)

# Synopsis: Making sure the Module meets some quality standard (help, tests).
task Merge_CodeCoverage_Files {
    if (!(Split-Path -isAbsolute $OutputDirectory))
    {
        $OutputDirectory = Join-Path -Path $ProjectPath -ChildPath $OutputDirectory
        Write-Build Yellow "Absolute path to Output Directory is $OutputDirectory"
    }

    $CodeCovOutputFile = "CodeCov_Merged.xml"
    if ($BuildInfo.ContainsKey("Pester") -eq $true -and
        $BuildInfo.Pester.ContainsKey("CodeCoverageMergedOutputFile") -eq $true)
    {
        $CodeCovOutputFile = $BuildInfo.Pester.CodeCoverageMergedOutputFile
    }

    $targetFile = Join-Path -Path $OutputDirectory -ChildPath $CodeCovOutputFile

    if (Test-Path -Path $targetFile)
    {
        Write-Build Yellow "File $targetFile found, deleting file"
        Remove-Item -Path $targetFile -Force
    }

    Write-Build White "Processing folder: $OutputDirectory"

    $codecovFiles = Get-ChildItem -Path $OutputDirectory -Include 'codecov*.xml' -Recurse

    if ($codecovFiles.Count -gt 1)
    {
        Write-Build DarkGray "Started merging $($codecovFiles.Count) code coverage files!"
        Start-CodeCoverageMerge -Files $codecovFiles -TargetFile $targetFile
        Write-Build DarkGray "Merge completed. Saved merge result to: $targetFile"
    }
    else
    {
        throw "Found $($codecovFiles.Count) code coverage file. Need at least two files to merge."
    }
}

function Confirm-CodeCoverageFileFormat
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]
        $CodeCovFile
    )

    $report = ($CodeCovFile.GetEnumerator() | Where-Object -FilterScript { $_.Name -eq "Report"})
    if ($null -ne $report -and $report.OuterXml -like "*JACOCO*")
    {
        return $true
    }

    return $false
}

function Start-CodeCoverageMerge
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Object[]]
        $Files,

        [Parameter(Mandatory = $true)]
        [System.String]
        $TargetFile
    )

    $firstFile = $Files | Select-Object -First 1
    $otherFiles = $Files | Select-Object -Skip 1

    [xml]$targetDocument = Get-Content -Path $firstFile.FullName -Raw

    if (Confirm-CodeCoverageFileFormat -CodeCovFile $targetDocument)
    {
        Write-Verbose "Successfully imported $($firstFile.Name) as a baseline"

        $merged = 0
        foreach ($file in $otherFiles)
        {
            [xml]$mergeDocument = Get-Content -Path $file.FullName -Raw
            Write-Verbose "Merging $($file.Name) into baseline"
            if (Confirm-CodeCoverageFileFormat -CodeCovFile $mergeDocument)
            {
                $targetDocument = Merge-JaCoCoReport -OriginalDocument $targetDocument -MergeDocument $mergeDocument
                $merged++
            }
            else
            {
                Write-Verbose "The following code coverage file is not using the JaCoCo format: $($file.Name)"
            }
        }
        Write-Verbose "Merge completed: Successfully merged $merged files into the baseline"

        $targetDocument = Update-JaCoCoStatistic -Document $targetDocument

        $fullTargetFilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($TargetFile)
        $targetDocument.Save($fullTargetFilePath)
    }
    else
    {
        throw "The following code coverage file is not using the JaCoCo format: $($firstFile.Name)"
    }
}
