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

Describe 'Create_Release_Git_Tag' {
    BeforeAll {
        $buildTaskName = 'Create_Release_Git_Tag'

        $taskAlias = Get-Alias -Name "$buildTaskName.build.Sampler.ib.tasks"
    }

    It 'Should have exported the alias correct' {
        $taskAlias.Name | Should -Be 'Create_Release_Git_Tag.build.Sampler.ib.tasks'
        $taskAlias.ReferencedCommand | Should -Be 'Create_Release_Git_Tag.build.ps1'
        $taskAlias.Definition | Should -Match 'Sampler[\/|\\]\d+\.\d+\.\d+[\/|\\]tasks[\/|\\]Create_Release_Git_Tag\.build\.ps1'
    }

    Context 'When creating a preview release tag' {
        BeforeAll {
            # Dot-source mocks
            . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

            function script:git
            {
                throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
            }

            Mock -CommandName git

            Mock -CommandName Sampler\Invoke-SamplerGit

            Mock -CommandName Sampler\Invoke-SamplerGit -ParameterFilter {
                $Argument -contains 'rev-parse' -and $Argument -contains 'HEAD'
            } -MockWith {
                return '0c23efc'
            }

            Mock -CommandName Sampler\Invoke-SamplerGit -ParameterFilter {
                $Argument -contains 'ls-remote'
            } -MockWith {
                return ''  # No existing remote tag
            }

            Mock -CommandName Sampler\Invoke-SamplerGit -ParameterFilter {
                $Argument -contains 'cat-file'
            } -MockWith {
                return $true  # Commit exists
            }

            Mock -CommandName Sampler\Invoke-SamplerGit -ParameterFilter {
                $Argument -contains 'rev-parse' -and $Argument[1] -like 'v*'
            } -MockWith {
                return '0c23efc'  # Tag verification
            }

            Mock -CommandName Start-Sleep

            $mockTaskParameters = @{
                ProjectPath = Join-Path -Path $TestDrive -ChildPath 'MyModule'
                OutputDirectory = Join-Path -Path $TestDrive -ChildPath 'MyModule/output'
                SourcePath = Join-Path -Path $TestDrive -ChildPath 'MyModule/source'
                ProjectName = 'MyModule'
                BasicAuthPAT = '22222'
                GitConfigUserName = 'bot'
                GitConfigUserEmail = 'bot@company.local'
                MainGitBranch = 'main'
                BuildCommit = '0c23efc'
            }
        }

        AfterAll {
            Remove-Item 'function:git'
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task $buildTaskName -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw
        }
    }

    Context 'When publishing should be skipped' {
        BeforeAll {
            $mockTaskParameters = @{
                SkipPublish = $true
            }
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task $buildTaskName -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw
        }
    }

    Context 'When remote tag already exists' {
        BeforeAll {
            # Dot-source mocks
            . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

            # Stub for git executable
            function script:git
            {
                throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
            }

            Mock -CommandName git

            Mock -CommandName Sampler\Invoke-SamplerGit

            Mock -CommandName Sampler\Invoke-SamplerGit -ParameterFilter {
                $Argument -contains 'rev-parse' -and $Argument -contains 'HEAD'
            } -MockWith {
                return '0c23efc'
            }

            Mock -CommandName Sampler\Invoke-SamplerGit -ParameterFilter {
                $Argument -contains 'ls-remote'
            } -MockWith {
                return 'abc123	refs/tags/v2.0.0'  # Existing remote tag
            }

            Mock -CommandName Start-Sleep

            $mockTaskParameters = @{
                ProjectPath = Join-Path -Path $TestDrive -ChildPath 'MyModule'
                OutputDirectory = Join-Path -Path $TestDrive -ChildPath 'MyModule/output'
                SourcePath = Join-Path -Path $TestDrive -ChildPath 'MyModule/source'
                ProjectName = 'MyModule'
                BasicAuthPAT = '22222'
                GitConfigUserName = 'bot'
                GitConfigUserEmail = 'bot@company.local'
                MainGitBranch = 'main'
                BuildCommit = '0c23efc'
            }
        }

        AfterAll {
            Remove-Item 'function:git'
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task $buildTaskName -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw
        }
    }

    Context 'When BuildCommit is resolved from CI environment variables' {
        BeforeAll {
            # Dot-source mocks
            . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

            function script:git
            {
                throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
            }

            Mock -CommandName git

            Mock -CommandName Sampler\Invoke-SamplerGit

            Mock -CommandName Sampler\Invoke-SamplerGit -ParameterFilter {
                $Argument -contains 'ls-remote'
            } -MockWith {
                return ''  # No existing remote tag
            }

            Mock -CommandName Sampler\Invoke-SamplerGit -ParameterFilter {
                $Argument -contains 'cat-file'
            } -MockWith {
                return $true  # Commit exists
            }

            Mock -CommandName Sampler\Invoke-SamplerGit -ParameterFilter {
                $Argument -contains 'rev-parse' -and $Argument[1] -like 'v*'
            } -MockWith {
                return 'abc123def456'  # Tag verification
            }

            Mock -CommandName Start-Sleep

            # Set environment variable to simulate GitHub Actions
            $env:GITHUB_SHA = 'abc123def456'

            $mockTaskParameters = @{
                ProjectPath = Join-Path -Path $TestDrive -ChildPath 'MyModule'
                OutputDirectory = Join-Path -Path $TestDrive -ChildPath 'MyModule/output'
                SourcePath = Join-Path -Path $TestDrive -ChildPath 'MyModule/source'
                ProjectName = 'MyModule'
                GitConfigUserName = 'bot'
                GitConfigUserEmail = 'bot@company.local'
                MainGitBranch = 'main'
                # Note: BuildCommit not provided, should be resolved from environment
            }
        }

        AfterAll {
            Remove-Item 'function:git'
            # Clean up environment variable
            if ($env:GITHUB_SHA) { Remove-Item env:GITHUB_SHA }
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task $buildTaskName -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw
        }
    }
}
