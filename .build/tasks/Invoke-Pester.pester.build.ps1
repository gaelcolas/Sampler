Param (
    # Project path
    [Parameter()]
    [string]
    $ProjectPath = (property ProjectPath $BuildRoot),

    [Parameter()]
    # Base directory of all output (default to 'output')
    [string]
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

    [Parameter()]
    [string]
    $ProjectName = (property ProjectName ''),

    [Parameter()]
    [string]
    $PesterOutputFolder = (property PesterOutputFolder 'testResults'),

    [Parameter()]
    [string]
    $PesterOutputFormat = (property PesterOutputFormat ''),

    [Parameter()]
    [object[]]
    $PesterScript = (property PesterScript ''),

    [Parameter()]
    [string[]]
    $PesterTag = (property PesterTag @()),

    [Parameter()]
    [string[]]
    $PesterExcludeTag = (property PesterExcludeTag @()),

    [Parameter()]
    [String]
    $CodeCoverageThreshold = (property CodeCoverageThreshold ''),

    # Build Configuration object
    [Parameter()]
    $BuildInfo = (property BuildInfo @{ })
)

Import-Module -Name "$PSScriptRoot/Common.Functions.psm1"

# Synopsis: Making sure the Module meets some quality standard (help, tests).
task Invoke_pester_tests {
    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-ProjectName -BuildRoot $BuildRoot
    }

    if (!(Split-Path -isAbsolute $OutputDirectory))
    {
        $OutputDirectory = Join-Path -Path $ProjectPath -ChildPath $OutputDirectory
        Write-Build Yellow "Absolute path to Output Directory is $OutputDirectory"
    }

    if (!(Split-Path -isAbsolute $PesterOutputFolder))
    {
        $PesterOutputFolder = Join-Path $OutputDirectory $PesterOutputFolder
    }

    $getModuleVersionParameters = @{
        OutputDirectory = $OutputDirectory
        ProjectName     = $ProjectName
    }

    $ModuleVersion = Get-ModuleVersion @getModuleVersionParameters

    if (!(Test-Path $PesterOutputFolder))
    {
        Write-Build Yellow "Creating folder $PesterOutputFolder"
        $null = New-Item -ItemType Directory -force $PesterOutputFolder -ErrorAction Stop
    }

    $GetCodeCoverageThresholdParameters = @{
        CodeCoverageThreshold = $CodeCoverageThreshold
        BuildInfo             = $BuildInfo
    }

    $CodeCoverageThreshold = Get-CodeCoverageThreshold @GetCodeCoverageThresholdParameters

    $DefaultPesterParams = @{
        OutputFormat                 = 'NUnitXML'
        PassThru                     = $true
        CodeCoverageOutputFileFormat = 'JaCoCo'
        Script                       = ('tests', (Join-Path $ProjectName 'tests'))
    }

    $DefaultExcludeFromCodeCoverage = @('test')

    # Build.ps1 parameters should be top priority
    # BuildInfo values should come next
    # Otherwise we should set some defaults
    $PesterCmd = Get-Command Invoke-Pester
    foreach ($ParamName in $PesterCmd.Parameters.Keys)
    {
        $TaskParamName = "Pester$ParamName"
        if (!(Get-Variable -Name $TaskParamName -ValueOnly -ErrorAction SilentlyContinue) -and ($PesterBuildConfig = $BuildInfo.Pester))
        {
            # The Variable is set to '' so we should try to use the Config'd one if exists
            if ($ParamValue = $PesterBuildConfig.($ParamName))
            {
                Write-Build DarkGray "Using $TaskParamName from Build Config"
                Set-Variable -Name $TaskParamName -Value $ParamValue
            } # or use a default if available
            elseif ($DefaultPesterParams.ContainsKey($ParamName))
            {
                Write-Build DarkGray "Using $TaskParamName from Defaults"
                Set-Variable -Name $TaskParamName -Value $DefaultPesterParams.($ParamName)
            }
        }
        else
        {
            Write-Build DarkGray "Using $TaskParamName from Build Invocation Parameters"
        }
    }

    # Code Coverage Exclude
    if (!$ExcludeFromCodeCoverage -and ($PesterBuildConfig = $BuildInfo.Pester))
    {
        if ($PesterBuildConfig.ContainsKey('ExcludeFromCodeCoverage'))
        {
            $ExcludeFromCodeCoverage = $PesterBuildConfig['ExcludeFromCodeCoverage']
        }
        else
        {
            $ExcludeFromCodeCoverage = $DefaultExcludeFromCodeCoverage
        }
    }

    "`tProject Path  = $ProjectPath"
    "`tProject Name  = $ProjectName"
    "`tTest Scripts  = $($PesterScript -join ', ')"
    "`tTags          = $($PesterTag -join ', ')"
    "`tExclude Tags  = $($PesterExcludeTag -join ', ')"
    "`tExclude Cov.  = $($ExcludeFromCodeCoverage -join ', ')"
    "`tModuleVersion = $ModuleVersion"

    $osShortName = Get-OperatingSystemShortName

    $powerShellVersion = 'PSv.{0}' -f $PSVersionTable.PSVersion

    $getPesterOutputFileFileNameParameters = @{
        ProjectName = $ProjectName
        ModuleVersion = $ModuleVersion
        OsShortName = $osShortName
        PowerShellVersion = $powerShellVersion
    }

    $PesterOutputFileFileName = Get-PesterOutputFileFileName @getPesterOutputFileFileNameParameters
    $PesterOutputFullPath = Join-Path $PesterOutputFolder "$($PesterOutputFormat)_$PesterOutputFileFileName"

    $moduleUnderTest = Import-Module $ProjectName -PassThru
    $PesterCodeCoverage = (Get-ChildItem -Path $moduleUnderTest.ModuleBase -Include *.psm1, *.ps1 -Recurse).Where{
        $result = $true
        foreach ($ExclPath in $ExcludeFromCodeCoverage)
        {
            if (!(Split-Path -IsAbsolute $ExclPath))
            {
                $ExclPath = Join-Path $moduleUnderTest.ModuleBase $ExclPath
            }
            if ($_.FullName -Match ([regex]::Escape($ExclPath)))
            {
                $result = $false
            }
        }
        $result
    }

    $PesterParams = @{
        OutputFormat = $PesterOutputFormat
        OutputFile   = $PesterOutputFullPath
        PassThru     = $true
    }

    $getCodeCoverageOutputFile = @{
        BuildInfo = $BuildInfo
        PesterOutputFolder = $PesterOutputFolder
    }

    $CodeCoverageOutputFile = Get-CodeCoverageOutputFile @getCodeCoverageOutputFile

    if (-not $CodeCoverageOutputFile)
    {
        $CodeCoverageOutputFile = (Join-Path $PesterOutputFolder "CodeCov_$PesterOutputFileFileName")
    }

    if ($codeCoverageThreshold -gt 0)
    {
        $PesterParams.Add('CodeCoverage', $PesterCodeCoverage)
        $PesterParams.Add('CodeCoverageOutputFile', $CodeCoverageOutputFile)
        $PesterParams.Add('CodeCoverageOutputFileFormat', $PesterCodeCoverageOutputFileFormat)
    }

    "`tCodeCoverage  = $($PesterParams['CodeCoverage'])"
    "`tCodeCoverageOutputFile  = $($PesterParams['CodeCoverageOutputFile'])"
    "`tCodeCoverageOutputFileFormat  = $($PesterParams['CodeCoverageOutputFileFormat'])"

    $codeCoverageOutputFileEncoding = Get-CodeCoverageOutputFileEncoding -BuildInfo $BuildInfo

    if ($codeCoverageThreshold -gt 0 -and $codeCoverageOutputFileEncoding)
    {
        $PesterParams.Add('CodeCoverageOutputFileEncoding', $codeCoverageOutputFileEncoding)

        "`tCodeCoverageOutputFileEncoding  = $($PesterParams['CodeCoverageOutputFileEncoding'])"
    }

    if ($PesterExcludeTag.count -gt 0) {
        $PesterParams.Add('ExcludeTag', $PesterExcludeTag)
    }

    if ($PesterTag.Count -gt 0)
    {
        $PesterParams.Add('Tag', $PesterTag)
    }

    # Test folders is specified, do not run invoke-pester against $BuildRoot
    if ($PesterScript.count -gt 0)
    {
        $PesterParams.Add('Script', @())
        Write-Build DarkGray " Adding PesterScript to params"

        # Assuming that if the first item in the PesterScript array is of a certain type,
        # all other items will be of the same type.
        switch ($PesterScript[0])
        {
            { $_ -is [System.String] } {
                foreach ($TestFolder in $PesterScript)
                {
                    if (!(Split-Path -isAbsolute $TestFolder))
                    {
                        $TestFolder = Join-Path $ProjectPath $TestFolder
                    }

                    Write-Build DarkGray "      ... $TestFolder"
                    # The Absolute path to this folder exists, adding to the list of pester scripts to run
                    if (Test-Path $TestFolder)
                    {
                        $PesterParams.Script += $TestFolder
                    }
                }
            }
            { $_ -is [System.Collections.Hashtable] } {
                foreach ($scriptItem in $PesterScript)
                {
                    Write-Build DarkGray "      ... $(Convert-HashtableToString -Hashtable $scriptItem)"
                    $PesterParams.Script += $scriptItem
                }
            }
        }
    }

    foreach ($ParamName in $PesterCmd.Parameters.keys)
    {
        $ParamValueFromScope = (Get-Variable "Pester$ParamName" -ValueOnly -ErrorAction SilentlyContinue)
        if (!$PesterParams.ContainsKey($ParamName) -and $ParamValueFromScope)
        {
            $PesterParams.Add($ParamName, $ParamValueFromScope)
        }
    }

    if ($codeCoverageThreshold -eq 0 -or (-not $codeCoverageThreshold))
    {
        Write-Build DarkGray "Removing Code Coverage parameters"
        foreach ($CodeCovParam in $PesterParams.Keys.Where{ $_ -like 'CodeCov*' })
        {
            $PesterParams.Remove($CodeCovParam)
        }
    }

    Import-Module -Name Pester -MinimumVersion 4.0
    $script:TestResults = Invoke-Pester @PesterParams
    $PesterResultObjectCliXml = Join-Path $PesterOutputFolder "PesterObject_$PesterOutputFileFileName"
    $null = $script:TestResults | Export-Clixml -Path $PesterResultObjectCliXml -Force

}

