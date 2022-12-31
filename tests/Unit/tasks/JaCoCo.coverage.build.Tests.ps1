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

Describe 'JaCoCo.coverage' {
    It 'Should have exported the alias correct' {
        $taskAlias = Get-Alias -Name 'JaCoCo.coverage.build.Sampler.ib.tasks'

        $taskAlias.Name | Should -Be 'JaCoCo.coverage.build.Sampler.ib.tasks'
        $taskAlias.ReferencedCommand | Should -Be 'JaCoCo.coverage.build.ps1'
        $taskAlias.Definition | Should -Match 'Sampler[\/|\\]\d+\.\d+\.\d+[\/|\\]tasks[\/|\\]JaCoCo\.coverage\.build\.ps1'
    }
}

Describe 'Merge_CodeCoverage_Files' {
    BeforeAll {
        # Dot-source mocks
        . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

        $taskAlias = Get-Alias -Name 'JaCoCo.coverage.build.Sampler.ib.tasks'

        $mockTaskParameters = @{
            OutputDirectory = Join-Path -Path $TestDrive -ChildPath 'output'
            ProjectName = 'MyModule'
        }
    }

    Context 'When code coverage is disabled' {
        BeforeAll {
            # Stub for Start-CodeCoverageMerge which is function inside the task script
            function Start-CodeCoverageMerge {}

            Mock -CommandName Start-CodeCoverageMerge
            Mock -CommandName Get-CodeCoverageThreshold -MockWith {
                return 0
            }
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task 'Merge_CodeCoverage_Files' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw

            Should -Invoke -CommandName Start-CodeCoverageMerge -Exactly -Times 0 -Scope It
        }
    }

    Context 'When there are only one source coverage file' {
        BeforeAll {
            # Stub for Start-CodeCoverageMerge which is function inside the task script
            function Start-CodeCoverageMerge {}

            Mock -CommandName Start-CodeCoverageMerge
            Mock -CommandName Get-CodeCoverageThreshold -MockWith {
                return 70
            }

            Mock -CommandName Get-ChildItem -ParameterFilter {
                $Include -eq 'Codecov*.xml'
            } -MockWith {
                return @{
                    FullName = $TestDrive | Join-Path -ChildPath 'Codecov_TestRun1.xml'
                }
            }

            Mock -CommandName Test-Path -ParameterFilter {
                $Path -match 'CodeCov_Merged\.xml'
            } -MockWith {
                return $true
            }

            Mock -CommandName Remove-Item
        }

        It 'Should throw the correct error' {
            {
                Invoke-Build -Task 'Merge_CodeCoverage_Files' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Throw -ExpectedMessage 'Found 1 code coverage file. Need at least two files to merge.'
        }
    }

    Context 'When code coverage is disabled' {
        BeforeAll {
            # Stub for Start-CodeCoverageMerge which is function inside the task script
            function Start-CodeCoverageMerge {}

            Mock -CommandName Start-CodeCoverageMerge

            Mock -CommandName Get-CodeCoverageThreshold -MockWith {
                return 70
            }

            Mock -CommandName Get-ChildItem -ParameterFilter {
                $Include -eq 'Codecov*.xml'
            } -MockWith {
                return @(
                    @{
                        FullName = $TestDrive | Join-Path -ChildPath 'Codecov_TestRun1.xml'
                    }
                    @{
                        FullName = $TestDrive | Join-Path -ChildPath 'Codecov_TestRun2.xml'
                    }
                )
            }

            Mock -CommandName Test-Path -ParameterFilter {
                $Path -match 'CodeCov_Merged\.xml'
            } -MockWith {
                return $true
            }

            Mock -CommandName Remove-Item
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task 'Merge_CodeCoverage_Files' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw

            Should -Invoke -CommandName Start-CodeCoverageMerge -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'Convert_Pester_Coverage' {
    BeforeAll {
        # Dot-source mocks
        . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

        $taskAlias = Get-Alias -Name 'JaCoCo.coverage.build.Sampler.ib.tasks'

        $mockTaskParameters = @{
            OutputDirectory = Join-Path -Path $TestDrive -ChildPath 'output'
            ProjectName = 'MyModule'
        }
    }

    Context 'When code coverage is disabled' {
        BeforeAll {
            Mock -CommandName Get-CodeCoverageThreshold -MockWith {
                return 0
            }
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task 'Convert_Pester_Coverage' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw
        }
    }

    Context 'When the pester object file is not found' {
        BeforeAll {
            Mock -CommandName Get-CodeCoverageThreshold -MockWith {
                return 70
            }

            Mock -CommandName Test-Path -ParameterFilter {
                $Path -match 'PesterObject_'
            } -MockWith {
                return $false
            }
        }

        It 'Should throw the correct error' {
            {
                Invoke-Build -Task 'Convert_Pester_Coverage' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Throw -ExpectedMessage 'No command were tested, nothing to convert.'
        }
    }

    Context 'When older Pester 5 version is used' {
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
                    Version = '5.1.0'
                    CodeCoverage = @{
                        CommandsMissed = @{
                            File = 'MyModule.psm1'
                        }
                        CommandsExecuted = @{
                            File = 'MyModule.psm1'
                        }
                    }
                }
            }
        }

        It 'Should throw the correct error' {
            {
                Invoke-Build -Task 'Convert_Pester_Coverage' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Throw -ExpectedMessage 'When Pester 5 is used then to correctly support code coverage the minimum required version is v5.2.0.'
        }
    }

    Context 'When converting built modules code coverage to match source files' {
        BeforeAll {
            Mock -CommandName Get-CodeCoverageThreshold -MockWith {
                return 70
            }

            Mock -CommandName Get-SamplerAbsolutePath -ParameterFilter {
                $Path -match 'testResults'
            } -MockWith {
                return $TestDrive | Join-Path -ChildPath 'testResults'
            }

            Mock -CommandName Get-PesterOutputFileFileName -MockWith {
                return 'MyModuleCoverage.xml'
            }

            Mock -CommandName Get-SamplerCodeCoverageOutputFile -MockWith {
                # Create the folder structure in the test drive.
                New-Item -Path $PesterOutputFolder -ItemType Directory -Force | Out-Null

                # Write a dummy XML file that can be read back by the task later on.
                '<xml></xml>' | Out-File -FilePath (Join-Path -Path $PesterOutputFolder -ChildPath 'CodeCov_MyModuleCoverage.xml') -Encoding UTF8 -Force
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
                        # Mocking that same types as Pester uses.
                        CommandsMissed = [System.Collections.ArrayList] @(
                            [PSCustomObject] @{
                                File = Join-Path -Path $TestDrive -ChildPath 'output/MyModule/1.0.0/MyModule.psm1'
                                Line        = 624
                                StartLine   = 624
                                EndLine     = 624
                                StartColumn = 23
                                EndColumn   = 144
                                Class       = $null
                                Function    = 'Get-MockCommand'
                                Command     = "Get-Something -MockParameter 'MyMockValue'"
                                HitCount    = 0
                            }
                        )
                    }
                }
            }

            Mock -CommandName Convert-LineNumber

            Mock -CommandName New-SamplerJaCoCoDocument -MockWith {
                return [Xml] '<xml></xml>'
            }

            Mock -CommandName Out-SamplerXml -ParameterFilter {
                $Path -match 'source_coverage\.xml'
            }

            Mock -CommandName Out-SamplerXml -ParameterFilter {
                $Path -match '\.xml\.bak'
            }

            Mock -CommandName Merge-JaCoCoReport -MockWith {
                return [Xml] '<xml></xml>'
            }

            Mock -CommandName Update-JaCoCoStatistic -MockWith {
                return [Xml] '<xml></xml>'
            }

            Mock -CommandName Out-SamplerXml -ParameterFilter {
                $Path -match 'CodeCov_MyModuleCoverage\.xml'
            }
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task 'Convert_Pester_Coverage' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw

            Should -Invoke -CommandName New-SamplerJaCoCoDocument -Exactly -Times 1 -Scope It
        }
    }
}
