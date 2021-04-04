$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName

Import-Module $ProjectName

Describe 'Update-JaCoCoStatistic' {
    BeforeAll {
        function Get-XmlAttributeValue
        {
            [CmdletBinding()]
            [OutputType([Hashtable])]
            param
            (
                [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
                [System.Xml.XmlDocument]
                $XmlDocument,

                [Parameter(Mandatory = $true)]
                [System.String]
                $XPath,

                [Parameter()]
                [Switch]
                $LineAttributes
            )

            $counter = $XmlDocument | Select-XML -XPath $XPath

            if ($LineAttributes.IsPresent)
            {
                $counterValues = @{
                    ci = ($counter.Node | Select-XML -XPath '@ci').Node.Value
                    mi = ($counter.Node | Select-XML -XPath '@mi').Node.Value
                    cb = ($counter.Node | Select-XML -XPath '@cb').Node.Value
                    mb = ($counter.Node | Select-XML -XPath '@mb').Node.Value
                }
            }
            else
            {
                $counterValues = @{
                    Missed = ($counter.Node | Select-XML -XPath '@missed').Node.Value
                    Covered = ($counter.Node | Select-XML -XPath '@covered').Node.Value
                }
            }

            return $counterValues
        }

        function Write-IndentedXml
        {
            [CmdletBinding()]
            param
            (
                [Parameter(Mandatory = $true)]
                [System.Xml.XmlDocument]
                $XmlDocument
            )

            $StringWriter = New-Object -TypeName 'System.IO.StringWriter'
            $XmlWriter = New-Object -TypeName 'System.XMl.XmlTextWriter' -ArgumentList $StringWriter

            $xmlWriter.Formatting = 'indented'
            $xmlWriter.Indentation = 2

            $XmlDocument.WriteContentTo($XmlWriter)

            $XmlWriter.Flush()

            $StringWriter.Flush()

            Write-Verbose -Message $StringWriter.ToString() -Verbose
        }

        $mockXmlDocument = @"
<?xml version="1.0" encoding="us-ascii" standalone="no"?>
<!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
        <class name="3.0.0\prefix" sourcefilename="prefix.ps1">
            <method name="&lt;script&gt;" desc="()" line="2">
                <counter type="INSTRUCTION" missed="0" covered="3" />
                <counter type="LINE" missed="0" covered="3" />
                <counter type="METHOD" missed="0" covered="1" />
            </method>
            <counter type="INSTRUCTION" missed="0" covered="3" />
            <counter type="LINE" missed="0" covered="3" />
            <counter type="METHOD" missed="0" covered="1" />
            <counter type="CLASS" missed="0" covered="1" />
        </class>
        <sourcefile name="prefix.ps1">
            <line nr="2" mi="0" ci="1" mb="0" cb="0" />
            <line nr="3" mi="0" ci="1" mb="0" cb="0" />
            <line nr="5" mi="0" ci="1" mb="0" cb="0" />
            <counter type="INSTRUCTION" missed="0" covered="3" />
            <counter type="LINE" missed="0" covered="3" />
            <counter type="METHOD" missed="0" covered="1" />
            <counter type="CLASS" missed="0" covered="1" />
        </sourcefile>
        <counter type="INSTRUCTION" missed="0" covered="3" />
        <counter type="LINE" missed="0" covered="3" />
        <counter type="METHOD" missed="0" covered="1" />
        <counter type="CLASS" missed="0" covered="1" />
    </package>
    <counter type="INSTRUCTION" missed="0" covered="3" />
    <counter type="LINE" missed="0" covered="3" />
    <counter type="METHOD" missed="0" covered="1" />
    <counter type="CLASS" missed="0" covered="1" />
</report>
"@
    }

    Context 'When calculating statistics for a single package' {
        It 'Should have not changed line <Line> attributes that is used as the base for the calculation' -TestCases @(
            @{
                Line = 2
            }
            @{
                Line = 3
            }
            @{
                Line = 5
            }
        ) {
            param
            (
                $Line
            )

            $result = Update-JaCoCoStatistic -Document $mockXmlDocument

            $result | Should -BeOfType [System.Xml.XmlDocument]

            $xPath = '/report/package[@name="3.0.0"]/sourcefile[@name="prefix.ps1"]/line[@nr="{0}"]' -f $Line

            ($result | Get-XmlAttributeValue -XPath $xPath -LineAttributes).mi | Should -Be 0
            ($result | Get-XmlAttributeValue -XPath $xPath -LineAttributes).ci | Should -Be 1
            ($result | Get-XmlAttributeValue -XPath $xPath -LineAttributes).mb | Should -Be 0
            ($result | Get-XmlAttributeValue -XPath $xPath -LineAttributes).cb | Should -Be 0

            # Write-IndentedXml $result
        }

        Context 'When a package exist' {
            It 'Should return the correct statistics for the package counter INSTRUCTION' {
                $result = Update-JaCoCoStatistic -Document $mockXmlDocument

                $result | Should -BeOfType [System.Xml.XmlDocument]

                $xPath = '/report/package[@name="3.0.0"]/counter[@type="INSTRUCTION"]'

                ($result | Get-XmlAttributeValue -XPath $xPath).Missed | Should -Be 0
                ($result | Get-XmlAttributeValue -XPath $xPath).Covered | Should -Be 3
            }

            It 'Should return the correct statistics for the package counter LINE' {
                $result = Update-JaCoCoStatistic -Document $mockXmlDocument

                $result | Should -BeOfType [System.Xml.XmlDocument]

                $xPath = '/report/package[@name="3.0.0"]/counter[@type="LINE"]'

                ($result | Get-XmlAttributeValue -XPath $xPath).Missed | Should -Be 0
                ($result | Get-XmlAttributeValue -XPath $xPath).Covered | Should -Be 3
            }

            It 'Should return the correct statistics for the package counter METHOD' {
                $result = Update-JaCoCoStatistic -Document $mockXmlDocument

                $result | Should -BeOfType [System.Xml.XmlDocument]

                $xPath = '/report/package[@name="3.0.0"]/counter[@type="METHOD"]'

                ($result | Get-XmlAttributeValue -XPath $xPath).Missed | Should -Be 0
                ($result | Get-XmlAttributeValue -XPath $xPath).Covered | Should -Be 1
            }

            It 'Should return the correct statistics for the package counter CLASS' {
                $result = Update-JaCoCoStatistic -Document $mockXmlDocument

                $result | Should -BeOfType [System.Xml.XmlDocument]

                $xPath = '/report/package[@name="3.0.0"]/counter[@type="CLASS"]'

                ($result | Get-XmlAttributeValue -XPath $xPath).Missed | Should -Be 0
                ($result | Get-XmlAttributeValue -XPath $xPath).Covered | Should -Be 1
            }

            Context 'When sourcefile for class exist' {
                It 'Should return the correct statistics for the sourcefile counter INSTRUCTION' {
                    $result = Update-JaCoCoStatistic -Document $mockXmlDocument

                    $result | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="3.0.0"]/sourcefile[@name="prefix.ps1"]/counter[@type="INSTRUCTION"]'

                    ($result | Get-XmlAttributeValue -XPath $xPath).Missed | Should -Be 0
                    ($result | Get-XmlAttributeValue -XPath $xPath).Covered | Should -Be 3
                }

                It 'Should return the correct statistics for the sourcefile counter LINE' {
                    $result = Update-JaCoCoStatistic -Document $mockXmlDocument

                    $result | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="3.0.0"]/sourcefile[@name="prefix.ps1"]/counter[@type="LINE"]'

                    ($result | Get-XmlAttributeValue -XPath $xPath).Missed | Should -Be 0
                    ($result | Get-XmlAttributeValue -XPath $xPath).Covered | Should -Be 3
                }

                It 'Should return the correct statistics for the sourcefile counter METHOD' {
                    $result = Update-JaCoCoStatistic -Document $mockXmlDocument

                    $result | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="3.0.0"]/sourcefile[@name="prefix.ps1"]/counter[@type="METHOD"]'

                    ($result | Get-XmlAttributeValue -XPath $xPath).Missed | Should -Be 0
                    ($result | Get-XmlAttributeValue -XPath $xPath).Covered | Should -Be 1
                }

                It 'Should return the correct statistics for the sourcefile counter CLASS' {
                    $result = Update-JaCoCoStatistic -Document $mockXmlDocument

                    $result | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="3.0.0"]/sourcefile[@name="prefix.ps1"]/counter[@type="CLASS"]'

                    ($result | Get-XmlAttributeValue -XPath $xPath).Missed | Should -Be 0
                    ($result | Get-XmlAttributeValue -XPath $xPath).Covered | Should -Be 1
                }
            }

            Context 'When the package contain a class' {
                It 'Should return the correct statistics for the class counter INSTRUCTION' {
                    $result = Update-JaCoCoStatistic -Document $mockXmlDocument

                    $result | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="3.0.0"]/class/counter[@type="INSTRUCTION"]'

                    ($result | Get-XmlAttributeValue -XPath $xPath).Missed | Should -Be 0
                    ($result | Get-XmlAttributeValue -XPath $xPath).Covered | Should -Be 3
                }

                It 'Should return the correct statistics for the class counter LINE' {
                    $result = Update-JaCoCoStatistic -Document $mockXmlDocument

                    $result | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="3.0.0"]/class/counter[@type="LINE"]'

                    ($result | Get-XmlAttributeValue -XPath $xPath).Missed | Should -Be 0
                    ($result | Get-XmlAttributeValue -XPath $xPath).Covered | Should -Be 3
                }

                It 'Should return the correct statistics for the class counter METHOD' {
                    $result = Update-JaCoCoStatistic -Document $mockXmlDocument

                    $result | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="3.0.0"]/class/counter[@type="METHOD"]'

                    ($result | Get-XmlAttributeValue -XPath $xPath).Missed | Should -Be 0
                    ($result | Get-XmlAttributeValue -XPath $xPath).Covered | Should -Be 1
                }

                It 'Should return the correct statistics for the class counter CLASS' {
                    $result = Update-JaCoCoStatistic -Document $mockXmlDocument

                    $result | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="3.0.0"]/class/counter[@type="CLASS"]'

                    ($result | Get-XmlAttributeValue -XPath $xPath).Missed | Should -Be 0
                    ($result | Get-XmlAttributeValue -XPath $xPath).Covered | Should -Be 1
                }

                Context 'When the class contain a method' {
                    It 'Should return the correct statistics for the method counter INSTRUCTION' {
                        $result = Update-JaCoCoStatistic -Document $mockXmlDocument

                        $result | Should -BeOfType [System.Xml.XmlDocument]

                        $xPath = '/report/package[@name="3.0.0"]/class/method[@name="<script>"]/counter[@type="INSTRUCTION"]'

                        ($result | Get-XmlAttributeValue -XPath $xPath).Missed | Should -Be 0
                        ($result | Get-XmlAttributeValue -XPath $xPath).Covered | Should -Be 3
                    }

                    It 'Should return the correct statistics for the method counter LINE' {
                        $result = Update-JaCoCoStatistic -Document $mockXmlDocument

                        $result | Should -BeOfType [System.Xml.XmlDocument]

                        $xPath = '/report/package[@name="3.0.0"]/class/method[@name="<script>"]/counter[@type="LINE"]'

                        ($result | Get-XmlAttributeValue -XPath $xPath).Missed | Should -Be 0
                        ($result | Get-XmlAttributeValue -XPath $xPath).Covered | Should -Be 3
                    }

                    It 'Should return the correct statistics for the method counter METHOD' {
                        $result = Update-JaCoCoStatistic -Document $mockXmlDocument

                        $result | Should -BeOfType [System.Xml.XmlDocument]

                        $xPath = '/report/package[@name="3.0.0"]/class/method[@name="<script>"]/counter[@type="METHOD"]'

                        ($result | Get-XmlAttributeValue -XPath $xPath).Missed | Should -Be 0
                        ($result | Get-XmlAttributeValue -XPath $xPath).Covered | Should -Be 1
                    }
                }
            }
        }

        It 'Should return the correct statistics for the report counter INSTRUCTION' {
            $result = Update-JaCoCoStatistic -Document $mockXmlDocument

            $result | Should -BeOfType [System.Xml.XmlDocument]

            $xPath = '/report/counter[@type="INSTRUCTION"]'

            ($result | Get-XmlAttributeValue -XPath $xPath).Missed | Should -Be 0
            ($result | Get-XmlAttributeValue -XPath $xPath).Covered | Should -Be 3

            # Write-IndentedXml $result
        }

        It 'Should return the correct statistics for the report counter LINE' {
            $result = Update-JaCoCoStatistic -Document $mockXmlDocument

            $result | Should -BeOfType [System.Xml.XmlDocument]

            $xPath = '/report/counter[@type="LINE"]'

            ($result | Get-XmlAttributeValue -XPath $xPath).Missed | Should -Be 0
            ($result | Get-XmlAttributeValue -XPath $xPath).Covered | Should -Be 3
        }

        It 'Should return the correct statistics for the report counter METHOD' {
            $result = Update-JaCoCoStatistic -Document $mockXmlDocument

            $result | Should -BeOfType [System.Xml.XmlDocument]

            $xPath = '/report/counter[@type="METHOD"]'

            ($result | Get-XmlAttributeValue -XPath $xPath).Missed | Should -Be 0
            ($result | Get-XmlAttributeValue -XPath $xPath).Covered | Should -Be 1
        }

        It 'Should return the correct statistics for the report counter CLASS' {
            $result = Update-JaCoCoStatistic -Document $mockXmlDocument

            $result | Should -BeOfType [System.Xml.XmlDocument]

            $xPath = '/report/counter[@type="CLASS"]'

            ($result | Get-XmlAttributeValue -XPath $xPath).Missed | Should -Be 0
            ($result | Get-XmlAttributeValue -XPath $xPath).Covered | Should -Be 1
        }
    }
}
