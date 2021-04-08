param
(
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

    [Parameter()]
    [System.String]
    $PesterOutputFolder = (property PesterOutputFolder 'testResults'),

    [Parameter()]
    [System.String]
    $CodeCoverageThreshold = (property CodeCoverageThreshold ''),

    # Build Configuration object
    [Parameter()]
    $BuildInfo = (property BuildInfo @{ })
)

# Synopsis: Merging several code coverage files together.
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

    "`tProject Name                    = '$ProjectName'"
    "`tSource Path                     = '$SourcePath'"
    "`tOutput Directory                = '$OutputDirectory'"

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

    "`tBuilt Module Manifest           = '$builtModuleManifest'"

    $ModuleVersion = Get-BuiltModuleVersion @GetBuiltModuleManifestParams
    $ModuleVersionObject = Split-ModuleVersion -ModuleVersion $ModuleVersion
    $ModuleVersionFolder = $ModuleVersionObject.Version
    $preReleaseTag = $ModuleVersionObject.PreReleaseString

    "`tModule Version                  = '$ModuleVersion'"
    "`tModule Version Folder           = '$ModuleVersionFolder'"
    "`tPre-release Tag                 = '$preReleaseTag'"

    $osShortName = Get-OperatingSystemShortName

    $powerShellVersion = 'PSv.{0}' -f $PSVersionTable.PSVersion

    $moduleFileName = '{0}.psm1' -f $ProjectName

    $PesterOutputFolder = Get-SamplerAbsolutePath -Path $PesterOutputFolder -RelativeTo $OutputDirectory

    "`tPester Output Folder            = '$PesterOutputFolder'"

    $GetCodeCoverageThresholdParameters = @{
        RuntimeCodeCoverageThreshold = $CodeCoverageThreshold
        BuildInfo                    = $BuildInfo
    }

    $CodeCoverageThreshold = Get-CodeCoverageThreshold @GetCodeCoverageThresholdParameters

    if (-not $CodeCoverageThreshold)
    {
        $CodeCoverageThreshold = 0
    }

    "`tCode Coverage Threshold         = '$CodeCoverageThreshold'"

    if ($CodeCoverageThreshold -gt 0)
    {
        $getPesterOutputFileFileNameParameters = @{
            ProjectName       = $ProjectName
            ModuleVersion     = $ModuleVersion
            OsShortName       = $osShortName
            PowerShellVersion = $powerShellVersion
        }

        $pesterOutputFileFileName = Get-PesterOutputFileFileName @getPesterOutputFileFileNameParameters

        $getCodeCoverageOutputFile = @{
            BuildInfo          = $BuildInfo
            PesterOutputFolder = $PesterOutputFolder
        }

        $CodeCoverageOutputFile = Get-SamplerCodeCoverageOutputFile @getCodeCoverageOutputFile

        if (-not $CodeCoverageOutputFile)
        {
            $CodeCoverageOutputFile = (Join-Path -Path $PesterOutputFolder -ChildPath "CodeCov_$pesterOutputFileFileName")
        }

        "`tCode Coverage Output File       = $CodeCoverageOutputFile"

        $CodeCoverageMergedOutputFile = 'CodeCov_Merged.xml'

        if ($BuildInfo.CodeCoverage.CodeCoverageMergedOutputFile)
        {
            $CodeCoverageMergedOutputFile = $BuildInfo.CodeCoverage.CodeCoverageMergedOutputFile
        }

        $CodeCoverageMergedOutputFile = Get-SamplerAbsolutePath -Path $CodeCoverageMergedOutputFile -RelativeTo $PesterOutputFolder

        "`tCode Coverage Merge Output File = $CodeCoverageMergedOutputFile"

        $CodeCoverageFilePattern = 'Codecov*.xml'

        if ($BuildInfo.ContainsKey('CodeCoverage') -and $BuildInfo.CodeCoverage.ContainsKey('CodeCoverageFilePattern'))
        {
            $CodeCoverageFilePattern = $BuildInfo.CodeCoverage.CodeCoverageFilePattern
        }

        "`tCode Coverage File Pattern      = $CodeCoverageFilePattern"

        if (-not [System.String]::IsNullOrEmpty($CodeCoverageFilePattern))
        {
            $codecovFiles = Get-ChildItem -Path $PesterOutputFolder -Include $CodeCoverageFilePattern -Recurse
        }

        "`tMerging Code Coverage Files     = {0}" -f ($codecovFiles.FullName -join ',')
        ""

        if (Test-Path -Path $CodeCoverageMergedOutputFile)
        {
            Write-Build Yellow "File $CodeCoverageMergedOutputFile found, deleting file."

            Remove-Item -Path $CodeCoverageMergedOutputFile -Force
        }

        Write-Build White "Processing folder: $OutputDirectory"

        if ($codecovFiles.Count -gt 1)
        {
            Write-Build DarkGray "Started merging $($codecovFiles.Count) code coverage files!"

            Start-CodeCoverageMerge -Files $codecovFiles -TargetFile $CodeCoverageMergedOutputFile

            Write-Build Green "Merge completed. Saved merge result to: $CodeCoverageMergedOutputFile"
        }
        else
        {
            throw "Found $($codecovFiles.Count) code coverage file. Need at least two files to merge."
        }
    }
    else
    {
        Write-Build White 'Code coverage is not enabled, skipping.'
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

        $xmlSettings = New-Object -TypeName 'System.Xml.XmlWriterSettings'
        $xmlSettings.Indent = $true
        $xmlSettings.Encoding = [System.Text.Encoding]::ASCII

        $TargetFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($TargetFile)

        $xmlWriter = [System.Xml.XmlWriter]::Create($TargetFile, $xmlSettings)

        $targetDocument.Save($xmlWriter)

        $xmlWriter.Close()
    }
    else
    {
        throw "The following code coverage file is not using the JaCoCo format: $($firstFile.Name)"
    }
}
