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
    
    if (!$IntegrationTestPath.Exists -and
        (   #Try a module structure where the
            ($IntegrationTestPath = [io.DirectoryInfo][system.io.path]::Combine($ProjectPath,$RelativePathToIntegrationTests)) -and
            !$IntegrationTestPath.Exists
        )
    )
    {
        Throw ('Cannot Execute Integration tests, Path Not found {0}' -f $IntegrationTestPath)
    }

    "`tIntegrationTest Path: $IntegrationTestPath"
    ''
    Push-Location $IntegrationTestPath

    Invoke-Pester -ErrorAction Stop

    Pop-Location
}