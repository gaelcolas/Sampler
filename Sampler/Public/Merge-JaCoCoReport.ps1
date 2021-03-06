<#
.SYNOPSIS
Merge two JaCoCoReports into one.

.DESCRIPTION
When you run tests independently for the same module, you may want to
get a unified report of all the code paths that were tested.
For instance, you want to get a unified report when the runs
where done on Linux and Windows.

This function helps merge the results of two runs into one file.
If you have more than two reports, keep merging them.

.PARAMETER OriginalDocument
One of the JaCoCoReports you would like to merge.

.PARAMETER MergeDocument
Second JaCoCoReports you would like to merge with the other one.

.EXAMPLE
Merge-JaCoCoReport -OriginalDocument 'C:\src\MyModule\Output\JaCoCoRun_linux.xml' -MergeDocument 'C:\src\MyModule\Output\JaCoCoRun_windows.xml'

.NOTES
See also Update-JaCoCoStatistic
Thanks to Yorick (@ykuijs) for this great feature!
#>
function Merge-JaCoCoReport
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]
        $OriginalDocument,

        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]
        $MergeDocument
    )

    foreach ($mPackage in $MergeDocument.report.package)
    {
        Write-Verbose "  Processing package: $($mPackage.Name)"
        $oPackage = $OriginalDocument.report.package | Where-Object { $_.Name -eq $mPackage.Name }

        foreach ($mSourcefile in $mPackage.sourcefile)
        {
            Write-Verbose "    Processing sourcefile: $($mSourcefile.Name)"
            if ($null -ne $oPackage)
            {
                foreach ($mPackageLine in $mSourcefile.line)
                {
                    $oSourcefile = $oPackage.sourcefile | Where-Object { $_.name -eq $mSourcefile.name }
                    $oPackageLine = $oSourcefile.line | Where-Object { $_.nr -eq $mPackageLine.nr }

                    if ($null -eq $oPackageLine)
                    {
                        # Missed line in origin, covered in merge
                        Write-Verbose "      Adding line: $($mPackageLine.nr)"
                        $null = $oPackage.sourcefile.AppendChild($oPackage.sourcefile.OwnerDocument.ImportNode($mPackageLine, $true))
                        continue
                    }

                    if (($oPackageLine.ci -eq 0) -and ($oPackageLine.mi -ne 0) -and `
                        ($mPackageLine.ci -ne 0) -and ($mPackageLine.mi -eq 0))
                    {
                        # Missed line in origin, covered in merge
                        Write-Verbose "      Updating missed line: $($mPackageLine.nr)"
                        $oPackageLine.ci = $mPackageLine.ci
                        $oPackageLine.mi = $mPackageLine.mi
                        continue
                    }

                    if ($oPackageLine.ci -lt $mPackageLine.ci)
                    {
                        # Missed line in origin, covered in merge
                        Write-Verbose "      Updating line: $($mPackageLine.nr)"
                        $oPackageLine.ci = $mPackageLine.ci
                        $oPackageLine.mi = $mPackageLine.mi
                        continue
                    }
                }
            }
            else
            {
                # New package, does not exist in origin. Add package.
                Write-Verbose "    Package '$($mPackage.Name)' does not exist in original file. Adding..."
                foreach ($xmlElement in $OriginalDocument.report)
                {
                    if ($xmlElement -is [System.Xml.XmlElement])
                    {
                        $null = $xmlElement.AppendChild($OriginalDocument.report.OwnerDocument.ImportNode($mPackage, $true))
                        break
                    }
                }
            }
        }
    }

    return $OriginalDocument
}