# Synopsis: This task ensures the build job fails if the test aren't successful.
task Fail_Build_if_Pester_Tests_failed {

    "Asserting that no test failed"

    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-ProjectName -BuildRoot $BuildRoot
    }

    if (!(Split-Path -isAbsolute $OutputDirectory))
    {
        $OutputDirectory = Join-Path -Path $ProjectPath -ChildPath $OutputDirectory
        Write-Build Yellow "Absolute path to Output Directory is $OutputDirectory"
    }

    if (!(Split-Path -isAbsolute $PesterOutputFolder))
    {
        $PesterOutputFolder = Join-Path $OutputDirectory $PesterOutputFolder
    }

    $osShortName = Get-OperatingSystemShortName

    $GetModuleVersionParameters = @{
        OutputDirectory = $OutputDirectory
        ProjectName     = $ProjectName
    }

    $ModuleVersion = Get-ModuleVersion @GetModuleVersionParameters

    $powerShellVersion = 'PSv.{0}' -f $PSVersionTable.PSVersion
    $getPesterOutputFileFileNameParameters = @{
        ProjectName = $ProjectName
        ModuleVersion = $ModuleVersion
        OsShortName = $osShortName
        PowerShellVersion = $powerShellVersion
    }

    $PesterOutputFileFileName = Get-PesterOutputFileFileName @getPesterOutputFileFileNameParameters
    $PesterResultObjectClixml = Join-Path $PesterOutputFolder "PesterObject_$PesterOutputFileFileName"

    Write-Build White "`tPester Output Object = $PesterResultObjectClixml"

    if (-not (Test-Path $PesterResultObjectClixml)) {
        if ( $CodeCoverageThreshold -eq 0 ) {
            Write-Build Green "Pester run and Coverage bypassed. No Pester output found but allowed."
            return
        }
        else
        {
            Throw "No command were tested. Threshold of $CodeCoverageThreshold % not met"
        }
    }
    else
    {
        $PesterObject = Import-Clixml -Path $PesterResultObjectClixml -ErrorAction Stop
        assert ($PesterObject.FailedCount -eq 0) ('Failed {0} tests. Aborting Build' -f $PesterObject.FailedCount)
    }
}

