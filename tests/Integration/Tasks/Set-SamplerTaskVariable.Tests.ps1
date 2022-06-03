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

<#
    This test need to change the variable names that are used in the pipeline to
    properly mock the code being tested.
    The current values are saved and set back at the end of the test.
#>

Describe 'Set-SamplerTaskVariable' {
    BeforeAll {
        # Remember the original (current) values from the pipeline.
        $originalBuildRoot = $BuildRoot
        $originalProjectName = $ProjectName
        $originalSourcePath = $SourcePath
        $originalModuleVersion = $ModuleVersion
        $originalModuleManifestPath = $ModuleManifestPath
        $originalOutputDirectory = $OutputDirectory
        $originalBuiltModuleSubdirectory = $BuiltModuleSubdirectory
        $originalReleaseNotesPath = $ReleaseNotesPath
        $originalVersionedOutputDirectory = $VersionedOutputDirectory
        $originalBuiltModuleManifest = $BuiltModuleManifest
        $originalBuiltModuleBase = $BuiltModuleBase
        $originalModuleVersionFolder = $ModuleVersionFolder
        $originalPreReleaseTag = $PreReleaseTag
        $originalBuiltModuleRootScriptPath = $BuiltModuleRootScriptPath
        $originalBuildInfo = if ($BuildInfo)
        {
            $BuildInfo.Clone()
        }
    }

    Context 'When calling the function with parameter AsNewBuild' {
        BeforeAll {
            # Mock BuildInfo
            $BuildInfo = @{}

            # Mock InvokeBuild variable $BuildRoot.
            $BuildRoot = Join-Path -Path $TestDrive -ChildPath 'MyProject'

            # Remove parent scope's value.
            $ProjectName = $null
            $SourcePath = $null

            $OutputDirectory = 'output'
            $BuiltModuleSubdirectory = ''
            $ReleaseNotesPath = 'ReleaseNotes.md'

            Mock -CommandName Get-SamplerProjectName -MockWith {
                return 'MyProject'
            }

            Mock -CommandName Get-SamplerSourcePath -MockWith {
                return (Join-Path -Path $TestDrive -ChildPath 'MyProject/source')
            }

            Mock -CommandName Get-BuildVersion -MockWith {
                return '1.0.0-preview'
            }
        }

        AfterAll {
            # Revert to the original values, so that the pipeline do not break.
            $BuildRoot = $originalBuildRoot
            $ProjectName = $originalProjectName
            $SourcePath = $originalSourcePath
            $OutputDirectory = $originalOutputDirectory
            $BuiltModuleSubdirectory = $originalBuiltModuleSubdirectory
            $ReleaseNotesPath = $originalReleaseNotesPath

            if ($originalBuildInfo)
            {
                $BuildInfo = $originalBuildInfo.Clone()
            }
        }

        It 'Should return the expected output' {
            <#
                Since Sampler adds its own alias in build.ps1 that does not point
                to the built module's Set-SamplerTaskVariable we must point
                out that the alias to test is the one in the module.
            #>
            $result = . Sampler\Set-SamplerTaskVariable -AsNewBuild

            Write-Debug ($result | Out-String) -Verbose

            $result | Should -Contain "`tProject Name               = 'MyProject'"
            $result | Should -Contain ("`tSource Path                = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/source'))
            $result | Should -Contain ("`tOutput Directory           = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/output'))
            $result | Should -Contain ("`tBuilt Module Subdirectory  = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/output/'))
            $result | Should -Contain ("`tModule Manifest Path (src) = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/source/MyProject.psd1'))
            $result | Should -Contain "`tModule Version             = '1.0.0-preview'"
            $result | Should -Contain ("`tRelease Notes path         = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/output/ReleaseNotes.md'))
        }

        Context 'When BuiltSubModuleDirectory is set on parameter' {
            BeforeAll {
                $BuiltModuleSubdirectory = 'SubDir1'
            }

            AfterAll {
                $BuiltModuleSubdirectory = $originalBuiltModuleSubdirectory
            }

            It 'Should return the expected output' {
                $result = . Sampler\Set-SamplerTaskVariable -AsNewBuild

                Write-Debug ($result | Out-String) -Verbose

                $result | Should -Contain "`tProject Name               = 'MyProject'"
                $result | Should -Contain ("`tSource Path                = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/source'))
                $result | Should -Contain ("`tOutput Directory           = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/output'))
                $result | Should -Contain ("`tBuilt Module Subdirectory  = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/output/SubDir1'))
                $result | Should -Contain ("`tModule Manifest Path (src) = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/source/MyProject.psd1'))
                $result | Should -Contain "`tModule Version             = '1.0.0-preview'"
                $result | Should -Contain ("`tRelease Notes path         = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/output/ReleaseNotes.md'))
            }
        }

        Context 'When BuiltSubModuleDirectory is set in the build configuration file' {
            BeforeAll {
                $BuiltModuleSubdirectory = ''
                $BuildInfo['BuiltModuleSubdirectory'] = 'SubDir2'
            }

            AfterAll {
                $BuiltModuleSubdirectory = $originalBuiltModuleSubdirectory

                if ($originalBuildInfo)
                {
                    $BuildInfo['BuiltModuleSubdirectory'] = $originalBuildInfo['BuiltModuleSubdirectory']
                }
            }

            It 'Should return the expected output' {
                $result = . Sampler\Set-SamplerTaskVariable -AsNewBuild -Verbose

                Write-Debug ($result | Out-String) -Verbose

                $result | Should -Contain "`tProject Name               = 'MyProject'"
                $result | Should -Contain ("`tSource Path                = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/source'))
                $result | Should -Contain ("`tOutput Directory           = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/output'))
                $result | Should -Contain ("`tBuilt Module Subdirectory  = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/output/SubDir2'))
                $result | Should -Contain ("`tModule Manifest Path (src) = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/source/MyProject.psd1'))
                $result | Should -Contain "`tModule Version             = '1.0.0-preview'"
                $result | Should -Contain ("`tRelease Notes path         = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/output/ReleaseNotes.md'))
            }
        }

        Context 'When BuiltSubModuleDirectory is set in the build configuration file and on parameter' {
            BeforeAll {
                $BuiltModuleSubdirectory = 'SubDir3'
                $BuildInfo['BuiltModuleSubdirectory'] = 'SubDirFile'
            }

            AfterAll {
                $BuiltModuleSubdirectory = $originalBuiltModuleSubdirectory

                if ($originalBuildInfo)
                {
                    $BuildInfo['BuiltModuleSubdirectory'] = $originalBuildInfo['BuiltModuleSubdirectory']
                }
            }

            It 'Should return the expected output' {
                $result = . Sampler\Set-SamplerTaskVariable -AsNewBuild

                Write-Debug ($result | Out-String) -Verbose

                $result | Should -Contain "`tProject Name               = 'MyProject'"
                $result | Should -Contain ("`tSource Path                = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/source'))
                $result | Should -Contain ("`tOutput Directory           = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/output'))
                $result | Should -Contain ("`tBuilt Module Subdirectory  = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/output/SubDir3'))
                $result | Should -Contain ("`tModule Manifest Path (src) = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/source/MyProject.psd1'))
                $result | Should -Contain "`tModule Version             = '1.0.0-preview'"
                $result | Should -Contain ("`tRelease Notes path         = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/output/ReleaseNotes.md'))
            }
        }
    }

    Context 'When calling the function without a parameter' {
        BeforeAll {
            # Mock BuildInfo
            $BuildInfo = @{}

            # Mock InvokeBuild variable $BuildRoot.
            $BuildRoot = Join-Path -Path $TestDrive -ChildPath 'MyProject'

            # Remove parent scope's value.
            $ProjectName = $null
            $SourcePath = $null

            $OutputDirectory = 'output'
            $BuiltModuleSubdirectory = ''
            $ReleaseNotesPath = 'ReleaseNotes.md'

            $VersionedOutputDirectory = $true

            Mock -CommandName Get-SamplerProjectName -MockWith {
                return 'MyProject'
            }

            Mock -CommandName Get-SamplerSourcePath -MockWith {
                return (Join-Path -Path $TestDrive -ChildPath 'MyProject/source')
            }

            $mockBuiltModuleManifest = Join-Path -Path $TestDrive -ChildPath 'MyProject/output/MyProject/1.0.0-preview/MyProject.psd1'

            Mock -CommandName Get-SamplerBuiltModuleManifest -MockWith {
                return $mockBuiltModuleManifest
            }

            Mock -CommandName Get-Item -MockWith {
                return @{
                    FullName = $mockBuiltModuleManifest
                }
            } -ParameterFilter {
                $Path -eq $mockBuiltModuleManifest
            }

            $mockBuiltModuleBase = Join-Path -Path $TestDrive -ChildPath 'MyProject/output/MyProject/1.0.0-preview'

            Mock -CommandName Get-SamplerBuiltModuleBase -MockWith {
                return $mockBuiltModuleBase
            }

            Mock -CommandName Get-Item -MockWith {
                return @{
                    FullName = $mockBuiltModuleBase
                }
            } -ParameterFilter {
                $Path -eq $mockBuiltModuleBase
            }

            Mock -CommandName Get-BuiltModuleVersion -MockWith {
                return '1.0.0-preview'
            }

            $mockBuiltModuleRootScriptPath = Join-Path -Path $TestDrive -ChildPath 'MyProject/output/MyProject/1.0.0-preview/MyProject.psm1'

            Mock -CommandName Get-SamplerModuleRootPath -MockWith {
                return $mockBuiltModuleRootScriptPath
            }

            Mock -CommandName Get-Item -MockWith {
                return @{
                    FullName = $mockBuiltModuleRootScriptPath
                }
            } -ParameterFilter {
                $Path -eq $mockBuiltModuleRootScriptPath
            }
        }

        AfterAll {
            # Revert to the original values, so that the pipeline do not break.
            $BuildRoot = $originalBuildRoot
            $ProjectName = $originalProjectName
            $SourcePath = $originalSourcePath
            $OutputDirectory = $originalOutputDirectory
            $BuiltModuleSubdirectory = $originalBuiltModuleSubdirectory
            $ReleaseNotesPath = $originalReleaseNotesPath

            if ($originalBuildInfo)
            {
                $BuildInfo = $originalBuildInfo.Clone()
            }
        }

        It 'Should return the expected output' {
            <#
                Since Sampler adds its own alias in build.ps1 that does not point
                to the built module's Set-SamplerTaskVariable we must point
                out that the alias to test is the one in the module.
            #>
            $result = . Sampler\Set-SamplerTaskVariable

            Write-Debug ($result | Out-String) -Verbose

            $result | Should -Contain "`tProject Name               = 'MyProject'"
            $result | Should -Contain ("`tSource Path                = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/source'))
            $result | Should -Contain ("`tOutput Directory           = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/output'))
            $result | Should -Contain ("`tBuilt Module Subdirectory  = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/output/'))
            $result | Should -Contain ("`tModule Manifest Path (src) = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/source/MyProject.psd1'))
            $result | Should -Contain "`tModule Version             = '1.0.0-preview'"
            $result | Should -Contain ("`tRelease Notes path         = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/output/ReleaseNotes.md'))

            $result | Should -Contain "`tVersioned Output Directory = 'True'"
            $result | Should -Contain ("`tBuilt Module Manifest      = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject\output\MyProject\1.0.0-preview\MyProject.psd1'))
            $result | Should -Contain ("`tBuilt Module Base          = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject\output\MyProject\1.0.0-preview'))
            $result | Should -Contain "`tModule Version Folder      = '1.0.0'"
            $result | Should -Contain "`tPre-release Tag            = 'preview'"
            $result | Should -Contain ("`tBuilt Module Root Script   = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject\output\MyProject\1.0.0-preview\MyProject.psm1'))
        }

        Context 'When BuiltSubModuleDirectory is set on parameter' {
            BeforeAll {
                $BuiltModuleSubdirectory = 'SubDir4'
                $mockBuiltModuleManifest = Join-Path -Path $TestDrive -ChildPath 'MyProject/output/SubDir4/MyProject/1.0.0-preview/MyProject.psd1'
                $mockBuiltModuleBase = Join-Path -Path $TestDrive -ChildPath 'MyProject/output/SubDir4/MyProject/1.0.0-preview'
                $mockBuiltModuleRootScriptPath = Join-Path -Path $TestDrive -ChildPath 'MyProject/output/SubDir4/MyProject/1.0.0-preview/MyProject.psm1'
            }

            AfterAll {
                $BuiltModuleSubdirectory = $originalBuiltModuleSubdirectory
            }

            It 'Should return the expected output' {
                <#
                    Since Sampler adds its own alias in build.ps1 that does not point
                    to the built module's Set-SamplerTaskVariable we must point
                    out that the alias to test is the one in the module.
                #>
                $result = . Sampler\Set-SamplerTaskVariable

                Write-Debug ($result | Out-String) -Verbose

                $result | Should -Contain "`tProject Name               = 'MyProject'"
                $result | Should -Contain ("`tSource Path                = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/source'))
                $result | Should -Contain ("`tOutput Directory           = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/output'))
                $result | Should -Contain ("`tBuilt Module Subdirectory  = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/output/SubDir4'))
                $result | Should -Contain ("`tModule Manifest Path (src) = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/source/MyProject.psd1'))
                $result | Should -Contain "`tModule Version             = '1.0.0-preview'"
                $result | Should -Contain ("`tRelease Notes path         = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/output/ReleaseNotes.md'))

                $result | Should -Contain "`tVersioned Output Directory = 'True'"
                $result | Should -Contain ("`tBuilt Module Manifest      = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject\output\SubDir4\MyProject\1.0.0-preview\MyProject.psd1'))
                $result | Should -Contain ("`tBuilt Module Base          = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject\output\SubDir4\MyProject\1.0.0-preview'))
                $result | Should -Contain "`tModule Version Folder      = '1.0.0'"
                $result | Should -Contain "`tPre-release Tag            = 'preview'"
                $result | Should -Contain ("`tBuilt Module Root Script   = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject\output\SubDir4\MyProject\1.0.0-preview\MyProject.psm1'))
            }
        }

        Context 'When BuiltSubModuleDirectory is set in the build configuration file' {
            BeforeAll {
                $BuiltModuleSubdirectory = ''
                $BuildInfo['BuiltModuleSubdirectory'] = 'SubDir5'
                $mockBuiltModuleManifest = Join-Path -Path $TestDrive -ChildPath 'MyProject/output/SubDir5/MyProject/1.0.0-preview/MyProject.psd1'
                $mockBuiltModuleBase = Join-Path -Path $TestDrive -ChildPath 'MyProject/output/SubDir5/MyProject/1.0.0-preview'
                $mockBuiltModuleRootScriptPath = Join-Path -Path $TestDrive -ChildPath 'MyProject/output/SubDir5/MyProject/1.0.0-preview/MyProject.psm1'
            }

            AfterAll {
                $BuiltModuleSubdirectory = $originalBuiltModuleSubdirectory

                if ($originalBuildInfo)
                {
                    $BuildInfo['BuiltModuleSubdirectory'] = $originalBuildInfo['BuiltModuleSubdirectory']
                }
            }

            It 'Should return the expected output' {
                <#
                    Since Sampler adds its own alias in build.ps1 that does not point
                    to the built module's Set-SamplerTaskVariable we must point
                    out that the alias to test is the one in the module.
                #>
                $result = . Sampler\Set-SamplerTaskVariable -Verbose

                Write-Debug ($result | Out-String) -Verbose

                $result | Should -Contain "`tProject Name               = 'MyProject'"
                $result | Should -Contain ("`tSource Path                = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/source'))
                $result | Should -Contain ("`tOutput Directory           = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/output'))
                $result | Should -Contain ("`tBuilt Module Subdirectory  = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/output/SubDir5'))
                $result | Should -Contain ("`tModule Manifest Path (src) = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/source/MyProject.psd1'))
                $result | Should -Contain "`tModule Version             = '1.0.0-preview'"
                $result | Should -Contain ("`tRelease Notes path         = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/output/ReleaseNotes.md'))

                $result | Should -Contain "`tVersioned Output Directory = 'True'"
                $result | Should -Contain ("`tBuilt Module Manifest      = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject\output\SubDir5\MyProject\1.0.0-preview\MyProject.psd1'))
                $result | Should -Contain ("`tBuilt Module Base          = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject\output\SubDir5\MyProject\1.0.0-preview'))
                $result | Should -Contain "`tModule Version Folder      = '1.0.0'"
                $result | Should -Contain "`tPre-release Tag            = 'preview'"
                $result | Should -Contain ("`tBuilt Module Root Script   = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject\output\SubDir5\MyProject\1.0.0-preview\MyProject.psm1'))
            }
        }

        Context 'When BuiltSubModuleDirectory is set in the build configuration file and on parameter' {
            BeforeAll {
                $BuiltModuleSubdirectory = 'SubDir6'
                $BuildInfo['BuiltModuleSubdirectory'] = 'SubDirFile'
                $mockBuiltModuleManifest = Join-Path -Path $TestDrive -ChildPath 'MyProject/output/SubDir6/MyProject/1.0.0-preview/MyProject.psd1'
                $mockBuiltModuleBase = Join-Path -Path $TestDrive -ChildPath 'MyProject/output/SubDir6/MyProject/1.0.0-preview'
                $mockBuiltModuleRootScriptPath = Join-Path -Path $TestDrive -ChildPath 'MyProject/output/SubDir6/MyProject/1.0.0-preview/MyProject.psm1'
            }

            AfterAll {
                $BuiltModuleSubdirectory = $originalBuiltModuleSubdirectory

                if ($originalBuildInfo)
                {
                    $BuildInfo['BuiltModuleSubdirectory'] = $originalBuildInfo['BuiltModuleSubdirectory']
                }
            }

            It 'Should return the expected output with parameter priority' {
                <#
                    Since Sampler adds its own alias in build.ps1 that does not point
                    to the built module's Set-SamplerTaskVariable we must point
                    out that the alias to test is the one in the module.
                #>
                $result = . Sampler\Set-SamplerTaskVariable

                Write-Debug ($result | Out-String) -Verbose

                $result | Should -Contain "`tProject Name               = 'MyProject'"
                $result | Should -Contain ("`tSource Path                = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/source'))
                $result | Should -Contain ("`tOutput Directory           = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/output'))
                $result | Should -Contain ("`tBuilt Module Subdirectory  = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/output/SubDir6'))
                $result | Should -Contain ("`tModule Manifest Path (src) = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/source/MyProject.psd1'))
                $result | Should -Contain "`tModule Version             = '1.0.0-preview'"
                $result | Should -Contain ("`tRelease Notes path         = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject/output/ReleaseNotes.md'))

                $result | Should -Contain "`tVersioned Output Directory = 'True'"
                $result | Should -Contain ("`tBuilt Module Manifest      = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject\output\SubDir6\MyProject\1.0.0-preview\MyProject.psd1'))
                $result | Should -Contain ("`tBuilt Module Base          = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject\output\SubDir6\MyProject\1.0.0-preview'))
                $result | Should -Contain "`tModule Version Folder      = '1.0.0'"
                $result | Should -Contain "`tPre-release Tag            = 'preview'"
                $result | Should -Contain ("`tBuilt Module Root Script   = '{0}'" -f (Join-Path -Path $TestDrive -ChildPath 'MyProject\output\SubDir6\MyProject\1.0.0-preview\MyProject.psm1'))
            }
        }
    }

    It 'Should have set all values back to original pipeline values' {
        $BuildRoot | Should -Be $originalBuildRoot
        $ProjectName | Should -Be $originalProjectName
        $SourcePath | Should -Be $originalSourcePath
        $OutputDirectory | Should -Be $originalOutputDirectory
        $BuiltModuleSubdirectory | Should -Be $originalBuiltModuleSubdirectory
        $ModuleManifestPath | Should -Be $originalModuleManifestPath
        $ModuleVersion | Should -Be $originalModuleVersion
        $ReleaseNotesPath | Should -Be $originalReleaseNotesPath
        $VersionedOutputDirectory | Should -Be $originalVersionedOutputDirectory
        $BuiltModuleManifest | Should -Be $originalBuiltModuleManifest
        $BuiltModuleBase | Should -Be $originalBuiltModuleBase
        $ModuleVersionFolder | Should -Be $originalModuleVersionFolder
        $PreReleaseTag | Should -Be $originalPreReleaseTag
        $BuiltModuleRootScriptPath | Should -Be $originalBuiltModuleRootScriptPath

        foreach ($buildKey in $BuildInfo.Keys)
        {
            $BuildInfo[$buildKey] | Should -Be $originalBuildInfo[$buildKey]
        }
    }
}
