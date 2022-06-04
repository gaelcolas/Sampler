
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
        $previousBuildInfo = $null

        if ($BuildInfo)
        {
            $previousBuildInfo = $BuildInfo.Clone()
        }

        $taskAlias = Get-Alias -Name 'Build-Module.ModuleBuilder.build.Sampler.ib.tasks'

        Mock -CommandName Get-BuiltModuleVersion -MockWith {
            return '2.0.0'
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

        $BuildInfo = @{
            CopyPaths = @('folder1','folder2')
        }

        Mock -CommandName Build-Module -RemoveParameterValidation 'SourcePath'

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

        $mockTaskParameters = @{
            OutputDirectory = Join-Path -Path $TestDrive -ChildPath 'MyModule/output'
            SourcePath = Join-Path -Path $TestDrive -ChildPath 'MyModule/source'
            ProjectName = 'MyModule'
        }
    }

    AfterAll {
        if ($previousBuildInfo)
        {
            $BuildInfo = $previousBuildInfo.Clone()
        }
    }

    Context 'When creating a preview release tag' {
        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task 'Build_ModuleOutput_ModuleBuilder' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw
        }
    }
}
