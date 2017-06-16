#Requires -Modules Pester
Param (
    [io.DirectoryInfo]
    $ProjectPath = (property ProjectPath (Join-Path $PSScriptRoot '../..' -Resolve -ErrorAction SilentlyContinue)),

    [string]
    $ProjectName = (property ProjectName (Split-Path -Leaf (Join-Path $PSScriptRoot '../..')) ),

    [string]
    $RelativePathToIntegrationTests = (property RelativePathToIntegrationTests 'tests/Integration'),

    [string]
    $LineSeparation = (property LineSeparation ('-' * 78))
)
task IntegrationTests {
    $LineSeparation
    "`t`t`t RUNNING INTEGRATION TESTS"
    $LineSeparation
    "`tProject Path = $ProjectPath"
    "`tProject Name = $ProjectName"
    "`tIntegration Tests   = $RelativePathToIntegrationTests"
    $IntegrationTestPath = [io.DirectoryInfo][system.io.path]::Combine($ProjectPath,$ProjectName,$RelativePathToIntegrationTests)
     "`tIntegration Tests  = $IntegrationTestPath"

    if (!$IntegrationTestPath.Exists -and
        (   #Try a module structure where the
            ($IntegrationTestPath = [io.DirectoryInfo][system.io.path]::Combine($ProjectPath,$RelativePathToIntegrationTests)) -and
            !$IntegrationTestPath.Exists
        )
    )
    {
        Write-Warning ('Integration tests Path Not found {0}' -f $IntegrationTestPath)
    }
    else {
        "`tIntegrationTest Path: $IntegrationTestPath"
        ''
        Push-Location $IntegrationTestPath

        Import-module Pester
        Invoke-Pester -ErrorAction Stop

        Pop-Location
    }
   
}