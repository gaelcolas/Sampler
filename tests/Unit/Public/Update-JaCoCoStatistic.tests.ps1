BeforeAll {
    $script:moduleName = 'Sampler'

    # If the module is not found, run the build task 'noop'.
    if (-not (Get-Module -Name $script:moduleName -ListAvailable))
    {
        # Redirect all streams to $null, except the error stream (stream 2)
        & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
    }

    # Re-import the module using force to get any code changes between runs.
    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Module -Name $script:moduleName
}

Describe 'Update-JaCoCoStatistic' {
    BeforeAll {
        . $PSScriptRoot/../TestHelpers/Get-XmlAttribute.ps1

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
        It 'Should have not changed line <Line> attributes that is used as the base for the calculation' -ForEach @(
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
            $result = Sampler\Update-JaCoCoStatistic -Document $mockXmlDocument

            $result | Should -BeOfType [System.Xml.XmlDocument]

            $xPath = '/report/package[@name="3.0.0"]/sourcefile[@name="prefix.ps1"]/line[@nr="{0}"]' -f $Line

            ($result | Get-XmlAttribute -XPath $xPath).mi | Should -Be 0
            ($result | Get-XmlAttribute -XPath $xPath).ci | Should -Be 1
            ($result | Get-XmlAttribute -XPath $xPath).mb | Should -Be 0
            ($result | Get-XmlAttribute -XPath $xPath).cb | Should -Be 0
        }

        Context 'When a package exist' {
            It 'Should return the correct statistics for the package counter INSTRUCTION' {
                $result = Sampler\Update-JaCoCoStatistic -Document $mockXmlDocument

                $result | Should -BeOfType [System.Xml.XmlDocument]

                $xPath = '/report/package[@name="3.0.0"]/counter[@type="INSTRUCTION"]'

                ($result | Get-XmlAttribute -XPath $xPath).Missed | Should -Be 0
                ($result | Get-XmlAttribute -XPath $xPath).Covered | Should -Be 3
            }

            It 'Should return the correct statistics for the package counter LINE' {
                $result = Sampler\Update-JaCoCoStatistic -Document $mockXmlDocument

                $result | Should -BeOfType [System.Xml.XmlDocument]

                $xPath = '/report/package[@name="3.0.0"]/counter[@type="LINE"]'

                ($result | Get-XmlAttribute -XPath $xPath).Missed | Should -Be 0
                ($result | Get-XmlAttribute -XPath $xPath).Covered | Should -Be 3
            }

            It 'Should return the correct statistics for the package counter METHOD' {
                $result = Sampler\Update-JaCoCoStatistic -Document $mockXmlDocument

                $result | Should -BeOfType [System.Xml.XmlDocument]

                $xPath = '/report/package[@name="3.0.0"]/counter[@type="METHOD"]'

                ($result | Get-XmlAttribute -XPath $xPath).Missed | Should -Be 0
                ($result | Get-XmlAttribute -XPath $xPath).Covered | Should -Be 1
            }

            It 'Should return the correct statistics for the package counter CLASS' {
                $result = Sampler\Update-JaCoCoStatistic -Document $mockXmlDocument

                $result | Should -BeOfType [System.Xml.XmlDocument]

                $xPath = '/report/package[@name="3.0.0"]/counter[@type="CLASS"]'

                ($result | Get-XmlAttribute -XPath $xPath).Missed | Should -Be 0
                ($result | Get-XmlAttribute -XPath $xPath).Covered | Should -Be 1
            }

            Context 'When sourcefile for class exist' {
                It 'Should return the correct statistics for the sourcefile counter INSTRUCTION' {
                    $result = Sampler\Update-JaCoCoStatistic -Document $mockXmlDocument

                    $result | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="3.0.0"]/sourcefile[@name="prefix.ps1"]/counter[@type="INSTRUCTION"]'

                    ($result | Get-XmlAttribute -XPath $xPath).Missed | Should -Be 0
                    ($result | Get-XmlAttribute -XPath $xPath).Covered | Should -Be 3
                }

                It 'Should return the correct statistics for the sourcefile counter LINE' {
                    $result = Sampler\Update-JaCoCoStatistic -Document $mockXmlDocument

                    $result | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="3.0.0"]/sourcefile[@name="prefix.ps1"]/counter[@type="LINE"]'

                    ($result | Get-XmlAttribute -XPath $xPath).Missed | Should -Be 0
                    ($result | Get-XmlAttribute -XPath $xPath).Covered | Should -Be 3
                }

                It 'Should return the correct statistics for the sourcefile counter METHOD' {
                    $result = Sampler\Update-JaCoCoStatistic -Document $mockXmlDocument

                    $result | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="3.0.0"]/sourcefile[@name="prefix.ps1"]/counter[@type="METHOD"]'

                    ($result | Get-XmlAttribute -XPath $xPath).Missed | Should -Be 0
                    ($result | Get-XmlAttribute -XPath $xPath).Covered | Should -Be 1
                }

                It 'Should return the correct statistics for the sourcefile counter CLASS' {
                    $result = Sampler\Update-JaCoCoStatistic -Document $mockXmlDocument

                    $result | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="3.0.0"]/sourcefile[@name="prefix.ps1"]/counter[@type="CLASS"]'

                    ($result | Get-XmlAttribute -XPath $xPath).Missed | Should -Be 0
                    ($result | Get-XmlAttribute -XPath $xPath).Covered | Should -Be 1
                }
            }

            Context 'When the package contain a class' {
                It 'Should return the correct statistics for the class counter INSTRUCTION' {
                    $result = Sampler\Update-JaCoCoStatistic -Document $mockXmlDocument

                    $result | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="3.0.0"]/class/counter[@type="INSTRUCTION"]'

                    ($result | Get-XmlAttribute -XPath $xPath).Missed | Should -Be 0
                    ($result | Get-XmlAttribute -XPath $xPath).Covered | Should -Be 3
                }

                It 'Should return the correct statistics for the class counter LINE' {
                    $result = Sampler\Update-JaCoCoStatistic -Document $mockXmlDocument

                    $result | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="3.0.0"]/class/counter[@type="LINE"]'

                    ($result | Get-XmlAttribute -XPath $xPath).Missed | Should -Be 0
                    ($result | Get-XmlAttribute -XPath $xPath).Covered | Should -Be 3
                }

                It 'Should return the correct statistics for the class counter METHOD' {
                    $result = Sampler\Update-JaCoCoStatistic -Document $mockXmlDocument

                    $result | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="3.0.0"]/class/counter[@type="METHOD"]'

                    ($result | Get-XmlAttribute -XPath $xPath).Missed | Should -Be 0
                    ($result | Get-XmlAttribute -XPath $xPath).Covered | Should -Be 1
                }

                It 'Should return the correct statistics for the class counter CLASS' {
                    $result = Sampler\Update-JaCoCoStatistic -Document $mockXmlDocument

                    $result | Should -BeOfType [System.Xml.XmlDocument]

                    $xPath = '/report/package[@name="3.0.0"]/class/counter[@type="CLASS"]'

                    ($result | Get-XmlAttribute -XPath $xPath).Missed | Should -Be 0
                    ($result | Get-XmlAttribute -XPath $xPath).Covered | Should -Be 1
                }

                Context 'When the class contain a method' {
                    It 'Should return the correct statistics for the method counter INSTRUCTION' {
                        $result = Sampler\Update-JaCoCoStatistic -Document $mockXmlDocument

                        $result | Should -BeOfType [System.Xml.XmlDocument]

                        $xPath = '/report/package[@name="3.0.0"]/class/method[@name="<script>"]/counter[@type="INSTRUCTION"]'

                        ($result | Get-XmlAttribute -XPath $xPath).Missed | Should -Be 0
                        ($result | Get-XmlAttribute -XPath $xPath).Covered | Should -Be 3
                    }

                    It 'Should return the correct statistics for the method counter LINE' {
                        $result = Sampler\Update-JaCoCoStatistic -Document $mockXmlDocument

                        $result | Should -BeOfType [System.Xml.XmlDocument]

                        $xPath = '/report/package[@name="3.0.0"]/class/method[@name="<script>"]/counter[@type="LINE"]'

                        ($result | Get-XmlAttribute -XPath $xPath).Missed | Should -Be 0
                        ($result | Get-XmlAttribute -XPath $xPath).Covered | Should -Be 3
                    }

                    It 'Should return the correct statistics for the method counter METHOD' {
                        $result = Sampler\Update-JaCoCoStatistic -Document $mockXmlDocument

                        $result | Should -BeOfType [System.Xml.XmlDocument]

                        $xPath = '/report/package[@name="3.0.0"]/class/method[@name="<script>"]/counter[@type="METHOD"]'

                        ($result | Get-XmlAttribute -XPath $xPath).Missed | Should -Be 0
                        ($result | Get-XmlAttribute -XPath $xPath).Covered | Should -Be 1
                    }
                }
            }
        }

        It 'Should return the correct statistics for the report counter INSTRUCTION' {
            $result = Sampler\Update-JaCoCoStatistic -Document $mockXmlDocument

            $result | Should -BeOfType [System.Xml.XmlDocument]

            $xPath = '/report/counter[@type="INSTRUCTION"]'

            ($result | Get-XmlAttribute -XPath $xPath).Missed | Should -Be 0
            ($result | Get-XmlAttribute -XPath $xPath).Covered | Should -Be 3
        }

        It 'Should return the correct statistics for the report counter LINE' {
            $result = Sampler\Update-JaCoCoStatistic -Document $mockXmlDocument

            $result | Should -BeOfType [System.Xml.XmlDocument]

            $xPath = '/report/counter[@type="LINE"]'

            ($result | Get-XmlAttribute -XPath $xPath).Missed | Should -Be 0
            ($result | Get-XmlAttribute -XPath $xPath).Covered | Should -Be 3
        }

        It 'Should return the correct statistics for the report counter METHOD' {
            $result = Sampler\Update-JaCoCoStatistic -Document $mockXmlDocument

            $result | Should -BeOfType [System.Xml.XmlDocument]

            $xPath = '/report/counter[@type="METHOD"]'

            ($result | Get-XmlAttribute -XPath $xPath).Missed | Should -Be 0
            ($result | Get-XmlAttribute -XPath $xPath).Covered | Should -Be 1
        }

        It 'Should return the correct statistics for the report counter CLASS' {
            $result = Sampler\Update-JaCoCoStatistic -Document $mockXmlDocument

            $result | Should -BeOfType [System.Xml.XmlDocument]

            $xPath = '/report/counter[@type="CLASS"]'

            ($result | Get-XmlAttribute -XPath $xPath).Missed | Should -Be 0
            ($result | Get-XmlAttribute -XPath $xPath).Covered | Should -Be 1
        }
    }
}
