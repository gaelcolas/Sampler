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
}

AfterAll {
    Remove-Module -Name $script:moduleName
}

Describe 'Invoke-Pester' {
    It 'Should have exported the alias correct' {
        $taskAlias = Get-Alias -Name 'Invoke-Pester.pester.build.Sampler.ib.tasks'

        $taskAlias.Name | Should -Be 'Invoke-Pester.pester.build.Sampler.ib.tasks'
        $taskAlias.ReferencedCommand | Should -Be 'Invoke-Pester.pester.build.ps1'
        $taskAlias.Definition | Should -Match 'Sampler[\/|\\]\d+\.\d+\.\d+[\/|\\]tasks[\/|\\]Invoke-Pester\.pester\.build\.ps1'
    }
}

Describe 'Import_Pester' {
    BeforeAll {
        $taskAlias = Get-Alias -Name 'Invoke-Pester.pester.build.Sampler.ib.tasks'

        Mock -CommandName Import-Module
    }

    It 'Should run the build task without throwing' {
        {
            Invoke-Build -Task 'Import_Pester' -File $taskAlias.Definition @mockTaskParameters
        } | Should -Not -Throw
    }
}

Describe 'Invoke_Pester_Tests_v4' {
    BeforeAll {
        # Dot-source mocks
        . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

        $taskAlias = Get-Alias -Name 'Invoke-Pester.pester.build.Sampler.ib.tasks'

        $mockTaskParameters = @{
            OutputDirectory = Join-Path -Path $TestDrive -ChildPath 'output'
            ProjectName = 'MyModule'
            PesterScript = $TestDrive
            # Mocks testing of passing a Invoke-Pester parameter.
            PesterTag = 'MyTag'
        }
    }

    Context 'When code coverage is disabled' {
        BeforeAll {
            $BuildInfo = @{
                Pester = @{
                    ExcludeFromCodeCoverage = 'MockExcludePathFromCoverage'
                    ExcludeTag = 'MockExcludeTag'
                }
            }

            Mock -CommandName Get-Module -MockWith {
                return @{
                    Version = '4.1.10'
                }
            }

            Mock -CommandName New-Item
            Mock -CommandName Get-CodeCoverageThreshold -MockWith {
                return 0
            }

            Mock -CommandName Get-Command -ParameterFilter {
                $Name -eq 'Invoke-Pester'
            } -MockWith {
                return @{
                    Parameters = @{
                        ExcludeTag = $null # Task will get value from build configuration
                        Tag = $null # Task will get value from passed parameter
                        OutputFormat = $null # Task will get value from default value
                    }
                }
            }

            Mock -CommandName Import-Module -ParameterFilter {
                $Name -eq 'MyModule'
            } -MockWith {
                return @{
                    ModuleBase = $TestDrive | Join-Path -ChildPath 'MyModule'
                }
            }

            Mock -CommandName Get-ChildItem -ParameterFilter {
                $Path -match 'MyModule'
            } -MockWith {
                return @(
                    @{
                        FullName = $TestDrive | Join-Path -ChildPath 'MyModule' | Join-Path -ChildPath 'MockExcludePathFromCoverage.ps1'
                    }
                    @{
                        FullName = $TestDrive | Join-Path -ChildPath 'MyModule' | Join-Path -ChildPath 'MyModule.psm1'
                    }
                )
            }

            Mock -CommandName Invoke-Pester -MockWith {
                return 'Mock Pester PassThru-object'
            }

            Mock -CommandName Export-Clixml
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task 'Invoke_Pester_Tests_v4' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-Pester -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'Invoke_Pester_Tests_v5' {
    BeforeAll {
        # Dot-source mocks
        . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

        $taskAlias = Get-Alias -Name 'Invoke-Pester.pester.build.Sampler.ib.tasks'

        $mockTaskParameters = @{
            OutputDirectory = Join-Path -Path $TestDrive -ChildPath 'output'
            ProjectName = 'MyModule'
            PesterScript = $TestDrive
            # Mocks testing of passing a Invoke-Pester parameter.
            PesterTag = 'MyTag'
        }
    }

    Context 'When code coverage is disabled' {
        BeforeAll {
            $BuildInfo = @{
                Pester = @{
                    Configuration = @{
                        Filter = @{
                            ExcludeTag = 'MockExcludeTag'
                        }
                    }
                    ExcludeFromCodeCoverage = 'MockExcludePathFromCoverage'
                }
            }

            Mock -CommandName Get-Module -MockWith {
                return @{
                    Version = '5.3.3'
                }
            }

            Mock -CommandName New-Item

            Mock -CommandName Import-Module -ParameterFilter {
                $Name -eq 'MyModule'
            }

            Mock -CommandName Invoke-Pester -MockWith {
                return 'Mock Pester PassThru-object'
            }

            Mock -CommandName Export-Clixml
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task 'Invoke_Pester_Tests_v5' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-Pester -Exactly -Times 1 -Scope It
        }
    }

    Context 'When code coverage is enabled' {
        BeforeAll {
            $BuildInfo = @{
                Pester = @{
                    Configuration = @{
                        Filter = @{
                            ExcludeTag = 'MockExcludeTag'
                        }
                        CodeCoverage = @{
                            CoveragePercentTarget = 70
                        }
                    }
                    ExcludeFromCodeCoverage = 'MockExcludePathFromCoverage'
                }
            }

            Mock -CommandName Get-Module -MockWith {
                return @{
                    Version = '5.3.3'
                }
            }

            Mock -CommandName New-Item

            Mock -CommandName Import-Module -ParameterFilter {
                $Name -eq 'MyModule'
            } -MockWith {
                return @{
                    ModuleBase = $TestDrive | Join-Path -ChildPath 'MyModule'
                }
            }

            Mock -CommandName Get-ChildItem -ParameterFilter {
                $Path -match 'MyModule'
            } -MockWith {
                return @(
                    @{
                        FullName = $TestDrive | Join-Path -ChildPath 'MyModule' | Join-Path -ChildPath 'MockExcludePathFromCoverage.ps1'
                    }
                    @{
                        FullName = $TestDrive | Join-Path -ChildPath 'MyModule' | Join-Path -ChildPath 'MyModule.psm1'
                    }
                )
            }

            Mock -CommandName Invoke-Pester -MockWith {
                return 'Mock Pester PassThru-object'
            }

            Mock -CommandName Export-Clixml
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task 'Invoke_Pester_Tests_v5' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-Pester -Exactly -Times 1 -Scope It
        }
    }
}
