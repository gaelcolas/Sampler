Param (
    [String]
    $BuildOutput = "$PSScriptRoot\BuildOutput",

    [String[]]
    $GalleryRepository, #used in ResolveDependencies, has default

    [Uri]
    $GalleryProxy #used in ResolveDependencies, $null if not specified
)

Get-ChildItem -Path "$PSScriptRoot/.build/" -Recurse -Include *.ps1 -Verbose |
    Foreach-Object {
        "Importing file $($_.BaseName)" 
        . $_.FullName 
    }

task .  ResolveDependencies,
        SetBuildVariable,
        UnitTests, 
        DoSomethingBeforeFailing,
        FailBuildIfFailedUnitTest, 
        IntegrationTests, 
        QualityTestsStopOnFail


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

Build ExampleBuild {
    Task Init {
        Clean $True
    }
    
    Task Build {
        With PSDeploy
        Tag Build
        StepVersion Minor
        DependingOn Init
    }
    
    Task Test {
        Path "$ProjectRoot\Tests"
        DependingOn Build
    }
    Task Publish {
        With PSDeploy
        Tag Publish
        DependingOn Test
    }
}


#>