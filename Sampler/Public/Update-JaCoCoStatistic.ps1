
<#
    .SYNOPSIS
        Update the Statistics of a freshly merged JaCoCoReports.

    .DESCRIPTION
        When you merge two or several JaCoCoReports together
        using the Merge-JaCoCoReport, the calculated statistics
        of the Original document are not updated.

        This Command will re-calculate the JaCoCo statistics and
        update the Document.

        For the Package, Class, Method of all source files and the total it will update:
        - the Instruction Covered
        - the Instruction Missed
        - the Line Covered
        - the Line Missed
        - the Method Covered
        - the Method Missed
        - the Class Covered
        - the Class Missed

    .PARAMETER Document
        JaCoCo report XML document that needs its statistics recalculated.

    .EXAMPLE
        Update-JaCoCoStatistic -Document (Merge-JaCoCoReport $file1 $file2)

    .NOTES
        See also Merge-JaCoCoReport
        Thanks to Yorick (@ykuijs) for this great feature!
#>
function Update-JaCoCoStatistic
{
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]
        $Document
    )

    Write-Verbose "Start updating statistics!"

    $totalInstructionCovered = 0
    $totalInstructionMissed = 0
    $totalLineCovered = 0
    $totalLineMissed = 0
    $totalMethodCovered = 0
    $totalMethodMissed = 0
    $totalClassCovered = 0
    $totalClassMissed = 0

    foreach ($oPackage in $Document.report.package)
    {
        Write-Verbose "Processing package $($oPackage.name)"

        $packageInstructionCovered = 0
        $packageInstructionMissed = 0
        $packageLineCovered = 0
        $packageLineMissed = 0
        $packageMethodCovered = 0
        $packageMethodMissed = 0
        $packageClassCovered = 0
        $packageClassMissed = 0

        foreach ($oPackageClass in $oPackage.class)
        {
            $classInstructionCovered = 0
            $classInstructionMissed = 0
            $classLineCovered = 0
            $classLineMissed = 0
            $classMethodCovered = 0
            $classMethodMissed = 0

            Write-Verbose "  Processing sourcefile $($oPackageClass.sourcefilename)"
            $oPackageSourcefile = $oPackage.sourcefile | Where-Object -FilterScript { $_.Name -eq $oPackageClass.sourcefilename }

            for ($i = 0; $i -lt ([array]($oPackageClass.method)).Count; $i++)
            {
                $methodInstructionCovered = 0
                $methodInstructionMissed = 0
                $methodLineCovered = 0
                $methodLineMissed = 0
                $methodCovered = 0
                $methodMissed = 0

                $currentMethod = [array]$oPackageClass.method
                $start = $currentMethod[$i].line
                if ($i -ne ($currentMethod.Count - 1))
                {
                    $end   = $currentMethod[$i+1].Line
                    Write-Verbose "    Processing method: $($currentMethod[$i].Name)"
                    [array]$coll = $oPackageSourcefile.line | Where-Object {
                        [int]$_.nr -ge $start -and [int]$_.nr -lt $end
                    }

                    foreach ($line in $coll)
                    {
                        $methodInstructionCovered += $line.ci
                        $methodInstructionMissed += $line.mi
                    }

                    [array]$cov = $coll | Where-Object -FilterScript { $_.ci -ne "0" }
                    $methodLineCovered = $cov.Count
                    [array]$mis = $coll | Where-Object -FilterScript { $_.ci -eq "0" }
                    $methodLineMissed = $mis.Count
                }
                else
                {
                    Write-Verbose "    Processing method: $($currentMethod[$i].Name)"
                    [array]$coll = $oPackageSourcefile.line | Where-Object {
                        [int]$_.nr -ge $start
                    }

                    foreach ($line in $coll)
                    {
                        $methodInstructionCovered += $line.ci
                        $methodInstructionMissed += $line.mi
                    }

                    [array]$cov = $coll | Where-Object -FilterScript { $_.ci -ne "0" }
                    $methodLineCovered = $cov.Count
                    [array]$mis = $coll | Where-Object -FilterScript { $_.ci -eq "0" }
                    $methodLineMissed = $mis.Count
                }

                $classInstructionCovered += $methodInstructionCovered
                $classInstructionMissed += $methodInstructionMissed
                $classLineCovered += $methodLineCovered
                $classLineMissed += $methodLineMissed
                if ($methodInstructionCovered -ne 0)
                {
                    $methodCovered = 1
                    $methodMissed = 0
                    $classMethodCovered++
                }
                else
                {
                    $methodCovered = 0
                    $methodMissed = 1
                    $classMethodMissed++
                }

                # Update Method stats
                $counterInstruction = $currentMethod[$i].counter | Where-Object { $_.type -eq 'INSTRUCTION' }
                $counterInstruction.covered = [string]$methodInstructionCovered
                $counterInstruction.missed = [string]$methodInstructionMissed

                $counterLine = $currentMethod[$i].counter | Where-Object { $_.type -eq 'LINE' }
                $counterLine.covered = [string]$methodLineCovered
                $counterLine.missed = [string]$methodLineMissed

                $counterMethod = $currentMethod[$i].counter | Where-Object { $_.type -eq 'METHOD' }
                $counterMethod.covered = [string]$methodCovered
                $counterMethod.missed = [string]$methodMissed


                Write-Verbose "      Method Instruction Covered : $methodInstructionCovered"
                Write-Verbose "      Method Instruction Missed  : $methodInstructionMissed"
                Write-Verbose "      Method Line Covered        : $methodLineCovered"
                Write-Verbose "      Method Line Missed         : $methodLineMissed"
                Write-Verbose "      Method Covered             : $methodCovered"
                Write-Verbose "      Method Missed              : $methodMissed"
            }

            $packageInstructionCovered += $classInstructionCovered
            $packageInstructionMissed += $classInstructionMissed
            $packageLineCovered += $classLineCovered
            $packageLineMissed += $classLineMissed
            $packageMethodCovered += $classMethodCovered
            $packageMethodMissed += $classMethodMissed

            <#
                JaCoCo considers constructors as well as static initializers as
                methods, so any code run at script level (method '<script>') should
                be considered as the class was run.
            #>
            if ($classInstructionCovered -ne 0)
            {
                $packageClassCovered++
                $classClassCovered = 1
                $classClassMissed = 0
            }
            else
            {
                $classClassCovered = 0
                $classClassMissed = 1
            }

            # Update Class stats
            $counterInstruction = $oPackageClass.counter | Where-Object { $_.type -eq 'INSTRUCTION' }
            $counterInstruction.covered = [string]$classInstructionCovered
            $counterInstruction.missed = [string]$classInstructionMissed

            $counterLine = $oPackageClass.counter | Where-Object { $_.type -eq 'LINE' }
            $counterLine.covered = [string]$classLineCovered
            $counterLine.missed = [string]$classLineMissed

            $counterMethod = $oPackageClass.counter | Where-Object { $_.type -eq 'METHOD' }
            $counterMethod.covered = [string]$classMethodCovered
            $counterMethod.missed = [string]$classMethodMissed

            $counterMethod = $oPackageClass.counter | Where-Object { $_.type -eq 'CLASS' }
            $counterMethod.covered = [string]$classClassCovered
            $counterMethod.missed = [string]$classClassMissed

            # Update Sourcefile stats
            $counterInstruction = $oPackageSourcefile.counter | Where-Object { $_.type -eq 'INSTRUCTION' }
            $counterInstruction.covered = [string]$classInstructionCovered
            $counterInstruction.missed = [string]$classInstructionMissed

            $counterLine = $oPackageSourcefile.counter | Where-Object { $_.type -eq 'LINE' }
            $counterLine.covered = [string]$classLineCovered
            $counterLine.missed = [string]$classLineMissed

            $counterMethod = $oPackageSourcefile.counter | Where-Object { $_.type -eq 'METHOD' }
            $counterMethod.covered = [string]$classMethodCovered
            $counterMethod.missed = [string]$classMethodMissed

            $counterMethod = $oPackageSourcefile.counter | Where-Object { $_.type -eq 'CLASS' }
            $counterMethod.covered = [string]$classClassCovered
            $counterMethod.missed = [string]$classClassMissed

            Write-Verbose "      Class Instruction Covered  : $classInstructionCovered"
            Write-Verbose "      Class Instruction Missed   : $classInstructionMissed"
            Write-Verbose "      Class Line Covered         : $classLineCovered"
            Write-Verbose "      Class Line Missed          : $classLineMissed"
            Write-Verbose "      Class Method Covered       : $classMethodCovered"
            Write-Verbose "      Class Method Missed        : $classMethodMissed"
        }

        $totalInstructionCovered += $packageInstructionCovered
        $totalInstructionMissed += $packageInstructionMissed
        $totalLineCovered += $packageLineCovered
        $totalLineMissed += $packageLineMissed
        $totalMethodCovered += $packageMethodCovered
        $totalMethodMissed += $packageMethodMissed
        $totalClassCovered += $packageClassCovered
        $totalClassMissed += $packageClassMissed

        # Update Package stats
        $counterInstruction = $oPackage.counter | Where-Object { $_.type -eq 'INSTRUCTION' }
        $counterInstruction.covered = [string]$packageInstructionCovered
        $counterInstruction.missed = [string]$packageInstructionMissed

        $counterLine = $oPackage.counter | Where-Object { $_.type -eq 'LINE' }
        $counterLine.covered = [string]$packageLineCovered
        $counterLine.missed = [string]$packageLineMissed

        $counterMethod = $oPackage.counter | Where-Object { $_.type -eq 'METHOD' }
        $counterMethod.covered = [string]$packageMethodCovered
        $counterMethod.missed = [string]$packageMethodMissed

        $counterClass = $oPackage.counter | Where-Object { $_.type -eq 'CLASS' }
        $counterClass.covered = [string]$packageClassCovered
        $counterClass.missed = [string]$packageClassMissed

        Write-Verbose "  Package Instruction Covered: $packageInstructionCovered"
        Write-Verbose "  Package Instruction Missed : $packageInstructionMissed"
        Write-Verbose "  Package Line Covered       : $packageLineCovered"
        Write-Verbose "  Package Line Missed        : $packageLineMissed"
        Write-Verbose "  Package Method Covered     : $packageMethodCovered"
        Write-Verbose "  Package Method Missed      : $packageMethodMissed"
        Write-Verbose "  Package Class Covered      : $packageClassCovered"
        Write-Verbose "  Package Class Missed       : $packageClassMissed"
    }

    #Update Total stats
    $counterInstruction = $Document.report.counter | Where-Object { $_.type -eq 'INSTRUCTION' }
    $counterInstruction.covered = [string]$totalInstructionCovered
    $counterInstruction.missed = [string]$totalInstructionMissed

    $counterLine = $Document.report.counter | Where-Object { $_.type -eq 'LINE' }
    $counterLine.covered = [string]$totalLineCovered
    $counterLine.missed = [string]$totalLineMissed

    $counterMethod = $Document.report.counter | Where-Object { $_.type -eq 'METHOD' }
    $counterMethod.covered = [string]$totalMethodCovered
    $counterMethod.missed = [string]$totalMethodMissed

    $counterClass = $Document.report.counter | Where-Object { $_.type -eq 'CLASS' }
    $counterClass.covered = [string]$totalClassCovered
    $counterClass.missed = [string]$totalClassMissed

    Write-Verbose "----------------------------------------"
    Write-Verbose " Totals"
    Write-Verbose "----------------------------------------"
    Write-Verbose "  Total Instruction Covered : $totalInstructionCovered"
    Write-Verbose "  Total Instruction Missed  : $totalInstructionMissed"
    Write-Verbose "  Total Line Covered        : $totalLineCovered"
    Write-Verbose "  Total Line Missed         : $totalLineMissed"
    Write-Verbose "  Total Method Covered      : $totalMethodCovered"
    Write-Verbose "  Total Method Missed       : $totalMethodMissed"
    Write-Verbose "  Total Class Covered       : $totalClassCovered"
    Write-Verbose "  Total Class Missed        : $totalClassMissed"
    Write-Verbose "----------------------------------------"

    Write-Verbose "Completed merging files and updating statistics!"

    return $Document
}
