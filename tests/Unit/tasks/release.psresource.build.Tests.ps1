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

Describe 'release.psresource' {
    It 'Should have exported the alias correctly' {
        $taskAlias = Get-Alias -Name 'release.psresource.build.Sampler.ib.tasks'

        $taskAlias.Name | Should -Be 'release.psresource.build.Sampler.ib.tasks'
        $taskAlias.ReferencedCommand | Should -Be 'release.psresource.build.ps1'
        $taskAlias.Definition | Should -Match 'Sampler[\/|\\]\d+\.\d+\.\d+[\/|\\]tasks[\/|\\]release\.psresource\.build\.ps1'
    }
}

Describe 'package_psresource_nupkg' {
    BeforeAll {
        # Dot-source mocks
        . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

        $taskAlias = Get-Alias -Name 'release.psresource.build.Sampler.ib.tasks'

        $mockTaskParameters = @{
            OutputDirectory = Join-Path -Path $TestDrive -ChildPath 'output'
            ProjectName = 'MyModule'
        }
    }

    Context 'When packaging a Nuget package' {
        BeforeAll {
            Mock -CommandName Unregister-PSResourceRepository
            Mock -CommandName Register-PSResourceRepository

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

                return @'
@{
    ModuleVersion = '2.0.0'
    GUID = '00000000-0000-0000-0000-000000000000'
    Author = 'Test'
    CompanyName = 'Test'
    Copyright = 'Test'
    Description = 'Test module'
    FunctionsToExport = '*'
    CmdletsToExport = '*'
    VariablesToExport = '*'
    AliasesToExport = '*'
    PrivateData = @{
        PSData = @{
            # ReleaseNotes = 'Test release notes'
        }
    }
}
'@
            }

            Mock -CommandName Get-SamplerModuleInfo -MockWith {
                return @{
                    RequiredModules = @()
                }
            } -RemoveParameterValidation 'ModuleManifestPath'

            Mock -CommandName Publish-PSResource
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task 'package_psresource_nupkg' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw

            Should -Invoke -CommandName Publish-PSResource -Exactly -Times 1 -Scope It
        }
    }

    Context 'When packaging a Nuget package with a required PSResource' {
        BeforeAll {
            Mock -CommandName Unregister-PSResourceRepository
            Mock -CommandName Register-PSResourceRepository
            Mock -CommandName Import-Module -MockWith {
                [PSCustomObject]@{
                    Name = 'MyDependentModule'
                    ModuleBase = $TestDrive | Join-Path -ChildPath 'MyDependentModule'
                    Path = $TestDrive | Join-Path -ChildPath 'MyDependentModule\MyDependentModule.psd1'
                }
            }

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

                return @'
@{
    ModuleVersion = '2.0.0'
    GUID = '00000000-0000-0000-0000-000000000000'
    Author = 'Test'
    CompanyName = 'Test'
    Copyright = 'Test'
    Description = 'Test module'
    FunctionsToExport = '*'
    CmdletsToExport = '*'
    VariablesToExport = '*'
    AliasesToExport = '*'
    PrivateData = @{
        PSData = @{
            # ReleaseNotes = 'Test release notes'
        }
    }
}
'@
            }

            Mock -CommandName Get-SamplerModuleInfo -MockWith {
                return @{
                    RequiredModules = @('MyDependentModule')
                }
            } -RemoveParameterValidation 'ModuleManifestPath' -ParameterFilter {
                $ModuleManifestPath -eq $BuiltModuleManifest
            }

            Mock -CommandName Get-SamplerModuleInfo -MockWith {
                return @{
                    RequiredModules = @()
                }
            } -RemoveParameterValidation 'ModuleManifestPath' -ParameterFilter {
                $ModuleManifestPath -ne $BuiltModuleManifest
            }

            Mock -CommandName Find-PSResource -ParameterFilter {
                $Repository -eq 'output'
            }

            Mock -CommandName Get-PSResource -ParameterFilter {
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

            Mock -CommandName Publish-PSResource
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task 'package_psresource_nupkg' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw

            Should -Invoke -CommandName Publish-PSResource -ParameterFilter {
                $Path -eq ($TestDrive | Join-Path -ChildPath 'MyDependentModule')
            } -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName Publish-PSResource -ParameterFilter {
                $Path -match 'MyModule'
            } -Exactly -Times 1 -Scope It
        }
    }
}
