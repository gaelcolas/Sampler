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

        Should -Invoke -CommandName Copy-Item -Exactly -Times 1 -Scope It
    }
}

Describe 'copy_paths_to_choco_staging' {
    BeforeAll {
        # Dot-source mocks
        . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

        $taskAlias = Get-Alias -Name 'ChocolateyPackage.build.Sampler.ib.tasks'

        $mockTaskParameters = @{
            SourcePath = Join-Path -Path $TestDrive -ChildPath 'MyModule/source'
            ProjectName = 'MyModule'
        }
    }

    Context 'When there is a package to copy' {
        BeforeAll {
            Mock -CommandName Get-ChildItem -ParameterFilter {
                $Path -match 'choco'
            } -MockWith {
                return @{
                    BaseName = 'MyPackage1'
                }
            }

            Mock -CommandName Copy-Item
        }

        Context 'When using Recurse' {
            BeforeAll {
                $BuildInfo = @{
                    Chocolatey = @{
                        copyToPackage = @{
                            Source = 'output\RequiredModules\Plaster'
                            Destination = 'MyPackage'
                            Recurse = $true
                            Exclude = 'NotThisFile*'
                            Force = $true
                        }
                    }
                }
            }

            It 'Should run the build task without throwing' {
                {
                    Invoke-Build -Task 'copy_paths_to_choco_staging' -File $taskAlias.Definition @mockTaskParameters
                } | Should -Not -Throw

                Should -Invoke -CommandName Copy-Item -Exactly -Times 1 -Scope It
            }
        }

        Context 'When Recurse is not used' {
            BeforeAll {
                $BuildInfo = @{
                    Chocolatey = @{
                        copyToPackage = @{
                            Source = 'output\RequiredModules\Plaster'
                            Destination = 'MyPackage'
                            Recurse = $false
                            Exclude = 'NotThisFile*'
                            Force = $true
                        }
                    }
                }
            }

            It 'Should run the build task without throwing' {
                {
                    Invoke-Build -Task 'copy_paths_to_choco_staging' -File $taskAlias.Definition @mockTaskParameters
                } | Should -Not -Throw

                Should -Invoke -CommandName Copy-Item -Exactly -Times 1 -Scope It
            }
        }

        Context 'When specifying package' {
            BeforeAll {
                $BuildInfo = @{
                    Chocolatey = @{
                        copyToPackage = @{
                            Source = 'output\RequiredModules\Plaster'
                            Destination = 'MyPackage'
                            Recurse = $false
                            Exclude = 'NotThisFile*'
                            Force = $true
                            PackageName = 'MyPackage1'
                        }
                    }
                }
            }

            It 'Should run the build task without throwing' {
                {
                    Invoke-Build -Task 'copy_paths_to_choco_staging' -File $taskAlias.Definition @mockTaskParameters
                } | Should -Not -Throw

                Should -Invoke -CommandName Copy-Item -Exactly -Times 1 -Scope It
            }
        }

    }
}

Describe 'upate_choco_nuspec_data' {
    BeforeAll {
        # Dot-source mocks
        . $PSScriptRoot/../TestHelpers/MockSetSamplerTaskVariable

        $taskAlias = Get-Alias -Name 'ChocolateyPackage.build.Sampler.ib.tasks'

        $mockTaskParameters = @{
            SourcePath = Join-Path -Path $TestDrive -ChildPath 'MyModule/source'
            ProjectName = 'MyModule'
        }
    }

    Context 'When there is a staged package' {
        BeforeAll {
            $BuildInfo = @{
                Chocolatey = @{
                    xmlNamespaces = @{
                        nuspec = 'http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd'
                    }
                    UpdateNuspecData = @{
                        Version = @{
                            XPath = '/nuspec:package/nuspec:metadata/nuspec:version'
                            # This will be resolved to correct value in the task.
                            Version = '$ModuleVersion'
                        }
                        ReleaseNotes = @{
                            XPath = '/nuspec:package/nuspec:metadata/nuspec:releaseNotes'
                            # This will be resolved to correct value in the task.
                            Version = '$ReleaseNotes'
                        }
                    }
                }
            }

            # Mock no-existent ReleaseNotes.md
            Mock -CommandName Get-Content -ParameterFilter {
                $Path -match 'ReleaseNotes.md'
            }

            # Get release notes from the changelog
            Mock -CommandName Get-Content -ParameterFilter {
                $Path -match 'CHANGELOG.md'
            } -MockWith {
                return 'Mock changelog content'
            }

            $mockNuspecPath = $TestDrive | Join-Path -ChildPath 'MyPackage1'
            $mockNuspecFilePath = $mockNuspecPath | Join-Path -ChildPath 'MyPackage1.nuspec'

            $mockNuspecContent = @'
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="https://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">
  <metadata>
    <id>MyPackage1</id>
    <version>__REPLACE__</version>
    <packageSourceUrl>https://github.com/gaelcolas/MyChocoPackage</packageSourceUrl>
    <owners>MyName</owners>
    <title>MyChocoPackage1 (Install)</title>
    <authors>MyName</authors>
    <projectUrl>https://company.local/project</projectUrl>
    <iconUrl>null</iconUrl>
    <projectSourceUrl>https://company.local/project</projectSourceUrl>
    <tags>MyChocoPackage1 MyName</tags>
    <summary>MyChocoPackage1 package sources</summary>
    <description>MyChocoPackage1 example</description>
    <releaseNotes>__REPLACE_RELEASENOTES__</releaseNotes>
  </metadata>
  <files>
    <file src="tools/**" target="tools" />
  </files>
</package>
'@

            New-Item -Path $mockNuspecPath -ItemType 'Directory' -Force

            # Need to write the nuspec to file so the task can manipulate the XML.
            $mockNuspecContent | Out-File -FilePath $mockNuspecFilePath -NoClobber -Encoding 'UTF8' -Force | Out-Null

            Mock -CommandName Get-ChildItem -ParameterFilter {
                $Path -match 'choco'
            } -MockWith {
                return @{
                    BaseName = 'MyPackage1'
                    FullName = $mockNuspecPath
                }
            }

            Mock -CommandName Copy-Item
        }

        It 'Should run the build task without throwing' {
            {
                Invoke-Build -Task 'upate_choco_nuspec_data' -File $taskAlias.Definition @mockTaskParameters
            } | Should -Not -Throw
        }
    }
}
