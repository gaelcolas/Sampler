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

Describe 'publish.nuget' {
    It 'Should have exported the alias correctly' {
        $taskAlias = Get-Alias -Name 'publish.nuget.build.Sampler.ib.tasks'

        $taskAlias.Name | Should -Be 'publish.nuget.build.Sampler.ib.tasks'
        $taskAlias.ReferencedCommand | Should -Be 'publish.nuget.build.ps1'
        $taskAlias.Definition | Should -Match 'Sampler[\/|\\]\d+\.\d+\.\d+[\/|\\]tasks[\/|\\]publish\.nuget\.build\.ps1'
    }
}

Describe 'publish_nupkg_to_gallery' {
    BeforeAll {
        # Dot-source mocks
        . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

        $taskAlias = Get-Alias -Name 'publish.nuget.build.Sampler.ib.tasks'

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
