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

Describe 'New-SamplerWorkspaceModuleLink' {
    Context 'When the link path does not exist and symbolic link creation succeeds' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                return $false
            }

            Mock -CommandName New-Item -MockWith {
                return [PSCustomObject] @{ FullName = 'C:\output\module\MyModule' }
            } -ParameterFilter {
                $ItemType -eq 'SymbolicLink'
            }
        }

        It 'Should return SymbolicLink' {
            InModuleScope -ScriptBlock {
                $result = Sampler\New-SamplerWorkspaceModuleLink `
                    -LinkPath 'C:\output\module\MyModule' `
                    -TargetPath 'C:\src\MyModule\output\module\MyModule' `
                    -Confirm:$false

                $result | Should -Be 'SymbolicLink'
            }
        }

        It 'Should invoke New-Item with ItemType SymbolicLink' {
            InModuleScope -ScriptBlock {
                $null = Sampler\New-SamplerWorkspaceModuleLink `
                    -LinkPath 'C:\output\module\MyModule' `
                    -TargetPath 'C:\src\MyModule\output\module\MyModule' `
                    -Confirm:$false

                Should -Invoke -CommandName New-Item -Exactly -Times 1 -Scope It -ParameterFilter {
                    $ItemType -eq 'SymbolicLink'
                }
            }
        }
    }

    Context 'When the link path already exists' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                return $true
            }

            Mock -CommandName Remove-Item

            Mock -CommandName New-Item -MockWith {
                return [PSCustomObject] @{ FullName = 'C:\output\module\MyModule' }
            } -ParameterFilter {
                $ItemType -eq 'SymbolicLink'
            }
        }

        It 'Should invoke Remove-Item to remove the existing link path' {
            InModuleScope -ScriptBlock {
                $null = Sampler\New-SamplerWorkspaceModuleLink `
                    -LinkPath 'C:\output\module\MyModule' `
                    -TargetPath 'C:\src\MyModule\output\module\MyModule' `
                    -Confirm:$false

                Should -Invoke -CommandName Remove-Item -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Path -eq 'C:\output\module\MyModule'
                }
            }
        }
    }

    Context 'When symbolic link creation fails on Windows and junction succeeds' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                return $false
            }

            Mock -CommandName New-Item -MockWith {
                throw 'Symbolic link creation failed'
            } -ParameterFilter {
                $ItemType -eq 'SymbolicLink'
            }

            Mock -CommandName New-Item -MockWith {
                return [PSCustomObject] @{ FullName = 'C:\output\module\MyModule' }
            } -ParameterFilter {
                $ItemType -eq 'Junction'
            }
        }

        It 'Should return Junction when falling back on Windows' {
            InModuleScope -ScriptBlock {
                $result = Sampler\New-SamplerWorkspaceModuleLink `
                    -LinkPath 'C:\output\module\MyModule' `
                    -TargetPath 'C:\src\MyModule\output\module\MyModule' `
                    -IsWindowsPlatform $true `
                    -Confirm:$false

                $result | Should -Be 'Junction'
            }
        }
    }

    Context 'When symbolic link creation fails on a non-Windows platform' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                return $false
            }

            Mock -CommandName New-Item -MockWith {
                throw 'Symbolic link creation failed'
            } -ParameterFilter {
                $ItemType -eq 'SymbolicLink'
            }
        }

        It 'Should throw when the platform is not Windows' {
            InModuleScope -ScriptBlock {
                { Sampler\New-SamplerWorkspaceModuleLink `
                        -LinkPath '/output/module/MyModule' `
                        -TargetPath '/src/MyModule/output/module/MyModule' `
                        -IsWindowsPlatform $false `
                        -Confirm:$false } |
                    Should -Throw
            }
        }
    }
}