# Synopsis: Fails the build if the code coverage is under predefined threshold.
task Pester_if_Code_Coverage_Under_Threshold {
    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-ProjectName -BuildRoot $BuildRoot
    }

    if (!$CodeCoverageThreshold)
    {
        if ($CodeCoverageThreshold = $BuildInfo.Pester.CodeCoverageThreshold)
        {
            Write-Verbose "Using CodeCoverage Threshold from config file"
        }
        else
        {
            $CodeCoverageThreshold = 0
        }
    }

    if (!(Split-Path -isAbsolute $OutputDirectory))
    {
        $OutputDirectory = Join-Path -Path $ProjectPath -ChildPath $OutputDirectory
        Write-Build Yellow "Absolute path to Output Directory is $OutputDirectory"
    }

    if (!(Split-Path -isAbsolute $PesterOutputFolder))
    {
        $PesterOutputFolder = Join-Path $OutputDirectory $PesterOutputFolder
    }

    $osShortName = Get-OperatingSystemShortName

    $GetModuleVersionParameters = @{
        OutputDirectory = $OutputDirectory
        ProjectName     = $ProjectName
    }

    $ModuleVersion = Get-ModuleVersion @GetModuleVersionParameters

    $powerShellVersion = 'PSv.{0}' -f $PSVersionTable.PSVersion

    $getPesterOutputFileFileNameParameters = @{
        ProjectName = $ProjectName
        ModuleVersion = $ModuleVersion
        OsShortName = $osShortName
        PowerShellVersion = $powerShellVersion
    }

    $PesterOutputFileFileName = Get-PesterOutputFileFileName @getPesterOutputFileFileNameParameters
    $PesterResultObjectClixml = Join-Path $PesterOutputFolder "PesterObject_$PesterOutputFileFileName"
    Write-Build White "`tPester Output Object = $PesterResultObjectClixml"

    if (-Not (Test-Path $PesterResultObjectClixml)) {
        if ( $CodeCoverageThreshold -eq 0 ) {
            Write-Build Green "Pester run and Coverage bypassed. No Pester output found but allowed."
            return
        }
        else
        {
            Throw "No command were tested. Threshold of $CodeCoverageThreshold % not met"
        }
    }
    else
    {
        $PesterObject = Import-Clixml -Path $PesterResultObjectClixml
    }

    if ($PesterObject.CodeCoverage.NumberOfCommandsAnalyzed)
    {
        $coverage = $PesterObject.CodeCoverage.NumberOfCommandsExecuted / $PesterObject.CodeCoverage.NumberOfCommandsAnalyzed
        if ($coverage -lt $CodeCoverageThreshold / 100)
        {
            Throw "The Code Coverage FAILURE: ($($Coverage*100) %) is under the threshold of $CodeCoverageThreshold %."
        }
        else
        {
            Write-Build Green "Code Coverage SUCCESS with value of $($coverage*100) % (Threshold $CodeCoverageThreshold %)"
        }
    }
}

