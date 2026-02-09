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
    $BuiltModuleSubdirectory = (property BuiltModuleSubdirectory ''),

    [Parameter()]
    [System.String]
    $ProjectName = (property ProjectName ''),

    [Parameter()]
    [System.String]
    $DscTestOutputFolder = (property DscTestOutputFolder 'testResults'),

    [Parameter()]
    [System.String]
    $DscTestOutputFormat = (property DscTestOutputFormat ''),

    [Parameter()]
    [System.String[]]
    $DscTestScript = (property DscTestScript ''),

    [Parameter()]
    [System.String[]]
    $DscTestTag = (property DscTestTag @()),

    [Parameter()]
    [System.String[]]
    $DscTestExcludeTag = (property DscTestExcludeTag @()),

    # Build Configuration object
    [Parameter()]
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)

# Synopsis: Making sure the Module meets some quality standard (help, tests)
task Invoke_DscResource_Tests {
    # Get the values for task variables, see https://github.com/gaelcolas/Sampler?tab=readme-ov-file#build-task-variables.
    . Set-SamplerTaskVariable

    $DscTestOutputFolder = Get-SamplerAbsolutePath -Path $DscTestOutputFolder -RelativeTo $OutputDirectory

    "`tDSC Test Output Folder   = '$DscTestOutputFolder'"

    $builtDscResourcesFolder = Get-SamplerAbsolutePath -Path 'DSCResources' -RelativeTo $builtModuleBase

    "`tBuilt DSC Resource Path  = '$builtDscResourcesFolder'"

    if (-not (Test-Path -Path $DscTestOutputFolder))
    {
        Write-Build -Color 'Yellow' -Text "Creating folder $DscTestOutputFolder"

        $null = New-Item -Path $DscTestOutputFolder -ItemType 'Directory' -Force -ErrorAction 'Stop'
    }

    $DscTestScript = $DscTestScript.Where{ -not [System.String]::IsNullOrEmpty($_) }
    $DscTestTag = $DscTestTag.Where{ -not [System.String]::IsNullOrEmpty($_) }
    $DscTestExcludeTag = $DscTestExcludeTag.Where{ -not [System.String]::IsNullOrEmpty($_) }

    # Same parameters for both Pester 4 and Pester 5.
    $defaultDscTestParams = @{
        PassThru = $true
    }

    $isPester5 = (Get-Module -Name 'Pester').Version -ge '5.0.0'

    if ($isPester5)
    {
        $defaultDscTestParams['Output'] = 'Detailed'
    }
    else
    {
        $defaultDscTestParams['OutputFile'] = $DscTestOutputFullPath
        $defaultDscTestParams['OutputFormat'] = 'NUnitXML'
    }

    Import-Module -Name 'DscResource.Test' -ErrorAction 'Stop'
    Import-Module -Name 'Pester' -MinimumVersion 4.0 -ErrorAction 'Stop'

    $dscTestCmd = Get-Command -Name Invoke-DscResourceTest

    <#
        This will build the DscTest* variables (e.g. PesterScript, or
        PesterOutputFormat) in this scope that are used in the rest of the code.
        It will use values for the variables in the following order:

        1. Skip creating the variable if a variable is already available because
           it was already set in a passed parameter (Pester*).
        2. Use the value from a property in the build.yaml under the key 'Pester:'.
        3. Use the default value set previously in the variable $defaultPesterParams.
    #>
    foreach ($paramName in $dscTestCmd.Parameters.Keys)
    {
        if (($paramName -eq 'ExcludeTagFilter' -or $paramName -eq 'TagFilter') -and -not $isPester5)
        {
            $paramName = $paramName -replace 'Filter'
        }

        $taskParamName = "DscTest$paramName"

        $DscTestBuildConfig = $BuildInfo.DscTest

        if (-not (Get-Variable -Name $taskParamName -ValueOnly -ErrorAction 'SilentlyContinue') -and ($DscTestBuildConfig))
        {
            $paramValue = $DscTestBuildConfig.($paramName)

            # The Variable is set to '' so we should try to use the Config'd one if exists
            if ($paramValue)
            {
                Write-Build -Color 'DarkGray' -Text "Using $taskParamName from Build Config"

                Set-Variable -Name $taskParamName -Value $paramValue
            } # or use a default if available
            elseif ($defaultDscTestParams.ContainsKey($paramName))
            {
                Write-Build -Color 'DarkGray' -Text "Using $taskParamName from Defaults"

                Set-Variable -Name $taskParamName -Value $defaultDscTestParams.($paramName)
            }
        }
        else
        {
            Write-Build -Color 'DarkGray' -Text "Using $taskParamName from Build Invocation Parameters"
        }
    }

    "`tTest Scripts             = $($DscTestScript -join ', ')"
    "`tTags                     = $($DscTestTag -join ', ')"
    "`tExclude Tags             = $($DscTestExcludeTag -join ', ')"

    $os = Get-OperatingSystemShortName

    $psVersion = 'PSv.{0}' -f $PSVersionTable.PSVersion
    $DscTestOutputFileFileName = "DscTest_{0}_v{1}.{2}.{3}.xml" -f $ProjectName, $ModuleVersion, $os, $psVersion
    $DscTestOutputFullPath = Join-Path -Path $DscTestOutputFolder -ChildPath "$($DscTestOutputFormat)_$DscTestOutputFileFileName"

    $dscTestParams = @{
        PassThru = $true
    }

    if ($isPester5)
    {
        $dscTestParams['Output'] = $DscTestOutput
    }
    else
    {
        $dscTestParams['OutputFormat'] = $DscTestOutputFormat
        $dscTestParams['OutputFile'] = $DscTestOutputFullPath
    }

    if ($DscTestModule)
    {
        $dscTestParams.Add('Module', $DscTestModule)
    }
    elseif ($DscTestFullyQualifiedModule)
    {
        $dscTestParams.Add('FullyQualifiedModule', $DscTestFullyQualifiedModule)
    }
    else
    {
        $dscTestParams.Add('ProjectPath', $ProjectPath)
    }

    if ($DscTestExcludeTag.Count -gt 0)
    {
        $dscTestParams.Add('ExcludeTag', $DscTestExcludeTag)
    }

    if ($DscTestTag.Count -gt 0)
    {
        $dscTestParams.Add('Tag', $DscTestTag)
    }

    # Test folders is specified, override invoke-DscResourceTest internal default
    if ($DscTestScript.Count -gt 0)
    {
        $dscTestParams.Add('Path', @())

        Write-Build -Color 'DarkGray' -Text " Adding DscTestScript to params"

        foreach ($testFolder in $DscTestScript)
        {
            if (-not (Split-Path -IsAbsolute $testFolder))
            {
                $testFolder = Join-Path -Path $ProjectPath -ChildPath $testFolder
            }

            Write-Build -Color 'DarkGray' -Text "      ... $testFolder"

            <#
                The Absolute path to this folder exists, adding to the list of
                DscTest scripts to run.
            #>
            if (Test-Path -Path $testFolder)
            {
                if ($isPester5)
                {
                    $dscTestParams.Path += $testFolder
                }
                else
                {
                    $dscTestParams.Script += $testFolder
                }
            }
        }
    }

    # Add all DscTest* variables in current scope into the $dscTestParams hashtable.
    foreach ($paramName in $DscTestCmd.Parameters.keys)
    {
        $paramValueFromScope = (Get-Variable -Name "DscTest$paramName" -ValueOnly -ErrorAction 'SilentlyContinue')

        if (-not $dscTestParams.ContainsKey($paramName) -and $paramValueFromScope)
        {
            $dscTestParams.Add($paramName, $paramValueFromScope)
        }
    }

    Write-Verbose -Message ($dscTestParams | ConvertTo-Json)

    $script:testResults = Invoke-DscResourceTest @dscTestParams

    $DscTestResultObjectCliXml = Join-Path -Path $DscTestOutputFolder -ChildPath "DscTestObject_$DscTestOutputFileFileName"

    $null = $script:testResults | Export-CliXml -Path $DscTestResultObjectCliXml -Force
}

