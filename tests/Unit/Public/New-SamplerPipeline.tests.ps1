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

BeforeDiscovery {
    $testCases = @(
        <#
            If the templates do not define those parameters, Invoke-Plaster will fail and this test will catch it.
            The template integration is done separately, hence why we don't need to test it here.
            We only test that the Add-Sample parameters & parameter set work with the templates we have defined.
        #>
        @{
            TestCaseName = 'Build'
            NewSamplerPipelineParameters = @{
                Pipeline = 'Build'
                ProjectName =  'MyBuild'
                License = 'true'
                LicenseType = 'MIT'
                SourceDirectory = 'Source'
                MainGitBranch = 'main'
                ModuleDescription = 'some desc'
                CustomRepo = 'PSGallery'
                Features = 'All'
            }
        }
        @{
            TestCaseName = 'ChocolateyPipeline'
            NewSamplerPipelineParameters = @{
                Pipeline = 'ChocolateyPipeline'
                ProjectName =  'MyChoco'
                License = 'true'
                LicenseType = 'MIT'
                SourceDirectory = 'Source'
                MainGitBranch = 'main'
                ModuleDescription = 'some desc'
                CustomRepo = 'PSGallery'
                Features = 'All'
            }
        }
    )
}

Describe New-SamplerPipeline {
    Context 'invoke plaster with correct parameters for template' {
        BeforeAll {
            Mock -CommandName Invoke-Plaster
        }

        It 'New-SamplerPipeline should call Invoke-Plaster with test case <TestCaseName>' -ForEach $testCases {
            $NewSamplerPipelineParameters.DestinationPath = $TestDrive

            { Sampler\New-SamplerPipeline @NewSamplerPipelineParameters  } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-Plaster -Scope It -Times 1
        }
    }
}
