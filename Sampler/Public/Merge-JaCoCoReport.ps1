
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
        Write-Verbose -Message "  Processing package: $($mergePackage.Name)"

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
                Write-Verbose -Message "    Processing class: $($mergeClass.Name)"

                $originalClass = $originalPackage.class |
                    Where-Object -FilterScript {
                        $_.name -eq $mergeClass.name
                    }

                # Evaluate if the sourcefile exist in the original document.
                if ($null -eq $originalClass)
                {
                    Write-Verbose -Message "      Adding class: $($mergeClass.name)"

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
                            Write-Verbose -Message "      Adding method: $($mergeClassMethod.name)"

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
                Write-Verbose -Message "    Processing sourcefile: $($mergeSourceFile.Name)"

                $originalSourceFile = $originalPackage.sourcefile |
                    Where-Object -FilterScript {
                        $_.name -eq $mergeSourceFile.name
                    }

                # Evaluate if the sourcefile exist in the original document.
                if ($null -eq $originalSourceFile)
                {
                    Write-Verbose -Message "      Adding sourcefile: $($mergeSourceFile.name)"

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
                            Write-Verbose -Message "      Adding line: $($mergeSourceFileLine.nr)"

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

                                Write-Verbose -Message "      Updating missed line: $($mergeSourceFileLine.nr)"

                                $originalSourceFileLine.ci = $mergeSourceFileLine.ci
                                $originalSourceFileLine.mi = $mergeSourceFileLine.mi
                            }
                            elseif ($originalSourceFileLine.ci -lt $mergeSourceFileLine.ci)
                            {
                                # Missed line in origin, covered in merge

                                Write-Verbose -Message "      Updating line: $($mergeSourceFileLine.nr)"

                                <#
                                    There is an open issue tracking if this is the
                                    correct way to calculate hit count:
                                    https://github.com/gaelcolas/Sampler/issues/392
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

            Write-Verbose -Message "    Package '$($mergePackage.Name)' does not exist in original file. Adding..."

            <#
                Must import the node with child elements first since it belongs
                to another XML document.
            #>
            $packageElementToMerge = $OriginalDocument.ImportNode($mergePackage, $true)

            <#
                Append the 'package' element to the 'report' element, there should
                only be one report element.

                The second item in the array of the 'report' property is the XmlElement
                object.
            #>
            $null = $OriginalDocument.report[1].AppendChild($packageElementToMerge)
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
