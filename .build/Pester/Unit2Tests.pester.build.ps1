Param (
    [io.DirectoryInfo]
    $ProjectPath = (property ProjectPath (Join-Path $PSScriptRoot '../..' -Resolve -ErrorAction SilentlyContinue)),

    [string]
    $BuildOutput = (property BuildOutput 'C:\BuildOutput'),

    [string]
    $ProjectName = (property ProjectName (Split-Path -Leaf (Join-Path $PSScriptRoot '../..')) ),

    [string]
    $ModuleSource = (property ModuleSource $ProjectName),

    [string]
    $PesterOutputFormat = (property PesterOutputFormat 'NUnitXml'),

    [string]
    $PathToUnit2Tests = (property PathToUnitTests 'tests/Unit2'),

    [string]
    $PesterOutputSubFolder = (property PesterOutputSubFolder 'PesterOut'),

    [Int]
    [ValidateRange(0,100)]
    $CodeCoverageThreshold = (property CodeCoverageThreshold 90),

    [string]
    $LineSeparation = (property LineSeparation ('-' * 78))
)

task Unit2Tests {
    $LineSeparation
    "`t`t`t RUNNING MODULE UNIT2 TESTS"
    $LineSeparation
    "`tProject Path = $ProjectPath"
    "`tProject Name = $ProjectName"
    "`tModule Source= $ModuleSource"
    "`tUnit Tests   = $PathToUnit2Tests"
    "`tResult Folder= $BuildOutput\Unit\"

    #Resolving the Unit Tests path based on 2 possible Path: 
    #    ProjectPath\ProjectName\tests\Unit (my way, I like to ship tests with Modules)
    # or ProjectPath\tests\Unit (Warren's way: http://ramblingcookiemonster.github.io/Building-A-PowerShell-Module/)
    $Unit2TestPath = [io.DirectoryInfo][system.io.path]::Combine($ProjectPath,$ModuleSource,$PathToUnit2Tests)
    
    if (!$Unit2TestPath.Exists -and
        (   #Try a module structure where the tests are outside of the Source directory
            $Unit2TestPath = [io.DirectoryInfo][system.io.path]::Combine($ProjectPath,$PathToUnit2Tests) -and
            !$Unit2TestPath.Exists
        )
    )
    {
        Throw ('Cannot Execute Unit tests, Path Not found {0}' -f $Unit2TestPath)
    }

    "`tUnitTest Path: $Unit2TestPath"
    ''

    if (![io.path]::IsPathRooted($BuildOutput)) {
        $BuildOutput = Join-Path -Path $ProjectPath.FullName -ChildPath $BuildOutput
    }

    $PSVersion = 'PSv{0}.{1}' -f $PSVersionTable.PSVersion.Major, $PSVersionTable.PSVersion.Minor
    $Timestamp = Get-date -uformat "%Y%m%d-%H%M%S"
    $TestResultFileName = "Unit2_$PSVersion`_$TimeStamp.xml"
    $TestResultFile = [system.io.path]::Combine($BuildOutput,'testResults','unit2',$PesterOutputFormat,$TestResultFileName)
    $TestResultFileParentFolder = Split-Path $TestResultFile -Parent
    $PesterOutFilePath = [system.io.path]::Combine($BuildOutput,'testResults','unit2',$PesterOutputSubFolder,$TestResultFileName)
    $PesterOutParentFolder = Split-Path $PesterOutFilePath -Parent
    
    if (!(Test-Path $PesterOutParentFolder)) {
        Write-Verbose "CREATING Pester Results Output Folder $PesterOutParentFolder"
        $null = mkdir $PesterOutParentFolder -Force
    }

    if (!(Test-Path $TestResultFileParentFolder)) {
        Write-Verbose "CREATING Test Results Output Folder $TestResultFileParentFolder"
        $null = mkdir $TestResultFileParentFolder -Force
    }

    Remove-module -Force $ProjectName -ErrorAction SilentlyContinue
    $ModulePsd1 = [io.Path]::Combine($BuildOutput,$ProjectName,"$ProjectName.psd1")
    $ModulePsm1 = [io.Path]::Combine($BuildOutput,$ProjectName,"$ProjectName.psm1")

    Import-Module -Force $ModulePsd1 -ErrorAction Stop | Write-Verbose
    
    Push-Location $Unit2TestPath
    $PesterParams = @{
        ErrorAction  = 'Stop'
        OutputFormat = $PesterOutputFormat
        OutputFile   = $TestResultFile
        CodeCoverage = $ModulePsm1
        PassThru     = $true
    }
    $script:Unit2TestResults = Invoke-Pester @PesterParams
    $null = $script:Unit2TestResults | Export-Clixml -Path $PesterOutFilePath -Force
    Pop-Location
}

task FailBuildIfFailedUnit2Test -If ($script:Unit2TestResults.FailedCount -ne 0) {
    assert ($script:Unit2TestResults.FailedCount -eq 0) ('Failed {0} Unit2 tests. Aborting Build' -f $script:Unit2TestResults.FailedCount)
}

task FailUnit2IfLastCodeConverageUnderThreshold {
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

    $TestResultFileName = "Unit2_*_*.xml"
    $PesterOutPath = [system.io.path]::Combine($BuildOutput,'testResults','unit2',$PesterOutputSubFolder,$TestResultFileName)
    $PesterOutPath
    $PesterOutFile =  Get-ChildItem -Path $PesterOutPath |  Sort-Object -Descending | Select-Object -first 1
    $PesterObject = Import-Clixml -Path $PesterOutFile.FullName
    if ($PesterObject) {
        $coverage = $PesterObject.CodeCoverage.NumberOfCommandsExecuted / $PesterObject.CodeCoverage.NumberOfCommandsAnalyzed
        if ($coverage -lt $CodeCoverageThreshold/100) {
            Throw "The code coverage ($($Coverage*100) %) is under the threshold of $CodeCoverageThreshold %."
        }
        else {
            Write-Host "Code Coverage accepted with value of $($coverage*100) %" -ForegroundColor Green
        }
    }
}

task Unit2TestsStopOnFail Unit2Tests,FailBuildIfFailedUnit2Test,FailUnit2IfLastCodeConverageUnderThreshold