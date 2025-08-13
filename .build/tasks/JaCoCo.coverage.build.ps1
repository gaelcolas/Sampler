param
(
    # Project path
    [Parameter()]
    [System.String]
    $ProjectPath = (property ProjectPath $BuildRoot),

    [Parameter()]
    # Base directory of all output (default to 'output')
    [System.String]
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

    [Parameter()]
    [System.String]
    $BuiltModuleSubdirectory = (property BuiltModuleSubdirectory ''),

    [Parameter()]
    [System.Management.Automation.SwitchParameter]
    $VersionedOutputDirectory = (property VersionedOutputDirectory $true),

    [Parameter()]
    [System.String]
    $ProjectName = (property ProjectName ''),

    [Parameter()]
    [System.String]
    $PesterOutputFolder = (property PesterOutputFolder 'testResults'),

    [Parameter()]
    [System.String]
    $PesterOutputFormat = (property PesterOutputFormat ''),

    [Parameter()]
    [System.Object[]]
    $PesterScript = (property PesterScript ''),

    [Parameter()]
    [System.String[]]
    $PesterTag = (property PesterTag @()),

    [Parameter()]
    [System.String[]]
    $PesterExcludeTag = (property PesterExcludeTag @()),

    [Parameter()]
    [System.String]
    $CodeCoverageThreshold = (property CodeCoverageThreshold ''),

    # Build Configuration object
    [Parameter()]
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)


