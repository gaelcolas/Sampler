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
