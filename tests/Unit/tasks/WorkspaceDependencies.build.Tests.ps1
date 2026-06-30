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

Describe 'WorkspaceDependencies.build' {
    It 'Should have exported the alias correctly' {
        $taskAlias = Get-Alias -Name 'WorkspaceDependencies.build.Sampler.ib.tasks'

        $taskAlias.Name | Should -Be 'WorkspaceDependencies.build.Sampler.ib.tasks'
        $taskAlias.ReferencedCommand | Should -Be 'WorkspaceDependencies.build.ps1'
        $taskAlias.Definition | Should -Match 'Sampler[\/|\\]\d+\.\d+\.\d+[\/|\\]tasks[\/|\\]WorkspaceDependencies\.build\.ps1'
    }
}

Describe 'Link_Local_Workspace_Dependencies' {
    BeforeAll {
        # Dot-source mocks
        . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

        $taskAlias = Get-Alias -Name 'WorkspaceDependencies.build.Sampler.ib.tasks'
    }

    Context 'When WorkspaceModules is configured in BuildInfo' {
        BeforeAll {
            $mockTaskParameters = @{
                OutputDirectory = Join-Path -Path $TestDrive -ChildPath 'output'
                BuildInfo       = @{
                    WorkspaceModules = @('ModuleA', 'ModuleB')
                }
            }

            Mock -CommandName Get-SamplerWorkspaceLinkedModuleRoot -MockWith {
                return (Join-Path -Path $TestDrive -ChildPath 'output\module')
            }

            Mock -CommandName Test-Path -MockWith {
                return $true
            }

            Mock -CommandName Get-SamplerWorkspaceBuiltModulePath -MockWith {
                return ('C:\src\{0}\output\module\{0}' -f $ModuleName)
            }

            Mock -CommandName New-SamplerWorkspaceModuleLink -MockWith {
                return 'SymbolicLink'
            }
        }

        It 'Should invoke New-SamplerWorkspaceModuleLink once per configured module' {
            {
                Invoke-Build -Task 'Link_Local_Workspace_Dependencies' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw

            Should -Invoke -CommandName New-SamplerWorkspaceModuleLink -Exactly -Times 2 -Scope It
        }
    }

    Context 'When WorkspaceModules is empty and not in BuildInfo' {
        BeforeAll {
            $mockTaskParameters = @{
                OutputDirectory = Join-Path -Path $TestDrive -ChildPath 'output'
                BuildInfo       = @{ }
            }

            Mock -CommandName New-SamplerWorkspaceModuleLink
        }

        It 'Should run without throwing and never call New-SamplerWorkspaceModuleLink' {
            {
                Invoke-Build -Task 'Link_Local_Workspace_Dependencies' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw

            Should -Invoke -CommandName New-SamplerWorkspaceModuleLink -Exactly -Times 0 -Scope It
        }
    }

    Context 'When New-SamplerWorkspaceModuleLink returns Junction' {
        BeforeAll {
            $mockTaskParameters = @{
                OutputDirectory = Join-Path -Path $TestDrive -ChildPath 'output'
                BuildInfo       = @{
                    WorkspaceModules = @('ModuleA')
                }
            }

            Mock -CommandName Get-SamplerWorkspaceLinkedModuleRoot -MockWith {
                return (Join-Path -Path $TestDrive -ChildPath 'output\module')
            }

            Mock -CommandName Test-Path -MockWith {
                return $true
            }

            Mock -CommandName Get-SamplerWorkspaceBuiltModulePath -MockWith {
                return 'C:\src\ModuleA\output\module\ModuleA'
            }

            Mock -CommandName New-SamplerWorkspaceModuleLink -MockWith {
                return 'Junction'
            }

            Mock -CommandName Write-Build
        }

        It 'Should invoke Write-Build with Yellow color for the Junction fallback' {
            {
                Invoke-Build -Task 'Link_Local_Workspace_Dependencies' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw

            Should -Invoke -CommandName Write-Build -Exactly -Times 1 -Scope It -ParameterFilter {
                $Color -eq 'Yellow'
            }
        }
    }
}
