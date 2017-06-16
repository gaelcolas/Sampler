#Requires -Modules Pester
Param (
    [io.DirectoryInfo]
    $ProjectPath = (property ProjectPath (Join-Path $PSScriptRoot '../..' -Resolve -ErrorAction SilentlyContinue)),

    [string]
    $BuildOutput = (property BuildOutput 'C:\BuildOutput'),

    [string]
    $ProjectName = (property ProjectName (Split-Path -Leaf (Join-Path $PSScriptRoot '../..')) ),

    [string]
    $RelativePathToQualityTests = (property RelativePathToQualityTests 'tests/QA'),

    [string]
    $LineSeparation = (property LineSeparation ('-' * 78))
)

task QualityTests {
    $LineSeparation
    "`t`t`t RUNNING Quality TESTS"
    $LineSeparation
    "`tProject Path = $ProjectPath"
    "`tProject Name = $ProjectName"
    "`tQuality Tests   = $RelativePathToQualityTests"

    $QualityTestPath = [io.DirectoryInfo][system.io.path]::Combine($ProjectPath,$ProjectName,$RelativePathToQualityTests)
    
    if (!$QualityTestPath.Exists -and
        (   #Try a module structure where the
            ($QualityTestPath = [io.DirectoryInfo][system.io.path]::Combine($ProjectPath,$RelativePathToQualityTests)) -and
            !$QualityTestPath.Exists
        )
    )
    {
        Write-Warning ('Cannot Execute Quality tests, Path Not found {0}' -f $QualityTestPath)
        return
    }

    "`tQualityTest Path: $QualityTestPath"
    if (![io.path]::IsPathRooted($BuildOutput)) {
        $BuildOutput = Join-Path -Path $ProjectPath.FullName -ChildPath $BuildOutput
    }
    # $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(".\nonexist\foo.txt")
    $PSVersion = $PSVersionTable.PSVersion.Major
    $Timestamp = Get-date -uformat "%Y%m%d-%H%M%S"
    $FileName = "TestResults_QA_PS$PSVersion`_$TimeStamp.xml"
    $TestFilePath = Join-Path -Path $BuildOutput -ChildPath $FileName
    
    if (!(Test-Path $BuildOutput)) {
        mkdir $BuildOutput -Force
    }

    Push-Location $QualityTestPath
    
    Import-module Pester
    $script:QualityTestResults = Invoke-Pester -ErrorAction Stop -OutputFormat NUnitXml -OutputFile $TestFilePath -PassThru
    
    Pop-Location
}

task FailBuildIfFailedQualityTest -If ($CodeCoverageThreshold -ne 0) {
    assert ($script:QualityTestResults.FailedCount -eq 0) ('Failed {0} Quality tests. Aborting Build' -f $script:QualityTestResults.FailedCount)
}

task QualityTestsStopOnFail QualityTests,FailBuildIfFailedQualityTest