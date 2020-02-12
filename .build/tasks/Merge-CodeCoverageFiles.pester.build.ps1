Param (
    # Project path
    [Parameter()]
    [string]
    $ProjectPath = (property ProjectPath $BuildRoot),

    [Parameter()]
    # Base directory of all output (default to 'output')
    [string]
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

    [Parameter()]
    [string]
    $ProjectName = (property ProjectName $(
            (Get-ChildItem $BuildRoot\*\*.psd1 -Exclude 'build.psd1', 'analyzersettings.psd1' | Where-Object {
                    ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
                    $(try
                        {
                            Test-ModuleManifest $_.FullName -ErrorAction Stop
                        }
                        catch
                        {
                            Write-Warning $_
                            $false
                        }) }
            ).BaseName
        )
    ),

    [Parameter()]
    [string]
    $ModuleVersion = (property ModuleVersion $(
            try
            {
                (gitversion | ConvertFrom-Json -ErrorAction Stop).InformationalVersion
            }
            catch
            {
                Write-Verbose "Error attempting to use GitVersion $($_)"
                ''
            }
        )),

    # Build Configuration object
    [Parameter()]
    $BuildInfo = (property BuildInfo @{ })
)

. $PSScriptRoot/Common.Functions.ps1

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
        $firstFile = $codecovFiles | Select-Object -First 1
        $otherFiles = $codecovFiles | Select-Object -Skip 1

        Write-Build DarkGray "Started merging $($codecovFiles.Count) code coverage files!"
        [xml]$targetDocument = Get-Content $firstFile.FullName

        if (Validate-CodeCoverageFileFormat -CodeCovFile $targetDocument)
        {
            Write-Build DarkGray "Successfully imported $($firstFile.Name) as a baseline"

            $merged = 0
            foreach ($file in $otherFiles)
            {
                [xml]$mergeDocument = Get-Content $file.FullName
                Write-Build DarkGray "Merging $($file.Name) into baseline"
                if (Validate-CodeCoverageFileFormat -CodeCovFile $mergeDocument)
                {
                    $targetDocument = Merge-JaCoCoReports -OriginalDocument $targetDocument -MergeDocument $mergeDocument
                    $merged++
                }
                else
                {
                    Write-Build DarkGray "The following code coverage file is not using the JaCoCo format: $($file.Name)"
                }
            }
            Write-Build DarkGray "Merge completed: Successfully merged $merged files into the baseline"

            $targetDocument = Update-JaCoCoStatistics -Document $targetDocument

            $fullTargetFilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($targetFile)
            $targetDocument.Save($fullTargetFilePath)
        }
        else
        {
            throw "The following code coverage file is not using the JaCoCo format: $($firstFile.Name)"
        }
    }
    else
    {
        throw "Found $($codecovFiles.Count) code coverage file. Need at least two files to merge."
    }
}

function Validate-CodeCoverageFileFormat
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
