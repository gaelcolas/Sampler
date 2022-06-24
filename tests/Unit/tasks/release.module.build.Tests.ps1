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

Describe 'release.module' {
    It 'Should have exported the alias correct' {
        $taskAlias = Get-Alias -Name 'release.module.build.Sampler.ib.tasks'

        $taskAlias.Name | Should -Be 'release.module.build.Sampler.ib.tasks'
        $taskAlias.ReferencedCommand | Should -Be 'release.module.build.ps1'
        $taskAlias.Definition | Should -Match 'Sampler[\/|\\]\d+\.\d+\.\d+[\/|\\]tasks[\/|\\]release\.module\.build\.ps1'
    }
}

Describe 'Create_changelog_release_output' {
    BeforeAll {
        # Dot-source mocks
        . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

        $taskAlias = Get-Alias -Name 'release.module.build.Sampler.ib.tasks'

        $mockTaskParameters = @{
            OutputDirectory = Join-Path -Path $TestDrive -ChildPath 'output'
            ProjectName = 'MyModule'
        }
    }

    Context 'When creating the changelog output for a PowerShell module' {
        BeforeAll {
            Mock -CommandName Update-Changelog -RemoveParameterValidation 'Path'

            Mock -CommandName Get-ChangelogData -MockWith {
                return @{
                    Released = @{
                        Version = '2.0.0'
                        RawData = 'Mock changelog release output'
                    }
                }
            } -RemoveParameterValidation 'Path'

            Mock -CommandName ConvertFrom-Changelog -RemoveParameterValidation 'Path'

            Mock -CommandName Get-Content -ParameterFilter {
                $Path -match 'ReleaseNotes\.md'
            } -MockWith {
                return 'Mock changelog release output'
            }

            Mock -CommandName Get-Content -ParameterFilter {
                $Path -match 'builtModule'
            } -MockWith {
                <#
                    The variable $BuiltModuleManifest will be set in the task
                    (mocked by MockSetSamplerTaskVariable) with a path to the
                    $TestDrive.
                    Here we make sure the path exist so that WriteAllLines() works
                    that is called in the task.
                #>
                New-Item -Path ($BuiltModuleManifest | Split-Path -Parent) -ItemType Directory -Force

                return '# ReleaseNotes ='
            }

            Mock -CommandName Test-Path -ParameterFilter {
                $Path -match 'builtModule'
            } -MockWith {
                return $true
            }

            Mock -CommandName Update-Manifest
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task 'Create_changelog_release_output' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw
        }
    }
}
