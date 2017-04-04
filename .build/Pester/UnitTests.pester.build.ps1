Param (
    [io.DirectoryInfo]
    $ProjectPath = (property ProjectPath (Join-Path $PSScriptRoot '../..' -Resolve -ErrorAction SilentlyContinue)),

    [string]
    $BuildOutput = (property BuildOutput 'C:\BuildOutput'),

    [string]
    $ProjectName = (property ProjectName (Split-Path -Leaf (Join-Path $PSScriptRoot '../..')) ),

    [string]
    $RelativePathToUnitTests = (property RelativePathToUnitTests 'tests/Unit'),

    [string]
    $NUnitSubFolder = (property NUnitSubFolder 'NUnit\Unit'),

    [string]
    $PesterOutputSubFolder = (property PesterOutputSubFolder 'PesterOut'),

    [string]
    $LineSeparation = (property LineSeparation ('-' * 78))
)

task UnitTests {
    $LineSeparation
    "`t`t`t RUNNING UNIT TESTS"
    $LineSeparation
    "`tProject Path = $ProjectPath"
    "`tProject Name = $ProjectName"
    "`tUnit Tests   = $RelativePathToUnitTests"
    $UnitTestPath = [io.DirectoryInfo][system.io.path]::Combine($ProjectPath,$ProjectName,$RelativePathToUnitTests)
    
    if (!$UnitTestPath.Exists -and
        (   #Try a module structure where the
            $UnitTestPath = [io.DirectoryInfo][system.io.path]::Combine($ProjectPath,$RelativePathToUnitTests) -and
            !$UnitTestPath.Exists
        )
    )
    {
        Throw ('Cannot Execute Unit tests, Path Not found {0}' -f $UnitTestPath)
    }

    "`tUnitTest Path: $UnitTestPath"
    if (![io.path]::IsPathRooted($BuildOutput)) {
        $BuildOutput = Join-Path -Path $ProjectPath.FullName -ChildPath $BuildOutput
    }
    # $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(".\nonexist\foo.txt")
    $PSVersion = $PSVersionTable.PSVersion.Major
    $Timestamp = Get-date -uformat "%Y%m%d-%H%M%S"
    $NUnitFileName = "TestResults_Unit_PSv$PSVersion`_$TimeStamp.xml"
    $NUnitFilePath = [system.io.path]::Combine($BuildOutput,$NUnitSubFolder,$NUnitFileName)
    $NUnitParentFolder = Split-Path $NUnitFilePath -Parent
    
    if (!(Test-Path $NUnitParentFolder)) {
        "CREATING NUnit Output Folder $NUnitParentFolder"
        $null = mkdir $NUnitParentFolder -Force
    }
    
    Push-Location $UnitTestPath
    $ListOfTestedFile = Get-ChildItem | Foreach-Object { $fileName = $_.BaseName -replace '\.tests',''; "$ProjectPath\$ProjectName\*\$fileName.ps1"  }
    $ListOfTestedFile
    $script:UnitTestResults = Invoke-Pester -ErrorAction Stop -OutputFormat NUnitXml -OutputFile $NUnitFilePath -CodeCoverage $ListOfTestedFile -PassThru


    $PesterOutFilePath = [system.io.path]::Combine($BuildOutput,$PesterOutputSubFolder,$NUnitFileName)
    
    $PesterOutParentFolder = Split-Path $PesterOutFilePath -Parent
    
    if (!(Test-Path $PesterOutParentFolder)) {
        "CREATING NUnit Output Folder $PesterOutParentFolder"
        $null = mkdir $PesterOutParentFolder -Force
    }
    $null = $script:UnitTestResults | Export-Clixml -Path $PesterOutFilePath -Force
    
    Pop-Location
}

task FailBuildIfFailedUnitTest -If ($script:UnitTestResults.FailedCount -ne 0) {
    assert ($script:UnitTestResults.FailedCount -eq 0) ('Failed {0} Unit tests. Aborting Build' -f $script:UnitTestResults.FailedCount)
}

task UnitTestsStopOnFail UnitTests,FailBuildIfFailedUnitTest