# Synopsis: Uploading Unit Test results to AppVeyor.
task Upload_Test_Results_To_AppVeyor -If { (property BuildSystem 'unknown') -eq 'AppVeyor' } {
    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-ProjectName -BuildRoot $BuildRoot
    }

    if (!(Split-Path -isAbsolute $OutputDirectory))
    {
        $OutputDirectory = Join-Path -Path $ProjectPath -ChildPath $OutputDirectory
        Write-Build Yellow "Absolute path to Output Directory is $OutputDirectory"
    }

    if (!(Split-Path -isAbsolute $PesterOutputFolder))
    {
        $PesterOutputFolder = Join-Path $OutputDirectory $PesterOutputFolder
    }

    if (!(Test-Path $PesterOutputFolder))
    {
        Write-Build Yellow "Creating folder $PesterOutputFolder"
        $null = New-Item -ItemType Directory -force $PesterOutputFolder -ErrorAction Stop
    }

    $osShortName = Get-OperatingSystemShortName

    $GetModuleVersionParameters = @{
        OutputDirectory = $OutputDirectory
        ProjectName     = $ProjectName
    }

    $ModuleVersion = Get-ModuleVersion @GetModuleVersionParameters

    $powerShellVersion = 'PSv.{0}' -f $PSVersionTable.PSVersion

    $getPesterOutputFileFileNameParameters = @{
        ProjectName = $ProjectName
        ModuleVersion = $ModuleVersion
        OsShortName = $osShortName
        PowerShellVersion = $powerShellVersion
    }

    $PesterOutputFileFileName = Get-PesterOutputFileFileName @getPesterOutputFileFileNameParameters
    $PesterOutputFullPath = Join-Path $PesterOutputFolder "$($PesterOutputFormat)_$PesterOutputFileFileName"

    $TestResultFile = Get-Item $PesterOutputFullPath -ErrorAction Ignore
    if ($TestResultFile)
    {
        Write-Build Green "  Uploading test results $TestResultFile to Appveyor"
        $TestResultFile | Add-TestResultToAppveyor
        Write-Build Green "  Upload Complete"
    }
}

# Synopsis: Meta task that runs Quality Tests, and fails if they're not successful
task Pester_Tests_Stop_On_Fail Invoke_pester_tests, Upload_Test_Results_To_AppVeyor, Fail_Build_if_Pester_Tests_failed
