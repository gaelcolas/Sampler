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

Describe 'generateHelp.PlatyPS' {
    It 'Should have exported the alias correct' {
        $taskAlias = Get-Alias -Name 'generateHelp.PlatyPS.build.Sampler.ib.tasks'

        $taskAlias.Name | Should -Be 'generateHelp.PlatyPS.build.Sampler.ib.tasks'
        $taskAlias.ReferencedCommand | Should -Be 'generateHelp.PlatyPS.build.ps1'
        $taskAlias.Definition | Should -Match 'Sampler[\/|\\]\d+\.\d+\.\d+[\/|\\]tasks[\/|\\]generateHelp\.PlatyPS\.build\.ps1'
    }
}

<#
    The task runs pwsh.exe and pass commands in a separate session
    so it is not possible to mock the commands.

    TODO: The tasks should be refactored to not start a separat session.
#>

# Describe 'Generate_MAML_from_built_module' {
#     BeforeAll {
#         # Dot-source mocks
#         . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

#         $taskAlias = Get-Alias -Name 'generateHelp.PlatyPS.build.Sampler.ib.tasks'

#         $mockTaskParameters = @{
#             SourcePath = Join-Path -Path $TestDrive -ChildPath 'MyModule/source'
#             ProjectName = 'MyModule'
#         }

#         # Stubs for PlatyPS module functions
#         function New-MarkdownHelp {}
#         function New-ExternalHelp {}
#     }

#     It 'Should run the build task without throwing' {
#         Mock -CommandName Import-Module -RemoveParameterValidation 'Name'

#         Mock -CommandName New-MarkdownHelp
#         Mock -CommandName New-ExternalHelp

#         Mock -CommandName Get-ChildItem -MockWith {
#             return $TestDrive
#         }

#         Mock -CommandName Copy-Item

#         {
#             Invoke-Build -Task 'Generate_MAML_from_built_module' -File $taskAlias.Definition @mockTaskParameters
#         } | Should -Not -Throw

#         Should -Invoke -CommandName Copy-Item -Exactly -Times 1 -Scope It
#     }
# }
