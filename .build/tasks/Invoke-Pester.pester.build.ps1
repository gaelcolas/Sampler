Param (
    # Project path
    [string]$ProjectPath = (property ProjectPath $BuildRoot),

    # Base directory of all output (default to 'output')
    [string]$OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

    [string]
    $ProjectName = (property ProjectName $(
            (Get-ChildItem $BuildRoot\*\*.psd1 | Where-Object {
                ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
                $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop }catch{$false}) }
            ).BaseName
        )
    ),

    [string]
    $ModuleVersion = (property ModuleVersion $(
            try {
                (gitversion | ConvertFrom-Json -ErrorAction Stop).InformationalVersion
            }
            catch {
                Write-Verbose "Error attempting to use GitVersion $($_)"
                ''
            }
        )),

    [string]$PesterOutputFolder = (property PesterOutputFolder 'testResults'),

    [string]$PesterOutputFormat = (property PesterOutputFormat 'NUnitXml'),

    [string[]]$PesterScript = (property PesterScript 'tests', (Join-Path $ProjectName 'tests')),

    [string[]]$PesterTag = (property PesterTag @()),

    [string[]]$PesterExcludeTag = (property PesterExcludeTag @()),

    [int]$CodeCoverageThreshold = (property CodeCoverageThreshold 100),

    # Build Configuration object
    $BuildInfo = (property BuildInfo @{})
)

# Synopsis: Making sure the Module meets some quality standard (help, tests)
task Invoke_pester_tests {
    "`tProject Path  = $ProjectPath"
    "`tProject Name  = $ProjectName"
    "`tTests         = $($PesterScript -join ', ')"
    "`tTags          = $($PesterTag -join ', ')"
    "`tExclude Tags  = $($PesterExcludeTag -join ', ')"
    "`tModuleVersion = $ModuleVersion"

    if (!(Split-path -isAbsolute $OutputDirectory)) {
        $OutputDirectory = Join-Path -Path $ProjectPath -ChildPath $OutputDirectory
        Write-Build Yellow "Absolute path to Output Directory is $OutputDirectory"
    }

    if (!(Split-path -isAbsolute $PesterOutputFolder)) {
        $PesterOutputFolder = Join-Path $OutputDirectory $PesterOutputFolder
    }

    if (!(Test-Path $PesterOutputFolder)) {
        Write-Build Yellow "Creating folder $PesterOutputFolder"
        $null = New-Item -ItemType Directory -force $PesterOutputFolder -ErrorAction Stop
    }

    if ([String]::IsNullOrEmpty($ModuleVersion)) {
        $ModuleInfo = Import-PowerShellDataFile "$OutputDirectory/$ProjectName/*/$ProjectName.psd1" -ErrorAction Stop
        if ($ModuleInfo.PrivateData.PSData.Prerelease) {
            $ModuleVersion = $ModuleInfo.ModuleVersion + "-" + $ModuleInfo.PrivateData.PSData.Prerelease
        }
        else {
            $ModuleVersion = $ModuleInfo.ModuleVersion
        }
    }
    else {
        $ModuleVersion, $BuildMetadata = $ModuleVersion -split '\+', 2
        $ModuleVersionFolder, $PreReleaseTag = $ModuleVersion -split '\-', 2
    }

    $os = if($isWindows -or $PSVersionTable.PSVersion.Major -le 5) {
        'Windows'
    }
    elseif($isMacOS) {
        'MacOS'
    }
    else {
        'Linux'
    }

    $PSVersion = 'PSv.{0}' -f $PSVersionTable.PSVersion
    $PesterOutputFileFileName = "{0}_v{1}.{2}.{3}.xml" -f $ProjectName, $ModuleVersion, $os, $PSVersion
    $PesterOutputFullPath = Join-Path $PesterOutputFolder "$($PesterOutputFormat)_$PesterOutputFileFileName"

    $moduleUnderTest = Import-Module $ProjectName -PassThru
    $ExcludeFromCodeCoverage = @('tasks','PlasterTemplate')
    $CodeCoverageFiles = (Get-ChildItem -Path $moduleUnderTest.ModuleBase -Include *.psm1, *.ps1 -Recurse).Where{
        $result = $true
        foreach ($ExclPath in $ExcludeFromCodeCoverage) {
            if (!(Split-Path -IsAbsolute $ExclPath)) {
                $ExclPath = Join-Path $moduleUnderTest.ModuleBase $ExclPath
            }
            if ($_.FullName -Match ([regex]::Escape($ExclPath))) {
                $result = $false
            }
        }
        $result
    }

    $PesterParams = @{
        OutputFormat                 = $PesterOutputFormat
        OutputFile                   = $PesterOutputFullPath
        PassThru                     = $true
        CodeCoverageOutputFileFormat = 'JaCoCo'
        CodeCoverage                 = $CodeCoverageFiles
        CodeCoverageOutputFile       = (Join-Path $PesterOutputFolder "CodeCov_$PesterOutputFileFileName")
        #ExcludeTag                   = 'FunctionalQuality', 'TestQuality', 'helpQuality'
    }

    if ($PesterExcludeTag) {
        $PesterParams.Add('ExcludeTag',$PesterExcludeTag)
    }

    if ($PesterTag) {
        $PesterParams.Add('Tag',$PesterTag)
    }

    # Test folders is specified, do not run invoke-pester against $BuildRoot
    if ($PesterScript.count -gt 0) {
        $PesterParams.Add('Script', @())
        foreach ($TestFolder in $PesterScript) {
            if (!(Split-path -isAbsolute $TestFolder)) {
                $TestFolder = Join-Path $ProjectPath $TestFolder
            }

            # The Absolute path to this folder exists, adding to the list of pester scripts to run
            if (Test-Path $TestFolder) {
                $PesterParams.Script += $TestFolder
            }
        }
    }

    $script:TestResults = Invoke-Pester @PesterParams -Verbose

    $PesterResultObjectCliXml = Join-Path $PesterOutputFolder "PesterObject_$PesterOutputFileFileName"
    $null = $script:TestResults | Export-CliXml -Path $PesterResultObjectCliXml -Force

}

