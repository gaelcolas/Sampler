[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pesters syntax')]
param ()

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

Describe 'Merge-JaCoCoReport' {
    <#
        This test will add the package <package name="NewPackage">.
    #>
    Context 'When a package is missing in original document' {
        BeforeAll {
            $mockXmlOriginal = @"
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

    $mockXmlToMerge = @"
<?xml version="1.0" encoding="us-ascii" standalone="no"?>
<!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="NewPackage">
        <class name="NewPackage\suffix" sourcefilename="suffix.ps1">
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

        It 'Should merge the coverage reports correctly' {
            # TODO: Remove Verbose
            $result = Sampler\Merge-JaCoCoReport -OriginalDocument $mockXmlOriginal -MergeDocument $mockXmlToMerge

            $result | Should -BeOfType [System.Xml.XmlDocument]

            $mockExpectedOuterXml = @'
<?xml version="1.0" encoding="us-ascii" standalone="no"?><!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
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
        <counter type="INSTRUCTION" missed="0" covered="3" />
        <counter type="LINE" missed="0" covered="3" />
        <counter type="METHOD" missed="0" covered="1" />
        <counter type="CLASS" missed="0" covered="1" />
    </package>
    <package name="NewPackage">
        <class name="NewPackage\suffix" sourcefilename="suffix.ps1">
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
'@
            $result.OuterXml | Should -Be (($mockExpectedOuterXml -replace '\r?\n')  -replace '>\s*<', '><')
        }
    }


    <#
        This tests so that the <class name="3.0.0\suffix" sourcefilename="suffix.ps1">
        is added to the same package (<package name="3.0.0">) in the original document.
    #>
    Context 'When a class is missing in original document' {
        BeforeAll {
            $mockXmlOriginal = @"
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

    $mockXmlToMerge = @"
<?xml version="1.0" encoding="us-ascii" standalone="no"?>
<!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
        <class name="3.0.0\suffix" sourcefilename="suffix.ps1">
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

        It 'Should merge the coverage reports correctly' {
            # TODO: Remove Verbose
            $result = Sampler\Merge-JaCoCoReport -OriginalDocument $mockXmlOriginal -MergeDocument $mockXmlToMerge

            $result | Should -BeOfType [System.Xml.XmlDocument]

            $mockExpectedOuterXml = @'
<?xml version="1.0" encoding="us-ascii" standalone="no"?><!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
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
        <counter type="INSTRUCTION" missed="0" covered="3" />
        <counter type="LINE" missed="0" covered="3" />
        <counter type="METHOD" missed="0" covered="1" />
        <counter type="CLASS" missed="0" covered="1" />
        <class name="3.0.0\suffix" sourcefilename="suffix.ps1">
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
    </package>
    <counter type="INSTRUCTION" missed="0" covered="3" />
    <counter type="LINE" missed="0" covered="3" />
    <counter type="METHOD" missed="0" covered="1" />
    <counter type="CLASS" missed="0" covered="1" />
</report>
'@
            $result.OuterXml | Should -Be (($mockExpectedOuterXml -replace '\r?\n')  -replace '>\s*<', '><')
        }
    }

    <#
        This tests so that the two <class name="3.0.0\suffix" sourcefilename="suffix.ps1">
        and <class name="3.0.0\ScriptFile" sourcefilename="ScriptFile.ps1">
        are added to the same package (<package name="3.0.0">) in the original document.
    #>
    Context 'When two classes are missing in original document' {
        BeforeAll {
            $mockXmlOriginal = @"
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

    $mockXmlToMerge = @"
<?xml version="1.0" encoding="us-ascii" standalone="no"?>
<!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
        <class name="3.0.0\suffix" sourcefilename="suffix.ps1">
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
        <class name="3.0.0\ScriptFile" sourcefilename="ScriptFile.ps1">
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

        It 'Should merge the coverage reports correctly' {
            # TODO: Remove Verbose
            $result = Sampler\Merge-JaCoCoReport -OriginalDocument $mockXmlOriginal -MergeDocument $mockXmlToMerge

            $result | Should -BeOfType [System.Xml.XmlDocument]

            $mockExpectedOuterXml = @'
<?xml version="1.0" encoding="us-ascii" standalone="no"?><!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
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
        <counter type="INSTRUCTION" missed="0" covered="3" />
        <counter type="LINE" missed="0" covered="3" />
        <counter type="METHOD" missed="0" covered="1" />
        <counter type="CLASS" missed="0" covered="1" />
        <class name="3.0.0\suffix" sourcefilename="suffix.ps1">
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
        <class name="3.0.0\ScriptFile" sourcefilename="ScriptFile.ps1">
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
    </package>
    <counter type="INSTRUCTION" missed="0" covered="3" />
    <counter type="LINE" missed="0" covered="3" />
    <counter type="METHOD" missed="0" covered="1" />
    <counter type="CLASS" missed="0" covered="1" />
</report>
'@
            $result.OuterXml | Should -Be (($mockExpectedOuterXml -replace '\r?\n')  -replace '>\s*<', '><')
        }
    }

    <#
        This tests so that the <class name="3.0.0\suffix" sourcefilename="suffix.ps1">
        is added to the same package (<package name="3.0.0">) in the original document.
    #>
    Context 'When a method is missing from a class in original document' {
        BeforeAll {
            $mockXmlOriginal = @"
<?xml version="1.0" encoding="us-ascii" standalone="no"?>
<!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
        <class name="3.0.0\ScriptFile" sourcefilename="ScriptFile.ps1">
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

    $mockXmlToMerge = @"
<?xml version="1.0" encoding="us-ascii" standalone="no"?>
<!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
        <class name="3.0.0\ScriptFile" sourcefilename="ScriptFile.ps1">
            <method name="&lt;script&gt;" desc="()" line="2">
                <counter type="INSTRUCTION" missed="0" covered="3" />
                <counter type="LINE" missed="0" covered="3" />
                <counter type="METHOD" missed="0" covered="1" />
            </method>
            <method name="GetSomething" desc="()" line="10">
                <counter type="INSTRUCTION" missed="0" covered="1" />
                <counter type="LINE" missed="0" covered="1" />
                <counter type="METHOD" missed="0" covered="1" />
            </method>
            <counter type="INSTRUCTION" missed="0" covered="3" />
            <counter type="LINE" missed="0" covered="3" />
            <counter type="METHOD" missed="0" covered="1" />
            <counter type="CLASS" missed="0" covered="1" />
        </class>
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

        It 'Should merge the coverage reports correctly' {
            # TODO: Remove Verbose
            $result = Sampler\Merge-JaCoCoReport -OriginalDocument $mockXmlOriginal -MergeDocument $mockXmlToMerge

            $result | Should -BeOfType [System.Xml.XmlDocument]

            $mockExpectedOuterXml = @'
<?xml version="1.0" encoding="us-ascii" standalone="no"?><!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
        <class name="3.0.0\ScriptFile" sourcefilename="ScriptFile.ps1">
            <method name="&lt;script&gt;" desc="()" line="2">
                <counter type="INSTRUCTION" missed="0" covered="3" />
                <counter type="LINE" missed="0" covered="3" />
                <counter type="METHOD" missed="0" covered="1" />
            </method>
            <counter type="INSTRUCTION" missed="0" covered="3" />
            <counter type="LINE" missed="0" covered="3" />
            <counter type="METHOD" missed="0" covered="1" />
            <counter type="CLASS" missed="0" covered="1" />
            <method name="GetSomething" desc="()" line="10">
                <counter type="INSTRUCTION" missed="0" covered="1" />
                <counter type="LINE" missed="0" covered="1" />
                <counter type="METHOD" missed="0" covered="1" />
            </method>
        </class>
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
'@
            $result.OuterXml | Should -Be (($mockExpectedOuterXml -replace '\r?\n')  -replace '>\s*<', '><')
        }
    }

    <#
        This tests so that the <sourcefile name="suffix.ps1"> is added to the
        same package (<package name="3.0.0">) in the original document.
    #>
    Context 'When a sourcefile is missing in original document' {
        BeforeAll {
            $mockXmlOriginal = @"
<?xml version="1.0" encoding="us-ascii" standalone="no"?>
<!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
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

    $mockXmlToMerge = @"
<?xml version="1.0" encoding="us-ascii" standalone="no"?>
<!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
        <sourcefile name="suffix.ps1">
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

        It 'Should merge the coverage reports correctly' {
            $result = Sampler\Merge-JaCoCoReport -OriginalDocument $mockXmlOriginal -MergeDocument $mockXmlToMerge

            $result | Should -BeOfType [System.Xml.XmlDocument]

            $mockExpectedOuterXml = @'
<?xml version="1.0" encoding="us-ascii" standalone="no"?><!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
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
        <sourcefile name="suffix.ps1">
            <line nr="2" mi="0" ci="1" mb="0" cb="0" />
            <line nr="3" mi="0" ci="1" mb="0" cb="0" />
            <line nr="5" mi="0" ci="1" mb="0" cb="0" />
            <counter type="INSTRUCTION" missed="0" covered="3" />
            <counter type="LINE" missed="0" covered="3" />
            <counter type="METHOD" missed="0" covered="1" />
            <counter type="CLASS" missed="0" covered="1" />
        </sourcefile>
    </package>
    <counter type="INSTRUCTION" missed="0" covered="3" />
    <counter type="LINE" missed="0" covered="3" />
    <counter type="METHOD" missed="0" covered="1" />
    <counter type="CLASS" missed="0" covered="1" />
</report>
'@
            $result.OuterXml | Should -Be (($mockExpectedOuterXml -replace '\r?\n')  -replace '>\s*<', '><')
        }
    }

    <#
        This tests so that the <sourcefile name="suffix.ps1"> and
        <sourcefile name="ScriptFile.ps1"> are added to the same
        package (<package name="3.0.0">) in the original document.
    #>
    Context 'When two sourcefile are missing in original document' {
        BeforeAll {
            $mockXmlOriginal = @"
<?xml version="1.0" encoding="us-ascii" standalone="no"?>
<!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
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

    $mockXmlToMerge = @"
<?xml version="1.0" encoding="us-ascii" standalone="no"?>
<!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
        <sourcefile name="suffix.ps1">
            <line nr="2" mi="0" ci="1" mb="0" cb="0" />
            <line nr="3" mi="0" ci="1" mb="0" cb="0" />
            <line nr="5" mi="0" ci="1" mb="0" cb="0" />
            <counter type="INSTRUCTION" missed="0" covered="3" />
            <counter type="LINE" missed="0" covered="3" />
            <counter type="METHOD" missed="0" covered="1" />
            <counter type="CLASS" missed="0" covered="1" />
        </sourcefile>
        <sourcefile name="ScriptFile.ps1">
            <line nr="5" mi="0" ci="1" mb="0" cb="0" />
            <line nr="6" mi="0" ci="1" mb="0" cb="0" />
            <line nr="9" mi="0" ci="1" mb="0" cb="0" />
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

        It 'Should merge the coverage reports correctly' {
            $result = Sampler\Merge-JaCoCoReport -OriginalDocument $mockXmlOriginal -MergeDocument $mockXmlToMerge

            $result | Should -BeOfType [System.Xml.XmlDocument]

            $mockExpectedOuterXml = @'
<?xml version="1.0" encoding="us-ascii" standalone="no"?><!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
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
        <sourcefile name="suffix.ps1">
            <line nr="2" mi="0" ci="1" mb="0" cb="0" />
            <line nr="3" mi="0" ci="1" mb="0" cb="0" />
            <line nr="5" mi="0" ci="1" mb="0" cb="0" />
            <counter type="INSTRUCTION" missed="0" covered="3" />
            <counter type="LINE" missed="0" covered="3" />
            <counter type="METHOD" missed="0" covered="1" />
            <counter type="CLASS" missed="0" covered="1" />
        </sourcefile>
        <sourcefile name="ScriptFile.ps1">
            <line nr="5" mi="0" ci="1" mb="0" cb="0" />
            <line nr="6" mi="0" ci="1" mb="0" cb="0" />
            <line nr="9" mi="0" ci="1" mb="0" cb="0" />
            <counter type="INSTRUCTION" missed="0" covered="3" />
            <counter type="LINE" missed="0" covered="3" />
            <counter type="METHOD" missed="0" covered="1" />
            <counter type="CLASS" missed="0" covered="1" />
        </sourcefile>
    </package>
    <counter type="INSTRUCTION" missed="0" covered="3" />
    <counter type="LINE" missed="0" covered="3" />
    <counter type="METHOD" missed="0" covered="1" />
    <counter type="CLASS" missed="0" covered="1" />
</report>
'@
            $result.OuterXml | Should -Be (($mockExpectedOuterXml -replace '\r?\n')  -replace '>\s*<', '><')
        }
    }

    Context 'When lines in a sourcefile is missing in original document' {
        BeforeAll {
            $mockXmlOriginal = @"
<?xml version="1.0" encoding="us-ascii" standalone="no"?>
<!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
        <sourcefile name="prefix.ps1">
            <line nr="1" mi="0" ci="1" mb="0" cb="0" />
            <line nr="2" mi="0" ci="1" mb="0" cb="0" />
            <line nr="3" mi="0" ci="1" mb="0" cb="0" />
            <line nr="10" mi="0" ci="1" mb="0" cb="0" />
            <counter type="INSTRUCTION" missed="0" covered="3" />
            <counter type="LINE" missed="0" covered="3" />
            <counter type="METHOD" missed="0" covered="1" />
            <counter type="CLASS" missed="0" covered="1" />
        </sourcefile>
        <sourcefile name="suffix.ps1">
            <line nr="2" mi="0" ci="1" mb="0" cb="0" />
            <line nr="3" mi="0" ci="1" mb="0" cb="0" />
            <line nr="5" mi="0" ci="1" mb="0" cb="0" />
            <counter type="INSTRUCTION" missed="0" covered="3" />
            <counter type="LINE" missed="0" covered="3" />
            <counter type="METHOD" missed="0" covered="1" />
            <counter type="CLASS" missed="0" covered="1" />
        </sourcefile>
        <sourcefile name="ScriptFile.ps1">
            <line nr="6" mi="0" ci="1" mb="0" cb="0" />
            <line nr="7" mi="0" ci="1" mb="0" cb="0" />
            <line nr="10" mi="0" ci="1" mb="0" cb="0" />
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

    $mockXmlToMerge = @"
<?xml version="1.0" encoding="us-ascii" standalone="no"?>
<!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
        <sourcefile name="suffix.ps1">
            <line nr="10" mi="0" ci="1" mb="0" cb="0" />
            <line nr="11" mi="1" ci="0" mb="0" cb="0" />
            <counter type="INSTRUCTION" missed="1" covered="1" />
            <counter type="LINE" missed="1" covered="1" />
            <counter type="METHOD" missed="0" covered="1" />
            <counter type="CLASS" missed="0" covered="1" />
        </sourcefile>
        <counter type="INSTRUCTION" missed="1" covered="1" />
        <counter type="LINE" missed="1" covered="1" />
        <counter type="METHOD" missed="0" covered="1" />
        <counter type="CLASS" missed="0" covered="1" />
    </package>
    <counter type="INSTRUCTION" missed="1" covered="1" />
    <counter type="LINE" missed="1" covered="1" />
    <counter type="METHOD" missed="0" covered="1" />
    <counter type="CLASS" missed="0" covered="1" />
</report>
"@
        }

        It 'Should merge the coverage reports correctly' {
            $result = Sampler\Merge-JaCoCoReport -OriginalDocument $mockXmlOriginal -MergeDocument $mockXmlToMerge

            $result | Should -BeOfType [System.Xml.XmlDocument]

            $mockExpectedOuterXml = @'
<?xml version="1.0" encoding="us-ascii" standalone="no"?><!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
        <sourcefile name="prefix.ps1">
            <line nr="1" mi="0" ci="1" mb="0" cb="0" />
            <line nr="2" mi="0" ci="1" mb="0" cb="0" />
            <line nr="3" mi="0" ci="1" mb="0" cb="0" />
            <line nr="10" mi="0" ci="1" mb="0" cb="0" />
            <counter type="INSTRUCTION" missed="0" covered="3" />
            <counter type="LINE" missed="0" covered="3" />
            <counter type="METHOD" missed="0" covered="1" />
            <counter type="CLASS" missed="0" covered="1" />
        </sourcefile>
        <sourcefile name="suffix.ps1">
            <line nr="2" mi="0" ci="1" mb="0" cb="0" />
            <line nr="3" mi="0" ci="1" mb="0" cb="0" />
            <line nr="5" mi="0" ci="1" mb="0" cb="0" />
            <counter type="INSTRUCTION" missed="0" covered="3" />
            <counter type="LINE" missed="0" covered="3" />
            <counter type="METHOD" missed="0" covered="1" />
            <counter type="CLASS" missed="0" covered="1" />
            <line nr="10" mi="0" ci="1" mb="0" cb="0" />
            <line nr="11" mi="1" ci="0" mb="0" cb="0" />
        </sourcefile>
        <sourcefile name="ScriptFile.ps1">
            <line nr="6" mi="0" ci="1" mb="0" cb="0" />
            <line nr="7" mi="0" ci="1" mb="0" cb="0" />
            <line nr="10" mi="0" ci="1" mb="0" cb="0" />
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
'@
            $result.OuterXml | Should -Be (($mockExpectedOuterXml -replace '\r?\n')  -replace '>\s*<', '><')
        }
    }

    Context 'When lines in a sourcefile is different that in the original document' {
        Context 'When lines was missed in original document but hit in the merge document' {
            BeforeAll {
                $mockXmlOriginal = @"
<?xml version="1.0" encoding="us-ascii" standalone="no"?>
<!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
        <sourcefile name="prefix.ps1">
            <line nr="2" mi="1" ci="0" mb="0" cb="0" />
            <line nr="3" mi="1" ci="0" mb="0" cb="0" />
        </sourcefile>
    </package>
</report>
"@

        $mockXmlToMerge = @"
<?xml version="1.0" encoding="us-ascii" standalone="no"?>
<!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
        <sourcefile name="prefix.ps1">
            <line nr="2" mi="0" ci="1" mb="0" cb="0" />
            <line nr="3" mi="0" ci="1" mb="0" cb="0" />
        </sourcefile>
    </package>
</report>
"@
            }

            It 'Should merge the coverage reports correctly' {
                $result = Sampler\Merge-JaCoCoReport -OriginalDocument $mockXmlOriginal -MergeDocument $mockXmlToMerge

                $result | Should -BeOfType [System.Xml.XmlDocument]

                $mockExpectedOuterXml = @'
<?xml version="1.0" encoding="us-ascii" standalone="no"?><!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
        <sourcefile name="prefix.ps1">
            <line nr="2" mi="0" ci="1" mb="0" cb="0" />
            <line nr="3" mi="0" ci="1" mb="0" cb="0" />
        </sourcefile>
    </package>
</report>
'@
                $result.OuterXml | Should -Be (($mockExpectedOuterXml -replace '\r?\n')  -replace '>\s*<', '><')
            }
        }

        Context 'When lines was hit in original document but missed in the merge document' {
            BeforeAll {
                $mockXmlOriginal = @"
<?xml version="1.0" encoding="us-ascii" standalone="no"?>
<!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
        <sourcefile name="prefix.ps1">
            <line nr="2" mi="0" ci="1" mb="0" cb="0" />
            <line nr="3" mi="0" ci="1" mb="0" cb="0" />
        </sourcefile>
    </package>
</report>
"@

        $mockXmlToMerge = @"
<?xml version="1.0" encoding="us-ascii" standalone="no"?>
<!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
        <sourcefile name="prefix.ps1">
            <line nr="2" mi="1" ci="0" mb="0" cb="0" />
            <line nr="3" mi="1" ci="0" mb="0" cb="0" />
        </sourcefile>
    </package>
</report>
"@
            }

            It 'Should merge the coverage reports correctly' {
                $result = Sampler\Merge-JaCoCoReport -OriginalDocument $mockXmlOriginal -MergeDocument $mockXmlToMerge

                $result | Should -BeOfType [System.Xml.XmlDocument]

                $mockExpectedOuterXml = @'
<?xml version="1.0" encoding="us-ascii" standalone="no"?><!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
        <sourcefile name="prefix.ps1">
            <line nr="2" mi="0" ci="1" mb="0" cb="0" />
            <line nr="3" mi="0" ci="1" mb="0" cb="0" />
        </sourcefile>
    </package>
</report>
'@
                $result.OuterXml | Should -Be (($mockExpectedOuterXml -replace '\r?\n')  -replace '>\s*<', '><')
            }
        }

        Context 'When lines was hit in original document and hit in the merge document' {
            BeforeAll {
                $mockXmlOriginal = @"
<?xml version="1.0" encoding="us-ascii" standalone="no"?>
<!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
        <sourcefile name="prefix.ps1">
            <line nr="2" mi="0" ci="1" mb="0" cb="0" />
            <line nr="3" mi="0" ci="1" mb="0" cb="0" />
        </sourcefile>
    </package>
</report>
"@

        $mockXmlToMerge = @"
<?xml version="1.0" encoding="us-ascii" standalone="no"?>
<!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
        <sourcefile name="prefix.ps1">
            <line nr="2" mi="0" ci="1" mb="0" cb="0" />
            <line nr="3" mi="0" ci="1" mb="0" cb="0" />
        </sourcefile>
    </package>
</report>
"@
            }

            It 'Should merge the coverage reports correctly' {
                $result = Sampler\Merge-JaCoCoReport -OriginalDocument $mockXmlOriginal -MergeDocument $mockXmlToMerge

                $result | Should -BeOfType [System.Xml.XmlDocument]

                $mockExpectedOuterXml = @'
<?xml version="1.0" encoding="us-ascii" standalone="no"?><!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
        <sourcefile name="prefix.ps1">
            <line nr="2" mi="0" ci="1" mb="0" cb="0" />
            <line nr="3" mi="0" ci="1" mb="0" cb="0" />
        </sourcefile>
    </package>
</report>
'@
                $result.OuterXml | Should -Be (($mockExpectedOuterXml -replace '\r?\n')  -replace '>\s*<', '><')
            }
        }

        Context 'When lines was missed in original document and missed in the merge document' {
            BeforeAll {
                $mockXmlOriginal = @"
<?xml version="1.0" encoding="us-ascii" standalone="no"?>
<!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
        <sourcefile name="prefix.ps1">
            <line nr="2" mi="1" ci="0" mb="0" cb="0" />
            <line nr="3" mi="1" ci="0" mb="0" cb="0" />
        </sourcefile>
    </package>
</report>
"@

        $mockXmlToMerge = @"
<?xml version="1.0" encoding="us-ascii" standalone="no"?>
<!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
        <sourcefile name="prefix.ps1">
            <line nr="2" mi="1" ci="0" mb="0" cb="0" />
            <line nr="3" mi="1" ci="0" mb="0" cb="0" />
        </sourcefile>
    </package>
</report>
"@
            }

            It 'Should merge the coverage reports correctly' {
                $result = Sampler\Merge-JaCoCoReport -OriginalDocument $mockXmlOriginal -MergeDocument $mockXmlToMerge

                $result | Should -BeOfType [System.Xml.XmlDocument]

                $mockExpectedOuterXml = @'
<?xml version="1.0" encoding="us-ascii" standalone="no"?><!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
        <sourcefile name="prefix.ps1">
            <line nr="2" mi="1" ci="0" mb="0" cb="0" />
            <line nr="3" mi="1" ci="0" mb="0" cb="0" />
        </sourcefile>
    </package>
</report>
'@
                $result.OuterXml | Should -Be (($mockExpectedOuterXml -replace '\r?\n')  -replace '>\s*<', '><')
            }
        }

        Context 'When lines were hit in original document but missed in the merge document, and lines were missed in original document but hit in the merge document' {
            BeforeAll {
                $mockXmlOriginal = @"
<?xml version="1.0" encoding="us-ascii" standalone="no"?>
<!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
<sessioninfo id="this" start="1617266666307" dump="1617266823528" />
<package name="3.0.0">
    <sourcefile name="prefix.ps1">
        <line nr="1" mi="0" ci="1" mb="0" cb="0" />
        <line nr="2" mi="1" ci="0" mb="0" cb="0" />
        <line nr="3" mi="1" ci="0" mb="0" cb="0" />
        <line nr="10" mi="0" ci="1" mb="0" cb="0" />
    </sourcefile>
</package>
</report>
"@

        $mockXmlToMerge = @"
<?xml version="1.0" encoding="us-ascii" standalone="no"?>
<!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
<sessioninfo id="this" start="1617266666307" dump="1617266823528" />
<package name="3.0.0">
    <sourcefile name="prefix.ps1">
        <line nr="1" mi="1" ci="0" mb="0" cb="0" />
        <line nr="2" mi="0" ci="1" mb="0" cb="0" />
        <line nr="3" mi="0" ci="1" mb="0" cb="0" />
        <line nr="10" mi="1" ci="0" mb="0" cb="0" />
    </sourcefile>
</package>
</report>
"@
            }

            It 'Should merge the coverage reports correctly' {
                $result = Sampler\Merge-JaCoCoReport -OriginalDocument $mockXmlOriginal -MergeDocument $mockXmlToMerge

                $result | Should -BeOfType [System.Xml.XmlDocument]

                $mockExpectedOuterXml = @'
<?xml version="1.0" encoding="us-ascii" standalone="no"?><!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
<sessioninfo id="this" start="1617266666307" dump="1617266823528" />
<package name="3.0.0">
    <sourcefile name="prefix.ps1">
        <line nr="1" mi="0" ci="1" mb="0" cb="0" />
        <line nr="2" mi="0" ci="1" mb="0" cb="0" />
        <line nr="3" mi="0" ci="1" mb="0" cb="0" />
        <line nr="10" mi="0" ci="1" mb="0" cb="0" />
    </sourcefile>
</package>
</report>
'@
                $result.OuterXml | Should -Be (($mockExpectedOuterXml -replace '\r?\n')  -replace '>\s*<', '><')
            }
        }

        Context 'When a lines was hit less times in original document than in the merge document' {
            BeforeAll {
                $mockXmlOriginal = @"
<?xml version="1.0" encoding="us-ascii" standalone="no"?>
<!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
        <sourcefile name="prefix.ps1">
            <line nr="2" mi="0" ci="1" mb="0" cb="0" />
            <line nr="3" mi="0" ci="1" mb="0" cb="0" />
        </sourcefile>
    </package>
</report>
"@

        $mockXmlToMerge = @"
<?xml version="1.0" encoding="us-ascii" standalone="no"?>
<!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
        <sourcefile name="prefix.ps1">
            <line nr="2" mi="0" ci="2" mb="0" cb="0" />
            <line nr="3" mi="0" ci="2" mb="0" cb="0" />
        </sourcefile>
    </package>
</report>
"@
            }

            It 'Should merge the coverage reports correctly' {
                $result = Sampler\Merge-JaCoCoReport -OriginalDocument $mockXmlOriginal -MergeDocument $mockXmlToMerge

                $result | Should -BeOfType [System.Xml.XmlDocument]

                $mockExpectedOuterXml = @'
<?xml version="1.0" encoding="us-ascii" standalone="no"?><!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
<report name="Pester (04/01/2021 08:47:03)">
    <sessioninfo id="this" start="1617266666307" dump="1617266823528" />
    <package name="3.0.0">
        <sourcefile name="prefix.ps1">
            <line nr="2" mi="0" ci="2" mb="0" cb="0" />
            <line nr="3" mi="0" ci="2" mb="0" cb="0" />
        </sourcefile>
    </package>
</report>
'@
                $result.OuterXml | Should -Be (($mockExpectedOuterXml -replace '\r?\n')  -replace '>\s*<', '><')
            }
        }
    }

    <#
        This test is a concatenation of the tests above, to verify that all changes
        works together.
    #>
    Context 'When a class, and a method for en existing class, sourcefile, and lines for an existing sourcefile is missing in the original document' {
        BeforeAll {
            $mockXmlOriginal = @"
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
        <class name="3.0.0\ScriptFile" sourcefilename="ScriptFile.ps1">
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

    $mockXmlToMerge = @"
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
            <line nr="10" mi="0" ci="1" mb="0" cb="0" />
            <line nr="11" mi="1" ci="0" mb="0" cb="0" />
            <counter type="INSTRUCTION" missed="1" covered="1" />
            <counter type="LINE" missed="1" covered="1" />
            <counter type="METHOD" missed="0" covered="1" />
            <counter type="CLASS" missed="0" covered="1" />
        </sourcefile>
        <class name="3.0.0\suffix" sourcefilename="suffix.ps1">
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
        <sourcefile name="suffix.ps1">
            <line nr="2" mi="0" ci="1" mb="0" cb="0" />
            <line nr="3" mi="0" ci="1" mb="0" cb="0" />
            <line nr="5" mi="0" ci="1" mb="0" cb="0" />
            <counter type="INSTRUCTION" missed="0" covered="3" />
            <counter type="LINE" missed="0" covered="3" />
            <counter type="METHOD" missed="0" covered="1" />
            <counter type="CLASS" missed="0" covered="1" />
        </sourcefile>
        <class name="3.0.0\ScriptFile" sourcefilename="ScriptFile.ps1">
            <method name="&lt;script&gt;" desc="()" line="2">
                <counter type="INSTRUCTION" missed="0" covered="3" />
                <counter type="LINE" missed="0" covered="3" />
                <counter type="METHOD" missed="0" covered="1" />
            </method>
            <method name="GetSomething" desc="()" line="10">
                <counter type="INSTRUCTION" missed="0" covered="1" />
                <counter type="LINE" missed="0" covered="1" />
                <counter type="METHOD" missed="0" covered="1" />
            </method>
            <counter type="INSTRUCTION" missed="0" covered="3" />
            <counter type="LINE" missed="0" covered="3" />
            <counter type="METHOD" missed="0" covered="1" />
            <counter type="CLASS" missed="0" covered="1" />
        </class>
        <sourcefile name="ScriptFile.ps1">
            <line nr="3" mi="0" ci="1" mb="0" cb="0" />
            <line nr="4" mi="0" ci="1" mb="0" cb="0" />
            <line nr="6" mi="0" ci="1" mb="0" cb="0" />
            <line nr="10" mi="0" ci="1" mb="0" cb="0" />
            <line nr="11" mi="0" ci="1" mb="0" cb="0" />
            <line nr="12" mi="0" ci="1" mb="0" cb="0" />
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

        It 'Should merge the coverage reports correctly' {
            $result = Sampler\Merge-JaCoCoReport -OriginalDocument $mockXmlOriginal -MergeDocument $mockXmlToMerge

            $result | Should -BeOfType [System.Xml.XmlDocument]

            $mockExpectedOuterXml = @'
<?xml version="1.0" encoding="us-ascii" standalone="no"?><!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"[]>
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
            <line nr="10" mi="0" ci="1" mb="0" cb="0" />
            <line nr="11" mi="1" ci="0" mb="0" cb="0" />
        </sourcefile>
        <class name="3.0.0\ScriptFile" sourcefilename="ScriptFile.ps1">
            <method name="&lt;script&gt;" desc="()" line="2">
                <counter type="INSTRUCTION" missed="0" covered="3" />
                <counter type="LINE" missed="0" covered="3" />
                <counter type="METHOD" missed="0" covered="1" />
            </method>
            <counter type="INSTRUCTION" missed="0" covered="3" />
            <counter type="LINE" missed="0" covered="3" />
            <counter type="METHOD" missed="0" covered="1" />
            <counter type="CLASS" missed="0" covered="1" />
            <method name="GetSomething" desc="()" line="10">
                <counter type="INSTRUCTION" missed="0" covered="1" />
                <counter type="LINE" missed="0" covered="1" />
                <counter type="METHOD" missed="0" covered="1" />
            </method>
        </class>
        <counter type="INSTRUCTION" missed="0" covered="3" />
        <counter type="LINE" missed="0" covered="3" />
        <counter type="METHOD" missed="0" covered="1" />
        <counter type="CLASS" missed="0" covered="1" />
        <class name="3.0.0\suffix" sourcefilename="suffix.ps1">
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
        <sourcefile name="suffix.ps1">
            <line nr="2" mi="0" ci="1" mb="0" cb="0" />
            <line nr="3" mi="0" ci="1" mb="0" cb="0" />
            <line nr="5" mi="0" ci="1" mb="0" cb="0" />
            <counter type="INSTRUCTION" missed="0" covered="3" />
            <counter type="LINE" missed="0" covered="3" />
            <counter type="METHOD" missed="0" covered="1" />
            <counter type="CLASS" missed="0" covered="1" />
        </sourcefile>
        <sourcefile name="ScriptFile.ps1">
            <line nr="3" mi="0" ci="1" mb="0" cb="0" />
            <line nr="4" mi="0" ci="1" mb="0" cb="0" />
            <line nr="6" mi="0" ci="1" mb="0" cb="0" />
            <line nr="10" mi="0" ci="1" mb="0" cb="0" />
            <line nr="11" mi="0" ci="1" mb="0" cb="0" />
            <line nr="12" mi="0" ci="1" mb="0" cb="0" />
            <counter type="INSTRUCTION" missed="0" covered="3" />
            <counter type="LINE" missed="0" covered="3" />
            <counter type="METHOD" missed="0" covered="1" />
            <counter type="CLASS" missed="0" covered="1" />
        </sourcefile>
    </package>
    <counter type="INSTRUCTION" missed="0" covered="3" />
    <counter type="LINE" missed="0" covered="3" />
    <counter type="METHOD" missed="0" covered="1" />
    <counter type="CLASS" missed="0" covered="1" />
</report>
'@
            $result.OuterXml | Should -Be (($mockExpectedOuterXml -replace '\r?\n')  -replace '>\s*<', '><')
        }
    }
}
