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

            Should -Invoke -CommandName Update-Manifest -ParameterFilter {
                $Value -eq 'Mock changelog release output'
            } -Exactly -Times 1 -Scope It
        }

        Context 'When the release notes are longer than 10000 characters' {
            BeforeAll {
                Mock -CommandName Get-ChangelogData -MockWith {
                    return @{
                        Released = @{
                            Version = '2.0.0'
                            # The string 'This will be removed' will be stripped.
                            RawData = '0123456789' * 1000 + 'This will be removed'
                        }
                    }
                } -RemoveParameterValidation 'Path'
            }

            It 'Should run the build task without throwing' {
                {
                    Invoke-Build -Task 'Create_changelog_release_output' -File $taskAlias.Definition @mockTaskParameters
                } | Should -Not -Throw

                Should -Invoke -CommandName Update-Manifest -ParameterFilter {
                    $Value -eq '0123456789' * 1000
                } -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When there are no ReleaseNotes.md but a CHANGELOG.md' {
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
                return $null
            }

            Mock -CommandName Get-Content -ParameterFilter {
                $Path -match 'CHANGELOG\.md'
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
                New-Item -Path ($BuiltModuleManifest | Split-Path -Parent) -ItemType Directory -Force | Out-Null

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

            Should -Invoke -CommandName Update-Manifest -ParameterFilter {
                $Value -eq 'Mock changelog release output'
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When there are no release notes' {
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
                return $null
            }

            Mock -CommandName Get-Content -ParameterFilter {
                $Path -match 'CHANGELOG\.md'
            } -MockWith {
                return $null
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
                New-Item -Path ($BuiltModuleManifest | Split-Path -Parent) -ItemType Directory -Force | Out-Null

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

            Should -Invoke -CommandName Update-Manifest -Exactly -Times 0 -Scope It
        }
    }
}