# Synopsis: This task ensures the build job fails if the test aren't successful.
task Fail_Build_if_Pester_Tests_failed -If ($CodeCoverageThreshold -ne 0) {
    "Asserting that no test failed"

    if (!(Split-path -isAbsolute $OutputDirectory)) {
        $OutputDirectory = Join-Path -Path $ProjectPath -ChildPath $OutputDirectory
        Write-Build Yellow "Absolute path to Output Directory is $OutputDirectory"
    }

    if (!(Split-path -isAbsolute $PesterOutputFolder)) {
        $PesterOutputFolder = Join-Path $OutputDirectory $PesterOutputFolder
    }

    $os = if($isWindows -or $PSVersionTable.PSVersion.Major -le 5) {
        'Windows'
    }
    elseif($isMacOS) {
        'MacOS'
    }
    else {
        'Linux'
    }

    if ([String]::IsNullOrEmpty($ModuleVersion)) {
        $ModuleInfo = Import-PowerShellDataFile "$OutputDirectory/$ProjectName/*/$ProjectName.psd1" -ErrorAction Stop
        if($ModuleInfo.PrivateData.PSData.Prerelease) {
            $ModuleVersion = $ModuleInfo.ModuleVersion + "-" + $ModuleInfo.PrivateData.PSData.Prerelease
        }
        else {
            $ModuleInfo.ModuleVersion
        }
    }
    else {
        $ModuleVersion, $BuildMetadata = $ModuleVersion -split '\+', 2
        $ModuleVersionFolder, $PreReleaseTag = $ModuleVersion -split '\-', 2
    }

    $PSVersion = 'PSv.{0}' -f $PSVersionTable.PSVersion
    $PesterOutputFileFileName = "{0}_v{1}.{2}.{3}.xml" -f $ProjectName, $ModuleVersion, $os, $PSVersion
    $PesterResultObjectClixml = Join-Path $PesterOutputFolder "PesterObject_$PesterOutputFileFileName"
    Write-Build White "`tPester Output Object = $PesterResultObjectClixml"


    if (-Not (Test-Path $PesterResultObjectClixml)) {
        if ( $CodeCoverageThreshold -eq 0 ) {
            Write-Build Green "Pester run and Coverage bypassed. No Pester output found but allowed."
            return
        }
        else {
            Throw "No command were tested. Threshold of $CodeCoverageThreshold % not met"
        }
    }
    else {
        $PesterObject = Import-Clixml -Path $PesterResultObjectClixml
    }

    assert ($PesterObject.FailedCount -eq 0) ('Failed {0} Quality tests. Aborting Build' -f $PesterObject.FailedCount)
}


