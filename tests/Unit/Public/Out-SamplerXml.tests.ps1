BeforeAll {
    $script:moduleName = 'Sampler'

    # If the module is not found, run the build task 'noop'.
    if (-not (Get-Module -Name $script:moduleName -ListAvailable))
    {
        # Redirect all streams to $null, except the error stream (stream 3)
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

Describe 'Out-SamplerXml' {
    BeforeAll {
        $mockXmlDocument = '<?xml version="1.0" encoding="utf-16" standalone="no"?><a><b /></a>'
    }

    It 'Should write a file with the correct content and correct encoding' {
        $mockPath = Join-Path -Path $TestDrive -ChildPath 'mockOutput.xml'

        $result = Sampler\Out-SamplerXml -XmlDocument $mockXmlDocument -Path $mockPath

        $contentsInFile = Get-Content -Path $mockPath -Raw

        $contentsInFile | Should -Be '<?xml version="1.0" encoding="utf-8" standalone="no"?><a><b /></a>'
    }
}
