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
    # Get the vales for task variables, see https://github.com/gaelcolas/Sampler#task-variables.
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

# Synopsis: Convert JaCoCo coverage so it supports a built module by way of ModuleBuilder.
task Convert_Pester_Coverage {
    # Get the vales for task variables, see https://github.com/gaelcolas/Sampler#task-variables.
    . Set-SamplerTaskVariable

    $builtDscResourcesFolder = Get-SamplerAbsolutePath -Path 'DSCResources' -RelativeTo $builtModuleBase

    "`tBuilt DSC Resource Path  = '$builtDscResourcesFolder'"

    $GetCodeCoverageThresholdParameters = @{
        RuntimeCodeCoverageThreshold = $CodeCoverageThreshold
        BuildInfo                    = $BuildInfo
    }

    $CodeCoverageThreshold = Get-CodeCoverageThreshold @GetCodeCoverageThresholdParameters

    "`tCode Coverage Threshold  = '$CodeCoverageThreshold'"

    if (-not $CodeCoverageThreshold)
    {
        $CodeCoverageThreshold = 0
    }

    $PesterOutputFolder = Get-SamplerAbsolutePath -Path $PesterOutputFolder -RelativeTo $OutputDirectory
    "`tPester Output Folder     = '$PesterOutputFolder'"

    $osShortName = Get-OperatingSystemShortName

    $powerShellVersion = 'PSv.{0}' -f $PSVersionTable.PSVersion

    $moduleFileName = '{0}.psm1' -f $ProjectName

    "`tModule File Name         = '$moduleFileName'"

    #### TODO: Split Script Task Variables here

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
        throw "No command were tested, nothing to convert."
    }
    else
    {
        $pesterObject = Import-Clixml -Path $PesterResultObjectClixml
    }

    # Get all missed commands that are in the main module file.
    $missedCommands = $pesterObject.CodeCoverage.MissedCommands |
        Where-Object -FilterScript { $_.File -match [RegEx]::Escape($moduleFileName) }

    # Get all hit commands that are in the main module file.
    $hitCommands = $pesterObject.CodeCoverage.HitCommands |
        Where-Object -FilterScript { $_.File -match [RegEx]::Escape($moduleFileName) }

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

    [System.Xml.XmlDocument] $coverageXml = ''

    <#
        This need to be set on Windows PowerShell even if it is already $null
        otherwise 'CreateDocumentType()' below will try to load the DTD. This
        does not happen on PowerShell and this line is not needed it Windows
        PowerShell is not used at all. Seems that setting this property changes
        something internal in [System.Xml.XmlDocument].
        See https://stackoverflow.com/questions/11135343/xml-documenttype-method-createdocumenttype-crashes-if-dtd-is-absent-net-c-sharp.
    #>
    $coverageXml.XmlResolver = $null

    # XML header.
    $xmlDeclaration = $coverageXml.CreateXmlDeclaration('1.0', 'UTF-8', 'no')

    # DTD: https://www.jacoco.org/jacoco/trunk/coverage/report.dtd
    $xmlDocumentType = $coverageXml.CreateDocumentType('report', '-//JACOCO//DTD Report 1.1//EN', 'report.dtd', $null)

    $coverageXml.AppendChild($xmlDeclaration) | Out-Null
    $coverageXml.AppendChild($xmlDocumentType) | Out-Null

    # Root element 'report'.
    $xmlElementReport = $coverageXml.CreateNode('element', 'report', $null)
    $xmlElementReport.SetAttribute('name', 'Sampler ({0})' -f (Get-Date).ToString('yyyy-mm-dd HH:mm:ss'))

    <#
        Child element 'sessioninfo'.

        The attributes 'start' and 'dump' is the time it took to run the tests in
        milliseconds, but it is not used in the end, we just add a plausible number
        here so it passes the referenced DTD, or any other parsing that might be done
        in the future.
    #>
    $testRunLengthInMilliseconds = 1785237 # ~30 minutes

    [System.Int64] $sessionInfoEndTime = [System.Math]::Floor((New-TimeSpan -Start (Get-Date -Date '01/01/1970') -End (Get-Date)).TotalMilliseconds)
    [System.Int64] $sessionInfoStartTime = [System.Math]::Floor($sessionInfoEndTime - $testRunLengthInMilliseconds)

    $xmlElementSessionInfo = $coverageXml.CreateNode('element', 'sessioninfo', $null)
    $xmlElementSessionInfo.SetAttribute('id', 'this')
    $xmlElementSessionInfo.SetAttribute('start', $sessionInfoStartTime)
    $xmlElementSessionInfo.SetAttribute('dump', $sessionInfoEndTime)
    $xmlElementReport.AppendChild($xmlElementSessionInfo) | Out-Null

    <#
        This is how each object in $allCommands looks like:

        # A method in a PowerShell class located in the Classes folder.
        File             : C:\source\DnsServerDsc\output\MyModule\1.0.0\MyModule.psm1
        Line             : 168
        StartLine        : 168
        EndLine          : 168
        StartColumn      : 25
        EndColumn        : 36
        Class            : ResourceBase
        Function         : Compare
        Command          : $currentState = $this.Get() | ConvertTo-HashTableFromObject
        HitCount         : 86
        SourceFile       : .\Classes\001.ResourceBase.ps1
        SourceLineNumber : 153

        # A function located in private or public folder.
        File             : C:\source\DnsServerDsc\output\MyModule\1.0.0\MyModule.psm1
        Line             : 2658
        StartLine        : 2658
        EndLine          : 2658
        StartColumn      : 26
        EndColumn        : 29
        Class            :
        Function         : Get-LocalizedDataRecursive
        Command          : $localizedData = @{}
        HitCount         : 225
        SourceFile       : .\Private\Get-LocalizedDataRecursive.ps1
        SourceLineNumber : 35
    #>
    $allCommands = $hitCommands + $missedCommands

    $sourcePathFolderName = (Split-Path -Path $SourcePath -Leaf) -replace '\\','/'

    $reportCounterInstruction = @{
        Missed  = 0
        Covered = 0
    }

    $reportCounterLine = @{
        Missed  = 0
        Covered = 0
    }

    $reportCounterMethod = @{
        Missed  = 0
        Covered = 0
    }

    $reportCounterClass = @{
        Missed  = 0
        Covered = 0
    }

    $packageCounterInstruction = @{
        Missed  = 0
        Covered = 0
    }

    $packageCounterLine = @{
        Missed  = 0
        Covered = 0
    }

    $packageCounterMethod = @{
        Missed  = 0
        Covered = 0
    }

    $packageCounterClass = @{
        Missed  = 0
        Covered = 0
    }

    $allSourceFileElements = @()

    # This is what the user expects to see.
    $packageDisplayName = $sourcePathFolderName

    # The module version is what is expected to be in the XML.
    $xmlPackageName = $ModuleVersionFolder

    Write-Debug -Message ('Creating XML output for JaCoCo package ''{0}''.' -f $packageDisplayName)

    <#
        Child element 'package'.

        This implementation assumes the attribute 'name' of the element 'package'
        should be the path to the folder that contains the PowerShell script files
        (relative from GitHub repository root).
    #>
    $xmlElementPackage = $coverageXml.CreateElement('package')
    $xmlElementPackage.SetAttribute('name', $xmlPackageName)

    $commandsGroupedOnSourceFile = $allCommands | Group-Object -Property 'SourceFile'

    foreach ($jaCocoClass in $commandsGroupedOnSourceFile)
    {
        $classCounterInstruction = @{
            Missed  = 0
            Covered = 0
        }

        $classCounterLine = @{
            Missed  = 0
            Covered = 0
        }

        $classCounterMethod = @{
            Missed  = 0
            Covered = 0
        }

        $classDisplayName = ($jaCocoClass.Name -replace '^\.', $sourcePathFolderName) -replace '\\','/'

        # The module version is what is expected to be in the XML.
        $sourceFilePath = ($jaCocoClass.Name -replace '^\.', $ModuleVersionFolder) -replace '\\','/'

        <#
            Get class name if it exist, otherwise use function name. The first
            object should in the array should give us the right information.
        #>
        $xmlClassName = if ([System.String]::IsNullOrEmpty($jaCocoClass.Group[0].Class))
        {
            if ([System.String]::IsNullOrEmpty($jaCocoClass.Group[0].Function))
            {
                '<script>'
            }
            else
            {
                $jaCocoClass.Group[0].Function
            }
        }
        else
        {
            $jaCocoClass.Group[0].Class
        }

        $sourceFileName = $sourceFilePath -replace [regex]::Escape('{0}/' -f $ModuleVersionFolder)

        Write-Debug -Message ("`tCreating XML output for JaCoCo class '{0}'." -f $classDisplayName)

        # Child element 'class'.
        $xmlElementClass = $coverageXml.CreateElement('class')
        $xmlElementClass.SetAttribute('name', $xmlClassName)
        $xmlElementClass.SetAttribute('sourcefilename', $sourceFileName)

        <#
            This assumes that a value in property Function is never $null. Test
            showed that commands at script level is assigned empty string in the
            Function property, so it should work for missed and hit commands at
            script level too.

            Sorting the objects after StartLine so they come in the order
            they appear in the code file. Also, it is necessary for the
            command Update-JoCaCoStatistic to work.
        #>
        $commandsGroupedOnFunction = $jaCocoClass.Group |
                Group-Object -Property 'Function' |
                Sort-Object -Property {
                    # Find the first line for each method.
                    ($_.Group.SourceLineNumber | Measure-Object -Minimum).Minimum
                }

        foreach ($jaCoCoMethod in $commandsGroupedOnFunction)
        {
            $functionName = if ([System.String]::IsNullOrEmpty($jaCoCoMethod.Name))
            {
                '<script>'
            }
            else
            {
                $jaCoCoMethod.Name
            }

            Write-Debug -Message ("`t`tCreating XML output for JaCoCo method '{0}'." -f $functionName)

            <#
                Sorting all commands in ascending order and using the first
                'SourceLineNumber' as the first line of the method. Assuming
                every code line for the method was in either $missedCommands
                or $hitCommands which the sorting is based on.
            #>
            $methodFirstLine = $jaCoCoMethod.Group |
                Sort-Object -Property 'SourceLineNumber' |
                    Select-Object -First 1 -ExpandProperty 'SourceLineNumber'

            # Child element 'method'.
            $xmlElementMethod = $coverageXml.CreateElement('method')
            $xmlElementMethod.SetAttribute('name', $functionName)
            $xmlElementMethod.SetAttribute('desc', '()')
            $xmlElementMethod.SetAttribute('line', $methodFirstLine)

            <#
                Documentation for counters:
                https://www.jacoco.org/jacoco/trunk/doc/counters.html
            #>

            <#
                Child element 'counter' and type INSTRUCTION.

                Each command can be hit multiple times, the INSTRUCTION counts
                how many times the command was hit or missed.
            #>
            $numberOfInstructionsCovered = (
                $jaCoCoMethod.Group |
                    Where-Object -FilterScript {
                        $_.HitCount -ge 1
                    }
            ).Count

            $numberOfInstructionsMissed = (
                $jaCoCoMethod.Group |
                    Where-Object -FilterScript {
                        $_.HitCount -eq 0
                    }
            ).Count

            $xmlElementCounterMethodInstruction = $coverageXml.CreateElement('counter')
            $xmlElementCounterMethodInstruction.SetAttribute('type', 'INSTRUCTION')
            $xmlElementCounterMethodInstruction.SetAttribute('missed', $numberOfInstructionsMissed)
            $xmlElementCounterMethodInstruction.SetAttribute('covered', $numberOfInstructionsCovered)
            $xmlElementMethod.AppendChild($xmlElementCounterMethodInstruction) | Out-Null

            $classCounterInstruction.Covered += $numberOfInstructionsCovered
            $classCounterInstruction.Missed += $numberOfInstructionsMissed

            $packageCounterInstruction.Covered += $numberOfInstructionsCovered
            $packageCounterInstruction.Missed += $numberOfInstructionsMissed

            $reportCounterInstruction.Covered += $numberOfInstructionsCovered
            $reportCounterInstruction.Missed += $numberOfInstructionsMissed

            <#
                Child element 'counter' and type LINE.

                The LINE counts how many unique lines that was hit or missed.
            #>
            $numberOfLinesCovered = (
                $jaCoCoMethod.Group |
                    Where-Object -FilterScript {
                        $_.HitCount -ge 1
                    } |
                        Sort-Object -Property 'SourceLineNumber' -Unique
            ).Count

            $numberOfLinesMissed = (
                $jaCoCoMethod.Group |
                    Where-Object -FilterScript {
                        $_.HitCount -eq 0
                    } |
                        Sort-Object -Property 'SourceLineNumber' -Unique
            ).Count

            $xmlElementCounterMethodLine = $coverageXml.CreateElement('counter')
            $xmlElementCounterMethodLine.SetAttribute('type', 'LINE')
            $xmlElementCounterMethodLine.SetAttribute('missed', $numberOfLinesMissed)
            $xmlElementCounterMethodLine.SetAttribute('covered', $numberOfLinesCovered)
            $xmlElementMethod.AppendChild($xmlElementCounterMethodLine) | Out-Null

            $classCounterLine.Covered += $numberOfLinesCovered
            $classCounterLine.Missed += $numberOfLinesMissed

            $packageCounterLine.Covered += $numberOfLinesCovered
            $packageCounterLine.Missed += $numberOfLinesMissed

            $reportCounterLine.Covered += $numberOfLinesCovered
            $reportCounterLine.Missed += $numberOfLinesMissed

            <#
                Child element 'counter' and type METHOD.

                The METHOD counts as covered if at least one line was hit in
                the method. This value seem not to be higher than 1, assuming
                that is true.
            #>
            $isLineInMethodCovered = (
                $jaCoCoMethod.Group |
                    Where-Object -FilterScript {
                        $_.HitCount -ge 1
                    }
            ).Count

            <#
                If at least one instructions was covered in the method, then
                method was covered.
            #>
            if ($isLineInMethodCovered)
            {
                $methodCovered = 1
                $methodMissed = 0

                $classCounterMethod.Covered += 1

                $packageCounterMethod.Covered += 1

                $reportCounterMethod.Covered += 1
            }
            else
            {
                $methodCovered = 0
                $methodMissed = 1

                $classCounterMethod.Missed += 1

                $packageCounterMethod.Missed += 1

                $reportCounterMethod.Missed += 1
            }

            $xmlElementCounterMethod = $coverageXml.CreateElement('counter')
            $xmlElementCounterMethod.SetAttribute('type', 'METHOD')
            $xmlElementCounterMethod.SetAttribute('missed', $methodMissed)
            $xmlElementCounterMethod.SetAttribute('covered', $methodCovered)
            $xmlElementMethod.AppendChild($xmlElementCounterMethod) | Out-Null

            $xmlElementClass.AppendChild($xmlElementMethod) | Out-Null
        }

        $xmlElementCounter_ClassInstruction = $coverageXml.CreateElement('counter')
        $xmlElementCounter_ClassInstruction.SetAttribute('type', 'INSTRUCTION')
        $xmlElementCounter_ClassInstruction.SetAttribute('missed', $classCounterInstruction.Missed)
        $xmlElementCounter_ClassInstruction.SetAttribute('covered', $classCounterInstruction.Covered)
        $xmlElementClass.AppendChild($xmlElementCounter_ClassInstruction) | Out-Null

        $xmlElementCounter_ClassLine = $coverageXml.CreateElement('counter')
        $xmlElementCounter_ClassLine.SetAttribute('type', 'LINE')
        $xmlElementCounter_ClassLine.SetAttribute('missed', $classCounterLine.Missed)
        $xmlElementCounter_ClassLine.SetAttribute('covered', $classCounterLine.Covered)
        $xmlElementClass.AppendChild($xmlElementCounter_ClassLine) | Out-Null

        if ($classCounterLine.Covered -gt 1)
        {
            $classCovered = 1
            $classMissed = 0

            $packageCounterClass.Covered += 1

            $reportCounterClass.Covered += 1
        }
        else
        {
            $classCovered = 0
            $classMissed = 1

            $packageCounterClass.Missed += 1

            $reportCounterClass.Missed += 1
        }

        $xmlElementCounter_ClassMethod = $coverageXml.CreateElement('counter')
        $xmlElementCounter_ClassMethod.SetAttribute('type', 'METHOD')
        $xmlElementCounter_ClassMethod.SetAttribute('missed', $classCounterMethod.Missed)
        $xmlElementCounter_ClassMethod.SetAttribute('covered', $classCounterMethod.Covered)
        $xmlElementClass.AppendChild($xmlElementCounter_ClassMethod) | Out-Null

        $xmlElementCounter_Class = $coverageXml.CreateElement('counter')
        $xmlElementCounter_Class.SetAttribute('type', 'CLASS')
        $xmlElementCounter_Class.SetAttribute('missed', $classMissed)
        $xmlElementCounter_Class.SetAttribute('covered', $classCovered)
        $xmlElementClass.AppendChild($xmlElementCounter_Class) | Out-Null

        $xmlElementPackage.AppendChild($xmlElementClass) | Out-Null

        <#
            Child element 'sourcefile'.

            Add sourcefile element to an array for each class. The array
            will be added to the XML document at the end of the package
            loop.
        #>
        $xmlElementSourceFile = $coverageXml.CreateElement('sourcefile')
        $xmlElementSourceFile.SetAttribute('name', $sourceFileName)

        $linesToReport = @()

        # Get all instructions that was covered by grouping on 'SourceLineNumber'.
        $linesCovered = $jaCocoClass.Group |
            Sort-Object -Property 'SourceLineNumber' |
                Where-Object {
                    $_.HitCount -ge 1
                } |
                    Group-Object -Property 'SourceLineNumber' -NoElement

        # Add each covered line with its count of instructions covered.
        $linesCovered |
            ForEach-Object {
                $linesToReport += @{
                    Line    = [System.UInt32] $_.Name
                    Covered = $_.Count
                    Missed  = 0
                }
            }

        # Get all instructions that was missed by grouping on 'SourceLineNumber'.
        $linesMissed = $jaCocoClass.Group |
            Sort-Object -Property 'SourceLineNumber' |
                Where-Object {
                    $_.HitCount -eq 0
                } |
                    Group-Object -Property 'SourceLineNumber' -NoElement

        # Add each missed line with its count of instructions missed.
        $linesMissed |
            ForEach-Object {
                # Test if there are an existing line that is covered.
                if ($linesToReport.Line -contains $_.Name)
                {
                    $lineNumberToLookup = $_.Name

                    $coveredLineItem = $linesToReport |
                        Where-Object -FilterScript {
                            $_.Line -eq $lineNumberToLookup
                        }

                    $coveredLineItem.Missed += $_.Count
                }
                else
                {
                    $linesToReport += @{
                        Line    = [System.UInt32] $_.Name
                        Covered = 0
                        Missed  = $_.Count
                    }
                }
            }

        $linesToReport |
            Sort-Object -Property 'Line' |
                ForEach-Object -Process {
                    $xmlElementLine = $coverageXml.CreateElement('line')
                    $xmlElementLine.SetAttribute('nr', $_.Line)

                    <#
                        Child element 'line'.

                        These attributes are best explained here:
                        https://stackoverflow.com/questions/33868761/how-to-interpret-the-jacoco-xml-file
                    #>

                    $xmlElementLine.SetAttribute('mi', $_.Missed)
                    $xmlElementLine.SetAttribute('ci', $_.Covered)
                    $xmlElementLine.SetAttribute('mb', 0)
                    $xmlElementLine.SetAttribute('cb', 0)

                    $xmlElementSourceFile.AppendChild($xmlElementLine) |
                        Out-Null
                    }

        <#
            Add counters to sourcefile element. Reuses those element that was
            created for the class element, as they will be the same.
        #>
        $xmlElementSourceFile.AppendChild($xmlElementCounter_ClassInstruction.CloneNode($false)) | Out-Null
        $xmlElementSourceFile.AppendChild($xmlElementCounter_ClassLine.CloneNode($false)) | Out-Null
        $xmlElementSourceFile.AppendChild($xmlElementCounter_ClassMethod.CloneNode($false)) | Out-Null
        $xmlElementSourceFile.AppendChild($xmlElementCounter_Class.CloneNode($false)) | Out-Null

        $allSourceFileElements += $xmlElementSourceFile
    } # end class loop

    # Add all sourcefile elements that was generated in the class-element-loop.
    $allSourceFileElements |
        ForEach-Object -Process {
            $xmlElementPackage.AppendChild($_) | Out-Null
        }

    # Add counters at the package level.
    $xmlElementCounter_PackageInstruction = $coverageXml.CreateElement('counter')
    $xmlElementCounter_PackageInstruction.SetAttribute('type', 'INSTRUCTION')
    $xmlElementCounter_PackageInstruction.SetAttribute('missed', $packageCounterInstruction.Missed)
    $xmlElementCounter_PackageInstruction.SetAttribute('covered', $packageCounterInstruction.Covered)
    $xmlElementPackage.AppendChild($xmlElementCounter_PackageInstruction) | Out-Null

    $xmlElementCounter_PackageLine = $coverageXml.CreateElement('counter')
    $xmlElementCounter_PackageLine.SetAttribute('type', 'LINE')
    $xmlElementCounter_PackageLine.SetAttribute('missed', $packageCounterLine.Missed)
    $xmlElementCounter_PackageLine.SetAttribute('covered', $packageCounterLine.Covered)
    $xmlElementPackage.AppendChild($xmlElementCounter_PackageLine) | Out-Null

    $xmlElementCounter_PackageMethod = $coverageXml.CreateElement('counter')
    $xmlElementCounter_PackageMethod.SetAttribute('type', 'METHOD')
    $xmlElementCounter_PackageMethod.SetAttribute('missed', $packageCounterMethod.Missed)
    $xmlElementCounter_PackageMethod.SetAttribute('covered', $packageCounterMethod.Covered)
    $xmlElementPackage.AppendChild($xmlElementCounter_PackageMethod) | Out-Null

    $xmlElementCounter_PackageClass = $coverageXml.CreateElement('counter')
    $xmlElementCounter_PackageClass.SetAttribute('type', 'CLASS')
    $xmlElementCounter_PackageClass.SetAttribute('missed', $packageCounterClass.Missed)
    $xmlElementCounter_PackageClass.SetAttribute('covered', $packageCounterClass.Covered)
    $xmlElementPackage.AppendChild($xmlElementCounter_PackageClass) | Out-Null

    $xmlElementReport.AppendChild($xmlElementPackage) | Out-Null

    # Add counters at the report level.
    $xmlElementCounter_ReportInstruction = $coverageXml.CreateElement('counter')
    $xmlElementCounter_ReportInstruction.SetAttribute('type', 'INSTRUCTION')
    $xmlElementCounter_ReportInstruction.SetAttribute('missed', $reportCounterInstruction.Missed)
    $xmlElementCounter_ReportInstruction.SetAttribute('covered', $reportCounterInstruction.Covered)
    $xmlElementReport.AppendChild($xmlElementCounter_ReportInstruction) | Out-Null

    $xmlElementCounter_ReportLine = $coverageXml.CreateElement('counter')
    $xmlElementCounter_ReportLine.SetAttribute('type', 'LINE')
    $xmlElementCounter_ReportLine.SetAttribute('missed', $reportCounterLine.Missed)
    $xmlElementCounter_ReportLine.SetAttribute('covered', $reportCounterLine.Covered)
    $xmlElementReport.AppendChild($xmlElementCounter_ReportLine) | Out-Null

    $xmlElementCounter_ReportMethod = $coverageXml.CreateElement('counter')
    $xmlElementCounter_ReportMethod.SetAttribute('type', 'METHOD')
    $xmlElementCounter_ReportMethod.SetAttribute('missed', $reportCounterMethod.Missed)
    $xmlElementCounter_ReportMethod.SetAttribute('covered', $reportCounterMethod.Covered)
    $xmlElementReport.AppendChild($xmlElementCounter_ReportMethod) | Out-Null

    $xmlElementCounter_ReportClass = $coverageXml.CreateElement('counter')
    $xmlElementCounter_ReportClass.SetAttribute('type', 'CLASS')
    $xmlElementCounter_ReportClass.SetAttribute('missed', $reportCounterClass.Missed)
    $xmlElementCounter_ReportClass.SetAttribute('covered', $reportCounterClass.Covered)
    $xmlElementReport.AppendChild($xmlElementCounter_ReportClass) | Out-Null

    $coverageXml.AppendChild($xmlElementReport) | Out-Null

    if ($DebugPreference -ne 'SilentlyContinue')
    {
        $StringWriter = New-Object -TypeName 'System.IO.StringWriter'
        $XmlWriter = New-Object -TypeName 'System.XMl.XmlTextWriter' -ArgumentList $StringWriter

        $xmlWriter.Formatting = 'indented'
        $xmlWriter.Indentation = 2

        $coverageXml.WriteContentTo($XmlWriter)

        $XmlWriter.Flush()

        $StringWriter.Flush()

        # Blank row in output
        ""

        Write-Debug -Message ($StringWriter.ToString() | Out-String)
    }

    $newCoverageFilePath = Join-Path -Path $PesterOutputFolder -ChildPath 'source_coverage.xml'

    Write-Build -Color 'DarkGray' -Text "`tWriting converted code coverage file to '$newCoverageFilePath'."

    $xmlSettings = New-Object -TypeName 'System.Xml.XmlWriterSettings'
    $xmlSettings.Indent = $true
    $xmlSettings.Encoding = [System.Text.Encoding]::$CodeCoverageOutputFileEncoding

    $xmlWriter = [System.Xml.XmlWriter]::Create($newCoverageFilePath, $xmlSettings)

    $coverageXml.Save($xmlWriter)

    $xmlWriter.Close()

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
    $newCoverageFilePath = Join-Path -Path $PesterOutputFolder -ChildPath $codeCoverageOutputBackupFile

    Write-Build -Color 'DarkGray' -Text "`tWriting a backup of original code coverage file to '$codeCoverageOutputBackupFile'."

    $xmlSettings = New-Object -TypeName 'System.Xml.XmlWriterSettings'
    $xmlSettings.Indent = $true
    $xmlSettings.Encoding = [System.Text.Encoding]::$CodeCoverageOutputFileEncoding

    $xmlWriter = [System.Xml.XmlWriter]::Create($codeCoverageOutputBackupFile, $xmlSettings)

    $originalXml.Save($xmlWriter)

    $xmlWriter.Close()

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

    Write-Build -Color 'DarkGray' -Text ("`tUpdating path to include source folder '{0}' in the package element in the coverage file." -f $sourcePathFolderName)

    Select-Xml -Xml $targetXmlDocument -XPath '//package' |
        ForEach-Object -Process {
            $_.Node.name = $_.Node.name -replace '^\d+\.\d+\.\d+', $sourcePathFolderName
        }

    Write-Build -Color 'DarkGray' -Text "`tWriting back updated code coverage file to '$CodeCoverageOutputFile'."

    $xmlSettings = New-Object -TypeName 'System.Xml.XmlWriterSettings'
    $xmlSettings.Indent = $true
    $xmlSettings.Encoding = [System.Text.Encoding]::$CodeCoverageOutputFileEncoding

    $xmlWriter = [System.Xml.XmlWriter]::Create($CodeCoverageOutputFile, $xmlSettings)

    $targetXmlDocument.Save($xmlWriter)

    $xmlWriter.Close()

    Write-Build -Color Green -Text 'Code Coverage successfully converted.'
}
