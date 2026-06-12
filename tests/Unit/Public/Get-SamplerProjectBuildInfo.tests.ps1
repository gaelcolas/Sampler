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

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Module -Name $script:moduleName
}

Describe 'Get-SamplerProjectBuildInfo' {
    BeforeAll {
        $defaultSetupParameters = @{
            ProjectPath              = (Join-Path -Path $TestDrive -ChildPath 'repo')
            OutputDirectory          = (Join-Path -Path $TestDrive -ChildPath 'output')
            BuiltModuleSubdirectory  = ''
            VersionedOutputDirectory = $true
            ProjectName              = 'MyModule'
            SourcePath               = (Join-Path -Path $TestDrive -ChildPath 'source')
            ModuleVersion            = '1.2.3'
            BuildInfo                = @{ }
        }

        Mock -CommandName Get-SamplerProjectName
        Mock -CommandName Get-SamplerSourcePath
        Mock -CommandName Get-SamplerProjectModuleManifest
    }

    Context 'When source root has no valid module manifest' {
        BeforeAll {
            Mock -CommandName Get-ChildItem -MockWith {
                return @(
                    [PSCustomObject] @{ FullName = (Join-Path -Path $TestDrive -ChildPath 'source/MyModule.psd1'); Name = 'MyModule.psd1'; BaseName = 'MyModule' }
                )
            }

            Mock -CommandName Test-ModuleManifest -MockWith {
                return [PSCustomObject] @{
                    Version     = '1.2.3'
                    Guid        = [System.Guid]::Empty
                    Author      = 'Sampler'
                    Description = 'Test'
                }
            }
        }

        It 'Should return Other build type and no built output' {
            $result = Sampler\Get-SamplerProjectBuildInfo @defaultSetupParameters

            $result.BuildType | Should -Be 'Other'
            $result.HasBuiltOutput | Should -BeFalse
        }
    }

    Context 'When source root has valid module manifest and built output does not exist' {
        BeforeAll {
            $script:expectedBuiltManifestPath =
                Join-Path -Path $TestDrive -ChildPath 'output/module/MyModule/1.2.3/MyModule.psd1'

            Mock -CommandName Get-ChildItem -MockWith {
                return @(
                    [PSCustomObject] @{ FullName = (Join-Path -Path $TestDrive -ChildPath 'source/MyModule.psd1'); Name = 'MyModule.psd1'; BaseName = 'MyModule' }
                )
            }

            Mock -CommandName Test-ModuleManifest -MockWith {
                return [PSCustomObject] @{
                    Version     = '1.2.3'
                    Guid        = [System.Guid]::NewGuid()
                    Author      = 'Sampler'
                    Description = 'Test'
                }
            }

            Mock -CommandName Get-SamplerBuiltModuleManifest -MockWith {
                return $script:expectedBuiltManifestPath
            }

            Mock -CommandName Get-Item -ParameterFilter {
                $Path -eq $script:expectedBuiltManifestPath
            }
        }

        It 'Should return PowerShellModule build type and no built output' {
            $result = Sampler\Get-SamplerProjectBuildInfo @defaultSetupParameters

            $result.BuildType | Should -Be 'PowerShellModule'
            $result.HasBuiltOutput | Should -BeFalse
        }
    }

    Context 'When source root has valid module manifest and built output exists' {
        BeforeAll {
            $script:expectedBuiltManifestPath =
                Join-Path -Path $TestDrive -ChildPath 'output/module/MyModule/1.2.3/MyModule.psd1'

            Mock -CommandName Get-ChildItem -MockWith {
                return @(
                    [PSCustomObject] @{ FullName = (Join-Path -Path $TestDrive -ChildPath 'source/MyModule.psd1'); Name = 'MyModule.psd1'; BaseName = 'MyModule' }
                )
            }

            Mock -CommandName Test-ModuleManifest -MockWith {
                return [PSCustomObject] @{
                    Version     = '1.2.3'
                    Guid        = [System.Guid]::NewGuid()
                    Author      = 'Sampler'
                    Description = 'Test'
                }
            }

            Mock -CommandName Get-SamplerBuiltModuleManifest -MockWith {
                return $script:expectedBuiltManifestPath
            }

            Mock -CommandName Get-Item -ParameterFilter {
                $Path -eq $script:expectedBuiltManifestPath
            } -MockWith {
                return [PSCustomObject] @{ FullName = $script:expectedBuiltManifestPath }
            }
        }

        It 'Should return PowerShellModule build type and built output' {
            $result = Sampler\Get-SamplerProjectBuildInfo @defaultSetupParameters

            $result.BuildType | Should -Be 'PowerShellModule'
            $result.HasBuiltOutput | Should -BeTrue
        }
    }

    Context 'When project name and module version are empty' {
        BeforeAll {
            Mock -CommandName Get-SamplerProjectName
            Mock -CommandName Get-SamplerSourcePath
            Mock -CommandName Get-SamplerProjectModuleManifest
        }

        It 'Should use the project path leaf and leave module version empty' {
            $emptyIdentityParameters = @{
                ProjectPath              = (Join-Path -Path $TestDrive -ChildPath 'RepoRoot')
                OutputDirectory          = (Join-Path -Path $TestDrive -ChildPath 'output')
                BuiltModuleSubdirectory  = ''
                VersionedOutputDirectory = $true
                ProjectName              = ''
                SourcePath               = ''
                ModuleVersion            = ''
                BuildInfo                = @{ }
            }

            $result = Sampler\Get-SamplerProjectBuildInfo @emptyIdentityParameters

            $result.ProjectName | Should -Be 'RepoRoot'
            $result.ModuleVersion | Should -BeNullOrEmpty
        }
    }

    Context 'When source path cannot be inferred from a manifest or conventional folder' {
        BeforeAll {
            Mock -CommandName Get-SamplerProjectModuleManifest
            Mock -CommandName Test-Path -MockWith {
                return $false
            }
        }

        It 'Should use the project path as the source path' {
            $sourceFallbackParameters = @{
                ProjectPath              = (Join-Path -Path $TestDrive -ChildPath 'PipelineRepo')
                OutputDirectory          = (Join-Path -Path $TestDrive -ChildPath 'output')
                BuiltModuleSubdirectory  = ''
                VersionedOutputDirectory = $true
                ProjectName              = ''
                SourcePath               = ''
                ModuleVersion            = ''
                BuildInfo                = @{ }
            }

            $result = Sampler\Get-SamplerProjectBuildInfo @sourceFallbackParameters

            $result.SourcePath | Should -Be (Join-Path -Path $TestDrive -ChildPath 'PipelineRepo')
            $result.BuildType | Should -Be 'Other'
        }
    }
}
