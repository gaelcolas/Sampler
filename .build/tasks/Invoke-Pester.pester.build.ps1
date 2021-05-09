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
    [System.Management.Automation.SwitchParameter]
    $VersionedOutputDirectory = (property VersionedOutputDirectory $true),

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

task Import_Pester {
    # This will import the Pester version in the first module folder it finds which will be '/output/RequiredModules'?
    Import-Module -Name 'Pester' -MinimumVersion 4.0 -ErrorAction Stop
}

<#
    Synopsis: Making sure the Module meets some quality standard (help, tests) using Pester 4.
#>
task Invoke_Pester_Tests_v4 {
    <#
        This will evaluate the version of Pester that has been imported into the
        session is v4.x.x.

        This is not using task conditioning `-If` because Invoke-Build is evaluate
        the task conditions before it runs any task which means task Import_Pester
        have not had a chance to import the module into the session.
        Also having this evaluation as a task condition will also slow down other
        tasks noticeable.
    #>
    $modulePester = Get-Module -Name 'Pester' |
        Where-Object -FilterScript {
            $_.Version -ge [System.Version] '4.0.0' -and $_.Version -lt [System.Version] '5.0.0'
        }

    # If the correct module is not imported, then exit.
    if (-not $modulePester)
    {
        "Pester 4 is not used in the pipeline, skipping task.`n"

        return
    }

    # Get the vales for task variables, see https://github.com/gaelcolas/Sampler#task-variables.
    . Set-SamplerTaskVariable

    $PesterOutputFolder = Get-SamplerAbsolutePath -Path $PesterOutputFolder -RelativeTo $OutputDirectory

    "`tPester Output Folder     = '$PesterOutputFolder"

    if (-not (Test-Path -Path $PesterOutputFolder))
    {
        Write-Build -Color 'Yellow' -Text "Creating folder $PesterOutputFolder"

        $null = New-Item -Path $PesterOutputFolder -ItemType 'Directory' -Force -ErrorAction 'Stop'
    }

    $GetCodeCoverageThresholdParameters = @{
        RuntimeCodeCoverageThreshold = $CodeCoverageThreshold
        BuildInfo                    = $BuildInfo
    }

    $CodeCoverageThreshold = Get-CodeCoverageThreshold @GetCodeCoverageThresholdParameters

    # Initialize default parameters
    $defaultPesterParameters = @{
        PassThru = $true
    }

    $defaultScriptPaths = @(
        'tests',
        (Join-Path -Path $ProjectName -ChildPath 'tests')
    )

    $defaultPesterParameters['Script'] = $defaultScriptPaths
    $defaultPesterParameters['CodeCoverageOutputFileFormat'] = 'JaCoCo'
    $defaultPesterParameters['OutputFormat'] = 'NUnitXML'

    $DefaultExcludeFromCodeCoverage = @('test')

    $pesterCmd = Get-Command -Name 'Invoke-Pester'

    <#
        This will build the Pester* variables (e.g. PesterScript, or
        PesterOutputFormat) in this scope that are used in the rest of the code.
        It will use values for the variables in the following order:

        1. Skip creating the variable if a variable is already available because
           it was already set in a passed parameter (Pester*).
        2. Use the value from a property in the build.yaml under the key 'Pester:'.
        3. Use the default value set previously in the variable $defaultPesterParameters.
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
            elseif ($defaultPesterParameters.ContainsKey($paramName))
            {
                Write-Build -Color 'DarkGray' -Text "Using $taskParamName from Defaults"

                Set-Variable -Name $taskParamName -Value $defaultPesterParameters.($paramName)
            }
        }
        else
        {
            Write-Build -Color 'DarkGray' -Text "Using $taskParamName from Build Invocation Parameters"
        }
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
        ProjectName       = $ProjectName
        ModuleVersion     = $ModuleVersion
        OsShortName       = $osShortName
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

    $pesterParams['OutputFormat'] = $PesterOutputFormat
    $pesterParams['OutputFile'] = $pesterOutputFullPath

    $getCodeCoverageOutputFile = @{
        BuildInfo          = $BuildInfo
        PesterOutputFolder = $PesterOutputFolder
    }

    $CodeCoverageOutputFile = Get-SamplerCodeCoverageOutputFile @getCodeCoverageOutputFile

    if (-not $CodeCoverageOutputFile)
    {
        $CodeCoverageOutputFile = (Join-Path -Path $PesterOutputFolder -ChildPath "CodeCov_$pesterOutputFileFileName")
    }

    if ($codeCoverageThreshold -gt 0)
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

    if ($codeCoverageThreshold -gt 0 -and $codeCoverageOutputFileEncoding)
    {
        $pesterParams.Add('CodeCoverageOutputFileEncoding', $codeCoverageOutputFileEncoding)
    }

    "`tCodeCoverageOutputFileEncoding  = $($pesterParams['CodeCoverageOutputFileEncoding'])"

    if ($PesterExcludeTag.Count -gt 0)
    {
        $pesterParams.Add('ExcludeTag', $PesterExcludeTag)
    }

    if ($PesterTag.Count -gt 0)
    {
        $pesterParams.Add('Tag', $PesterTag)
    }

    # Test folders is specified, do not run invoke-pester against $BuildRoot
    if ($PesterScript.Count -gt 0)
    {
        $pesterParams.Add('Script', @())

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
                        $pesterParams.Script += $testFolder
                    }
                }
            }

            { $_ -is [System.Collections.Hashtable] }
            {
                foreach ($scriptItem in $PesterScript)
                {
                    Write-Build -Color 'DarkGray' -Text "      ... $(Convert-HashtableToString -Hashtable $scriptItem)"

                    $pesterParams.Script += $scriptItem
                }
            }
        }
    }

    # Add all Pester* variables in current scope into the $pesterParams hashtable.
    foreach ($paramName in $pesterCmd.Parameters.keys)
    {
        $paramValueFromScope = (Get-Variable -Name "Pester$paramName" -ValueOnly -ErrorAction 'SilentlyContinue')

        if (-not $pesterParams.ContainsKey($paramName) -and $paramValueFromScope)
        {
            $pesterParams.Add($paramName, $paramValueFromScope)
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
    ""

    # Get the vales for task variables, see https://github.com/gaelcolas/Sampler#task-variables.
    . Set-SamplerTaskVariable

    $PesterOutputFolder = Get-SamplerAbsolutePath -Path $PesterOutputFolder -RelativeTo $OutputDirectory

    "`tPester Output Folder     = '$PesterOutputFolder'"

    $osShortName = Get-OperatingSystemShortName

    $GetCodeCoverageThresholdParameters = @{
        RuntimeCodeCoverageThreshold = $CodeCoverageThreshold
        BuildInfo                    = $BuildInfo
    }

    $CodeCoverageThreshold = Get-CodeCoverageThreshold @GetCodeCoverageThresholdParameters

    "`tCode Coverage Threshold  = '$CodeCoverageThreshold'"

    $powerShellVersion = 'PSv.{0}' -f $PSVersionTable.PSVersion

    $getPesterOutputFileFileNameParameters = @{
        ProjectName       = $ProjectName
        ModuleVersion     = $ModuleVersion
        OsShortName       = $osShortName
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

<#
    Synopsis: Making sure the Module meets some quality standard (help, tests) using Pester 5.
#>
task Invoke_Pester_Tests_v5 {
    <#
        This will evaluate the version of Pester that has been imported into the
        session is v5.0.0 or higher.

        This is not using task conditioning `-If` because Invoke-Build is evaluate
        the task conditions before it runs any task which means task Import_Pester
        have not had a chance to import the module into the session.
        Also having this evaluation as a task condition will also slow down other
        tasks noticeable.
    #>
    $isWrongPesterVersion = (Get-Module -Name 'Pester').Version -lt [System.Version] '5.0.0'

    # If the correct module is not imported, then exit.
    if ($isWrongPesterVersion)
    {
        "Pester 5 is not used in the pipeline, skipping task.`n"

        return
    }

    # Get the vales for task variables, see https://github.com/gaelcolas/Sampler#task-variables.
    . Set-SamplerTaskVariable

    $PesterOutputFolder = Get-SamplerAbsolutePath -Path $PesterOutputFolder -RelativeTo $OutputDirectory

    "`tPester Output Folder    = '$PesterOutputFolder"

    if (-not (Test-Path -Path $PesterOutputFolder))
    {
        Write-Build -Color 'Yellow' -Text "Creating folder $PesterOutputFolder"

        $null = New-Item -Path $PesterOutputFolder -ItemType 'Directory' -Force -ErrorAction 'Stop'
    }

    $GetCodeCoverageThresholdParameters = @{
        RuntimeCodeCoverageThreshold = $CodeCoverageThreshold
        BuildInfo                    = $BuildInfo
    }

    $CodeCoverageThreshold = Get-CodeCoverageThreshold @GetCodeCoverageThresholdParameters

    $osShortName = Get-OperatingSystemShortName

    $powerShellVersion = 'PSv.{0}' -f $PSVersionTable.PSVersion

    $getPesterOutputFileFileNameParameters = @{
        ProjectName       = $ProjectName
        ModuleVersion     = $ModuleVersion
        OsShortName       = $osShortName
        PowerShellVersion = $powerShellVersion
    }

    $pesterOutputFileFileName = Get-PesterOutputFileFileName @getPesterOutputFileFileNameParameters

    "`tPester Output Filename  = '$pesterOutputFileFileName'"

    $pesterOutputFullPath = Get-SamplerAbsolutePath -Path "$($PesterOutputFormat)_$pesterOutputFileFileName" -RelativeTo $PesterOutputFolder

    "`tPester Output Full Path = '$pesterOutputFullPath'"

    <#
        Set default Pester configuration.
    #>

    $defaultPesterParameters = @{
        Configuration = [pesterConfiguration]::Default
    }

    $defaultPesterParameters.Configuration.Run.PassThru = $true
    $defaultPesterParameters.Configuration.Run.Path = @() # Test script path is added later
    $defaultPesterParameters.Configuration.Run.ExcludePath = @()
    $defaultPesterParameters.Configuration.Output.Verbosity = 'Detailed'

    $defaultPesterParameters.Configuration.CodeCoverage.Enabled = $true
    $defaultPesterParameters.Configuration.CodeCoverage.Path = @() # Coverage path is added later
    $defaultPesterParameters.Configuration.CodeCoverage.OutputFormat = 'JaCoCo'
    $defaultPesterParameters.Configuration.CodeCoverage.CoveragePercentTarget = 80
    $defaultPesterParameters.Configuration.CodeCoverage.OutputPath = Join-Path -Path $PesterOutputFolder -ChildPath "CodeCov_$pesterOutputFileFileName"
    $defaultPesterParameters.Configuration.CodeCoverage.OutputEncoding = 'UTF8'
    $defaultPesterParameters.Configuration.CodeCoverage.ExcludeTests = $true # Exclude our own test code from code coverage.

    $defaultPesterParameters.Configuration.TestResult.Enabled = $true
    $defaultPesterParameters.Configuration.TestResult.OutputFormat = 'NUnit2.5'
    $defaultPesterParameters.Configuration.TestResult.OutputPath = Join-Path -Path $PesterOutputFolder -ChildPath "TestResult_$pesterOutputFileFileName"
    $defaultPesterParameters.Configuration.TestResult.OutputEncoding = 'UTF8'
    $defaultPesterParameters.Configuration.TestResult.TestSuiteName = $ProjectName

    $defaultPesterParameters.Configuration.Filter.Tag = @()
    $defaultPesterParameters.Configuration.Filter.ExcludeTag = @()

    $pesterParameters = $defaultPesterParameters.Clone()

    <#
        Handle deprecated Pester build configuration.
    #>

    if ($BuildInfo.Pester -and -not $BuildInfo.Pester.Configuration)
    {
        if ($BuildInfo.Pester.Path.Count -ge 1)
        {
            $deprecatedBuildConfigPath = $("- " + $BuildInfo.Pester.Path -join "`n        - ")
        }

        if ($BuildInfo.Pester.Tag.Count -ge 1)
        {
            $deprecatedBuildConfigTag = $("- " + $BuildInfo.Pester.Tag -join "`n        - ")
        }

        if ($BuildInfo.Pester.ExcludeTag.Count -ge 1)
        {
            $deprecatedBuildConfigExcludeTag = $("- " + $BuildInfo.Pester.ExcludeTag -join "`n        - ")
        }

        if ($BuildInfo.Pester.ExcludeFromCodeCoverage.Count -ge 1)
        {
            $deprecatedBuildConfigExcludeFromCodeCoverage = $("- " + $BuildInfo.Pester.ExcludeFromCodeCoverage -join "`n    - ")
        }

        Write-Build -Color 'DarkGray' -Text @"

----------------------------------------------------------------------------------------------------
Consider updating the build configuration to the new advanced configuration options:
----------------------------------------------------------------------------------------------------
# PESTER CONFIG START
Pester:
  # Pester Advanced configuration. If a key is not set it is using Sampler pipeline default value.
  Configuration:
    Run:
      Path:
        $($deprecatedBuildConfigPath)
      ExcludePath:
    Filter:
      Tag:
        $($deprecatedBuildConfigTag)
      ExcludeTag:
        $($deprecatedBuildConfigExcludeTag)
    Output:
      Verbosity:
    CodeCoverage:
      Path:
      OutputFormat:
      CoveragePercentTarget: $($BuildInfo.Pester.CodeCoverageThreshold)
      OutputPath: $($BuildInfo.Pester.CodeCoverageOutputFile)
      OutputEncoding: $($BuildInfo.Pester.CodeCoverageOutputFileEncoding)
      ExcludeTests:
    TestResult:
      OutputFormat: $($BuildInfo.Pester.OutputFormat)
      OutputPath:
      OutputEncoding:
      TestSuiteName:
  # Sampler pipeline configuration
  ExcludeFromCodeCoverage:
    $($deprecatedBuildConfigExcludeFromCodeCoverage)
# PESTER CONFIG END
----------------------------------------------------------------------------------------------------
"@
    }

    # Set $ExcludeFromCodeCoverage from deprecated Pester build configuration.
    $ExcludeFromCodeCoverage = @($BuildInfo.Pester.ExcludeFromCodeCoverage)

    if ([System.String]::IsNullOrEmpty($CodeCoverageThreshold))
    {
        # Set $CodeCoverageThreshold from deprecated Pester build configuration.
        $CodeCoverageThreshold = $BuildInfo.Pester.CodeCoverageThreshold
    }

    <#
        Set $PesterScript from deprecated Pester build configuration, unless it was
        provided in task parameter.
    #>
    if ([System.String]::IsNullOrEmpty($PesterScript))
    {
        $PesterScript = @($BuildInfo.Pester.Path)
    }

    # TODO: Handle deprecated  OutputFormat, ExcludeTag, Tag, CodeCoverageOutputFile, CodeCoverageOutputFileEncoding

    <#
        TODO: Read new configuration key in build configuration. Add build.yml logic from DscResource.Test to override defaults
    #>

# # Only run these tags.
# $pesterConfig.Filter.Tag = @(
#     'GetRegistryPropertyValue'
#     'FormatPath'
#     'ConnectUncPath'
# )

    <#
        Set all Pester task parameters values to override Pester defaults and Pester key in build config.
    #>

    if (-not [System.String]::IsNullOrEmpty($CodeCoverageThreshold))
    {
        $pesterParameters.Configuration.CodeCoverage.CoveragePercentTarget = $CodeCoverageThreshold
    }

    if ($PesterExcludeTag.Count -gt 0)
    {
        $pesterParameters.Configuration.Filter.ExcludeTag = @($PesterExcludeTag)
    }

    "`tPester Exclude Tags     = $($pesterParameters.Configuration.Filter.ExcludeTag.Value -join ', ')"

    if ($PesterTag.Count -gt 0)
    {
        $pesterParameters.Configuration.Filter.Tag = @($PesterTag)
    }

    "`tPester Tags             = $($pesterParameters.Configuration.Filter.Tag.Value -join ', ')"

    # Import the module that should be tested.
    $moduleUnderTest = Import-Module -Name $ProjectName -PassThru

    # Disable code coverage if threshold is set to 0.
    if ($CodeCoverageThreshold -eq 0 -or -not $codeCoverageThreshold)
    {
        $pesterParameters.Configuration.CodeCoverage.Enabled = $false

        Write-Build -Color 'DarkGray' -Text "Disabling Code Coverage."
    }
    else
    {
        # If there is no code coverage path yet, use default - all .psm1 and .ps1 in built module root.
        if (-not $pesterParameters.Configuration.CodeCoverage.Path.Value)
        {
            $defaultCodeCoveragePaths = (Get-ChildItem -Path $moduleUnderTest.ModuleBase -Include @('*.psm1', '*.ps1') -Recurse).Where{
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

            $pesterParameters.Configuration.CodeCoverage.Path = @($defaultCodeCoveragePaths.FullName)
        }

        ""
        "`tCode Coverage Source Path       = $($pesterParameters.Configuration.CodeCoverage.Path.Value -join ', ')"
        "`tExclude Code Coverage Path      = $($ExcludeFromCodeCoverage -join ', ')"
        "`tExclude Tests Source Path       = $($pesterParameters.Configuration.CodeCoverage.ExcludeTests.Value)"
        "`tCode Coverage Output Path       = $($pesterParameters.Configuration.CodeCoverage.OutputPath.Value)"
        "`tCode Coverage Output Format     = $($pesterParameters.Configuration.CodeCoverage.OutputFormat.Value)"
        "`tCode Coverage Output Encoding   = $($pesterParameters.Configuration.CodeCoverage.OutputEncoding.Value)"
        "`tCode Coverage Percent Threshold = $($pesterParameters.Configuration.CodeCoverage.CoveragePercentTarget.Value)"
    }

    if ($pesterParameters.Configuration.TestResult.Enabled.Value)
    {
        if (-not [System.String]::IsNullOrEmpty($PesterOutputFormat))
        {
            $pesterParameters.Configuration.TestResult.OutputFormat = $PesterOutputFormat
        }

        ""
        "`tTest Result Test Suite Name     = $($pesterParameters.Configuration.TestResult.TestSuiteName.Value)"
        "`tTest Result Output Path         = $($pesterParameters.Configuration.TestResult.OutputPath.Value)"
        "`tTest Result Output Format       = $($pesterParameters.Configuration.TestResult.OutputFormat.Value)"
        "`tTest Result Output Encoding     = $($pesterParameters.Configuration.TestResult.OutputEncoding.Value)"
        "`tTest Result Percent Threshold   = $($pesterParameters.Configuration.CodeCoverage.CoveragePercentTarget.Value)"
    }
    else
    {
        Write-Build -Color 'DarkGray' -Text "Disabling Test Results."
    }

    <#
        TODO: Support test scripts that requires parameters. Those scripts need
              to be added as a PesterContainer (for each path). Code below need
              to handle this in the future.
    #>

    # Evaluate if there is any test script provided from task parameter or build config.
    if ([System.String]::IsNullOrEmpty($PesterScript))
    {
        # Use the default, search project path recursively for tests.
        $pesterParameters.Configuration.Run.Path = @(
            Join-Path -Path $ProjectPath -ChildPath 'tests'
            Join-Path -Path $ProjectPath -ChildPath 'Tests'
        )
    }
    else
    {
        # Specific test folders are specified.
        $pesterParameters.Configuration.Run.Path = @()

        foreach ($testFolder in $PesterScript)
        {
            if (-not (Split-Path -IsAbsolute $testFolder))
            {
                $testFolder = Join-Path -Path $ProjectPath -ChildPath $testFolder
            }

            # The absolute path to this folder exists, adding to the list of pester scripts to run
            if (Test-Path -Path $testFolder)
            {
                $pesterParameters.Configuration.Run.Path.Value += $testFolder
            }
        }
    }

    ""
    "`tTest Scripts = $($pesterParameters.Configuration.Run.Path.Value -join ', ')"

    $script:TestResults = Invoke-Pester @pesterParameters

    $PesterResultObjectCliXml = Join-Path -Path $PesterOutputFolder -ChildPath "PesterObject_$pesterOutputFileFileName"

    $null = $script:TestResults |
        Export-Clixml -Path $PesterResultObjectCliXml -Force
}

# Synopsis: Fails the build if the code coverage is under predefined threshold.
task Pester_If_Code_Coverage_Under_Threshold {
    # Get the vales for task variables, see https://github.com/gaelcolas/Sampler#task-variables.
    . Set-SamplerTaskVariable

    $GetCodeCoverageThresholdParameters = @{
        RuntimeCodeCoverageThreshold = $CodeCoverageThreshold
        BuildInfo                    = $BuildInfo
    }

    $CodeCoverageThreshold = Get-CodeCoverageThreshold @GetCodeCoverageThresholdParameters

    "`tCode Coverage Threshold  = '$CodeCoverageThreshold'"

    if (-not $CodeCoverageThreshold)
    {
        $CodeCoverageThreshold = 0
    }

    $PesterOutputFolder = Get-SamplerAbsolutePath -Path $PesterOutputFolder -RelativeTo $OutputDirectory

    "`tPester Output Folder     = '$PesterOutputFolder'"

    if (-not (Split-Path -IsAbsolute $PesterOutputFolder))
    {
        $PesterOutputFolder = Join-Path -Path $OutputDirectory -ChildPath $PesterOutputFolder
    }

    $osShortName = Get-OperatingSystemShortName

    $powerShellVersion = 'PSv.{0}' -f $PSVersionTable.PSVersion

    $getPesterOutputFileFileNameParameters = @{
        ProjectName       = $ProjectName
        ModuleVersion     = $ModuleVersion
        OsShortName       = $osShortName
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
    # Get the vales for task variables, see https://github.com/gaelcolas/Sampler#task-variables.
    . Set-SamplerTaskVariable

    $PesterOutputFolder = Get-SamplerAbsolutePath -Path $PesterOutputFolder -RelativeTo $OutputDirectory

    "`tPester Output Folder     = '$PesterOutputFolder'"

    if (-not (Test-Path -Path $PesterOutputFolder))
    {
        Write-Build -Color 'Yellow' -Text "Creating folder $PesterOutputFolder"

        $null = New-Item -Path $PesterOutputFolder -ItemType Directory -Force -ErrorAction 'Stop'
    }

    $osShortName = Get-OperatingSystemShortName

    $powerShellVersion = 'PSv.{0}' -f $PSVersionTable.PSVersion

    $getPesterOutputFileFileNameParameters = @{
        ProjectName       = $ProjectName
        ModuleVersion     = $ModuleVersion
        OsShortName       = $osShortName
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
task Pester_Tests_Stop_On_Fail Import_Pester, Invoke_Pester_Tests_v4, Invoke_Pester_Tests_v5, Upload_Test_Results_To_AppVeyor, Fail_Build_If_Pester_Tests_Failed
