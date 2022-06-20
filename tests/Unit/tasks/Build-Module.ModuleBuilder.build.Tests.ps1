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

Describe 'Build-Module.ModuleBuilder' {
    It 'Should have exported the alias correct' {
        $taskAlias = Get-Alias -Name 'Build-Module.ModuleBuilder.build.Sampler.ib.tasks'

        $taskAlias.Name | Should -Be 'Build-Module.ModuleBuilder.build.Sampler.ib.tasks'
        $taskAlias.ReferencedCommand | Should -Be 'Build-Module.ModuleBuilder.build.ps1'
        $taskAlias.Definition | Should -Match 'Sampler[\/|\\]\d+\.\d+\.\d+[\/|\\]tasks[\/|\\]Build-Module\.ModuleBuilder\.build\.ps1'
    }
}

Describe 'Build_ModuleOutput_ModuleBuilder' {
    BeforeAll {
        # Dot-source mocks
        . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

        $BuildInfo = @{
            CopyPaths = @('folder1','folder2')
        }

        Mock -CommandName Get-Command -MockWith {
            return @{
                Parameters = @{
                    Keys = @('SourcePath', 'OutputDirectory', 'VersionedOutputDirectory', 'CopyPaths')
                }
            }
        } -ParameterFilter {
            <#
                Make sure to only mock the command in the task, otherwise we mess up
                Invoke-Build that runs in the same scope a the task.
            #>
            $Name -eq 'Build-Module'
        }

        Mock -CommandName Build-Module -RemoveParameterValidation 'SourcePath' -MockWith {
            # This is necessary to mock Windows PowerShell
            return @{
                RootModule = (
                    Join-Path -Path $TestDrive -ChildPath 'output' |
                        Join-Path -ChildPath 'builtModule' |
                        Join-Path -ChildPath 'MyModule' |
                        Join-Path -ChildPath '2.0.0' |
                        Join-Path -ChildPath 'MyModule.psm1'
                )
            }
        }

        # This is necessary to mock Windows PowerShell
        New-Item -Name 'MyModule.psm1' -ItemType File -Force -Path (
            Join-Path -Path $TestDrive -ChildPath 'output' |
                Join-Path -ChildPath 'builtModule' |
                Join-Path -ChildPath 'MyModule' |
                Join-Path -ChildPath '2.0.0'
        )

        # This is necessary to mock Windows PowerShell
        Mock -CommandName Get-Content -MockWith {
            return '# Mocked .psm1 file'
        } -ParameterFilter {
            $Path -eq (
                Join-Path -Path $TestDrive -ChildPath 'output' |
                    Join-Path -ChildPath 'builtModule' |
                    Join-Path -ChildPath 'MyModule' |
                    Join-Path -ChildPath '2.0.0' |
                    Join-Path -ChildPath 'MyModule.psm1'
            )
        }

        Mock -CommandName Test-Path -MockWith {
            return $true
        } -ParameterFilter {
            $Path -match 'ReleaseNotes.md'
        }

        Mock -CommandName Get-Content -ParameterFilter {
            $Path -match 'ReleaseNotes.md'
        } -MockWith {
            return 'Mock release notes'
        }

        Mock -CommandName Update-Metadata -RemoveParameterValidation 'Path'

        $taskAlias = Get-Alias -Name 'Build-Module.ModuleBuilder.build.Sampler.ib.tasks'

        $mockTaskParameters = @{
            OutputDirectory = Join-Path -Path $TestDrive -ChildPath 'MyModule/output'
            SourcePath = Join-Path -Path $TestDrive -ChildPath 'MyModule/source'
            ProjectName = 'MyModule'
        }
    }

    It 'Should run the build task without throwing' {
        {
            Invoke-Build -Task 'Build_ModuleOutput_ModuleBuilder' -File $taskAlias.Definition @mockTaskParameters
        } | Should -Not -Throw
    }
}

