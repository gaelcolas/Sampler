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

Describe 'Get-BuiltModuleVersion' {
    BeforeAll {
        Mock -CommandName Get-SamplerBuiltModuleManifest -MockWith {
            return (Join-Path -Path $TestDrive -ChildPath 'MyModule.psd1')
        }
    }

    Context 'When module version is full release' {
        BeforeAll {
            Mock -CommandName Import-PowerShellDataFile -MockWith {
                return @{
                    'ModuleVersion' = '2.1.1'
                }
            }
        }

        It 'Should return the correct semantic version' {
            $result = Sampler\Get-BuiltModuleVersion -OutputDirectory $TestDrive -ModuleName 'MyModule'

            $result | Should -Be '2.1.1'
        }
    }

    Context 'When module version is preview release' {
        BeforeAll {
            Mock -CommandName Import-PowerShellDataFile -MockWith {
                return @{
                    'ModuleVersion' = '2.1.1'
                    'PrivateData' = @{
                        PSData = @{
                            Prerelease = 'preview.1'
                        }
                    }
                }
            }
        }

        It 'Should return the correct semantic version' {
            $result = Sampler\Get-BuiltModuleVersion -OutputDirectory $TestDrive -ModuleName 'MyModule'

            $result | Should -Be '2.1.1-preview.1'
        }
    }
}
