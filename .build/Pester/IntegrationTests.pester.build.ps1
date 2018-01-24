Param (
    [string]
    $ProjectName = (property ProjectName (Split-Path -Leaf $BuildRoot) ),

    [string]
    $RelativePathToIntegrationTests = (property RelativePathToIntegrationTests 'tests/Integration')
)

# Synopsis: Running the Integration tests if present
task IntegrationTests {
    "`tProject Path = $BuildRoot"
    "`tProject Name = $ProjectName"
    "`tIntegration Tests   = $RelativePathToIntegrationTests"
    $IntegrationTestPath = [io.DirectoryInfo][system.io.path]::Combine($BuildRoot,$ProjectName,$RelativePathToIntegrationTests)
     "`tIntegration Tests  = $IntegrationTestPath"

    if (!$IntegrationTestPath.Exists -and
        (   #Try a module structure where the
            ($IntegrationTestPath = [io.DirectoryInfo][system.io.path]::Combine($BuildRoot,$RelativePathToIntegrationTests)) -and
            !$IntegrationTestPath.Exists
        )
    )
    {
        Write-Warning ("`t>> Integration tests Path Not found {0}" -f $IntegrationTestPath)
    }
    else {
        "`tIntegrationTest Path: $IntegrationTestPath"
        ''
        Push-Location $IntegrationTestPath

        Import-module Pester -ErrorAction Stop
        Invoke-Pester -ErrorAction Stop

        Pop-Location
    }
   
}