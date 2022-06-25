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

Describe 'Fail_Build_If_Pester_Tests_Failed' {
    BeforeAll {
        # Dot-source mocks
        . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

        $taskAlias = Get-Alias -Name 'Invoke-Pester.pester.build.Sampler.ib.tasks'

        $mockTaskParameters = @{
            OutputDirectory = Join-Path -Path $TestDrive -ChildPath 'output'
            ProjectName = 'MyModule'
        }
    }

    Context 'When tests failed' {
        BeforeAll {
            Mock -CommandName Get-CodeCoverageThreshold -MockWith {
                return 70
            }

            Mock -CommandName Test-Path -ParameterFilter {
                $Path -match 'PesterObject_'
            } -MockWith {
                return $true
            }

            Mock -CommandName Import-Clixml -MockWith {
                return @{
                    FailedCount = 10
                }
            }
        }

        It 'Should throw the correct error' {
            {
                Invoke-Build -Task 'Fail_Build_If_Pester_Tests_Failed' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Throw -ExpectedMessage 'Assertion failed. Failed 10 tests. Aborting Build'
        }
    }

    Context 'When tests failed' {
        BeforeAll {
            Mock -CommandName Get-CodeCoverageThreshold -MockWith {
                return 70
            }

            Mock -CommandName Test-Path -ParameterFilter {
                $Path -match 'PesterObject_'
            } -MockWith {
                return $true
            }

            Mock -CommandName Import-Clixml -MockWith {
                return @{
                    FailedCount = 0
                }
            }
        }

        It 'hould run the build task without throwing' {
            {
                Invoke-Build -Task 'Fail_Build_If_Pester_Tests_Failed' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw
        }
    }
}

Describe 'Pester_If_Code_Coverage_Under_Threshold' {
    BeforeAll {
        # Dot-source mocks
        . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

        $taskAlias = Get-Alias -Name 'Invoke-Pester.pester.build.Sampler.ib.tasks'

        $mockTaskParameters = @{
            OutputDirectory = Join-Path -Path $TestDrive -ChildPath 'output'
            ProjectName = 'MyModule'
        }
    }

    Context 'When running Pester 5' {
        Context 'When code coverage threshold was not met' {
            BeforeAll {
                Mock -CommandName Get-CodeCoverageThreshold -MockWith {
                    return 70
                }

                Mock -CommandName Test-Path -ParameterFilter {
                    $Path -match 'PesterObject_'
                } -MockWith {
                    return $true
                }

                Mock -CommandName Import-Clixml -MockWith {
                    return @{
                        Version = '5.3.3'
                        CodeCoverage = @{
                            CoveragePercent = 40
                        }
                    }
                }
            }

            It 'Should run the build task without throwing' {
                {
                    Invoke-Build -Task 'Pester_If_Code_Coverage_Under_Threshold' -File $taskAlias.Definition @mockTaskParameters
                } | Should -Throw -ExpectedMessage 'Code Coverage FAILURE: 40 % is under the threshold of 70 %.'
            }
        }

        Context 'When meeting code coverage threshold' {
            BeforeAll {
                Mock -CommandName Get-CodeCoverageThreshold -MockWith {
                    return 70
                }

                Mock -CommandName Test-Path -ParameterFilter {
                    $Path -match 'PesterObject_'
                } -MockWith {
                    return $true
                }

                Mock -CommandName Import-Clixml -MockWith {
                    return @{
                        Version = '5.3.3'
                        CodeCoverage = @{
                            CoveragePercent = 75
                        }
                    }
                }
            }

            It 'Should run the build task without throwing' {
                {
                    Invoke-Build -Task 'Pester_If_Code_Coverage_Under_Threshold' -File $taskAlias.Definition @mockTaskParameters
                } | Should -Not -Throw
            }
        }
    }

    Context 'When running Pester 4' {
        Context 'When code coverage threshold was not met' {
            BeforeAll {
                Mock -CommandName Get-CodeCoverageThreshold -MockWith {
                    return 70
                }

                Mock -CommandName Test-Path -ParameterFilter {
                    $Path -match 'PesterObject_'
                } -MockWith {
                    return $true
                }

                Mock -CommandName Import-Clixml -MockWith {
                    return @{
                        CodeCoverage = @{
                            NumberOfCommandsExecuted = 20
                            NumberOfCommandsAnalyzed = 40
                        }
                    }
                }
            }

            It 'Should run the build task without throwing' {
                {
                    Invoke-Build -Task 'Pester_If_Code_Coverage_Under_Threshold' -File $taskAlias.Definition @mockTaskParameters
                } | Should -Throw -ExpectedMessage 'Code Coverage FAILURE: 50 % is under the threshold of 70 %.'
            }
        }

        Context 'When meeting code coverage threshold' {
            BeforeAll {
                Mock -CommandName Get-CodeCoverageThreshold -MockWith {
                    return 70
                }

                Mock -CommandName Test-Path -ParameterFilter {
                    $Path -match 'PesterObject_'
                } -MockWith {
                    return $true
                }

                Mock -CommandName Import-Clixml -MockWith {
                    return @{
                        CodeCoverage = @{
                            NumberOfCommandsExecuted = 40
                            NumberOfCommandsAnalyzed = 50
                        }
                    }
                }
            }

            It 'Should run the build task without throwing' {
                {
                    Invoke-Build -Task 'Pester_If_Code_Coverage_Under_Threshold' -File $taskAlias.Definition @mockTaskParameters
                } | Should -Not -Throw
            }
        }
    }
}

Describe 'Pester_Run_Times' {
    BeforeAll {
        # Dot-source mocks
        . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

        $taskAlias = Get-Alias -Name 'Invoke-Pester.pester.build.Sampler.ib.tasks'

        $mockTaskParameters = @{
            OutputDirectory = Join-Path -Path $TestDrive -ChildPath 'output'
            ProjectName = 'MyModule'
        }
    }

    Context 'When running Pester 5' {
        Context 'When code coverage threshold was not met' {
            BeforeAll {
                Mock -CommandName Get-Module -MockWith {
                    return @{
                        Version = '4.1.10'
                    }
                }
            }

            It 'Should run the build task without throwing' {
                {
                    Invoke-Build -Task 'Pester_Run_Times' -File $taskAlias.Definition @mockTaskParameters
                } | Should -Not -Throw
            }
        }
    }

    Context 'When running Pester 5' {
        Context 'When code coverage threshold was not met' {
            BeforeAll {
                Mock -CommandName Get-Module -MockWith {
                    return @{
                        Version = '5.3.3'
                    }
                }

                Mock -CommandName Get-CodeCoverageThreshold -MockWith {
                    return 70
                }

                Mock -CommandName Test-Path -ParameterFilter {
                    $Path -match 'PesterObject_'
                } -MockWith {
                    return $true
                }

                Mock -CommandName Import-Clixml -MockWith {
                    return @{
                        Version = '5.3.3'
                        Duration = New-TimeSpan -Seconds 10
                        TotalCount = 21
                        Containers = @(
                            @{
                                Duration = New-TimeSpan -Seconds 5
                                Result = 'Passed'
                                PassedCount = 10
                                FailedCount = 0
                                SkippedCount = 0
                                TotalCount = 10
                                Item = @{
                                    Name = 'TestScript1'
                                }
                            }
                            @{
                                Duration = New-TimeSpan -Seconds 5
                                Result = 'Failed'
                                PassedCount = 10
                                FailedCount = 1
                                SkippedCount = 0
                                TotalCount = 1
                                Item = @{
                                    Name = 'TestScript2'
                                }
                            }
                        )
                    }
                }
            }

            It 'Should run the build task without throwing' {
                {
                    Invoke-Build -Task 'Pester_Run_Times' -File $taskAlias.Definition @mockTaskParameters
                } | Should -Not -Throw
            }
        }
    }
}
