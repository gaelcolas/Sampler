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

Describe 'ChocolateyPackage' {
    It 'Should have exported the alias correct' {
        $taskAlias = Get-Alias -Name 'ChocolateyPackage.build.Sampler.ib.tasks'

        $taskAlias.Name | Should -Be 'ChocolateyPackage.build.Sampler.ib.tasks'
        $taskAlias.ReferencedCommand | Should -Be 'ChocolateyPackage.build.ps1'
        $taskAlias.Definition | Should -Match 'Sampler[\/|\\]\d+\.\d+\.\d+[\/|\\]tasks[\/|\\]ChocolateyPackage\.build\.ps1'
    }
}

Describe 'copy_chocolatey_source_to_staging' {
    BeforeAll {
        # Dot-source mocks
        . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

        $taskAlias = Get-Alias -Name 'ChocolateyPackage.build.Sampler.ib.tasks'

        $mockTaskParameters = @{
            SourcePath = Join-Path -Path $TestDrive -ChildPath 'MyModule/source'
            ProjectName = 'MyModule'
        }
    }

    It 'Should run the build task without throwing' {
        Mock -CommandName Get-ChildItem -ParameterFilter {
            $Path -match 'Chocolatey'
        } -MockWith {
            return @{
                BaseName = 'Package1'
            }
        }

        Mock -CommandName Copy-Item

        {
            Invoke-Build -Task 'copy_chocolatey_source_to_staging' -File $taskAlias.Definition @mockTaskParameters
        } | Should -Not -Throw

    }
}
