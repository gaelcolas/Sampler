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
        ))
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

    $PSVersion = 'PSv{0}' -f $PSVersionTable.PSVersion
    $PesterOutputFileFileName = "{0}_v{1}.PSVersion.{2}.xml" -f $ProjectName, $ModuleVersion, $PSVersion
    $PesterOutputFullPath = Join-Path $PesterOutputFolder $PesterOutputFileFileName

    $moduleUnderTest = Import-Module $ProjectName -PassThru

    $PesterParams = @{
        OutputFormat                 = $PesterOutputFormat
        OutputFile                   = $PesterOutputFullPath
        PassThru                     = $true
        CodeCoverageOutputFileFormat = 'JaCoCo'
        CodeCoverage                 = @($moduleUnderTest.path)
        CodeCoverageOutputFile       = (Join-Path $PesterOutputFolder "CodeCov_$PesterOutputFileFileName")
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
task Fail_if_Last_Code_Coverage_is_Under_Threshold {
    "`tProject Path     = $BuildRoot"
    "`tProject Name     = $ProjectName"
    "`tUnit Tests       = $PathToUnitTests"
    "`tResult Folder    = $BuildOutput\Unit\"
    "`tMin Coverage     = $CodeCoverageThreshold %"
    ''
    $moduleUnderTest = Import-Module $ProjectName -PassThru

    if (![io.path]::IsPathRooted($BuildOutput)) {
        $BuildOutput = Join-Path -Path $BuildRoot -ChildPath $BuildOutput
    }

    $TestResultFileName = "Unit_*.xml"
    $PesterOutPath = [system.io.path]::Combine($BuildOutput, 'testResults', 'unit', $PesterOutputSubFolder, $TestResultFileName)
    if (-Not (Test-Path $PesterOutPath)) {
        if ( $CodeCoverageThreshold -eq 0 ) {
            Write-Host "Code Coverage SUCCESS with value of 0%. No Pester output found." -ForegroundColor Magenta
            return
        }
        else {
            Throw "No command were tested. Threshold of $CodeCoverageThreshold % not met"
        }
    }
    $PesterOutPath
    $PesterOutFile = Get-ChildItem -Path $PesterOutPath |  Sort-Object -Descending | Select-Object -first 1
    $PesterObject = Import-Clixml -Path $PesterOutFile.FullName
    if ($PesterObject.CodeCoverage.NumberOfCommandsAnalyzed) {
        $coverage = $PesterObject.CodeCoverage.NumberOfCommandsExecuted / $PesterObject.CodeCoverage.NumberOfCommandsAnalyzed
        if ($coverage -lt $CodeCoverageThreshold / 100) {
            Throw "The Code Coverage FAILURE: ($($Coverage*100) %) is under the threshold of $CodeCoverageThreshold %."
        }
        else {
            Write-Host "Code Coverage SUCCESS with value of $($coverage*100) %" -ForegroundColor Green
        }
    }
}

# Synopsis: Meta task that runs Quality Tests, and fails if they're not successful
task Pester_Tests_Stop_On_Fail Invoke_pester_tests, Fail_Build_if_Pester_Tests_failed