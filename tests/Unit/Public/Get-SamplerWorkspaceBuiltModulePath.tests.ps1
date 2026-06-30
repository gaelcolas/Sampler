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
    Context 'When the built module manifest is found in output/module/<name>' {
        BeforeAll {
            Mock -CommandName Get-SamplerWorkspaceRepositoryRoot -MockWith {
                return (Join-Path -Path $TestDrive -ChildPath 'MyModule')
            }

            Mock -CommandName Get-ChildItem -MockWith {
                $moduleRoot   = Join-Path -Path $TestDrive -ChildPath (Join-Path -Path 'MyModule' -ChildPath (Join-Path -Path 'output' -ChildPath (Join-Path -Path 'module' -ChildPath 'MyModule')))
                $versionDir   = Join-Path -Path $moduleRoot -ChildPath '1.0.0'
                $manifestFile = Join-Path -Path $versionDir -ChildPath 'MyModule.psd1'

                return [PSCustomObject] @{
                    FullName  = $manifestFile
                    Directory = [PSCustomObject] @{
                        Parent   = [PSCustomObject] @{ FullName = $moduleRoot }
                        FullName = $versionDir
                    }
                }
            } -ParameterFilter {
                $Path -like '*module*MyModule*'
            }
        }

        It 'Should return the versioned module parent directory' {
            $expectedPath = Join-Path -Path $TestDrive -ChildPath (Join-Path -Path 'MyModule' -ChildPath (Join-Path -Path 'output' -ChildPath (Join-Path -Path 'module' -ChildPath 'MyModule')))

            $result = Sampler\Get-SamplerWorkspaceBuiltModulePath -ModuleName 'MyModule' -WorkspaceRoot $TestDrive

            $result | Should -Be $expectedPath
        }
    }

    Context 'When no built manifest is found' {
        BeforeAll {
            Mock -CommandName Get-SamplerWorkspaceRepositoryRoot -MockWith {
                return (Join-Path -Path $TestDrive -ChildPath 'MyModule')
            }

            Mock -CommandName Get-ChildItem -MockWith {
                return $null
            }
        }

        It 'Should throw with a message containing the module name' {
            { Sampler\Get-SamplerWorkspaceBuiltModulePath -ModuleName 'MyModule' -WorkspaceRoot $TestDrive } |
                Should -Throw -ExpectedMessage '*MyModule*'
        }
    }
}
