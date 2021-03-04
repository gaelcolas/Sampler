param
(
    # Project path
    [Parameter()]
    [System.String]
    $ProjectPath = (property ProjectPath $BuildRoot),

    [Parameter()]
    # Base directory of all output (default to 'output')
    [System.String]
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

    [Parameter()]
    [System.String]
    $ProjectName = (property ProjectName ''),

    [Parameter()]
    [System.String]
    $PesterOutputFolder = (property PesterOutputFolder 'testResults'),

    [Parameter()]
    [System.String]
    $PesterOutputFormat = (property PesterOutputFormat ''),

    [Parameter()]
    [System.Object[]]
    $PesterScript = (property PesterScript ''),

    [Parameter()]
    [System.String[]]
    $PesterTag = (property PesterTag @()),

    [Parameter()]
    [System.String[]]
    $PesterExcludeTag = (property PesterExcludeTag @()),

    [Parameter()]
    [System.String]
    $CodeCoverageThreshold = (property CodeCoverageThreshold ''),

    # Build Configuration object
    [Parameter()]
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)

# Synopsis: Making sure the Module meets some quality standard (help, tests).
task Invoke_Pester_Tests {
    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-SamplerProjectName -BuildRoot $BuildRoot
    }

    if (-not (Split-Path -IsAbsolute $OutputDirectory))
    {
        $OutputDirectory = Join-Path -Path $ProjectPath -ChildPath $OutputDirectory

        Write-Build -Color 'Yellow' -Text "Absolute path to Output Directory is $OutputDirectory"
    }

    if (-not (Split-Path -IsAbsolute $PesterOutputFolder))
    {
        $PesterOutputFolder = Join-Path -Path $OutputDirectory -ChildPath $PesterOutputFolder
    }

    $getModuleVersionParameters = @{
        OutputDirectory = $OutputDirectory
        ProjectName     = $ProjectName
    }

    $ModuleVersion = Get-BuiltModuleVersion @getModuleVersionParameters

    if (-not (Test-Path -Path $PesterOutputFolder))
    {
        Write-Build -Color 'Yellow' -Text "Creating folder $PesterOutputFolder"

        $null = New-Item -Path $PesterOutputFolder -ItemType 'Directory' -Force -ErrorAction 'Stop'
    }

    $GetCodeCoverageThresholdParameters = @{
        RuntimeCodeCoverageThreshold = $CodeCoverageThreshold
        BuildInfo             = $BuildInfo
    }

    $CodeCoverageThreshold = Get-CodeCoverageThreshold @GetCodeCoverageThresholdParameters

    Import-Module -Name 'Pester' -MinimumVersion 4.0 -ErrorAction Stop

    $isPester5 = (Get-Module -Name 'Pester').Version -ge '5.0.0'

    # Same parameters for both Pester 4 and Pester 5.
    $defaultPesterParams = @{
        PassThru = $true
    }

    $defaultScriptPaths = @(
        'tests',
        (Join-Path -Path $ProjectName -ChildPath 'tests')
    )

    if ($isPester5)
    {
        $defaultPesterParams['Path'] = $defaultScriptPaths
        $defaultPesterParams['Output'] = 'Detailed'
    }
    else
    {
        $defaultPesterParams['Script'] = $defaultScriptPaths
        $defaultPesterParams['CodeCoverageOutputFileFormat'] = 'JaCoCo'
        $defaultPesterParams['OutputFormat'] = 'NUnitXML'
    }

    $DefaultExcludeFromCodeCoverage = @('test')

    $pesterCmd = Get-Command -Name 'Invoke-Pester'

    <#
        This will build the Pester* variables (e.g. PesterScript, or
        PesterOutputFormat) in this scope that are used in the rest of the code.
        It will use values for the variables in the following order:

        1. Skip creating the variable if a variable is already available because
           it was already set in a passed parameter (Pester*).
        2. Use the value from a property in the build.yaml under the key 'Pester:'.
        3. Use the default value set previously in the variable $defaultPesterParams.
    #>
    foreach ($paramName in $pesterCmd.Parameters.Keys)
    {
        $taskParamName = "Pester$paramName"

        $pesterBuildConfig = $BuildInfo.Pester

        # Skip if a value was passed as a parameter.
        if (-not (Get-Variable -Name $taskParamName -ValueOnly -ErrorAction 'SilentlyContinue') -and ($pesterBuildConfig))
        {
            $paramValue = $pesterBuildConfig.($paramName)

            # The Variable is set to '' so we should try to use the Config'd one if exists
            if ($paramValue)
            {
                Write-Build -Color 'DarkGray' -Text "Using $taskParamName from Build Config"

                Set-Variable -Name $taskParamName -Value $paramValue
            } # or use a default if available
            elseif ($defaultPesterParams.ContainsKey($paramName))
            {
                Write-Build -Color 'DarkGray' -Text "Using $taskParamName from Defaults"

                Set-Variable -Name $taskParamName -Value $DefaultPesterParams.($paramName)
            }
        }
        else
        {
            Write-Build -Color 'DarkGray' -Text "Using $taskParamName from Build Invocation Parameters"
        }
    }

    <#
        For Pester 5, switch over to Pester 4 variable name. This is done to reduce
        the code changes needed to get both Pester 4 and Pester 5 compatibility.

        The variable PesterPath comes from the child key 'Path:' under the parent
        key 'Pester:' in the build configuration file. For Pester 4 the key
        is 'Script:' instead of 'Path:'.

        For Pester 5, if the variable $PesterScript is set then the user passed in
        a value in the parameter 'PesterScript' (most likely through the build.ps1).
        If that is the case the value in $PesterScript take precedence. If there is
        no value in $PesterScript then we set it to the value of $PesterPath.
    #>
    if ($isPester5 -and [System.String]::IsNullOrEmpty($PesterScript))
    {
        $PesterScript = $PesterPath
    }

    $pesterBuildConfig = $BuildInfo.Pester

    # Code Coverage Exclude
    if (-not $ExcludeFromCodeCoverage -and ($pesterBuildConfig))
    {
        if ($pesterBuildConfig.ContainsKey('ExcludeFromCodeCoverage'))
        {
            $ExcludeFromCodeCoverage = $pesterBuildConfig['ExcludeFromCodeCoverage']
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

    $pesterOutputFileFileName = Get-PesterOutputFileFileName @getPesterOutputFileFileNameParameters
    $pesterOutputFullPath = Join-Path -Path $PesterOutputFolder -ChildPath "$($PesterOutputFormat)_$pesterOutputFileFileName"

    $moduleUnderTest = Import-Module -Name $ProjectName -PassThru
    $PesterCodeCoverage = (Get-ChildItem -Path $moduleUnderTest.ModuleBase -Include @('*.psm1', '*.ps1') -Recurse).Where{
        $result = $true

        foreach ($excludePath in $ExcludeFromCodeCoverage)
        {
            if (-not (Split-Path -IsAbsolute $excludePath))
            {
                $excludePath = Join-Path -Path $moduleUnderTest.ModuleBase -ChildPath $excludePath
            }

            if ($_.FullName -match ([regex]::Escape($excludePath)))
            {
                $result = $false
            }
        }

        $result
    }

    $pesterParams = @{
        PassThru = $true
    }

    if ($isPester5)
    {
        $pesterParams['Output'] = $PesterOutput
    }
    else
    {
        $pesterParams['OutputFormat'] = $PesterOutputFormat
        $pesterParams['OutputFile'] = $pesterOutputFullPath
    }

    $getCodeCoverageOutputFile = @{
        BuildInfo = $BuildInfo
        PesterOutputFolder = $PesterOutputFolder
    }

    $CodeCoverageOutputFile = Get-SamplerCodeCoverageOutputFile @getCodeCoverageOutputFile

    if (-not $CodeCoverageOutputFile)
    {
        $CodeCoverageOutputFile = (Join-Path -Path $PesterOutputFolder -ChildPath "CodeCov_$pesterOutputFileFileName")
    }

    if (-not $isPester5 -and $codeCoverageThreshold -gt 0)
    {
        $pesterParams.Add('CodeCoverage', $PesterCodeCoverage)
        $pesterParams.Add('CodeCoverageOutputFile', $CodeCoverageOutputFile)
        $pesterParams.Add('CodeCoverageOutputFileFormat', $PesterCodeCoverageOutputFileFormat)
    }

    "`t"
    "`tCodeCoverage                    = $($pesterParams['CodeCoverage'])"
    "`tCodeCoverageOutputFile          = $($pesterParams['CodeCoverageOutputFile'])"
    "`tCodeCoverageOutputFileFormat    = $($pesterParams['CodeCoverageOutputFileFormat'])"

    $codeCoverageOutputFileEncoding = Get-SamplerCodeCoverageOutputFileEncoding -BuildInfo $BuildInfo

    if (-not $isPester5 -and $codeCoverageThreshold -gt 0 -and $codeCoverageOutputFileEncoding)
    {
        $pesterParams.Add('CodeCoverageOutputFileEncoding', $codeCoverageOutputFileEncoding)
    }

    "`tCodeCoverageOutputFileEncoding  = $($pesterParams['CodeCoverageOutputFileEncoding'])"

    if ($PesterExcludeTag.Count -gt 0)
    {
        if ($isPester5)
        {
            $pesterParams.Add('ExcludeTagFilter', $PesterExcludeTag)
        }
        else
        {
            $pesterParams.Add('ExcludeTag', $PesterExcludeTag)
        }
    }

    if ($PesterTag.Count -gt 0)
    {
        if ($isPester5)
        {
            $pesterParams.Add('TagFilter', $PesterTag)
        }
        else
        {
            $pesterParams.Add('Tag', $PesterTag)
        }
    }

    # Test folders is specified, do not run invoke-pester against $BuildRoot
    if ($PesterScript.Count -gt 0)
    {
        if ($isPester5)
        {
            $pesterParams.Add('Path', @())
        }
        else
        {
            $pesterParams.Add('Script', @())
        }

        Write-Build -Color 'DarkGray' -Text " Adding PesterScript to params"

        <#
            Assuming that if the first item in the PesterScript array is of a certain type,
            all other items will be of the same type.
        #>
        switch ($PesterScript[0])
        {
            { $_ -is [System.String] }
            {
                foreach ($testFolder in $PesterScript)
                {
                    if (-not (Split-Path -IsAbsolute $testFolder))
                    {
                        $testFolder = Join-Path -Path $ProjectPath -ChildPath $testFolder
                    }

                    Write-Build -Color 'DarkGray' -Text "      ... $testFolder"

                    # The Absolute path to this folder exists, adding to the list of pester scripts to run
                    if (Test-Path -Path $testFolder)
                    {
                        if ($isPester5)
                        {
                            $pesterParams.Path += $testFolder
                        }
                        else
                        {
                            $pesterParams.Script += $testFolder
                        }
                    }
                }
            }

            { $_ -is [System.Collections.Hashtable] }
            {
                foreach ($scriptItem in $PesterScript)
                {
                    Write-Build -Color 'DarkGray' -Text "      ... $(Convert-SamplerHashtableToString -Hashtable $scriptItem)"

                    if ($isPester5)
                    {
                        $pesterParams.Path += $scriptItem
                    }
                    else
                    {
                        $pesterParams.Script += $scriptItem
                    }
                }
            }
        }
    }

    # Add all Pester* variables in current scope into the $pesterParams hashtable.
    foreach ($paramName in $pesterCmd.Parameters.keys)
    {
        if (-not $isPester5 -or ($isPester5 -and 'Simple' -in $pesterCmd.Parameters.$paramName.ParameterSets.Keys))
        {
            $paramValueFromScope = (Get-Variable -Name "Pester$paramName" -ValueOnly -ErrorAction 'SilentlyContinue')

            if (-not $pesterParams.ContainsKey($paramName) -and $paramValueFromScope)
            {
                $pesterParams.Add($paramName, $paramValueFromScope)
            }
        }
    }

    if ($codeCoverageThreshold -eq 0 -or (-not $codeCoverageThreshold))
    {
        Write-Build -Color 'DarkGray' -Text "Removing Code Coverage parameters"

        foreach ($CodeCovParam in $pesterParams.Keys.Where{ $_ -like 'CodeCov*' })
        {
            $pesterParams.Remove($CodeCovParam)
        }
    }

    $script:TestResults = Invoke-Pester @pesterParams

    $PesterResultObjectCliXml = Join-Path -Path $PesterOutputFolder -ChildPath "PesterObject_$pesterOutputFileFileName"

    $null = $script:TestResults |
        Export-Clixml -Path $PesterResultObjectCliXml -Force

}

# Synopsis: This task ensures the build job fails if the test aren't successful.
task Fail_Build_If_Pester_Tests_Failed {
    "Asserting that no test failed"

    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-SamplerProjectName -BuildRoot $BuildRoot
    }

    if (-not (Split-Path -IsAbsolute $OutputDirectory))
    {
        $OutputDirectory = Join-Path -Path $ProjectPath -ChildPath $OutputDirectory

        Write-Build -Color 'Yellow' -Text "Absolute path to Output Directory is $OutputDirectory"
    }

    if (-not (Split-Path -IsAbsolute $PesterOutputFolder))
    {
        $PesterOutputFolder = Join-Path -Path $OutputDirectory -ChildPath $PesterOutputFolder
    }

    $osShortName = Get-OperatingSystemShortName

    $GetModuleVersionParameters = @{
        OutputDirectory = $OutputDirectory
        ProjectName     = $ProjectName
    }

    $ModuleVersion = Get-BuiltModuleVersion @GetModuleVersionParameters

    $powerShellVersion = 'PSv.{0}' -f $PSVersionTable.PSVersion

    $getPesterOutputFileFileNameParameters = @{
        ProjectName = $ProjectName
        ModuleVersion = $ModuleVersion
        OsShortName = $osShortName
        PowerShellVersion = $powerShellVersion
    }

    $PesterOutputFileFileName = Get-PesterOutputFileFileName @getPesterOutputFileFileNameParameters

    $PesterResultObjectClixml = Join-Path -Path $PesterOutputFolder -ChildPath "PesterObject_$PesterOutputFileFileName"

    Write-Build -Color 'White' -Text "`tPester Output Object = $PesterResultObjectClixml"

    if (-not (Test-Path -Path $PesterResultObjectClixml))
    {
        if ($CodeCoverageThreshold -eq 0)
        {
            Write-Build -Color 'Green' -Text "Pester run and Coverage bypassed. No Pester output found but allowed."

            return
        }
        else
        {
            throw "No command were tested. Threshold of $CodeCoverageThreshold % not met"
        }
    }
    else
    {
        $pesterObject = Import-Clixml -Path $PesterResultObjectClixml -ErrorAction 'Stop'

        Assert-Build -Condition ($pesterObject.FailedCount -eq 0) -Message ('Failed {0} tests. Aborting Build' -f $pesterObject.FailedCount)
    }
}