Describe 'publish_nupkg_to_gallery' {
    BeforeAll {
        # Dot-source mocks
        . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

        $taskAlias = Get-Alias -Name 'release.module.build.Sampler.ib.tasks'

        $mockTaskParameters = @{
            OutputDirectory = Join-Path -Path $TestDrive -ChildPath 'output'
            ProjectName = 'MyModule'
            GalleryApiToken = 'MyToken'
        }
    }

    Context 'When publish Nuget package' {
        BeforeAll {
            # Stub for executable nuget
            function nuget {}

            Mock -CommandName nuget -MockWith {
                return '0'
            }

            Mock -CommandName Get-ChildItem -ParameterFilter {
                $Path -match '\.nupkg'
            } -MockWith {
                return $TestDrive
            }
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task 'publish_nupkg_to_gallery' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw

            Should -Invoke -CommandName nuget -Exactly -Times 1 -Scope It
        }
    }

    Context 'When publish Nuget package with .NET SDK' {
        BeforeAll {
            # Stub for executable dotnet
            function dotnet {}

            Mock -CommandName dotnet -MockWith {
                return '0'
            }

            Mock -CommandName Get-Command -ParameterFilter {
                $Name -eq 'nuget' -and  $ErrorAction -eq 'SilentlyContinue'
            } -MockWith {
                $null
            }

            Mock -CommandName Get-ChildItem -ParameterFilter {
                $Path -match '\.nupkg'
            } -MockWith {
                return $TestDrive
            }
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task 'publish_nupkg_to_gallery' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw

            Should -Invoke -CommandName dotnet -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'package_module_nupkg' {
    BeforeAll {
        # Dot-source mocks
        . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

        $taskAlias = Get-Alias -Name 'release.module.build.Sampler.ib.tasks'

        $mockTaskParameters = @{
            OutputDirectory = Join-Path -Path $TestDrive -ChildPath 'output'
            ProjectName = 'MyModule'
        }
    }

    Context 'When packeting a Nuget package' {
        BeforeAll {
            Mock -CommandName Unregister-PSRepository
            Mock -CommandName Register-PSRepository

            Mock -CommandName Get-ChildItem -ParameterFilter {
                $Path -match '\.nupkg'
            } -MockWith {
                return $TestDrive
            }

            Mock -CommandName Remove-Item

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
                New-Item -Path ($BuiltModuleManifest | Split-Path -Parent) -ItemType Directory -Force | Out-Null

                return '# ReleaseNotes ='
            }

            Mock -CommandName Get-SamplerModuleInfo -MockWith {
                return @{
                    RequiredModules = @()
                }
            } -RemoveParameterValidation 'ModuleManifestPath'

            Mock -CommandName Publish-Module
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task 'package_module_nupkg' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw

            Should -Invoke -CommandName Publish-Module -Exactly -Times 1 -Scope It
        }
    }

    Context 'When packeting a Nuget package with a required module' {
        BeforeAll {
            Mock -CommandName Unregister-PSRepository
            Mock -CommandName Register-PSRepository

            Mock -CommandName Get-ChildItem -ParameterFilter {
                $Path -match '\.nupkg'
            } -MockWith {
                return $TestDrive
            }

            Mock -CommandName Remove-Item

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
                New-Item -Path ($BuiltModuleManifest | Split-Path -Parent) -ItemType Directory -Force | Out-Null

                return '# ReleaseNotes ='
            }

            Mock -CommandName Get-SamplerModuleInfo -MockWith {
                return @{
                    RequiredModules = @('MyDependentModule')
                }
            } -RemoveParameterValidation 'ModuleManifestPath'

            Mock -CommandName Find-Module -ParameterFilter {
                $Repository -eq 'output'
            }

            Mock -CommandName Get-Module -ParameterFilter {
                $FullyQualifiedName.Name -eq 'MyDependentModule'
            } -MockWith {
                return @{
                    Name = 'MyDependentModule'
                    ModuleBase = $TestDrive | Join-Path -ChildPath 'MyDependentModule'
                    Version = [Version] '1.1.0'
                    PrivateData = @{
                        PSData = @{
                            Prerelease = 'preview1'
                        }
                    }
                }
            }

            Mock -CommandName Publish-Module
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task 'package_module_nupkg' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw

            Should -Invoke -CommandName Get-Module -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName Publish-Module -ParameterFilter {
                $Path -eq ($TestDrive | Join-Path -ChildPath 'MyDependentModule')
            } -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName Publish-Module -ParameterFilter {
                $Path -match 'MyModule'
            } -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'publish_module_to_gallery' {
    BeforeAll {
        # Dot-source mocks
        . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

        $taskAlias = Get-Alias -Name 'release.module.build.Sampler.ib.tasks'

        $mockTaskParameters = @{
            OutputDirectory = Join-Path -Path $TestDrive -ChildPath 'output'
            ProjectName = 'MyModule'
            GalleryApiToken = 'MyToken'
        }
    }

    Context 'When publishing a PowerShell module' {
        Context 'When using PowerShellGet' {
            BeforeAll {
                # Mocking the task filter `-if` so the task is run.
                Mock -CommandName Get-Command -ParameterFilter {
                    $Name.Count -eq 2
                } -MockWith {
                    # We can return anything here, as long as it is not null.
                    return 'Run task'
                }

                <#
                    This mocks the evaluation inside the task, if PowerShellGet
                    or PSResourceGet should be used.
                #>
                Mock -CommandName Get-Module -ParameterFilter {
                    $Name -eq 'Microsoft.PowerShell.PSResourceGet'
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
                    New-Item -Path ($BuiltModuleManifest | Split-Path -Parent) -ItemType Directory -Force | Out-Null

                    return '# ReleaseNotes ='
                }

                Mock -CommandName Publish-Module
            }

            It 'Should run the build task without throwing' {
                {
                    Invoke-Build -Task 'publish_module_to_gallery' -File $taskAlias.Definition @mockTaskParameters
                } | Should -Not -Throw

                Should -Invoke -CommandName Publish-Module -Exactly -Times 1 -Scope It
            }
        }

        Context 'When using Microsoft.PowerShell.PSResourceGet' {
            BeforeAll {
                # Mocking the task filter `-if` so the task is run.
                Mock -CommandName Get-Command -ParameterFilter {
                    $Name.Count -eq 2
                } -MockWith {
                    # We can return anything here, as long as it is not null.
                    return 'Run task'
                }

                <#
                    This mocks the evaluation inside the task, if PowerShellGet
                    or PSResourceGet should be used.
                #>
                Mock -CommandName Get-Module -ParameterFilter {
                    $Name -eq 'Microsoft.PowerShell.PSResourceGet'
                } -MockWith {
                    # We can return anything here, as long as it is not null.
                    return 'Microsoft.PowerShell.PSResourceGet'
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
                    New-Item -Path ($BuiltModuleManifest | Split-Path -Parent) -ItemType Directory -Force | Out-Null

                    return '# ReleaseNotes ='
                }

                Mock -CommandName Get-PSResourceRepository
                Mock -CommandName Publish-PSResource
            }

            It 'Should run the build task without throwing' {
                {
                    Invoke-Build -Task 'publish_module_to_gallery' -File $taskAlias.Definition @mockTaskParameters
                } | Should -Not -Throw

                Should -Invoke -CommandName Publish-PSResource -Exactly -Times 1 -Scope It
            }
        }
    }
}
