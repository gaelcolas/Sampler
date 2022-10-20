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

Describe 'GuestConfig' {
    It 'Should have exported the alias correct' {
        $taskAlias = Get-Alias -Name 'GuestConfig.build.Sampler.ib.tasks'

        $taskAlias.Name | Should -Be 'GuestConfig.build.Sampler.ib.tasks'
        $taskAlias.ReferencedCommand | Should -Be 'GuestConfig.build.ps1'
        $taskAlias.Definition | Should -Match 'Sampler[\/|\\]\d+\.\d+\.\d+[\/|\\]tasks[\/|\\]GuestConfig\.build\.ps1'
    }
}

Describe 'build_guestconfiguration_packages' {
    BeforeAll {
        # Dot-source mocks
        . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

        $taskAlias = Get-Alias -Name 'GuestConfig.build.Sampler.ib.tasks'

        $mockTaskParameters = @{
            SourcePath = Join-Path -Path $TestDrive -ChildPath 'MyModule/source'
            ProjectName = 'MyModule'
            OutputDirectory = Join-Path -Path $TestDrive -ChildPath 'output'
        }
    }

    Context 'When using MOF file' {
        BeforeAll {
            # Stub function to be able to mock the command.
            function New-GuestConfigurationPackage {}

            Mock -CommandName Get-ChildItem -ParameterFilter {
                $Path -match 'GCPackages'
            } -MockWith {
                return @{
                    Name = 'GCPackage1'
                    FullName = $TestDrive | Join-Path -ChildPath 'GCPackage1'
                }
            }

            Mock -CommandName Test-Path -ParameterFilter {
                $Path -match 'GCPackage1'
            } -MockWith {
                return $true
            }

            Mock -CommandName Test-Path -ParameterFilter {
                $Path -match '\.mof'
            } -MockWith {
                return $true
            }

            Mock -CommandName Import-PowerShellDataFile
            Mock -CommandName New-GuestConfigurationPackage -MockWith {
                return @{
                    Path = $TestDrive | Join-Path -ChildPath 'GCPackage1'
                }
            }

            Mock -CommandName Move-Item
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task 'build_guestconfiguration_packages' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw
        }
    }

    <#
        TODO: The below test does not work since the script block to compiles the
              configuration sometimes throws the error:
              Cannot process argument transformation on parameter 'ResourceModuleTuplesToImport'. Cannot convert the "System.Collections.ArrayList" value of type "System.Collections.ArrayList" to type "System.Tuple`3[System.String[],Microsoft.PowerShell.Commands.ModuleSpecification[],System.Version]".
    #>

#     Context 'When using configuration file' {
#         BeforeAll {
#             # Stub function to be able to mock the command.
#             function New-GuestConfigurationPackage {}

#             $mockGCPackagePath = $TestDrive | Join-Path -ChildPath 'GCPackage1'

#             New-Item -Path $mockGCPackagePath -ItemType Directory -Force | Out-Null

#             # Create the mock output folder so configuration can be compiled.
#             New-Item -Path ($TestDrive | Join-Path -ChildPath 'output/MOFs') -ItemType Directory -Force | Out-Null

#             $mockConfigurationScriptFile = @'
# Configuration GCPackage1
# {
#     Node "localhost"
#     {
#         File DirectoryCopy
#         {
#             Ensure = "Present"
#             Type = "Directory"
#             Recurse = $true
#             SourcePath = "\\PullServer\DemoSource"
#             DestinationPath = "C:\Users\Public\Documents\DSCDemo\DemoDestination"
#         }
#     }
# }
# '@

#             $mockConfigurationScriptFile | Out-File -FilePath ($mockGCPackagePath | Join-Path -ChildPath 'GCPackage1.config.ps1') -Encoding UTF8 -Force

#             Mock -CommandName Get-ChildItem -ParameterFilter {
#                 $Path -match 'GCPackages'
#             } -MockWith {
#                 return @{
#                     Name = 'GCPackage1'
#                     FullName = $mockGCPackagePath
#                 }
#             }

#             Mock -CommandName Test-Path -ParameterFilter {
#                 $Path -match 'GCPackage1'
#             } -MockWith {
#                 return $true
#             }

#             Mock -CommandName Test-Path -ParameterFilter {
#                 $Path -match '\.mof'
#             } -MockWith {
#                 return $false
#             }

#             Mock -CommandName Import-PowerShellDataFile
#             Mock -CommandName New-GuestConfigurationPackage -MockWith {
#                 return @{
#                     Path = $TestDrive | Join-Path -ChildPath 'GCPackage1'
#                 }
#             }

#             Mock -CommandName Move-Item
#         }

#         It 'Should run the build task without throwing' {
#             {
#                 Invoke-Build -Task 'build_guestconfiguration_packages' -File $taskAlias.Definition @mockTaskParameters
#             } | Should -Not -Throw
#         }
#     }
}
