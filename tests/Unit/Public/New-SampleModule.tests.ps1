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

    <#
        Plaster's `Invoke-Plaster` declares manifest-driven parameters via a
        `dynamicparam` block, so Pester's auto-generated mock proxy refuses
        any value the static signature does not list. To make the unit tests
        deterministic, replace `Invoke-Plaster` inside the Sampler module
        session with a static stub that mirrors every parameter the current
        `Templates/Sampler/plasterManifest.xml` exposes. The stub records the
        full bound-parameter set into a script-scoped variable so individual
        tests can assert on it without hitting the real Plaster pipeline.
    #>
    InModuleScope -ScriptBlock {
        function script:Invoke-Plaster
        {
            [CmdletBinding()]
            param (
                [Parameter()] [System.String]   $TemplatePath,
                [Parameter()] [System.String]   $DestinationPath,
                [Parameter()] [System.Management.Automation.SwitchParameter] $NoLogo,
                [Parameter()] [System.String]   $ModuleType,
                [Parameter()] [System.String[]] $Features,
                [Parameter()] [System.String]   $ModuleAuthor,
                [Parameter()] [System.String]   $ModuleName,
                [Parameter()] [System.String]   $ModuleDescription,
                [Parameter()] [System.String]   $CustomRepo,
                [Parameter()] [System.String]   $ModuleVersion,
                [Parameter()] [System.String]   $UseGit,
                [Parameter()] [System.String]   $MainGitBranch,
                [Parameter()] [System.String]   $UseGitVersion,
                [Parameter()] [System.String]   $UseCodeCovIo,
                [Parameter()] [System.String]   $UseGitHub,
                [Parameter()] [System.String]   $UseAzurePipelines,
                [Parameter()] [System.String]   $GitHubOwner,
                [Parameter()] [System.String]   $GitHubOwnerDscCommunity,
                [Parameter()] [System.String]   $UseVSCode,
                [Parameter()] [System.String]   $License,
                [Parameter()] [System.String]   $LicenseType,
                [Parameter()] [System.String]   $SourceDirectory
            )

            $script:capturedPlasterParameters = $PSBoundParameters
        }
    }
}

AfterAll {
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Module -Name $script:moduleName
}

BeforeDiscovery {
    $testCases = @(
        <#
            If the templates do not define those parameters, Invoke-Plaster will fail and this test will catch it.
            The template integration is done separately, hence why we don't need to test it here.
            We only test that the New-SampleModule parameters & parameter set work with the template we have defined.
        #>
        @{
            TestCaseName = 'CompleteSample_NoLicense'
            NewSampleModuleParameters = @{
                ModuleName      = 'MyModule'
                ModuleVersion   = '0.0.1'
                ModuleAuthor    = "test user"
                LicenseType     = 'None'
                ModuleType      = 'CompleteSample'
            }
        }
        @{
            TestCaseName = 'SimpleModule_MIT'
            NewSampleModuleParameters = @{
                ModuleName      = 'MyModule'
                ModuleVersion   = '0.0.1'
                ModuleAuthor    = "test user"
                LicenseType     = 'MIT'
                ModuleType      = 'SimpleModule'
            }
        }
    )
}

Describe New-SampleModule {
    Context 'Invoke plaster with correct parameters for template' {
        It 'New-Sample module should call Invoke-Plaster with test case <TestCaseName>' -ForEach $testCases {
            $NewSampleModuleParameters.DestinationPath = $TestDrive

            InModuleScope -Parameters @{ NewSampleModuleParameters = $NewSampleModuleParameters } -ScriptBlock {
                $script:capturedPlasterParameters = $null

                { New-SampleModule @NewSampleModuleParameters } | Should -Not -Throw

                $script:capturedPlasterParameters | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'When -Features is supplied without -ModuleType' {
        It 'Should auto-switch ModuleType to CustomModule so that -Features is honored by the template' {
            InModuleScope -Parameters @{ DestinationPath = $TestDrive } -ScriptBlock {
                $script:capturedPlasterParameters = $null

                $newSampleModuleParameters = @{
                    DestinationPath   = $DestinationPath
                    ModuleName        = 'testMod'
                    ModuleDescription = 'test module by features'
                    CustomRepo        = 'myrepo'
                    Features          = @('Enum', 'Classes', 'git', 'UnitTests')
                }

                { New-SampleModule @newSampleModuleParameters } | Should -Not -Throw

                $script:capturedPlasterParameters['ModuleType'] | Should -Be 'CustomModule'
            }
        }

        It 'Should derive every Use* template parameter from -Features so that no prompts are required' {
            InModuleScope -Parameters @{ DestinationPath = $TestDrive } -ScriptBlock {
                $script:capturedPlasterParameters = $null

                $newSampleModuleParameters = @{
                    DestinationPath   = $DestinationPath
                    ModuleName        = 'testMod'
                    ModuleDescription = 'test module by features'
                    CustomRepo        = 'myrepo'
                    Features          = @('Enum', 'Classes', 'git', 'UnitTests')
                }

                { New-SampleModule @newSampleModuleParameters } | Should -Not -Throw

                $script:capturedPlasterParameters['UseGit']            | Should -Be 'true'
                $script:capturedPlasterParameters['UseGitVersion']     | Should -Be 'false'
                $script:capturedPlasterParameters['UseGitHub']         | Should -Be 'false'
                $script:capturedPlasterParameters['UseAzurePipelines'] | Should -Be 'false'
                $script:capturedPlasterParameters['UseCodeCovIo']      | Should -Be 'false'
                $script:capturedPlasterParameters['UseVSCode']         | Should -Be 'false'
            }
        }

        It 'Should set every Use* template parameter to true when the All feature is selected' {
            InModuleScope -Parameters @{ DestinationPath = $TestDrive } -ScriptBlock {
                $script:capturedPlasterParameters = $null

                $newSampleModuleParameters = @{
                    DestinationPath   = $DestinationPath
                    ModuleName        = 'testMod'
                    ModuleDescription = 'test module by features'
                    Features          = @('All')
                }

                { New-SampleModule @newSampleModuleParameters } | Should -Not -Throw

                $script:capturedPlasterParameters['UseGit']            | Should -Be 'true'
                $script:capturedPlasterParameters['UseGitVersion']     | Should -Be 'true'
                $script:capturedPlasterParameters['UseGitHub']         | Should -Be 'true'
                $script:capturedPlasterParameters['UseAzurePipelines'] | Should -Be 'true'
                $script:capturedPlasterParameters['UseCodeCovIo']      | Should -Be 'true'
                $script:capturedPlasterParameters['UseVSCode']         | Should -Be 'true'
            }
        }

        It 'Should not auto-switch ModuleType when -ModuleType is explicitly supplied alongside -Features' {
            InModuleScope -Parameters @{ DestinationPath = $TestDrive } -ScriptBlock {
                $script:capturedPlasterParameters = $null

                $newSampleModuleParameters = @{
                    DestinationPath   = $DestinationPath
                    ModuleName        = 'testMod'
                    ModuleDescription = 'test module by features'
                    ModuleType        = 'SimpleModule'
                    Features          = @('git')
                }

                { New-SampleModule @newSampleModuleParameters } | Should -Not -Throw

                $script:capturedPlasterParameters['ModuleType'] | Should -Be 'SimpleModule'
            }
        }
    }
}