# Synopsis: Fails the build if the code coverage is under predefined threshold
task Pester_if_Code_Coverage_Under_Threshold {

    if (!(Split-path -isAbsolute $OutputDirectory)) {
        $OutputDirectory = Join-Path -Path $ProjectPath -ChildPath $OutputDirectory
        Write-Build Yellow "Absolute path to Output Directory is $OutputDirectory"
    }

    if (!(Split-path -isAbsolute $PesterOutputFolder)) {
        $PesterOutputFolder = Join-Path $OutputDirectory $PesterOutputFolder
    }

    $os = if($isWindows -or $PSVersionTable.PSVersion.Major -le 5) {
        'Windows'
    }
    elseif($isMacOS) {
        'MacOS'
    }
    else {
        'Linux'
    }

    if ([String]::IsNullOrEmpty($ModuleVersion)) {
        $ModuleInfo = Import-PowerShellDataFile "$OutputDirectory/$ProjectName/*/$ProjectName.psd1" -ErrorAction Stop
        if($ModuleInfo.PrivateData.PSData.Prerelease) {
            $ModuleVersion = $ModuleInfo.ModuleVersion + "-" + $ModuleInfo.PrivateData.PSData.Prerelease
        }
        else {
            $ModuleInfo.ModuleVersion
        }
    }
    else {
        $ModuleVersion, $BuildMetadata = $ModuleVersion -split '\+', 2
        $ModuleVersionFolder, $PreReleaseTag = $ModuleVersion -split '\-', 2
    }

    $PSVersion = 'PSv.{0}' -f $PSVersionTable.PSVersion
    $PesterOutputFileFileName = "{0}_v{1}.{2}.{3}.xml" -f $ProjectName, $ModuleVersion, $os, $PSVersion
    $PesterResultObjectClixml = Join-Path $PesterOutputFolder "PesterObject_$PesterOutputFileFileName"
    Write-Build White "`tPester Output Object = $PesterResultObjectClixml"


    if (-Not (Test-Path $PesterResultObjectClixml)) {
        if ( $CodeCoverageThreshold -eq 0 ) {
            Write-Build Green "Pester run and Coverage bypassed. No Pester output found but allowed."
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

    if (!(Split-path -isAbsolute $OutputDirectory)) {
        $OutputDirectory = Join-Path -Path $ProjectPath -ChildPath $OutputDirectory
        Write-Build Yellow "Absolute path to Output Directory is $OutputDirectory"
    }

    if (!(Split-path -isAbsolute $PesterOutputFolder)) {
        $PesterOutputFolder = Join-Path $OutputDirectory $PesterOutputFolder
    }

    if (!(Test-Path $PesterOutputFolder)) {
        Write-Build Yellow "Creating folder $PesterOutputFolder"
        $null = New-Item -ItemType Directory -force $PesterOutputFolder -ErrorAction Stop
    }

    $os = if($isWindows -or $PSVersionTable.PSVersion.Major -le 5) {
        'Windows'
    }
    elseif($isMacOS) {
        'MacOS'
    }
    else {
        'Linux'
    }

    if ([String]::IsNullOrEmpty($ModuleVersion)) {
        $ModuleInfo = Import-PowerShellDataFile "$OutputDirectory/$ProjectName/*/$ProjectName.psd1" -ErrorAction Stop
        if($ModuleInfo.PrivateData.PSData.Prerelease) {
            $ModuleVersion = $ModuleInfo.ModuleVersion + "-" + $ModuleInfo.PrivateData.PSData.Prerelease
        }
        else {
            $ModuleInfo.ModuleVersion
        }
    }
    else {
        $ModuleVersion, $BuildMetadata = $ModuleVersion -split '\+', 2
        $ModuleVersionFolder, $PreReleaseTag = $ModuleVersion -split '\-', 2
    }

    $PSVersion = 'PSv.{0}' -f $PSVersionTable.PSVersion
    $PesterOutputFileFileName = "{0}_v{1}.{2}.{3}.xml" -f $ProjectName, $ModuleVersion, $os, $PSVersion
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
