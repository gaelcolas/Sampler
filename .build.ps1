#Requires -Modules InvokeBuild
Param (
    [String]
    $BuildOutput = "$PSScriptRoot\BuildOutput",

    [String[]]
    $GalleryRepository, #used in ResolveDependencies, has default

    [Uri]
    $GalleryProxy, #used in ResolveDependencies, $null if not specified

    [Switch]
    $ForceEnvironmentVariables = [switch]$true,

    [String]
    $DependencyTarget = "$BuildOutput/modules"
    
)
if ((Get-PSCallStack)[1].InvocationInfo.MyCommand.Name -ne 'Invoke-Build.ps1') {
    Invoke-Build
    return
}

Get-ChildItem -Path "$PSScriptRoot/.build/" -Recurse -Include *.ps1 -Verbose |
    Foreach-Object {
        "Importing file $($_.BaseName)" | Write-Verbose
        . $_.FullName 
    }

task .  Clean,
        ResolveDependencies,
        SetBuildEnvironment,
        UnitTests,
        UploadUnitTestResultsToAppVeyor,
        FailBuildIfFailedUnitTest, 
        FailIfLastCodeConverageUnderThreshold,
        IntegrationTests, 
        QualityTestsStopOnFail

task testAll UnitTests, IntegrationTests, QualityTestsStopOnFail

#task . ResolveDependencies, SetBuildVariable, UnitTestsStopOnFail, IntegrationTests
<#

### Idea to toy with, from Brandon Pagett

Task Build {
    With PSDeploy {
        Tag Build
        StepVersion Minor
        DependingOn Init
   }
}

### Or 

BuildWorkflow SampleBuild {
    Task Init {
        With BuildHelpers {
            Task Clean
        }
    }
    
    Task Build {
        With PSDeploy {
            Task Deploy
            Tag Build
            StepVersion Minor
            DependingOn Init
        }
    }
    
    Task Test {
        Path "$ProjectRoot\Tests"
        DependingOn Build
    }
    Task Publish {
        With PSDeploy {
            Tag Publish
            DependingOn Test
        }
    }
}


#>