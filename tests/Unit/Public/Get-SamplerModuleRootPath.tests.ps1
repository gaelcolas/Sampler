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

Describe 'Get-SamplerModuleRootPath' {
    Context 'When module manifest does not contain the property RootModule' {
        BeforeAll {
            Mock -CommandName Get-SamplerModuleInfo -MockWith {
                return @{}
            }
        }

        It 'Should return $null' {
            $result = Get-SamplerModuleRootPath -ModuleManifestPath $TestDrive

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When module manifest property RootModule' {
        BeforeAll {
            Mock -CommandName Get-SamplerModuleInfo -MockWith {
                return @{
                    RootModule = 'MyModule.psm1'
                }
            }
        }

        It 'Should return $null' {
            $result = Get-SamplerModuleRootPath -ModuleManifestPath (Join-Path -Path $TestDrive -ChildPath 'MyModule')

            $result | Should -Be (Join-Path -Path $TestDrive -ChildPath 'MyModule.psm1')
        }
    }
}
