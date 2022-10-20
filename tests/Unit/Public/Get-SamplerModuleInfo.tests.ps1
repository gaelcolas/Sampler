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

Describe 'Get-SamplerModuleInfo' {
    Context 'When running Windows PowerShell' {
        BeforeAll {
            Mock -CommandName Get-Command
            Mock -CommandName Import-Module
            Mock -CommandName Import-PowerShellDataFile -RemoveParameterValidation 'Path'

            InModuleScope -ScriptBlock {
                $script:previousPSVersionTable = $PSVersionTable.Clone()
                $script:PSVersionTable = @{
                    PSVersion = @{
                        Major = '5'
                    }
                }
            }
        }

        AfterAll {
            InModuleScope -ScriptBlock {
                $script:PSVersionTable = $previousPSVersionTable.Clone()
            }
        }

        It 'Should call the expected mocks' {
            { Sampler\Get-SamplerModuleInfo -ModuleManifestPath $TestDrive } | Should -Not -Throw

            Should -Invoke -CommandName Get-Command -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Import-Module -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Import-PowerShellDataFile -Exactly -Times 1 -Scope It
        }
    }

    Context 'When running PowerShell' {
        BeforeAll {
            Mock -CommandName Get-Command
            Mock -CommandName Import-Module
            Mock -CommandName Import-PowerShellDataFile -RemoveParameterValidation 'Path'

            InModuleScope -ScriptBlock {
                $script:previousPSVersionTable = $PSVersionTable.Clone()
                $script:PSVersionTable = @{
                    PSVersion = @{
                        Major = '7'
                    }
                }
            }
        }

        AfterAll {
            InModuleScope -ScriptBlock {
                $script:PSVersionTable = $previousPSVersionTable.Clone()
            }
        }

        It 'Should call the expected mocks' {
            { Sampler\Get-SamplerModuleInfo -ModuleManifestPath $TestDrive } | Should -Not -Throw

            Should -Invoke -CommandName Get-Command -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Import-Module -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Import-PowerShellDataFile -Exactly -Times 1 -Scope It
        }
    }
}
