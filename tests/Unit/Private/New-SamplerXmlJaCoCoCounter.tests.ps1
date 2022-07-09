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

Describe 'New-SamplerXmlJaCoCoCounter' {

    Context 'When calling without PassThru' {
        It 'Should append the correct element' {
            InModuleScope -ScriptBlock {
                $mockXmlDocument = New-Object -TypeName 'System.Xml.XmlDocument'
                $mockElement = $mockXmlDocument.CreateElement('report')

                { New-SamplerXmlJaCoCoCounter -XmlNode $mockElement -CounterType 'LINE' -Covered 2 -Missed 1 } | Should -Not -Throw

                $mockElement.OuterXml | Should -Be '<report><counter type="LINE" missed="1" covered="2" /></report>'
            }
        }
    }

    Context 'When calling with PassThru' {
        It 'Should append the correct element' {
            InModuleScope -ScriptBlock {
                $mockXmlDocument = New-Object -TypeName 'System.Xml.XmlDocument'
                $mockElement = $mockXmlDocument.CreateElement('report')

                $result = New-SamplerXmlJaCoCoCounter -XmlNode $mockElement -CounterType 'LINE' -Covered 2 -Missed 1 -PassThru

                $mockElement.OuterXml | Should -Be '<report><counter type="LINE" missed="1" covered="2" /></report>'

                $result.OuterXml | Should -Be '<counter type="LINE" missed="1" covered="2" />'
            }
        }
    }
}
