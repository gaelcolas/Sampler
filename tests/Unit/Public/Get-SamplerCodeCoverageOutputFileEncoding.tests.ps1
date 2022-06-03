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

Describe 'Get-SamplerCodeCoverageOutputFileEncoding' {
    It 'Should return $null' {
        $result = Get-SamplerCodeCoverageOutputFileEncoding -BuildInfo @{}

        $result | Should -BeNullOrEmpty
    }

    It 'Should return the correct file encoding' {
        $result = Get-SamplerCodeCoverageOutputFileEncoding -BuildInfo @{
            Pester = @{
                CodeCoverageOutputFileEncoding = 'UTF8'
            }
        }

        $result | Should -Be 'UTF8'
    }
}