# Synopsis: This task ensures the build job fails if the test aren't successful.
task Fail_Build_If_DscResource_Tests_Failed {
    "Asserting that no test failed"
    ""

    # Get the values for task variables, see https://github.com/gaelcolas/Sampler?tab=readme-ov-file#build-task-variables.
    . Set-SamplerTaskVariable

    $DscTestOutputFolder = Get-SamplerAbsolutePath -Path $DscTestOutputFolder -RelativeTo $OutputDirectory

    $os = Get-OperatingSystemShortName

    $builtDscResourcesFolder = Get-SamplerAbsolutePath -Path 'DSCResources' -RelativeTo $builtModuleBase

    "`tBuilt DSC Resource Path  = '$builtDscResourcesFolder'"

    $psVersion = 'PSv.{0}' -f $PSVersionTable.PSVersion
    $DscTestOutputFileFileName = "DscTest_{0}_v{1}.{2}.{3}.xml" -f $ProjectName, $ModuleVersion, $os, $psVersion
    $DscTestResultObjectClixml = Join-Path -Path $DscTestOutputFolder -ChildPath "DscTestObject_$DscTestOutputFileFileName"

    "`tDscTest Output Object    = $DscTestResultObjectClixml"

    if (-not (Test-Path -Path $DscTestResultObjectClixml))
    {
        throw "No command were tested. $DscTestResultObjectClixml not found"
    }
    else
    {
        $DscTestObject = Import-Clixml -Path $DscTestResultObjectClixml -ErrorAction 'Stop'

        Assert-Build -Condition ($DscTestObject.FailedCount -eq 0) -Message ('Failed {0} tests. Aborting Build' -f $DscTestObject.FailedCount)
    }
}

