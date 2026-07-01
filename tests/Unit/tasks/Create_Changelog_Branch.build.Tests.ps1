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

Describe 'Create_Changelog_Branch' {
    BeforeAll {
        $buildTaskName = 'Create_Changelog_Branch'

        $taskAlias = Get-Alias -Name "$buildTaskName.build.Sampler.ib.tasks"
    }

    It 'Should have exported the alias correctly' {
        $taskAlias.Name | Should -Be 'Create_Changelog_Branch.build.Sampler.ib.tasks'
        $taskAlias.ReferencedCommand | Should -Be 'Create_Changelog_Branch.build.ps1'
        $taskAlias.Definition | Should -Match 'Sampler[\/|\\]\d+\.\d+\.\d+[\/|\\]tasks[\/|\\]Create_Changelog_Branch\.build\.ps1'
    }

    Context 'When no release tag is found' {
        BeforeAll {
            # Dot-source mocks
            . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

            Mock -CommandName Sampler\Invoke-SamplerGit

            Mock -CommandName Sampler\Invoke-SamplerGit -ParameterFilter {
                $Argument -contains 'rev-parse'
            } -MockWith {
                return '0c23efc'
            }

            $mockTaskParameters = @{
                ProjectPath        = Join-Path -Path $TestDrive -ChildPath 'MyModule'
                OutputDirectory    = Join-Path -Path $TestDrive -ChildPath 'MyModule/output'
                SourcePath         = Join-Path -Path $TestDrive -ChildPath 'MyModule/source'
                ProjectName        = 'MyModule'
                BasicAuthPAT       = '22222'
                GitConfigUserName  = 'bot'
                GitConfigUserEmail = 'bot@company.local'
                MainGitBranch      = 'main'
                ChangelogPath      = 'CHANGELOG.md'
                BuildInfo          = @{}
            }
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task $buildTaskName -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw
        }
    }

    Context 'When creating change log PR' {
        BeforeAll {
            # Dot-source mocks
            . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

            Mock -CommandName Sampler\Invoke-SamplerGit

            Mock -CommandName Sampler\Invoke-SamplerGit -ParameterFilter {
                $Argument -contains 'rev-parse'
            } -MockWith {
                return '0c23efc'
            }

            Mock -CommandName Sampler\Invoke-SamplerGit -ParameterFilter {
                $Argument -contains 'tag'
            } -MockWith {
                return 'v2.0.0'
            }

            Mock -CommandName Update-Changelog -RemoveParameterValidation 'Path'

            $mockTaskParameters = @{
                ProjectPath        = Join-Path -Path $TestDrive -ChildPath 'MyModule'
                OutputDirectory    = Join-Path -Path $TestDrive -ChildPath 'MyModule/output'
                SourcePath         = Join-Path -Path $TestDrive -ChildPath 'MyModule/source'
                ProjectName        = 'MyModule'
                BasicAuthPAT       = '22222'
                GitConfigUserName  = 'bot'
                GitConfigUserEmail = 'bot@company.local'
                MainGitBranch      = 'main'
                ChangelogPath      = 'CHANGELOG.md'
                BuildInfo          = @{}
            }
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task $buildTaskName -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw
        }
    }

    Context 'When MainGitBranch is not set and BuildInfo.GitConfig.MainGitBranch is configured' {
        BeforeAll {
            # Dot-source mocks
            . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

            Mock -CommandName Sampler\Invoke-SamplerGit

            Mock -CommandName Sampler\Invoke-SamplerGit -ParameterFilter {
                $Argument -contains 'rev-parse'
            } -MockWith {
                return '0c23efc'
            }

            $mockTaskParameters = @{
                ProjectPath        = Join-Path -Path $TestDrive -ChildPath 'MyModule'
                OutputDirectory    = Join-Path -Path $TestDrive -ChildPath 'MyModule/output'
                SourcePath         = Join-Path -Path $TestDrive -ChildPath 'MyModule/source'
                ProjectName        = 'MyModule'
                BasicAuthPAT       = '22222'
                GitConfigUserName  = 'bot'
                GitConfigUserEmail = 'bot@company.local'
                MainGitBranch      = ''
                ChangelogPath      = 'CHANGELOG.md'
                BuildInfo          = @{
                    GitConfig = @{
                        MainGitBranch = 'develop'
                    }
                }
            }
        }

        It 'Should run the build task without throwing and use the branch from BuildInfo' {
            {
                Invoke-Build -Task $buildTaskName -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw

            Should -Invoke -CommandName Sampler\Invoke-SamplerGit -Scope It -ParameterFilter {
                $Argument -contains 'rev-parse' -and $Argument -contains 'origin/develop'
            }
        }
    }

    Context 'When GitConfigUserName and GitConfigUserEmail are not set' {
        BeforeAll {
            # Dot-source mocks
            . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

            Mock -CommandName Sampler\Invoke-SamplerGit

            Mock -CommandName Sampler\Invoke-SamplerGit -ParameterFilter {
                $Argument -contains 'rev-parse'
            } -MockWith {
                return '0c23efc'
            }

            $mockTaskParameters = @{
                ProjectPath        = Join-Path -Path $TestDrive -ChildPath 'MyModule'
                OutputDirectory    = Join-Path -Path $TestDrive -ChildPath 'MyModule/output'
                SourcePath         = Join-Path -Path $TestDrive -ChildPath 'MyModule/source'
                ProjectName        = 'MyModule'
                BasicAuthPAT       = '22222'
                GitConfigUserName  = ''
                GitConfigUserEmail = ''
                MainGitBranch      = 'main'
                ChangelogPath      = 'CHANGELOG.md'
                BuildInfo          = @{}
            }
        }

        It 'Should run the build task without throwing and not call git config user.name or user.email' {
            {
                Invoke-Build -Task $buildTaskName -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw

            Should -Not -Invoke -CommandName Sampler\Invoke-SamplerGit -Scope It -ParameterFilter {
                $Argument -contains 'user.name' -or $Argument -contains 'user.email'
            }
        }
    }
}
