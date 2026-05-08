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

Describe 'DscResource.Authoring' {
    It 'Should have exported the alias correctly' {
        $taskAlias = Get-Alias -Name 'DscResource.Authoring.build.Sampler.ib.tasks'

        $taskAlias.Name | Should -Be 'DscResource.Authoring.build.Sampler.ib.tasks'
        $taskAlias.ReferencedCommand | Should -Be 'DscResource.Authoring.build.ps1'
        $taskAlias.Definition | Should -Match 'Sampler[\/|\\]\d+\.\d+\.\d+[\/|\\]tasks[\/|\\]DscResource\.Authoring\.build\.ps1'
    }
}

Describe 'Create_DscAdaptedResourceManifests' {
    BeforeAll {
        # Dot-source mocks
        . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

        $taskAlias = Get-Alias -Name 'DscResource.Authoring.build.Sampler.ib.tasks'

        $mockTaskParameters = @{
            OutputDirectory = Join-Path -Path $TestDrive -ChildPath 'output'
            ProjectName     = 'MyModule'
        }
    }

    Context 'When the built module manifest does not exist' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                return $false
            } -ParameterFilter {
                $Path -match 'MyModule\.psd1'
            }

            Mock -CommandName Import-Module -RemoveParameterValidation 'Name'
        }

        It 'Should throw the correct error' {
            {
                Invoke-Build -Task 'Create_DscAdaptedResourceManifests' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Throw -ExpectedMessage "*could not be found*"
        }
    }

    Context 'When the built module contains no class-based DSC resources' {
        BeforeAll {
            # Create the built module manifest so Test-Path returns $true.
            $mockBuiltModuleDir = Join-Path -Path $TestDrive -ChildPath 'output' |
                Join-Path -ChildPath 'builtModule' |
                Join-Path -ChildPath 'MyModule' |
                Join-Path -ChildPath '2.0.0'

            New-Item -Path $mockBuiltModuleDir -ItemType Directory -Force | Out-Null
            New-Item -Path (Join-Path -Path $mockBuiltModuleDir -ChildPath 'MyModule.psd1') -ItemType File -Force | Out-Null

            Mock -CommandName Import-Module -RemoveParameterValidation 'Name'

            Mock -CommandName New-DscAdaptedResourceManifest -MockWith {
                return $null
            }
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task 'Create_DscAdaptedResourceManifests' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw
        }

        It 'Should not write any manifest files' {
            Mock -CommandName Set-Content

            Invoke-Build -Task 'Create_DscAdaptedResourceManifests' -File $taskAlias.Definition @mockTaskParameters

            Should -Invoke -CommandName Set-Content -Exactly -Times 0 -Scope It
        }
    }

    Context 'When the built module contains class-based DSC resources with no task configuration' {
        BeforeAll {
            # Create the built module manifest so Test-Path returns $true.
            $mockBuiltModuleDir = Join-Path -Path $TestDrive -ChildPath 'output' |
                Join-Path -ChildPath 'builtModule' |
                Join-Path -ChildPath 'MyModule' |
                Join-Path -ChildPath '2.0.0'

            New-Item -Path $mockBuiltModuleDir -ItemType Directory -Force | Out-Null
            New-Item -Path (Join-Path -Path $mockBuiltModuleDir -ChildPath 'MyModule.psd1') -ItemType File -Force | Out-Null

            $mockAdaptedManifest = [PSCustomObject] @{
                Type = 'MyModule/MyResource'
            }

            $mockAdaptedManifest | Add-Member -MemberType ScriptMethod -Name 'ToJson' -Value {
                return '{"type":"MyModule/MyResource"}'
            }

            Mock -CommandName Import-Module -RemoveParameterValidation 'Name'

            Mock -CommandName New-DscAdaptedResourceManifest -MockWith {
                return @($mockAdaptedManifest)
            }

            Mock -CommandName Set-Content
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task 'Create_DscAdaptedResourceManifests' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw
        }

        It 'Should write one adapted resource manifest file using the default file name pattern' {
            Invoke-Build -Task 'Create_DscAdaptedResourceManifests' -File $taskAlias.Definition @mockTaskParameters

            Should -Invoke -CommandName Set-Content -ParameterFilter {
                $Path -match 'MyModule\.MyResource\.dsc\.adaptedResource\.json'
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the task is configured with a custom FileNamePattern' {
        BeforeAll {
            # Create the built module manifest so Test-Path returns $true.
            $mockBuiltModuleDir = Join-Path -Path $TestDrive -ChildPath 'output' |
                Join-Path -ChildPath 'builtModule' |
                Join-Path -ChildPath 'MyModule' |
                Join-Path -ChildPath '2.0.0'

            New-Item -Path $mockBuiltModuleDir -ItemType Directory -Force | Out-Null
            New-Item -Path (Join-Path -Path $mockBuiltModuleDir -ChildPath 'MyModule.psd1') -ItemType File -Force | Out-Null

            $mockAdaptedManifest = [PSCustomObject] @{
                Type = 'MyModule/MyResource'
            }

            $mockAdaptedManifest | Add-Member -MemberType ScriptMethod -Name 'ToJson' -Value {
                return '{"type":"MyModule/MyResource"}'
            }

            Mock -CommandName Import-Module -RemoveParameterValidation 'Name'

            Mock -CommandName New-DscAdaptedResourceManifest -MockWith {
                return @($mockAdaptedManifest)
            }

            Mock -CommandName Set-Content

            $mockTaskParametersWithConfig = $mockTaskParameters + @{
                BuildInfo = @{
                    'DscResource.Authoring' = @{
                        Create_DscAdaptedResourceManifests = @{
                            FileNamePattern = '{ResourceName}.custom.json'
                        }
                    }
                }
            }
        }

        It 'Should write the adapted resource manifest file using the configured file name pattern' {
            Invoke-Build -Task 'Create_DscAdaptedResourceManifests' -File $taskAlias.Definition @mockTaskParametersWithConfig

            Should -Invoke -CommandName Set-Content -ParameterFilter {
                $Path -match 'MyResource\.custom\.json'
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the task is configured with PropertyOverrides for a resource' {
        BeforeAll {
            # Create the built module manifest so Test-Path returns $true.
            $mockBuiltModuleDir = Join-Path -Path $TestDrive -ChildPath 'output' |
                Join-Path -ChildPath 'builtModule' |
                Join-Path -ChildPath 'MyModule' |
                Join-Path -ChildPath '2.0.0'

            New-Item -Path $mockBuiltModuleDir -ItemType Directory -Force | Out-Null
            New-Item -Path (Join-Path -Path $mockBuiltModuleDir -ChildPath 'MyModule.psd1') -ItemType File -Force | Out-Null

            $mockAdaptedManifest = [PSCustomObject] @{
                Type = 'MyModule/MyResource'
            }

            $mockAdaptedManifest | Add-Member -MemberType ScriptMethod -Name 'ToJson' -Value {
                return '{"type":"MyModule/MyResource"}'
            }

            $mockUpdatedManifest = [PSCustomObject] @{
                Type = 'MyModule/MyResource'
            }

            $mockUpdatedManifest | Add-Member -MemberType ScriptMethod -Name 'ToJson' -Value {
                return '{"type":"MyModule/MyResource","updated":true}'
            }

            Mock -CommandName Import-Module -RemoveParameterValidation 'Name'

            Mock -CommandName New-DscAdaptedResourceManifest -MockWith {
                return @($mockAdaptedManifest)
            }

            Mock -CommandName New-DscPropertyOverride -MockWith {
                return [PSCustomObject] @{ Name = 'Ensure' }
            }

            Mock -CommandName Update-DscAdaptedResourceManifest -MockWith {
                return $mockUpdatedManifest
            }

            Mock -CommandName Set-Content

            $mockTaskParametersWithOverrides = $mockTaskParameters + @{
                BuildInfo = @{
                    'DscResource.Authoring' = @{
                        Create_DscAdaptedResourceManifests = @{
                            PropertyOverrides = @{
                                MyResource = @(
                                    @{
                                        Name        = 'Ensure'
                                        Description = 'Whether the resource should exist.'
                                    }
                                )
                            }
                        }
                    }
                }
            }
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task 'Create_DscAdaptedResourceManifests' -File $taskAlias.Definition @mockTaskParametersWithOverrides
            } | Should -Not -Throw
        }

        It 'Should apply property overrides and write the adapted resource manifest' {
            Invoke-Build -Task 'Create_DscAdaptedResourceManifests' -File $taskAlias.Definition @mockTaskParametersWithOverrides

            Should -Invoke -CommandName Update-DscAdaptedResourceManifest -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Content -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'Create_DscResourceManifestsList' {
    BeforeAll {
        # Dot-source mocks
        . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

        $taskAlias = Get-Alias -Name 'DscResource.Authoring.build.Sampler.ib.tasks'

        $mockTaskParameters = @{
            OutputDirectory = Join-Path -Path $TestDrive -ChildPath 'output'
            ProjectName     = 'MyModule'
        }
    }

    Context 'When the built module manifest does not exist' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                return $false
            } -ParameterFilter {
                $Path -match 'MyModule\.psd1'
            }

            Mock -CommandName Import-Module -RemoveParameterValidation 'Name'
        }

        It 'Should throw the correct error' {
            {
                Invoke-Build -Task 'Create_DscResourceManifestsList' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Throw -ExpectedMessage "*could not be found*"
        }
    }

    Context 'When the built module contains no class-based DSC resources' {
        BeforeAll {
            # Create the built module manifest so Test-Path returns $true.
            $mockBuiltModuleDir = Join-Path -Path $TestDrive -ChildPath 'output' |
                Join-Path -ChildPath 'builtModule' |
                Join-Path -ChildPath 'MyModule' |
                Join-Path -ChildPath '2.0.0'

            New-Item -Path $mockBuiltModuleDir -ItemType Directory -Force | Out-Null
            New-Item -Path (Join-Path -Path $mockBuiltModuleDir -ChildPath 'MyModule.psd1') -ItemType File -Force | Out-Null

            Mock -CommandName Import-Module -RemoveParameterValidation 'Name'

            Mock -CommandName New-DscAdaptedResourceManifest -MockWith {
                return $null
            }
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task 'Create_DscResourceManifestsList' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw
        }

        It 'Should not write the manifests list file' {
            Mock -CommandName Set-Content

            Invoke-Build -Task 'Create_DscResourceManifestsList' -File $taskAlias.Definition @mockTaskParameters

            Should -Invoke -CommandName Set-Content -Exactly -Times 0 -Scope It
        }
    }

    Context 'When the built module contains class-based DSC resources with no task configuration' {
        BeforeAll {
            # Create the built module manifest so Test-Path returns $true.
            $mockBuiltModuleDir = Join-Path -Path $TestDrive -ChildPath 'output' |
                Join-Path -ChildPath 'builtModule' |
                Join-Path -ChildPath 'MyModule' |
                Join-Path -ChildPath '2.0.0'

            New-Item -Path $mockBuiltModuleDir -ItemType Directory -Force | Out-Null
            New-Item -Path (Join-Path -Path $mockBuiltModuleDir -ChildPath 'MyModule.psd1') -ItemType File -Force | Out-Null

            $mockAdaptedManifest = [PSCustomObject] @{
                Type = 'MyModule/MyResource'
            }

            $mockManifestList = [PSCustomObject] @{
                AdaptedResources = @($mockAdaptedManifest)
            }

            $mockManifestList | Add-Member -MemberType ScriptMethod -Name 'ToJson' -Value {
                return '{"adaptedResources":[{"type":"MyModule/MyResource"}]}'
            }

            Mock -CommandName Import-Module -RemoveParameterValidation 'Name'

            Mock -CommandName New-DscAdaptedResourceManifest -MockWith {
                return @($mockAdaptedManifest)
            }

            Mock -CommandName New-DscResourceManifest -MockWith {
                return $mockManifestList
            }

            Mock -CommandName Set-Content
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task 'Create_DscResourceManifestsList' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw
        }

        It 'Should write a single manifests list file using the default output file name' {
            Invoke-Build -Task 'Create_DscResourceManifestsList' -File $taskAlias.Definition @mockTaskParameters

            Should -Invoke -CommandName Set-Content -ParameterFilter {
                $Path -match 'MyModule\.dsc\.manifests\.json'
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the task is configured with a custom OutputFileName' {
        BeforeAll {
            # Create the built module manifest so Test-Path returns $true.
            $mockBuiltModuleDir = Join-Path -Path $TestDrive -ChildPath 'output' |
                Join-Path -ChildPath 'builtModule' |
                Join-Path -ChildPath 'MyModule' |
                Join-Path -ChildPath '2.0.0'

            New-Item -Path $mockBuiltModuleDir -ItemType Directory -Force | Out-Null
            New-Item -Path (Join-Path -Path $mockBuiltModuleDir -ChildPath 'MyModule.psd1') -ItemType File -Force | Out-Null

            $mockAdaptedManifest = [PSCustomObject] @{
                Type = 'MyModule/MyResource'
            }

            $mockManifestList = [PSCustomObject] @{
                AdaptedResources = @($mockAdaptedManifest)
            }

            $mockManifestList | Add-Member -MemberType ScriptMethod -Name 'ToJson' -Value {
                return '{"adaptedResources":[{"type":"MyModule/MyResource"}]}'
            }

            Mock -CommandName Import-Module -RemoveParameterValidation 'Name'

            Mock -CommandName New-DscAdaptedResourceManifest -MockWith {
                return @($mockAdaptedManifest)
            }

            Mock -CommandName New-DscResourceManifest -MockWith {
                return $mockManifestList
            }

            Mock -CommandName Set-Content

            $mockTaskParametersWithConfig = $mockTaskParameters + @{
                BuildInfo = @{
                    'DscResource.Authoring' = @{
                        Create_DscResourceManifestsList = @{
                            OutputFileName = 'custom.dsc.manifests.json'
                        }
                    }
                }
            }
        }

        It 'Should write the manifests list file using the configured output file name' {
            Invoke-Build -Task 'Create_DscResourceManifestsList' -File $taskAlias.Definition @mockTaskParametersWithConfig

            Should -Invoke -CommandName Set-Content -ParameterFilter {
                $Path -match 'custom\.dsc\.manifests\.json'
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the task is configured with PropertyOverrides for a resource' {
        BeforeAll {
            # Create the built module manifest so Test-Path returns $true.
            $mockBuiltModuleDir = Join-Path -Path $TestDrive -ChildPath 'output' |
                Join-Path -ChildPath 'builtModule' |
                Join-Path -ChildPath 'MyModule' |
                Join-Path -ChildPath '2.0.0'

            New-Item -Path $mockBuiltModuleDir -ItemType Directory -Force | Out-Null
            New-Item -Path (Join-Path -Path $mockBuiltModuleDir -ChildPath 'MyModule.psd1') -ItemType File -Force | Out-Null

            $mockAdaptedManifest = [PSCustomObject] @{
                Type = 'MyModule/MyResource'
            }

            $mockUpdatedManifest = [PSCustomObject] @{
                Type = 'MyModule/MyResource'
            }

            $mockManifestList = [PSCustomObject] @{
                AdaptedResources = @($mockUpdatedManifest)
            }

            $mockManifestList | Add-Member -MemberType ScriptMethod -Name 'ToJson' -Value {
                return '{"adaptedResources":[{"type":"MyModule/MyResource","updated":true}]}'
            }

            Mock -CommandName Import-Module -RemoveParameterValidation 'Name'

            Mock -CommandName New-DscAdaptedResourceManifest -MockWith {
                return @($mockAdaptedManifest)
            }

            Mock -CommandName New-DscPropertyOverride -MockWith {
                return [PSCustomObject] @{ Name = 'Ensure' }
            }

            Mock -CommandName Update-DscAdaptedResourceManifest -MockWith {
                return $mockUpdatedManifest
            }

            Mock -CommandName New-DscResourceManifest -MockWith {
                return $mockManifestList
            }

            Mock -CommandName Set-Content

            $mockTaskParametersWithOverrides = $mockTaskParameters + @{
                BuildInfo = @{
                    'DscResource.Authoring' = @{
                        Create_DscResourceManifestsList = @{
                            PropertyOverrides = @{
                                MyResource = @(
                                    @{
                                        Name        = 'Ensure'
                                        Description = 'Whether the resource should exist.'
                                    }
                                )
                            }
                        }
                    }
                }
            }
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task 'Create_DscResourceManifestsList' -File $taskAlias.Definition @mockTaskParametersWithOverrides
            } | Should -Not -Throw
        }

        It 'Should apply property overrides and write the manifests list file' {
            Invoke-Build -Task 'Create_DscResourceManifestsList' -File $taskAlias.Definition @mockTaskParametersWithOverrides

            Should -Invoke -CommandName Update-DscAdaptedResourceManifest -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Content -Exactly -Times 1 -Scope It
        }
    }
}