# Synopsis: Uploading Unit Test results to AppVeyor
task Upload_DscResourceTest_Results_To_AppVeyor -If { (property BuildSystem 'unknown') -eq 'AppVeyor' } {
    # Get the values for task variables, see https://github.com/gaelcolas/Sampler?tab=readme-ov-file#build-task-variables.
    . Set-SamplerTaskVariable

    $DscTestOutputFolder = Get-SamplerAbsolutePath -Path $DscTestOutputFolder -RelativeTo $OutputDirectory

    if (-not (Test-Path -Path $DscTestOutputFolder))
    {
        Write-Build -Color 'Yellow' -Text "Creating folder $DscTestOutputFolder"

        $null = New-Item -Path $DscTestOutputFolder -ItemType Directory -Force -ErrorAction 'Stop'
    }

    $os = Get-OperatingSystemShortName

    $builtDscResourcesFolder = Get-SamplerAbsolutePath -Path 'DSCResources' -RelativeTo $builtModuleBase

    "`tBuilt DSC Resource Path  = '$builtDscResourcesFolder'"

    $psVersion = 'PSv.{0}' -f $PSVersionTable.PSVersion
    $DscTestOutputFileFileName = "DscResource.Test_{0}_v{1}.{2}.{3}.xml" -f $ProjectName, $ModuleVersion, $os, $psVersion

    $DscTestOutputFullPath = Join-Path -Path $DscTestOutputFolder -ChildPath "$($DscTestOutputFormat)_$DscTestOutputFileFileName"

    $testResultFile = Get-Item -Path $DscTestOutputFullPath -ErrorAction 'Ignore'

    if ($testResultFile)
    {
        Write-Build -Color 'Green' -Text "  Uploading test results $testResultFile to Appveyor"

        $testResultFile | Add-TestResultToAppveyor

        Write-Build -Color 'Green' -Text "  Upload Complete"
    }
}

# Synopsis: Meta task that runs Quality Tests, and fails if they're not successful
task DscResource_Tests_Stop_On_Fail Invoke_DscResource_Tests, Upload_DscResourceTest_Results_To_AppVeyor, Fail_Build_If_DscResource_Tests_Failed