# Synopsis: Merging several code coverage files together.
task Merge_CodeCoverage_Files {
    # Get the values for task variables, see https://github.com/gaelcolas/Sampler?tab=readme-ov-file#build-task-variables.
    . Set-SamplerTaskVariable

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

        "`tMerging Code Coverage Files     = '{0}'" -f ($codecovFiles.FullName -join ', ')
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
        Write-Verbose -Message "Successfully imported $($firstFile.Name) as a baseline"

        $merged = 0
        foreach ($file in $otherFiles)
        {
            [xml]$mergeDocument = Get-Content -Path $file.FullName -Raw
            Write-Verbose -Message "Merging $($file.Name) into baseline"
            if (Confirm-CodeCoverageFileFormat -CodeCovFile $mergeDocument)
            {
                $targetDocument = Merge-JaCoCoReport -OriginalDocument $targetDocument -MergeDocument $mergeDocument
                $merged++
            }
            else
            {
                Write-Verbose -Message "The following code coverage file is not using the JaCoCo format: $($file.Name)"
            }
        }

        Write-Verbose -Message "Merge completed: Successfully merged $merged files into the baseline"

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

# Synopsis: Convert JaCoCo coverage so it supports a built module by way of ModuleBuilder.
task Convert_Pester_Coverage {
    # Get the values for task variables, see https://github.com/gaelcolas/Sampler?tab=readme-ov-file#build-task-variables.
    . Set-SamplerTaskVariable

    $GetCodeCoverageThresholdParameters = @{
        RuntimeCodeCoverageThreshold = $CodeCoverageThreshold
        BuildInfo                    = $BuildInfo
    }

    $CodeCoverageThreshold = Get-CodeCoverageThreshold @GetCodeCoverageThresholdParameters

    if (-not $CodeCoverageThreshold)
    {
        $CodeCoverageThreshold = 0
    }

    "`tCode Coverage Threshold  = '$CodeCoverageThreshold'"

    $PesterOutputFolder = Get-SamplerAbsolutePath -Path $PesterOutputFolder -RelativeTo $OutputDirectory
    "`tPester Output Folder     = '$PesterOutputFolder'"

    $osShortName = Get-OperatingSystemShortName

    $powerShellVersion = 'PSv.{0}' -f $PSVersionTable.PSVersion

    $moduleFileName = '{0}.psm1' -f $ProjectName

    "`tModule File Name         = '$moduleFileName'"

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

    "`t"
    "`tCodeCoverageOutputFile         = $CodeCoverageOutputFile"

    $CodeCoverageOutputFileEncoding = $BuildInfo.Pester.CodeCoverageOutputFileEncoding

    if (-not $CodeCoverageOutputFileEncoding)
    {
        $CodeCoverageOutputFileEncoding = 'ascii'
    }

    "`tCodeCoverageOutputFileEncoding = $CodeCoverageOutputFileEncoding"
    ""

    if ($CodeCoverageThreshold -eq 0)
    {
        Write-Build -Color 'Green' -Text 'Coverage bypassed. Nothing to convert.'

        return
    }

    $PesterResultObjectClixml = Join-Path $PesterOutputFolder "PesterObject_$pesterOutputFileFileName"

    Write-Build -Color 'White' -Text "`tPester Output Object = $PesterResultObjectClixml"

    if (-not (Test-Path -Path $PesterResultObjectClixml))
    {
        throw 'No command were tested, nothing to convert.'
    }
    else
    {
        $pesterObject = Import-Clixml -Path $PesterResultObjectClixml
    }

    <#
        Evaluate Pester version to use the correct properties for hit and missed commands.
        The property Version does not exist on the result object from Pester 4.
    #>
    if ($pesterObject.Version)
    {
        # Pester 5

        [System.Version] $pesterVersion, $null = $pesterObject.Version -split '-'

        if ($pesterVersion -ge '5.0.0' -and $pesterVersion -lt '5.2.0')
        {
            throw 'When Pester 5 is used then to correctly support code coverage the minimum required version is v5.2.0.'
        }
        else
        {
            $originalMissedCommands = $pesterObject.CodeCoverage.CommandsMissed
            $originalHitCommands = $pesterObject.CodeCoverage.CommandsExecuted
        }
    }
    else
    {
        # Pester 4

        $originalMissedCommands = $pesterObject.CodeCoverage.MissedCommands
        $originalHitCommands = $pesterObject.CodeCoverage.HitCommands
    }

    # Get all missed commands that are in the main module file.
    $missedCommands = $originalMissedCommands |
        Where-Object -FilterScript { $_.File -match [RegEx]::Escape($moduleFileName) }

    if ($null -ne $missedCommands)
    {
        # Handle if there is just one item retuned, casting back to array.
        $missedCommands = @($missedCommands)
    }

    # Get all hit commands that are in the main module file.
    $hitCommands = $originalHitCommands |
        Where-Object -FilterScript { $_.File -match [RegEx]::Escape($moduleFileName) }

    if ($null -ne $hitCommands)
    {
        # Handle if there is just one item retuned, casting back to array.
        $hitCommands = @($hitCommands)
    }

    <#
        The command Convert-LineNumber uses 'PassThru' very strange. It is needed
        to update the content of passed in object correctly (from the pipeline in
        this case). When using PassThru the command adds the properties SourceFile
        and SourceLineNumber.

        The command Convert-LineNumber is part of ModuleBuilder.
    #>
    $missedCommands | Convert-LineNumber -ErrorAction 'Stop' -PassThru | Out-Null
    $hitCommands | Convert-LineNumber -ErrorAction 'Stop' -PassThru | Out-Null

    # Blank line in output.
    ""

    Write-Build -Color 'White' -Text "Missed commands in source files:"

    # Output missed commands to visualize it in the pipeline output.
    $allMissedCommandsInSourceFiles = $missedCommands + (
        $pesterObject.CodeCoverage.MissedCommands |
            Where-Object -FilterScript { $_.File -notmatch [RegEx]::Escape($moduleFileName) }
    )

    $allMissedCommandsInSourceFiles |
        Select-Object @{
            Name = 'File'
            Expr = {
                if ($_.SourceFile)
                {
                    $_.SourceFile
                }
                else
                {
                    $_.File
                }
            }
        },
        @{
            Name = 'Line'
            Expr = {
                if ($_.SourceLineNumber)
                {
                    $_.SourceLineNumber
                }
                else
                {
                    $_.Line
                }
            }
        }, Function, Command |
            Out-String

    # Blank line in output.
    ""

    Write-Build -Color 'White' -Text "Converting coverage file."

    <#
        Cannot find a good example how package and class relate to PowerShell.
        This implementation tries to mimic what Pester outputs in its coverage
        file.
    #>

    Write-Build -Color 'DarkGray' -Text "`tBuilding new code coverage file against source."

    $coverageXml = New-SamplerJaCoCoDocument -MissedCommands $missedCommands -HitCommands $hitCommands -PackageName $SourcePath -PackageDisplayName $ModuleVersionFolder

    $newCoverageFilePath = Join-Path -Path $PesterOutputFolder -ChildPath 'source_coverage.xml'

    Write-Build -Color 'DarkGray' -Text "`tWriting converted code coverage file to '$newCoverageFilePath'."

    Out-SamplerXml -Path $newCoverageFilePath -XmlDocument $coverageXml -Encoding $CodeCoverageOutputFileEncoding

    Write-Build -Color 'DarkGray' -Text "`tImporting original code coverage file '$CodeCoverageOutputFile'."

    $originalXml = New-Object -TypeName 'System.Xml.XmlDocument'

    <#
        This need to be set on Windows PowerShell even if it is already $null
        otherwise 'Load()' below will try to load the DTD. This
        does not happen on PowerShell and this line is not needed it Windows
        PowerShell is not used at all. Seems that setting this property changes
        something internal in [System.Xml.XmlDocument].
        See https://stackoverflow.com/questions/11135343/xml-documenttype-method-createdocumenttype-crashes-if-dtd-is-absent-net-c-sharp.
    #>
    $originalXml.XmlResolver = $null

    $originalXml.Load($CodeCoverageOutputFile)

    $codeCoverageOutputBackupFile = $CodeCoverageOutputFile -replace '\.xml', '.xml.bak'

    Write-Build -Color 'DarkGray' -Text "`tWriting a backup of original code coverage file to '$codeCoverageOutputBackupFile'."

    Out-SamplerXml -Path $codeCoverageOutputBackupFile -XmlDocument $originalXml -Encoding $CodeCoverageOutputFileEncoding

    Write-Build -Color 'DarkGray' -Text "`tRemoving XML node from original code coverage."

    $xPath = '//package[@name="{0}"]' -f $ModuleVersionFolder

    Write-Build -Color 'DarkGray' -Text "`t`tUsing XPath: '$xPath'."

    $elementToRemove = Select-XML -Xml $originalXml -XPath $xPath

    if ($elementToRemove)
    {
        $elementToRemove.Node.ParentNode.RemoveChild($elementToRemove.Node) | Out-Null
    }

    Write-Build -Color 'DarkGray' -Text "`tMerging temporary code coverage file with the original code coverage file."

    $targetXmlDocument = Merge-JaCoCoReport -OriginalDocument $originalXml -MergeDocument $coverageXml

    Write-Build -Color 'DarkGray' -Text "`tUpdating statistics in the new code coverage file."

    $targetXmlDocument = Update-JaCoCoStatistic -Document $targetXmlDocument

    $sourcePathFolderName = Split-Path -Path $SourcePath -Leaf

    Write-Build -Color 'DarkGray' -Text ("`tUpdating path to include source folder '{0}' in the package element in the coverage file." -f $sourcePathFolderName)

    Select-Xml -Xml $targetXmlDocument -XPath '//package' |
        ForEach-Object -Process {
            $_.Node.name = $_.Node.name -replace '^\d+\.\d+\.\d+', $sourcePathFolderName
        }

    Write-Build -Color 'DarkGray' -Text "`tWriting back updated code coverage file to '$CodeCoverageOutputFile'."

    Out-SamplerXml -Path $CodeCoverageOutputFile -XmlDocument $targetXmlDocument -Encoding $CodeCoverageOutputFileEncoding

    Write-Build -Color Green -Text 'Code Coverage successfully converted.'
}
