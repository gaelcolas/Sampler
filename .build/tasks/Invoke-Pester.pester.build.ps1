Param (
    # Project path
    [string]$ProjectPath = (property ProjectPath $BuildRoot),

    # Base directory of all output (default to 'output')
    [string]$OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

    [string]$PesterOutputFolder = (property PesterOutputFolder 'testResults'),

    [string]$ProjectName = (property ProjectName (Split-Path -Leaf $BuildRoot)),

    [string]$PesterOutputFormat = (property PesterOutputFormat 'NUnitXml'),

    [string[]]$PesterScript = (property PesterScript 'tests', (Join-Path $ProjectName 'tests')),

    [string[]]$PesterTag = (property PesterTag @()),

    [string[]]$PesterExcludeTag = (property PesterExcludeTag @()),

    [string]$ModuleVersion = (property ModuleVersion $(
            if (Get-Command gitversion) {
                (gitversion | ConvertFrom-Json).InformationalVersion
            }
            else { '0.0.1' }
        )),
    [int]$CodeCoverageThreshold = (property CodeCoverageThreshold 100)
)

# Synopsis: Making sure the Module meets some quality standard (help, tests)
task Invoke_pester_tests {
    "`tProject Path  = $ProjectPath"
    "`tProject Name  = $ProjectName"
    "`tTests         = $($PesterScript -join ', ')"
    "`tTags          = $($PesterTag -join ', ')"
    "`tExclude Tags  = $($PesterExcludeTags -join ', ')"

    if (![io.path]::IsPathRooted($OutputDirectory)) {
        $OutputDirectory = Join-Path -Path $ProjectPath -ChildPath $OutputDirectory
        Write-Build Yellow "Absolute path to Output Directory is $OutputDirectory"
    }

    if (![io.path]::IsPathRooted($PesterOutputFolder)) {
        $PesterOutputFolder = Join-Path $OutputDirectory $PesterOutputFolder
    }

    if (!(Test-Path $PesterOutputFolder)) {
        Write-Build Yellow "Creating folder $PesterOutputFolder"
        $null = mkdir -force $PesterOutputFolder -ErrorAction Stop
    }

    $PSVersion = 'PSv.{0}' -f $PSVersionTable.PSVersion
    $PesterOutputFileFileName = "{0}_v{1}.PSVersion.{2}.xml" -f $ProjectName, $ModuleVersion, $PSVersion
    $PesterOutputFullPath = Join-Path $PesterOutputFolder "$($PesterOutputFormat)_$PesterOutputFileFileName"

    $moduleUnderTest = Import-Module $ProjectName -PassThru

    $PesterParams = @{
        OutputFormat                 = $PesterOutputFormat
        OutputFile                   = $PesterOutputFullPath
        PassThru                     = $true
        CodeCoverageOutputFileFormat = 'JaCoCo'
        CodeCoverage                 = @($moduleUnderTest.path)
        CodeCoverageOutputFile       = (Join-Path $PesterOutputFolder "CodeCov_$PesterOutputFileFileName")
        #ExcludeTag                   = 'FunctionalQuality', 'TestQuality', 'helpQuality'
    }

    # Test folders is specified, do not run invoke-pester against $BuildRoot
    if ($PesterScript.count -gt 0) {
        $PesterParams.Add('Script', @())
        foreach ($TestFolder in $PesterScript) {
            if (![io.path]::IsPathRooted($TestFolder)) {
                $TestFolder = Join-Path $ProjectPath $TestFolder
            }

            # The Absolute path to this folder exists, adding to the list of pester scripts to run
            if (Test-Path $TestFolder) {
                $PesterParams.Script += $TestFolder
            }
        }
    }

    $script:TestResults = Invoke-Pester @PesterParams -Verbose

    $PesterResultObjectClixml = Join-Path $PesterOutputFolder "PesterObject_$PesterOutputFileFileName"
    $null = $script:TestResults | Export-Clixml -Path $PesterResultObjectClixml -Force

}

