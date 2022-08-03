
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
        See also Update-JaCoCoStatistic that will update the counter elements.
        Thanks to Yorick (@ykuijs) for this great feature!
#>
function Merge-JaCoCoReport
{
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]
        $OriginalDocument,

        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]
        $MergeDocument
    )

    # Loop through all existing packages in the document to merge.
    foreach ($mergePackage in $MergeDocument.report.package)
    {
        Write-Verbose "  Processing package: $($mergePackage.Name)"

        # Get the package from the original document.
        $originalPackage = $OriginalDocument.report.package |
            Where-Object -FilterScript {
                $_.Name -eq $mergePackage.Name
            }

        # Evaluate if the package exist in the original document.
        if ($null -ne $originalPackage)
        {
            <#
                Package already exist, evaluate that the package in original
                document does not miss anything that the merge document contain.
            #>

            <#
                Loop through the package's <class> in the merge document and
                verify that they exist in the original document.
            #>
            foreach ($mergeClass in $mergePackage.class)
            {
                Write-Verbose "    Processing class: $($mergeClass.Name)"

                $originalClass = $originalPackage.class |
                    Where-Object -FilterScript {
                        $_.name -eq $mergeClass.name
                    }

                # Evaluate if the sourcefile exist in the original document.
                if ($null -eq $originalClass)
                {
                    Write-Verbose "      Adding class: $($mergeClass.name)"

                    # Add missing sourcefile from merge document to original document.
                    $null = $originalPackage.AppendChild($originalPackage.OwnerDocument.ImportNode($mergeClass, $true))
                }
                else
                {
                    <#
                        Loop through the sourcefile's <method> in the merge document and
                        verify that they exist in the original document.
                    #>
                    foreach ($mergeClassMethod in $mergeClass.method)
                    {
                        $originalClassMethod = $originalClass.method |
                            Where-Object -FilterScript {
                                $_.name -eq $mergeClassMethod.name
                            }

                        if ($null -eq $originalClassMethod)
                        {
                            # Missed line in origin, covered in merge.
                            Write-Verbose "      Adding method: $($mergeClassMethod.name)"

                            $null = $originalClass.AppendChild($originalClass.OwnerDocument.ImportNode($mergeClassMethod, $true))

                            # Skip to next line.
                            continue
                        }
                    }
                }
            }

            <#
                Loop through the package's <sourcefile> in the merge document and
                verify that they exist in the original document.
            #>
            foreach ($mergeSourceFile in $mergePackage.sourcefile)
            {
                Write-Verbose "    Processing sourcefile: $($mergeSourceFile.Name)"

                $originalSourceFile = $originalPackage.sourcefile |
                    Where-Object -FilterScript {
                        $_.name -eq $mergeSourceFile.name
                    }

                # Evaluate if the sourcefile exist in the original document.
                if ($null -eq $originalSourceFile)
                {
                    Write-Verbose "      Adding sourcefile: $($mergeSourceFile.name)"

                    # Add missing sourcefile from merge document to original document.
                    $null = $originalPackage.AppendChild($originalPackage.OwnerDocument.ImportNode($mergeSourceFile, $true))
                }
                else
                {
                    <#
                        Loop through the sourcefile's <line> in the merge document and
                        verify that they exist in the original document.
                    #>
                    foreach ($mergeSourceFileLine in $mergeSourceFile.line)
                    {
                        $originalSourceFileLine = $originalSourceFile.line |
                            Where-Object -FilterScript {
                                $_.nr -eq $mergeSourceFileLine.nr
                            }

                        if ($null -eq $originalSourceFileLine)
                        {
                            # Missed line in origin, covered in merge.
                            Write-Verbose "      Adding line: $($mergeSourceFileLine.nr)"

                            $null = $originalSourceFile.AppendChild($originalSourceFile.OwnerDocument.ImportNode($mergeSourceFileLine, $true))

                            # Skip to next line.
                            continue
                        }
                        else
                        {
                            if ($originalSourceFileLine.ci -eq 0 -and $mergeSourceFileLine.ci -ne 0 -and
                                $originalSourceFileLine.mi -ne 0 -and $mergeSourceFileLine.mi -eq 0)
                            {
                                # Missed line in origin, covered in merge

                                Write-Verbose "      Updating missed line: $($mergeSourceFileLine.nr)"

                                $originalSourceFileLine.ci = $mergeSourceFileLine.ci
                                $originalSourceFileLine.mi = $mergeSourceFileLine.mi
                            }
                            elseif ($originalSourceFileLine.ci -lt $mergeSourceFileLine.ci)
                            {
                                # Missed line in origin, covered in merge

                                Write-Verbose "      Updating line: $($mergeSourceFileLine.nr)"

                                <#
                                    TODO: This overwrite the hit count on original line
                                          if the original line count is less than the
                                          merge line count, but shouldn't the hit count
                                          of merge document be added to the count of the
                                          original?

                                            Original ci = 1
                                               Merge ci = 2

                                                  Result: 3

                                        And shouldn't it always add to the hit count, not
                                        just when original line is less than the merge line?

                                            Original ci = 1
                                               Merge ci = 1

                                                  Result: 2

                                        This is also true for missed hit count that
                                        can be more than 1.

                                        Example from the project SqlServerDsc and the
                                        DSC resource SqlAg (DSC_SqlAg.psm1):

                                        <line nr="300" mi="3" ci="0" mb="0" cb="0" />
                                        <line nr="301" mi="1" ci="0" mb="0" cb="0" />
                                        <line nr="303" mi="2" ci="0" mb="0" cb="0" />

                                        Uncertain how hit count should be calculated so
                                        I leave this comment for future improvement.
                                #>
                                $originalSourceFileLine.ci = $mergeSourceFileLine.ci
                                $originalSourceFileLine.mi = $mergeSourceFileLine.mi
                            }

                        }
                    }
                }
            }
        }
        else
        {
            <#
                New package, does not exist in origin. Add package.
            #>

            Write-Verbose "    Package '$($mergePackage.Name)' does not exist in original file. Adding..."

            <#
                Must import the node with child elements first since it belongs
                to another XML document.
            #>
            $packageElementToMerge = $OriginalDocument.ImportNode($mergePackage, $true)

            <#
                Append the 'package' element to the 'report' element.
                The second array item in 'report' property is the XmlElement object.
            #>
            $OriginalDocument.report[1].AppendChild($packageElementToMerge) | Out-Null
        }
    }

    <#
        The counters at the 'report' element level need to be moved at the end
        of the document to comply with the DTD. Select out the counter elements
        under the report element, and move any that is found.
    #>
    $elementToMove = Select-XML -Xml $OriginalDocument -XPath '/report/counter'

    if ($elementToMove)
    {
        $elementToMove | ForEach-Object -Process {
            $elementToMove.Node.ParentNode.AppendChild($_.Node) | Out-Null
        }
    }

    return $OriginalDocument
}
