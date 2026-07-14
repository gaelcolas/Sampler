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

Describe 'Set-SamplerTaskVariable' {
    It 'Should have exported the alias correctly' {
        <#
            Need to add scope global to get the alias that is exported by the module,
            not the alias that is exported by build.ps1 into local session (to be
            able to dogfood itself).
        #>
        $taskAlias = Get-Alias -Name 'Set-SamplerTaskVariable' -Scope 'Global'

        $taskAlias.Name | Should -Be 'Set-SamplerTaskVariable'
        $taskAlias.ReferencedCommand | Should -Be 'Set-SamplerTaskVariable.ps1'
        $taskAlias.Definition | Should -Match 'Sampler[\/|\\]\d+\.\d+\.\d+[\/|\\]scripts[\/|\\]Set-SamplerTaskVariable\.ps1'
    }

    Context 'When called with parameter AsNewBuild' {
        BeforeAll {
            $BuildRoot = $TestDrive

            $ProjectName = $null
            $SourcePath = $null
            $OutputDirectory = 'output'
            $ReleaseNotesPath = $null
            $BuiltModuleSubDirectory = 'builtModule'
            $ModuleManifestPath = $null
            $ChocolateyBuildOutput = 'choco'
            $ModuleVersion = $null

            Mock -CommandName Get-SamplerProjectName -MockWith {
                return 'MyModule'
            }

            Mock -CommandName Get-SamplerSourcePath -MockWith {
                return (Join-Path -Path $TestDrive -ChildPath 'source')
            }

            Mock -CommandName Get-SamplerProjectBuildInfo -MockWith {
                return @{
                    ProjectName    = 'MyModule'
                    SourcePath     = (Join-Path -Path $TestDrive -ChildPath 'source')
                    ModuleVersion  = $null
                    BuildType      = 'PowerShellModule'
                    HasBuiltOutput = $false
                }
            }

            Mock -CommandName Get-SamplerAbsolutePath -ParameterFilter {
                $Path -eq 'MyModule.psd1'
            } -MockWith {
                return (Join-Path -Path $TestDrive -ChildPath (Join-Path -Path 'source' -ChildPath 'MyModule.psd1'))
            }

            <#
                Default (catch-all) mock for any other Path/RelativeTo combination
                resolved by Set-SamplerTaskVariable.ps1 (e.g. $OutputDirectory,
                $ReleaseNotesPath, $BuiltModuleSubDirectory, $ChocolateyBuildOutput).
                Mimics the real Get-SamplerAbsolutePath behavior of joining a
                relative $Path onto $RelativeTo.
            #>
            Mock -CommandName Get-SamplerAbsolutePath -MockWith {
                if ([System.String]::IsNullOrEmpty($Path))
                {
                    return $RelativeTo
                }

                if ([System.Io.Path]::IsPathRooted($Path))
                {
                    return $Path
                }

                return (Join-Path -Path $RelativeTo -ChildPath $Path)
            }

            Mock -CommandName Get-SamplerBuildVersion -MockWith {
                return '2.0.0'
            }
        }

        It 'Should run the scripts and return correct values for variables' {
            . Sampler\Set-SamplerTaskVariable -AsNewBuild

            $ProjectName | Should -Be 'MyModule'
            $SourcePath | Should -Be (Join-Path -Path $TestDrive -ChildPath 'source')
            $OutputDirectory | Should -Be (Join-Path -Path $TestDrive -ChildPath 'output')
            $ReleaseNotesPath.TrimEnd('\/') | Should -Be (Join-Path -Path $TestDrive -ChildPath 'output')
            $BuiltModuleSubDirectory | Should -Be (Join-Path -Path $TestDrive -ChildPath (Join-Path -Path 'output' -ChildPath 'builtModule'))
            $ChocolateyBuildOutput | Should -Be (Join-Path -Path $TestDrive -ChildPath (Join-Path -Path 'output' -ChildPath 'choco'))
            $ModuleManifestPath | Should -Be (Join-Path -Path $TestDrive -ChildPath (Join-Path -Path 'source' -ChildPath 'MyModule.psd1'))
            $ModuleVersion | Should -Be '2.0.0'
        }
    }

    Context 'When called from a Chocolatey task' {
        BeforeAll {
            $BuildRoot = $TestDrive

            $ProjectName = $null
            $SourcePath = $null
            $OutputDirectory = 'output'
            $ReleaseNotesPath = $null
            $BuiltModuleSubDirectory = 'builtModule'
            $ModuleManifestPath = $null
            $ChocolateyBuildOutput = 'choco'
            $ModuleVersion = $null

            Mock -CommandName Get-SamplerProjectName -MockWith {
                return 'MyModule'
            }

            Mock -CommandName Get-SamplerSourcePath -MockWith {
                return (Join-Path -Path $TestDrive -ChildPath 'source')
            }

            Mock -CommandName Get-SamplerProjectBuildInfo -MockWith {
                return @{
                    ProjectName    = 'MyModule'
                    SourcePath     = (Join-Path -Path $TestDrive -ChildPath 'source')
                    ModuleVersion  = $null
                    BuildType      = 'PowerShellModule'
                    HasBuiltOutput = $false
                }
            }

            Mock -CommandName Get-SamplerAbsolutePath -ParameterFilter {
                $Path -eq 'MyModule.psd1'
            } -MockWith {
                return (Join-Path -Path $TestDrive -ChildPath (Join-Path -Path 'source' -ChildPath 'MyModule.psd1'))
            }

            <#
                Default (catch-all) mock for any other Path/RelativeTo combination
                resolved by Set-SamplerTaskVariable.ps1 (e.g. $OutputDirectory,
                $ReleaseNotesPath, $BuiltModuleSubDirectory, $ChocolateyBuildOutput).
                Mimics the real Get-SamplerAbsolutePath behavior of joining a
                relative $Path onto $RelativeTo.
            #>
            Mock -CommandName Get-SamplerAbsolutePath -MockWith {
                if ([System.String]::IsNullOrEmpty($Path))
                {
                    return $RelativeTo
                }

                if ([System.Io.Path]::IsPathRooted($Path))
                {
                    return $Path
                }

                return (Join-Path -Path $RelativeTo -ChildPath $Path)
            }

            Mock -CommandName Get-SamplerBuildVersion -MockWith {
                return '2.0.0'
            }
        }

        It 'Should run the scripts and return correct values for variables' {
            . Sampler\Set-SamplerTaskVariable -AsNewBuild -ArtifactContext 'Chocolatey'

            $ProjectName | Should -Be 'MyModule'
            $SourcePath | Should -Be (Join-Path -Path $TestDrive -ChildPath 'source')
            $OutputDirectory | Should -Be (Join-Path -Path $TestDrive -ChildPath 'output')
            $ReleaseNotesPath.TrimEnd('\/') | Should -Be (Join-Path -Path $TestDrive -ChildPath 'output')
            $BuiltModuleSubDirectory | Should -Be (Join-Path -Path $TestDrive -ChildPath (Join-Path -Path 'output' -ChildPath 'builtModule'))
            $ChocolateyBuildOutput | Should -Be (Join-Path -Path $TestDrive -ChildPath (Join-Path -Path 'output' -ChildPath 'choco'))
            $ModuleManifestPath | Should -Be (Join-Path -Path $TestDrive -ChildPath (Join-Path -Path 'source' -ChildPath 'MyModule.psd1'))
            $ModuleVersion | Should -Be '2.0.0'
        }
    }

    Context 'When called without any parameter' {
        BeforeAll {
            # Dot-source mocks (this is also used in unit tests for build tasks)
            . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable
        }

        It 'Should run the scripts and return correct values for variables' {
            . Sampler\Set-SamplerTaskVariable

            $ProjectName | Should -Be 'MyModule'
            $SourcePath | Should -Be (Join-Path -Path $TestDrive -ChildPath 'source')
            $OutputDirectory | Should -Be (Join-Path -Path $TestDrive -ChildPath 'output')
            $ReleaseNotesPath.TrimEnd('\/') | Should -Be (Join-Path -Path $TestDrive -ChildPath 'output')
            $BuiltModuleSubDirectory | Should -Be (Join-Path -Path $TestDrive -ChildPath (Join-Path -Path 'output' -ChildPath 'builtModule'))
            $ChocolateyBuildOutput | Should -Be (Join-Path -Path $TestDrive -ChildPath (Join-Path -Path 'output' -ChildPath 'choco'))
            $ModuleManifestPath | Should -Be (Join-Path -Path $TestDrive -ChildPath (Join-Path -Path 'source' -ChildPath 'MyModule.psd1'))
            $VersionedOutputDirectory | Should -BeTrue

            $BuiltModuleManifest | Should -Be (
                Join-Path -Path $TestDrive -ChildPath 'output' |
                    Join-Path -ChildPath 'builtModule' |
                    Join-Path -ChildPath 'MyModule' |
                    Join-Path -ChildPath '2.0.0' |
                    Join-Path -ChildPath 'MyModule.psd1'
            )

            $BuiltModuleBase | Should -Be (
                Join-Path -Path $TestDrive -ChildPath 'output' |
                    Join-Path -ChildPath 'builtModule' |
                    Join-Path -ChildPath 'MyModule' |
                    Join-Path -ChildPath '2.0.0'
            )

            $ModuleVersion | Should -Be '2.0.0'
            $ModuleVersionFolder | Should -Be '2.0.0'

            $BuiltModuleRootScriptPath | Should -Be (
                Join-Path -Path $TestDrive -ChildPath 'output' |
                    Join-Path -ChildPath 'builtModule' |
                    Join-Path -ChildPath 'MyModule' |
                    Join-Path -ChildPath '2.0.0' |
                    Join-Path -ChildPath 'MyModule.psm1'
            )
        }

        It 'Should throw when the module build output does not exist' {
            Mock -CommandName Get-Item -MockWith {
                return $null
            } -ParameterFilter {
                $Path -contains (
                    Join-Path -Path $TestDrive -ChildPath 'output' |
                        Join-Path -ChildPath 'builtModule' |
                        Join-Path -ChildPath 'MyModule' |
                        Join-Path -ChildPath '2.0.0' |
                        Join-Path -ChildPath 'MyModule.psd1'
                )
            }

            { . Sampler\Set-SamplerTaskVariable } |
                Should -Throw -ExpectedMessage "Could not find the built module manifest for module 'MyModule'. Build the module before running tasks that require the built module output."
        }
    }
}