# Synopsis: This task ensures the build job fails if the test aren't successful.
task Fail_Build_if_Pester_Tests_failed -If ($CodeCoverageThreshold -ne 0) {
    "Asserting that no test failed"
    assert ($script:TestResults.FailedCount -eq 0) ('Failed {0} Quality tests. Aborting Build' -f $script:TestResults.FailedCount)
}


# Synopsis: Fails the build if the code coverage is under predefined threshold
task Pester_if_Code_Coverage_Under_Threshold {

    if (![io.path]::IsPathRooted($OutputDirectory)) {
        $OutputDirectory = Join-Path -Path $ProjectPath -ChildPath $OutputDirectory
        Write-Build Yellow "Absolute path to Output Directory is $OutputDirectory"
    }

    if (![io.path]::IsPathRooted($PesterOutputFolder)) {
        $PesterOutputFolder = Join-Path $OutputDirectory $PesterOutputFolder
    }

    $PSVersion = 'PSv.{0}' -f $PSVersionTable.PSVersion
    $PesterOutputFileFileName = "{0}_v{1}.PSVersion.{2}.xml" -f $ProjectName, $ModuleVersion, $PSVersion
    $PesterResultObjectClixml = Join-Path $PesterOutputFolder "PesterObject_$PesterOutputFileFileName"
    Write-Build White "`tPester Output Object = $PesterResultObjectClixml"


    if (-Not (Test-Path $PesterResultObjectClixml)) {
        if ( $CodeCoverageThreshold -eq 0 ) {
            Write-Host "Code Coverage SUCCESS with value of 0%. No Pester output found." -ForegroundColor Magenta
            return
        }
        else {
            Throw "No command were tested. Threshold of $CodeCoverageThreshold % not met"
        }
    }
    else {
        $PesterObject = Import-Clixml -Path $PesterResultObjectClixml
    }

    if ($PesterObject.CodeCoverage.NumberOfCommandsAnalyzed) {
        $coverage = $PesterObject.CodeCoverage.NumberOfCommandsExecuted / $PesterObject.CodeCoverage.NumberOfCommandsAnalyzed
        if ($coverage -lt $CodeCoverageThreshold / 100) {
            Throw "The Code Coverage FAILURE: ($($Coverage*100) %) is under the threshold of $CodeCoverageThreshold %."
        }
        else {
            Write-Build Green "Code Coverage SUCCESS with value of $($coverage*100) %"
        }
    }
}

# Synopsis: Uploading Unit Test results to AppVeyor
task Upload_Test_Results_To_AppVeyor -If {(property BuildSystem 'unknown') -eq 'AppVeyor'} {

    if (![io.path]::IsPathRooted($OutputDirectory)) {
        $OutputDirectory = Join-Path -Path $ProjectPath -ChildPath $OutputDirectory
        Write-Build Yellow "Absolute path to Output Directory is $OutputDirectory"
    }

    if (![io.path]::IsPathRooted($PesterOutputFolder)) {
        $PesterOutputFolder = Join-Path $OutputDirectory $PesterOutputFolder
    }

    if (!(Test-Path $PesterOutputFolder)) {
        Write-Build Yellow "Creating folder $PesterOutputFolder"
        $null = mkdir -force $PesterOutputFolder -ErrorAction Stop
    }

    $PSVersion = 'PSv.{0}' -f $PSVersionTable.PSVersion
    $PesterOutputFileFileName = "{0}_v{1}.PSVersion.{2}.xml" -f $ProjectName, $ModuleVersion, $PSVersion
    $PesterOutputFullPath = Join-Path $PesterOutputFolder "$($PesterOutputFormat)_$PesterOutputFileFileName"

    $TestResultFile = Get-Item $PesterOutputFullPath -ErrorAction Ignore
    if($TestResultFile) {
        Write-Build Green "  Uploading test results $TestResultFile to Appveyor"
        $TestResultFile | Add-TestResultToAppveyor
        Write-Build Green "  Upload Complete"
    }
}

# Synopsis: Meta task that runs Quality Tests, and fails if they're not successful
task Pester_Tests_Stop_On_Fail Invoke_pester_tests, Upload_Test_Results_To_AppVeyor, Fail_Build_if_Pester_Tests_failed