# Synopsis: Fails the build if the code coverage is under predefined threshold.
task Pester_If_Code_Coverage_Under_Threshold {
    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-SamplerProjectName -BuildRoot $BuildRoot
    }

    if (-not $CodeCoverageThreshold)
    {
        if ($CodeCoverageThreshold = $BuildInfo.Pester.CodeCoverageThreshold)
        {
            Write-Verbose -Message "Using CodeCoverage Threshold from config file"
        }
        else
        {
            $CodeCoverageThreshold = 0
        }
    }

    if (-not (Split-Path -IsAbsolute $OutputDirectory))
    {
        $OutputDirectory = Join-Path -Path $ProjectPath -ChildPath $OutputDirectory

        Write-Build -Color 'Yellow' -Text "Absolute path to Output Directory is $OutputDirectory"
    }

    if (-not (Split-Path -IsAbsolute $PesterOutputFolder))
    {
        $PesterOutputFolder = Join-Path -Path $OutputDirectory -ChildPath $PesterOutputFolder
    }

    $osShortName = Get-OperatingSystemShortName

    $GetModuleVersionParameters = @{
        OutputDirectory = $OutputDirectory
        ProjectName     = $ProjectName
    }

    $ModuleVersion = Get-BuiltModuleVersion @GetModuleVersionParameters

    $powerShellVersion = 'PSv.{0}' -f $PSVersionTable.PSVersion

    $getPesterOutputFileFileNameParameters = @{
        ProjectName = $ProjectName
        ModuleVersion = $ModuleVersion
        OsShortName = $osShortName
        PowerShellVersion = $powerShellVersion
    }

    $PesterOutputFileFileName = Get-PesterOutputFileFileName @getPesterOutputFileFileNameParameters

    $PesterResultObjectClixml = Join-Path $PesterOutputFolder "PesterObject_$PesterOutputFileFileName"

    Write-Build -Color 'White' -Text "`tPester Output Object = $PesterResultObjectClixml"

    if (-not (Test-Path -Path $PesterResultObjectClixml))
    {
        if ($CodeCoverageThreshold -eq 0)
        {
            Write-Build -Color 'Green' -Text "Pester run and Coverage bypassed. No Pester output found but allowed."

            return
        }
        else
        {
            throw "No command were tested. Threshold of $CodeCoverageThreshold % not met"
        }
    }
    else
    {
        $pesterObject = Import-Clixml -Path $PesterResultObjectClixml
    }

    if ($pesterObject.CodeCoverage.NumberOfCommandsAnalyzed)
    {
        $coverage = $pesterObject.CodeCoverage.NumberOfCommandsExecuted / $pesterObject.CodeCoverage.NumberOfCommandsAnalyzed
        if ($coverage -lt $CodeCoverageThreshold / 100)
        {
            throw "The Code Coverage FAILURE: ($($Coverage*100) %) is under the threshold of $CodeCoverageThreshold %."
        }
        else
        {
            Write-Build -Color Green -Text "Code Coverage SUCCESS with value of $($coverage*100) % (Threshold $CodeCoverageThreshold %)"
        }
    }
}

