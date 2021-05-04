
<#
    .SYNOPSIS
        Creates a new JaCoCo XML document based on the provided missed and hit
        lines.

    .DESCRIPTION
        Creates a new JaCoCo XML document based on the provided missed and hit
        lines. This command is usually used together with the output object from
        Pester that also have been passed through ModuleBuilder's Convert-LineNumber.

    .PARAMETER MissedCommands
        An array of PSCustomObject that contain all the missed code lines.

    .PARAMETER HitCommands
        An array of PSCustomObject that contain all the code lines that were hit.

    .PARAMETER PackageName
        The name of package of the test source files, e.g. 'source', 'MyFunction',
        or '2.3.0'.

    .PARAMETER PackageDisplayName
        The display name of the package if it should be shown to the user differently,
        e.g. 'source' if the package name is '2.3.0'. Defaults to the same value as
        PackageName.

    .EXAMPLE
        $pesterObject = Invoke-Pester ./tests/unit -CodeCoverage
        $pesterObject.CodeCoverage.MissedCommands |
            Convert-LineNumber -ErrorAction 'Stop' -PassThru | Out-Null
        $pesterObject.CodeCoverage.HitCommands |
            Convert-LineNumber -ErrorAction 'Stop' -PassThru | Out-Null
        New-SamplerJaCoCoDocument `
            -MissedCommands $pesterObject.CodeCoverage.MissedCommands `
            -HitCommands $pesterObject.CodeCoverage.HitCommands `
            -PackageName 'source'

    .EXAMPLE
        New-SamplerJaCoCoDocument `
            -MissedCommands @{
                Class            = 'ResourceBase'
                Function         = 'Compare'
                HitCount         = 0
                SourceFile       = '.\Classes\001.ResourceBase.ps1'
                SourceLineNumber = 4
            } `
            -HitCommands @{
                Class            = 'ResourceBase'
                Function         = 'Compare'
                HitCount         = 2
                SourceFile       = '.\Classes\001.ResourceBase.ps1'
                SourceLineNumber = 3
            } `
            -PackageName 'source'
