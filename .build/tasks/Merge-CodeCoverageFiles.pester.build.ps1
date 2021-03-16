param (
    # Project path
    [Parameter()]
    [string]
    $ProjectPath = (property ProjectPath $BuildRoot),

    [Parameter()]
    # Base directory of all output (default to 'output')
    [string]
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

    [Parameter()]
    [System.String]
    $BuiltModuleSubdirectory = (property BuiltModuleSubdirectory ''),

    [Parameter()]
    [System.Management.Automation.SwitchParameter]
    $VersionedOutputDirectory = (property VersionedOutputDirectory $true),

    # Build Configuration object
    [Parameter()]
    $BuildInfo = (property BuildInfo @{ })
)

# Synopsis: Making sure the Module meets some quality standard (help, tests).
task Merge_CodeCoverage_Files {
    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-SamplerProjectName -BuildRoot $BuildRoot
    }

    if ([System.String]::IsNullOrEmpty($SourcePath))
    {
        $SourcePath = Get-SamplerSourcePath -BuildRoot $BuildRoot
    }

    $OutputDirectory = Get-SamplerAbsolutePath -Path $OutputDirectory -RelativeTo $BuildRoot

    "`tProject Name          = '$ProjectName'"
    "`tSource Path           = '$SourcePath'"
    "`tOutput Directory      = '$OutputDirectory'"

    if ($VersionedOutputDirectory)
    {
        # VersionedOutputDirectory is not [bool]'' nor $false nor [bool]$null
        # Assume true, wherever it was set
        $VersionedOutputDirectory = $true
    }
    else
    {
        # VersionedOutputDirectory may be [bool]'' but we can't tell where it's
        # coming from, so assume the build info (Build.yaml) is right
        $VersionedOutputDirectory = $BuildInfo['VersionedOutputDirectory']
    }

    $GetBuiltModuleManifestParams = @{
        OutputDirectory          = $OutputDirectory
        BuiltModuleSubdirectory  = $BuiltModuleSubDirectory
        ModuleName               = $ProjectName
        VersionedOutputDirectory = $VersionedOutputDirectory
        ErrorAction              = 'Stop'
    }

    $builtModuleManifest = Get-SamplerBuiltModuleManifest @GetBuiltModuleManifestParams

    "`tBuilt Module Manifest = '$builtModuleManifest'"

    $ModuleVersion = Get-BuiltModuleVersion @GetBuiltModuleManifestParams
    $ModuleVersionObject = Split-ModuleVersion -ModuleVersion $ModuleVersion
    $ModuleVersionFolder = $ModuleVersionObject.Version
    $preReleaseTag       = $ModuleVersionObject.PreReleaseString

    "`tModule Version        = '$ModuleVersion'"
    "`tModule Version Folder = '$ModuleVersionFolder'"
    "`tPre-release Tag       = '$preReleaseTag'"


    $CodeCovOutputFile = "CodeCov_Merged.xml"
    if ($BuildInfo.ContainsKey("Pester") -eq $true -and
        $BuildInfo.Pester.ContainsKey("CodeCoverageMergedOutputFile") -eq $true)
    {
        $CodeCovOutputFile = $BuildInfo.Pester.CodeCoverageMergedOutputFile
    }

    $targetFile = Get-SamplerAbsolutePath -Path $CodeCovOutputFile -RelativeTo $OutputDirectory

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
