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

Describe 'Split-ModuleVersion' {
    It 'Should split a preview release module version' {
        $result = Split-ModuleVersion -ModuleVersion '1.15.0-pr0224'

        $result.Version | Should -Be '1.15.0'
        $result.PreReleaseString | Should -Be 'pr0224'
        $result.ModuleVersion | Should -Be '1.15.0-pr0224'
    }

    It 'Should split preview release module version with build information suffix' {
        $result = Split-ModuleVersion -ModuleVersion '1.15.0-pr0224-0022+Sha.47ae45eb2cfed02b249f239a7c55e5c71b26ab76.Date.2020-01-07'

        $result.Version | Should -Be '1.15.0'
        $result.PreReleaseString | Should -Be 'pr0224'
        $result.ModuleVersion | Should -Be '1.15.0-pr0224'
    }

    It 'Should split a full release module version' {
        $result = Split-ModuleVersion -ModuleVersion '1.15.0'

        $result.Version | Should -Be '1.15.0'
        $result.PreReleaseString | Should -BeNullOrEmpty
        $result.ModuleVersion | Should -Be '1.15.0'
    }

}