#>
function New-SamplerJaCoCoDocument
{
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [System.Object[]]
        $MissedCommands,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [System.Object[]]
        $HitCommands,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PackageName,

        [Parameter()]
        [System.String]
        $PackageDisplayName
    )

    if (-not $PSBoundParameters.ContainsKey('PackageDisplayName'))
    {
        $PackageDisplayName = $PackageName
    }

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
    $allCommands = $HitCommands + $MissedCommands

    $sourcePathFolderName = (Split-Path -Path $PackageDisplayName -Leaf) -replace '\\','/'

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
    $xmlPackageName = $PackageName

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
        $sourceFilePath = ($jaCocoClass.Name -replace '^\.', $PackageName) -replace '\\','/'

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

        $sourceFileName = $sourceFilePath -replace [regex]::Escape('{0}/' -f $PackageName)

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

            Sorting the objects after SourceLineNumber so they come in the order
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
                every code line for the method was in either $MissedCommands
                or $HitCommands which the sorting is based on.
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
                # Make sure to always return an array, even for just one object.
                @(
                    $jaCoCoMethod.Group |
                        Where-Object -FilterScript {
                            $_.HitCount -ge 1
                        }
                )
            ).Count

            $numberOfInstructionsMissed = (
                # Make sure to always return an array, even for just one object.
                @(
                    $jaCoCoMethod.Group |
                        Where-Object -FilterScript {
                            $_.HitCount -eq 0
                        }
                )
            ).Count

            New-SamplerXmlJaCoCoCounter -XmlNode $xmlElementMethod -CounterType 'INSTRUCTION' -Covered $numberOfInstructionsCovered -Missed $numberOfInstructionsMissed

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
                # Make sure to always return an array, even for just one object.
                @(
                    $jaCoCoMethod.Group |
                        Where-Object -FilterScript {
                            $_.HitCount -ge 1
                        } |
                            Sort-Object -Property 'SourceLineNumber' -Unique
                )
            ).Count

            $numberOfLinesMissed = (
                # Make sure to always return an array, even for just one object.
                @(
                    $jaCoCoMethod.Group |
                        Where-Object -FilterScript {
                            $_.HitCount -eq 0
                        } |
                            Sort-Object -Property 'SourceLineNumber' -Unique
                )
            ).Count

            New-SamplerXmlJaCoCoCounter -XmlNode $xmlElementMethod -CounterType 'LINE' -Covered $numberOfLinesCovered -Missed $numberOfLinesMissed

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
                # Make sure to always return an array, even for just one object.
                @(
                    $jaCoCoMethod.Group |
                        Where-Object -FilterScript {
                            $_.HitCount -ge 1
                        }
                )
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

            New-SamplerXmlJaCoCoCounter -XmlNode $xmlElementMethod -CounterType 'METHOD' -Covered $methodCovered -Missed $methodMissed

            $xmlElementClass.AppendChild($xmlElementMethod) | Out-Null
        }

        $xmlElementCounter_ClassInstruction = New-SamplerXmlJaCoCoCounter -XmlNode $xmlElementClass -CounterType 'INSTRUCTION' -Covered $classCounterInstruction.Covered -Missed $classCounterInstruction.Missed -PassThru
        $xmlElementCounter_ClassLine = New-SamplerXmlJaCoCoCounter -XmlNode $xmlElementClass -CounterType 'LINE' -Covered $classCounterLine.Covered -Missed $classCounterLine.Missed -PassThru

        if ($classCounterLine.Covered -ge 1)
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

        $xmlElementCounter_ClassMethod = New-SamplerXmlJaCoCoCounter -XmlNode $xmlElementClass -CounterType 'METHOD' -Covered $classCounterMethod.Covered -Missed $classCounterMethod.Missed -PassThru
        $xmlElementCounter_Class = New-SamplerXmlJaCoCoCounter -XmlNode $xmlElementClass -CounterType 'CLASS' -Covered $classCovered -Missed $classMissed -PassThru

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
    New-SamplerXmlJaCoCoCounter -XmlNode $xmlElementPackage -CounterType 'INSTRUCTION' -Covered $packageCounterInstruction.Covered -Missed $packageCounterInstruction.Missed
    New-SamplerXmlJaCoCoCounter -XmlNode $xmlElementPackage -CounterType 'LINE' -Covered $packageCounterLine.Covered -Missed $packageCounterLine.Missed
    New-SamplerXmlJaCoCoCounter -XmlNode $xmlElementPackage -CounterType 'METHOD' -Covered $packageCounterMethod.Covered -Missed $packageCounterMethod.Missed
    New-SamplerXmlJaCoCoCounter -XmlNode $xmlElementPackage -CounterType 'CLASS' -Covered $packageCounterClass.Covered -Missed $packageCounterClass.Missed

    $xmlElementReport.AppendChild($xmlElementPackage) | Out-Null

    # Add counters at the report level.
    New-SamplerXmlJaCoCoCounter -XmlNode $xmlElementReport -CounterType 'INSTRUCTION' -Covered $reportCounterInstruction.Covered -Missed $reportCounterInstruction.Missed
    New-SamplerXmlJaCoCoCounter -XmlNode $xmlElementReport -CounterType 'LINE' -Covered $reportCounterLine.Covered -Missed $reportCounterLine.Missed
    New-SamplerXmlJaCoCoCounter -XmlNode $xmlElementReport -CounterType 'METHOD' -Covered $reportCounterMethod.Covered -Missed $reportCounterMethod.Missed
    New-SamplerXmlJaCoCoCounter -XmlNode $xmlElementReport -CounterType 'CLASS' -Covered $reportCounterClass.Covered -Missed $reportCounterClass.Missed

    $coverageXml.AppendChild($xmlElementReport) | Out-Null

    return $coverageXml
}
