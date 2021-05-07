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

    $builtDscResourcesFolder = Get-SamplerAbsolutePath -Path 'DSCResources' -RelativeTo $builtModuleBase

    "`tBuilt DSC Resource Path  = '$builtDscResourcesFolder'"

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

    Import-Module -Name 'Pester' -MinimumVersion 4.0 -ErrorAction Stop

    $isPester5 = (Get-Module -Name 'Pester').Version -ge '5.0.0'

    # Initialize default parameters
    $defaultPesterParams = @{
        PassThru = $true
    }

    $defaultScriptPaths = @(
        'tests',
        (Join-Path -Path $ProjectName -ChildPath 'tests')
    )

    $defaultPesterParams['Script'] = $defaultScriptPaths
    $defaultPesterParams['CodeCoverageOutputFileFormat'] = 'JaCoCo'
    $defaultPesterParams['OutputFormat'] = 'NUnitXML'

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

    $builtDscResourcesFolder = Get-SamplerAbsolutePath -Path 'DSCResources' -RelativeTo $builtModuleBase

    "`tBuilt DSC Resource Path  = '$builtDscResourcesFolder'"

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
        CodeCoverageThreshold = $CodeCoverageThreshold
        BuildInfo             = $BuildInfo
    }

    $CodeCoverageThreshold = Get-CodeCoverageThreshold @GetCodeCoverageThresholdParameters

    #Import-Module -Name 'Pester' -MinimumVersion 4.0 -ErrorAction Stop

    #$isPester5 = (Get-Module -Name 'Pester').Version -ge '5.0.0'

    # Initialize default value of configuration
    $defaultPesterParams = @{
        Configuration = [pesterConfiguration]::Default
    }
    $defaultPesterParams['Configuration'].Run.Passthru = $true

    $defaultScriptPaths = @(
        'tests',
        (Join-Path -Path $ProjectName -ChildPath 'tests')
    )

    $defaultPesterParams['Configuration'].Run.Path = $defaultScriptPaths
    $defaultPesterParams['Configuration'].OutPut.Verbosity = 'Detailed'

    $defaultPesterParams['Configuration'].CodeCoverage.Enabled = $true
    $defaultPesterParams['Configuration'].CodeCoverage.OutputFormat = 'JaCoCo'
    $defaultPesterParams['Configuration'].TestResult.Enabled = $true
    $defaultPesterParams['Configuration'].TestResult.OutputFormat = 'NUnitXML'

    $DefaultExcludeFromCodeCoverage = @('test')

    #$pesterCmd = Get-Command -Name 'Invoke-Pester'

    <#
        This will build the Pester* variables (e.g. PesterScript, or
        PesterOutputFormat) in this scope that are used in the rest of the code.
        It will use values for the variables in the following order:

        1. Skip creating the variable if a variable is already available because
           it was already set in a passed parameter (Pester*).
        2. Use the value from a property in the build.yaml under the key 'Pester:'.
        3. Use the default value set previously in the variable $defaultPesterParams.

        In pester 5 using parameters is depreciate. We must use the [PesterConfiguration] class.
        But the name of properties isn't the same as the parameters.

        Example :
            Pester 4 parameters                 |       Pester 5 Configuration Properties
            -Script                             =       .Run.Path
            -EnableExit                         =       .Run.Exit
            -Tag                                =       .Filter.Tag
            -ExcludeTag                         =       .Filter.ExcludeTag
            -PassThru                           =       .Run.PassThru
            -CodeCoverage                       =       .CodeCoverage.Path
            -CodeCoverageOutPutFile             =       .CodeCoverage.OutPutPath
            -CodeCoverageOutPutFileEncoding     =       .CodeCoverage.OutPutEncoding
            -CodeCoverageOutPutFileFormat       =       .CodeCoverage.OutPutFormat
            -OutPutFile                         =       .TestResult.OutPutPath
            -OutPutFormat                       =       .TestResult.OutPutFormat

        To find all properties of subobjects :
        foreach ($confProperty in $defaultPesterParams['Configuration'].psobject.Properties.Name | ForEach-Object {
           -join ($confProperty,$defaultPesterParams['Configuration'].$confProperty.psobject.properties.Name -join)
        }

    #>


    $parameterPesterv4 = @(
        Script
        EnableExit
        PassThru
        Tag
        ExcludeTag
        CodeCoverageOutPutFileFormat
        CodeCoverageOutPutFile
        CodeCoverageOutPutFileEncoding
        CodeCoverage
        OutPutFormat
        OutPutFile
        TestName
    )



    foreach ($paramName in $parameterPesterv4)
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

    #Invoke pester

    $pesterParams = @{
        Configuration = [pesterConfiguration]::Default
    }
    $pesterParams['Configuration'].Run.PassThru = $true

    $pesterParams['Configuration'].TestResult.Enabled = $true
    $pesterParams['Configuration'].TestResult.OutputFormat = $PesterOutputFormat
    $pesterParams['Configuration'].TestResult.OutputPath = $pesterOutputFullPath

    $getCodeCoverageOutputFile = @{
        BuildInfo = $BuildInfo
        PesterOutputFolder = $PesterOutputFolder
    }

    $CodeCoverageOutputFile = Get-CodeCoverageOutputFile @getCodeCoverageOutputFile

    if (-not $CodeCoverageOutputFile)
    {
        $CodeCoverageOutputFile = (Join-Path -Path $PesterOutputFolder -ChildPath "CodeCov_$pesterOutputFileFileName")
    }

    if ($codeCoverageThreshold -gt 0)
    {
        $pesterParams['Configuration'].CodeCoverage.Enabled = $true
        $pesterParams['Configuration'].CodeCoverage.Path = $PesterCodeCoverage.FullName
        $pesterParams['Configuration'].CodeCoverage.OutputPath = $CodeCoverageOutputFile
        $pesterParams['Configuration'].CodeCoverage.OutputFormat = $PesterCodeCoverageOutputFileFormat
    }

    "`t"
    "`tCodeCoverage                    = $($pesterParams['Configuration'].CodeCoverage.Path.Value)"
    "`tCodeCoverageOutputFile          = $($pesterParams['Configuration'].CodeCoverage.OutputPath.Value)"
    "`tCodeCoverageOutputFileFormat    = $($pesterParams['Configuration'].CodeCoverage.OutputFormat.Value)"

    $codeCoverageOutputFileEncoding = Get-CodeCoverageOutputFileEncoding -BuildInfo $BuildInfo

    if ($codeCoverageThreshold -gt 0 -and $codeCoverageOutputFileEncoding)
    {
        $pesterParams['Configuration'].CodeCoverage.OutputEncoding = $codeCoverageOutputFileEncoding
    }

    "`tCodeCoverageOutputFileEncoding  = $($pesterParams['Configuration'].CodeCoverage.OutputEncoding.Value)"

    if ($PesterExcludeTag.Count -gt 0)
    {
        $pesterParams['Configuration'].Filter.ExcludeTag = $PesterExcludeTag
    }

    if ($PesterTag.Count -gt 0)
    {
        $pesterParams['Configuration'].Filter.Tag = $PesterTag
    }

    # Test folders is specified, do not run invoke-pester against $BuildRoot
    if ($PesterScript.Count -gt 0)
    {
        $pesterParams['Configuration'].Run.Path = @()

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
                        $pesterParams['Configuration'].Run.Path.Value += $testFolder
                    }
                }
            }

            { $_ -is [System.Collections.Hashtable] }
            {
                foreach ($scriptItem in $PesterScript)
                {
                    Write-Build -Color 'DarkGray' -Text "      ... $(Convert-SamplerHashtableToString -Hashtable $scriptItem)"

                    $pesterParams['Configuration'].Run.Path.Value += $scriptItem
                }
            }
        }
    }

    # Add all Pester* variables in current scope into the $pesterParams hashtable.
    # play with correspondence table
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
        Write-Build -Color 'DarkGray' -Text "Desabling Code Coverage configuration"

        $pesterParams['Configuration'].CodeCoverage.Enabled = $false
    }

    $script:TestResults = Invoke-Pester @pesterParams

    $PesterResultObjectCliXml = Join-Path -Path $PesterOutputFolder -ChildPath "PesterObject_$pesterOutputFileFileName"

    $null = $script:TestResults |
        Export-Clixml -Path $PesterResultObjectCliXml -Force
}

# Synopsis: Fails the build if the code coverage is under predefined threshold.
task Pester_If_Code_Coverage_Under_Threshold {
    # Get the vales for task variables, see https://github.com/gaelcolas/Sampler#task-variables.
    . Set-SamplerTaskVariable

    $builtDscResourcesFolder = Get-SamplerAbsolutePath -Path 'DSCResources' -RelativeTo $builtModuleBase

    "`tBuilt DSC Resource Path  = '$builtDscResourcesFolder'"

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

    $builtDscResourcesFolder = Get-SamplerAbsolutePath -Path 'DSCResources' -RelativeTo $builtModuleBase

    "`tBuilt DSC Resource Path  = '$builtDscResourcesFolder'"

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
