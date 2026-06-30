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

Describe 'Get-SamplerWorkspaceBuiltModulePath' {
    Context 'When the built module manifest is found in output\module\<name>' {
        BeforeAll {
            Mock -CommandName Get-SamplerWorkspaceRepositoryRoot -MockWith {
                return 'C:\src\MyModule'
            }

            Mock -CommandName Get-ChildItem -MockWith {
                $fakeParentParent = [System.IO.DirectoryInfo]::new('C:\src\MyModule\output\module\MyModule')
                $fakeParent = [System.IO.DirectoryInfo]::new('C:\src\MyModule\output\module\MyModule\1.0.0')

                $fakeItem = [PSCustomObject] @{
                    FullName  = 'C:\src\MyModule\output\module\MyModule\1.0.0\MyModule.psd1'
                    Directory = [PSCustomObject] @{
                        Parent   = $fakeParentParent
                        FullName = $fakeParent.FullName
                    }
                }

                return $fakeItem
            } -ParameterFilter {
                $Path -like '*output\module\MyModule\*'
            }
        }

        It 'Should return the versioned module parent directory' {
            InModuleScope -ScriptBlock {
                $result = Sampler\Get-SamplerWorkspaceBuiltModulePath -ModuleName 'MyModule' -WorkspaceRoot 'C:\src'

                $result | Should -Be 'C:\src\MyModule\output\module\MyModule'
            }
        }
    }

    Context 'When no built manifest is found' {
        BeforeAll {
            Mock -CommandName Get-SamplerWorkspaceRepositoryRoot -MockWith {
                return 'C:\src\MyModule'
            }

            Mock -CommandName Get-ChildItem -MockWith {
                return $null
            }
        }

        It 'Should throw with a message containing the module name' {
            InModuleScope -ScriptBlock {
                { Sampler\Get-SamplerWorkspaceBuiltModulePath -ModuleName 'MyModule' -WorkspaceRoot 'C:\src' } |
                    Should -Throw -ExpectedMessage '*MyModule*'
            }
        }
    }
}
