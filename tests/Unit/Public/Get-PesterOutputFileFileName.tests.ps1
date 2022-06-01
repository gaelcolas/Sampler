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

Describe 'Get-PesterOutputFileFileName' {
    It 'should return the corret file name' {
        $getPesterOutputFileFileNameParameters = @{
            ProjectName = 'MyModule'
            ModuleVersion = '2.0.0'
            OsShortName = 'Windows'
            PowerShellVersion = '7.2'
        }

        $result = Get-PesterOutputFileFileName @getPesterOutputFileFileNameParameters

        $result | Should -Be 'MyModule_v2.0.0.Windows.7.2.xml'
    }

}
