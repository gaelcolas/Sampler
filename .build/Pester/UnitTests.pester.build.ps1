#Requires -Modules Pester
Param (
    [io.DirectoryInfo]
    $ProjectPath = (property ProjectPath (Join-Path $PSScriptRoot '../..' -Resolve -ErrorAction SilentlyContinue)),

    [string]
    $BuildOutput = (property BuildOutput 'C:\BuildOutput'),

    [string]
    $ProjectName = (property ProjectName (Split-Path -Leaf (Join-Path $PSScriptRoot '../..')) ),

    [string]
    $PesterOutputFormat = (property PesterOutputFormat 'NUnitXml'),

    [string]
    $PathToUnitTests = (property PathToUnitTests 'tests/Unit'),

    [string]
    $PesterOutputSubFolder = (property PesterOutputSubFolder 'PesterOut'),

    [Int]
    [ValidateRange(0,100)]
    $CodeCoverageThreshold = (property CodeCoverageThreshold 90),

    [string]
    $LineSeparation = (property LineSeparation ('-' * 78))
)

task UnitTests {
    $LineSeparation
    "`t`t`t RUNNING UNIT TESTS"
    $LineSeparation
    "`tProject Path = $ProjectPath"
    "`tProject Name = $ProjectName"
    "`tUnit Tests   = $PathToUnitTests"
    "`tResult Folder= $BuildOutput\Unit\"

    #Resolving the Unit Tests path based on 2 possible Path: 
    #    ProjectPath\ProjectName\tests\Unit (my way, I like to ship tests with Modules)
    # or ProjectPath\tests\Unit (Warren's way: http://ramblingcookiemonster.github.io/Building-A-PowerShell-Module/)
    $UnitTestPath = [io.DirectoryInfo][system.io.path]::Combine($ProjectPath,$ProjectName,$PathToUnitTests)
    
    if (!$UnitTestPath.Exists -and
        (   #Try a module structure where the tests are outside of the Source directory
            ($UnitTestPath = [io.DirectoryInfo][system.io.path]::Combine($ProjectPath,$PathToUnitTests)) -and
            !$UnitTestPath.Exists
        )
    )
    {
        Write-Warning ('Cannot Execute Unit tests, Path Not found {0}' -f $UnitTestPath)
        return
    }

    "`tUnitTest Path: $UnitTestPath"
    ''

    if (![io.path]::IsPathRooted($BuildOutput)) {
        $BuildOutput = Join-Path -Path $ProjectPath.FullName -ChildPath $BuildOutput
    }

    $PSVersion = 'PSv{0}.{1}' -f $PSVersionTable.PSVersion.Major, $PSVersionTable.PSVersion.Minor
    $Timestamp = Get-date -uformat "%Y%m%d-%H%M%S"
    $TestResultFileName = "Unit_$PSVersion`_$TimeStamp.xml"
    $TestResultFile = [system.io.path]::Combine($BuildOutput,'testResults','unit',$PesterOutputFormat,$TestResultFileName)
    $TestResultFileParentFolder = Split-Path $TestResultFile -Parent
    $PesterOutFilePath = [system.io.path]::Combine($BuildOutput,'testResults','unit',$PesterOutputSubFolder,$TestResultFileName)
    $PesterOutParentFolder = Split-Path $PesterOutFilePath -Parent
    
    if (!(Test-Path $PesterOutParentFolder)) {
        Write-Verbose "CREATING Pester Results Output Folder $PesterOutParentFolder"
        $null = mkdir $PesterOutParentFolder -Force
    }

    if (!(Test-Path $TestResultFileParentFolder)) {
        Write-Verbose "CREATING Test Results Output Folder $TestResultFileParentFolder"
        $null = mkdir $TestResultFileParentFolder -Force
    }
    
    Push-Location $UnitTestPath
    $ListOfTestedFile = Get-ChildItem | Foreach-Object { $fileName = $_.BaseName -replace '\.tests',''; "$ProjectPath\$ProjectName\*\$fileName.ps1"  }
    $ListOfTestedFile | ForEach-Object { Write-Verbose $_}
    $PesterParams = @{
        ErrorAction  = 'Stop'
        OutputFormat = $PesterOutputFormat
        OutputFile   = $TestResultFile
        CodeCoverage = $ListOfTestedFile
        PassThru     = $true
    }
    Import-module Pester
    $script:UnitTestResults = Invoke-Pester @PesterParams
    $null = $script:UnitTestResults | Export-Clixml -Path $PesterOutFilePath -Force
    Pop-Location
}

task FailBuildIfFailedUnitTest -If ($CodeCoverageThreshold -ne 0) {
    assert ($script:UnitTestResults.FailedCount -eq 0) ('Failed {0} Unit tests. Aborting Build' -f $script:UnitTestResults.FailedCount)
}

task FailIfLastCodeConverageUnderThreshold {
    $LineSeparation
    "`t`t`t LOADING LAST CODE COVERAGE From FILE"
    $LineSeparation
    "`tProject Path     = $ProjectPath"
    "`tProject Name     = $ProjectName"
    "`tUnit Tests       = $PathToUnitTests"
    "`tResult Folder    = $BuildOutput\Unit\"
    "`tMin Coverage     = $CodeCoverageThreshold %"
    ''

    if (![io.path]::IsPathRooted($BuildOutput)) {
        $BuildOutput = Join-Path -Path $ProjectPath.FullName -ChildPath $BuildOutput
    }

    $TestResultFileName = "Unit_*_*.xml"
    $PesterOutPath = [system.io.path]::Combine($BuildOutput,'testResults','unit',$PesterOutputSubFolder,$TestResultFileName)
    if (-Not (Test-Path $PesterOutPath)) {
        if ( $CodeCoverageThreshold -eq 0 ) {
            Write-Host "Code Coverage accepted with value of 0%. No Pester output found." -ForegroundColor Magenta
            return
        }
        else {
            Throw "No command were tested. Threshold of $CodeCoverageThreshold % not met"
        }
    }
    $PesterOutPath
    $PesterOutFile =  Get-ChildItem -Path $PesterOutPath |  Sort-Object -Descending | Select-Object -first 1
    $PesterObject = Import-Clixml -Path $PesterOutFile.FullName
    if ($PesterObject.CodeCoverage.NumberOfCommandsAnalyzed) {
        $coverage = $PesterObject.CodeCoverage.NumberOfCommandsExecuted / $PesterObject.CodeCoverage.NumberOfCommandsAnalyzed
        if ($coverage -lt $CodeCoverageThreshold/100) {
            Throw "The code coverage ($($Coverage*100) %) is under the threshold of $CodeCoverageThreshold %."
        }
        else {
            Write-Host "Code Coverage accepted with value of $($coverage*100) %" -ForegroundColor Green
        }
    }
}

task UnitTestsStopOnFail UnitTests,FailBuildIfFailedUnitTest,FailIfLastCodeConverageUnderThreshold