# Synopsis: Uploading Unit Test results to AppVeyor.
task Upload_Test_Results_To_AppVeyor -If { (property BuildSystem 'unknown') -eq 'AppVeyor' } {
    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-SamplerProjectName -BuildRoot $BuildRoot
    }

    if (-not (Split-Path -IsAbsolute $OutputDirectory))
    {
        $OutputDirectory = Join-Path -Path $ProjectPath -ChildPath $OutputDirectory

        Write-Build -Color 'Yellow' -Text "Absolute path to Output Directory is $OutputDirectory"
    }

    if (-not (Split-Path -IsAbsolute $PesterOutputFolder))
    {
        $PesterOutputFolder = Join-Path $OutputDirectory $PesterOutputFolder
    }

    if (-not (Test-Path -Path $PesterOutputFolder))
    {
        Write-Build -Color 'Yellow' -Text "Creating folder $PesterOutputFolder"

        $null = New-Item -Path $PesterOutputFolder -ItemType Directory -Force -ErrorAction 'Stop'
    }

    $osShortName = Get-OperatingSystemShortName

    $GetModuleVersionParameters = @{
        OutputDirectory = $OutputDirectory
        ProjectName     = $ProjectName
    }

    $ModuleVersion = Get-BuiltModuleVersion @GetModuleVersionParameters

    $powerShellVersion = 'PSv.{0}' -f $PSVersionTable.PSVersion

    $getPesterOutputFileFileNameParameters = @{
        ProjectName = $ProjectName
        ModuleVersion = $ModuleVersion
        OsShortName = $osShortName
        PowerShellVersion = $powerShellVersion
    }

    $pesterOutputFileFileName = Get-PesterOutputFileFileName @getPesterOutputFileFileNameParameters

    $pesterOutputFullPath = Join-Path -Path $PesterOutputFolder -ChildPath "$($PesterOutputFormat)_$pesterOutputFileFileName"

    $testResultFile = Get-Item -Path $pesterOutputFullPath -ErrorAction 'Ignore'

    if ($testResultFile)
    {
        Write-Build -Color 'Green' -Text "  Uploading test results $testResultFile to Appveyor"

        $testResultFile | Add-TestResultToAppveyor

        Write-Build -Color 'Green' -Text "  Upload Complete"
    }
}

# Synopsis: Meta task that runs Quality Tests, and fails if they're not successful
task Pester_Tests_Stop_On_Fail Invoke_Pester_Tests, Upload_Test_Results_To_AppVeyor, Fail_Build_If_Pester_Tests_Failed