Describe 'Build_NestedModules_ModuleBuilder' {
    BeforeAll {
        # Dot-source mocks
        . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

        $BuildInfo = @{
            CopyPaths = @('folder1','folder2')
        }

        $taskAlias = Get-Alias -Name 'Build-Module.ModuleBuilder.build.Sampler.ib.tasks'

        $mockTaskParameters = @{
            OutputDirectory = Join-Path -Path $TestDrive -ChildPath 'MyModule/output'
            SourcePath = Join-Path -Path $TestDrive -ChildPath 'MyModule/source'
            ProjectName = 'MyModule'
        }
    }

    Context 'When build configuration does not contain nested module' {
        BeforeAll {
            Mock -CommandName Get-SamplerModuleInfo -MockWith {
                return @{
                    NestedModules = @()
                }
            } -RemoveParameterValidation 'ModuleManifestPath'
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task 'Build_NestedModules_ModuleBuilder' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw
        }
    }

    Context 'When build configuration contain a nested module' {
        Context 'When nested module should only be copied' {
            Context 'When property Path is not provided in build configuration' {
                BeforeAll {
                    $BuildInfo.NestedModule = @{
                        'DscResource.Common' = @{
                            CopyOnly = $true
                            AddToManifest = $false
                            Exclude = 'PSGetModuleInfo.xml'
                        }
                    }

                    Mock -CommandName Get-SamplerModuleInfo -MockWith {
                        return @{
                            NestedModules = @()
                        }
                    } -RemoveParameterValidation 'ModuleManifestPath'

                    Mock -CommandName Copy-Item
                }

                It 'Should run the build task without throwing' {
                    {
                        Invoke-Build -Task 'Build_NestedModules_ModuleBuilder' -File $taskAlias.Definition @mockTaskParameters
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Copy-Item -ParameterFilter {
                        ($Path -replace '\\', '/') -eq ((Join-Path -Path $TestDrive -ChildPath 'MyModule\source\Modules\DscResource.Common\DscResource.Common.psd1') -replace '\\', '/')
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When property Path is provided in build configuration' {
                BeforeAll {
                    $BuildInfo.NestedModule = @{
                        'DscResource.Common' = @{
                            CopyOnly = $true
                            Path = "$TestDrive/Modules/DscResource.Common"
                            AddToManifest = $false
                            Exclude = 'PSGetModuleInfo.xml'
                        }
                    }

                    Mock -CommandName Get-SamplerModuleInfo -MockWith {
                        return @{
                            NestedModules = @()
                        }
                    } -RemoveParameterValidation 'ModuleManifestPath'

                    Mock -CommandName Copy-Item
                }

                It 'Should run the build task without throwing' {
                    {
                        Invoke-Build -Task 'Build_NestedModules_ModuleBuilder' -File $taskAlias.Definition @mockTaskParameters
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Copy-Item -ParameterFilter {
                        ($Path -replace '\\', '/') -eq ((Join-Path -Path $TestDrive -ChildPath 'Modules\DscResource.Common\DscResource.Common.psd1') -replace '\\', '/')
                    } -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When nested module should be built' {
            Context 'When property SourcePath is not provided in build configuration' {
                BeforeAll {
                    $BuildInfo.NestedModule = @{
                        'DscResource.Common' = @{
                            CopyOnly = $false
                            AddToManifest = $false
                            Exclude = 'PSGetModuleInfo.xml'
                        }
                    }

                    Mock -CommandName Get-SamplerModuleInfo -MockWith {
                        return @{
                            NestedModules = @()
                        }
                    } -RemoveParameterValidation 'ModuleManifestPath'

                    Mock -CommandName Build-Module -RemoveParameterValidation 'SourcePath'
                }

                It 'Should run the build task without throwing' {
                    {
                        Invoke-Build -Task 'Build_NestedModules_ModuleBuilder' -File $taskAlias.Definition @mockTaskParameters
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Build-Module -Exactly -Times 1 -Scope It
                }
            }

            Context 'When property SourcePath is provided in build configuration' {
                BeforeAll {
                    $BuildInfo.NestedModule = @{
                        'DscResource.Common' = @{
                            SourcePath = './output/$ProjectName/$ModuleVersionFolder/Modules/$NestedModuleName'
                            AddToManifest = $false
                            Exclude = 'PSGetModuleInfo.xml'
                        }
                    }

                    Mock -CommandName Get-SamplerModuleInfo -MockWith {
                        return @{
                            NestedModules = @()
                        }
                    } -RemoveParameterValidation 'ModuleManifestPath'

                    Mock -CommandName Build-Module -RemoveParameterValidation 'SourcePath'
                }

                It 'Should run the build task without throwing' {
                    {
                        Invoke-Build -Task 'Build_NestedModules_ModuleBuilder' -File $taskAlias.Definition @mockTaskParameters
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Build-Module -Exactly -Times 1 -Scope It
                }
            }

            Context 'When property Verbose is provided in build configuration' {
                BeforeAll {
                    $BuildInfo.NestedModule = @{
                        'DscResource.Common' = @{
                            SourcePath = './output/$ProjectName/$ModuleVersionFolder/Modules/$NestedModuleName'
                            AddToManifest = $false
                            Exclude = 'PSGetModuleInfo.xml'
                            Verbose = $true
                        }
                    }

                    Mock -CommandName Get-SamplerModuleInfo -MockWith {
                        return @{
                            NestedModules = @()
                        }
                    } -RemoveParameterValidation 'ModuleManifestPath'

                    Mock -CommandName Build-Module -RemoveParameterValidation 'SourcePath'
                    Mock -CommandName Write-Verbose -ParameterFilter {
                        $Message -match 'OutputDirectory'
                    }
                }

                It 'Should run the build task without throwing' {
                    {
                        Invoke-Build -Task 'Build_NestedModules_ModuleBuilder' -File $taskAlias.Definition @mockTaskParameters
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Build-Module -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Write-Verbose -ParameterFilter {
                        $Message -match 'OutputDirectory'
                    } -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When nested module should be added to manifest' {
            BeforeAll {
                Mock -CommandName Get-SamplerModuleInfo -MockWith {
                    return @{
                        NestedModules = @()
                    }
                } -RemoveParameterValidation 'ModuleManifestPath'
            }

            # TODO: Add test when a nested module is in build configuration and should be added to module manifest
        }

        Context 'When module manifest already contain a nested module' {
            BeforeAll {
                Mock -CommandName Get-SamplerModuleInfo -MockWith {
                    return @{
                        NestedModules = @('PreviousNestedModule')
                    }
                } -RemoveParameterValidation 'ModuleManifestPath'
            }

            # TODO: Add tests for when there is already a nested module in the manifest to make sure it adds and not removes
        }
    }
}
