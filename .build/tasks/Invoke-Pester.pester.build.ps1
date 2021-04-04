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

# Synopsis: Making sure the Module meets some quality standard (help, tests).
task Invoke_Pester_Tests {
    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-SamplerProjectName -BuildRoot $BuildRoot
    }

    $OutputDirectory = Get-SamplerAbsolutePath -Path $OutputDirectory -RelativeTo $BuildRoot
    $PesterOutputFolder = Get-SamplerAbsolutePath -Path $PesterOutputFolder -RelativeTo $OutputDirectory

    "`tProject Name             = '$ProjectName'"
    "`tOutput Directory         = '$OutputDirectory'"
    "`tPester Output Folder     = '$PesterOutputFolder"

    if ($VersionedOutputDirectory)
    {
        # VersionedOutputDirectory is not [bool]'' nor $false nor [bool]$null
        # Assume true, wherever it was set
        $VersionedOutputDirectory = $true
    }
    else
    {
        # VersionedOutputDirectory may be [bool]'' but we can't tell where it's
        # coming from, so assume the build info (Build.yaml) is right
        $VersionedOutputDirectory = $BuildInfo['VersionedOutputDirectory']
    }

    $GetBuiltModuleManifestParams = @{
        OutputDirectory          = $OutputDirectory
        BuiltModuleSubDirectory  = $BuiltModuleSubDirectory
        ModuleName               = $ProjectName
        VersionedOutputDirectory = $VersionedOutputDirectory
        ErrorAction              = 'Stop'
    }

    $builtModuleBase = Get-SamplerBuiltModuleBase @GetBuiltModuleManifestParams
    "`tBuilt Module Base        = '$builtModuleBase'"

    $builtModuleManifest = Get-SamplerBuiltModuleManifest @GetBuiltModuleManifestParams
    "`tBuilt Module Manifest    = '$builtModuleManifest'"

    if ($builtModuleRootScriptPath = Get-SamplerModuleRootPath -ModuleManifestPath $builtModuleManifest)
    {
        $builtModuleRootScriptPath = (Get-Item -Path $builtModuleRootScriptPath -ErrorAction SilentlyContinue).FullName
    }

    "`tBuilt ModuleRoot script  = '$builtModuleRootScriptPath'"

    $builtDscResourcesFolder = Get-SamplerAbsolutePath -Path 'DSCResources' -RelativeTo $builtModuleBase
    "`tBuilt DSC Resource Path  = '$builtDscResourcesFolder'"

    $ModuleVersion = Get-BuiltModuleVersion @GetBuiltModuleManifestParams
    $ModuleVersionObject = Split-ModuleVersion -ModuleVersion $ModuleVersion
    $ModuleVersionFolder = $ModuleVersionObject.Version
    $preReleaseTag = $ModuleVersionObject.PreReleaseString

    "`tModule Version           = '$ModuleVersion'"
    "`tModule Version Folder    = '$ModuleVersionFolder'"
    "`tPre-release Tag          = '$preReleaseTag'"

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
        BuildInfo          = $BuildInfo
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

    $OutputDirectory = Get-SamplerAbsolutePath -Path $OutputDirectory -RelativeTo $BuildRoot
    $PesterOutputFolder = Get-SamplerAbsolutePath -Path $PesterOutputFolder -RelativeTo $OutputDirectory

    "`tProject Name             = '$ProjectName'"
    "`tOutput Directory         = '$OutputDirectory'"
    "`tPester Output Folder     = '$PesterOutputFolder'"

    $osShortName = Get-OperatingSystemShortName
    $GetCodeCoverageThresholdParameters = @{
        RuntimeCodeCoverageThreshold = $CodeCoverageThreshold
        BuildInfo                    = $BuildInfo
    }

    $CodeCoverageThreshold = Get-CodeCoverageThreshold @GetCodeCoverageThresholdParameters
    "`tCode Coverage Threshold  = '$CodeCoverageThreshold'"

    if ($VersionedOutputDirectory)
    {
        # VersionedOutputDirectory is not [bool]'' nor $false nor [bool]$null
        # Assume true, wherever it was set
        $VersionedOutputDirectory = $true
    }
    else
    {
        # VersionedOutputDirectory may be [bool]'' but we can't tell where it's
        # coming from, so assume the build info (Build.yaml) is right
        $VersionedOutputDirectory = $BuildInfo['VersionedOutputDirectory']
    }

    $GetBuiltModuleManifestParams = @{
        OutputDirectory          = $OutputDirectory
        BuiltModuleSubDirectory  = $BuiltModuleSubDirectory
        ModuleName               = $ProjectName
        VersionedOutputDirectory = $VersionedOutputDirectory
        ErrorAction              = 'Stop'
    }

    $builtModuleBase = Get-SamplerBuiltModuleBase @GetBuiltModuleManifestParams
    "`tBuilt Module Base        = '$builtModuleBase'"

    $builtModuleManifest = Get-SamplerBuiltModuleManifest @GetBuiltModuleManifestParams
    "`tBuilt Module Manifest    = '$builtModuleManifest'"

    if ($builtModuleRootScriptPath = Get-SamplerModuleRootPath -ModuleManifestPath $builtModuleManifest)
    {
        $builtModuleRootScriptPath = (Get-Item -Path $builtModuleRootScriptPath -ErrorAction SilentlyContinue).FullName
    }

    "`tBuilt ModuleRoot script  = '$builtModuleRootScriptPath'"

    $builtDscResourcesFolder = Get-SamplerAbsolutePath -Path 'DSCResources' -RelativeTo $builtModuleBase
    "`tBuilt DSC Resource Path  = '$builtDscResourcesFolder'"

    $ModuleVersion = Get-BuiltModuleVersion @GetBuiltModuleManifestParams
    $ModuleVersionObject = Split-ModuleVersion -ModuleVersion $ModuleVersion
    $ModuleVersionFolder = $ModuleVersionObject.Version
    $preReleaseTag = $ModuleVersionObject.PreReleaseString

    "`tModule Version           = '$ModuleVersion'"
    "`tModule Version Folder    = '$ModuleVersionFolder'"
    "`tPre-release Tag          = '$preReleaseTag'"

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

# Synopsis: Fails the build if the code coverage is under predefined threshold.
task Pester_If_Code_Coverage_Under_Threshold {
    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-SamplerProjectName -BuildRoot $BuildRoot
    }

    if ([System.String]::IsNullOrEmpty($SourcePath))
    {
        $SourcePath = Get-SamplerSourcePath -BuildRoot $BuildRoot
    }

    $OutputDirectory = Get-SamplerAbsolutePath -Path $OutputDirectory -RelativeTo $BuildRoot

    "`tProject Name             = '$ProjectName'"
    "`tSource Path              = '$SourcePath'"
    "`tOutput Directory         = '$OutputDirectory'"

    if ($VersionedOutputDirectory)
    {
        # VersionedOutputDirectory is not [bool]'' nor $false nor [bool]$null
        # Assume true, wherever it was set
        $VersionedOutputDirectory = $true
    }
    else
    {
        # VersionedOutputDirectory may be [bool]'' but we can't tell where it's
        # coming from, so assume the build info (Build.yaml) is right
        $VersionedOutputDirectory = $BuildInfo['VersionedOutputDirectory']
    }

    $GetBuiltModuleManifestParams = @{
        OutputDirectory          = $OutputDirectory
        BuiltModuleSubDirectory  = $BuiltModuleSubDirectory
        ModuleName               = $ProjectName
        VersionedOutputDirectory = $VersionedOutputDirectory
        ErrorAction              = 'Stop'
    }

    $builtModuleBase = Get-SamplerBuiltModuleBase @GetBuiltModuleManifestParams
    "`tBuilt Module Base        = '$builtModuleBase'"

    $builtModuleManifest = Get-SamplerBuiltModuleManifest @GetBuiltModuleManifestParams
    "`tBuilt Module Manifest    = '$builtModuleManifest'"

    if ($builtModuleRootScriptPath = Get-SamplerModuleRootPath -ModuleManifestPath $builtModuleManifest)
    {
        $builtModuleRootScriptPath = (Get-Item -Path $builtModuleRootScriptPath -ErrorAction SilentlyContinue).FullName
    }

    "`tBuilt ModuleRoot script  = '$builtModuleRootScriptPath'"

    $builtDscResourcesFolder = Get-SamplerAbsolutePath -Path 'DSCResources' -RelativeTo $builtModuleBase
    "`tBuilt DSC Resource Path  = '$builtDscResourcesFolder'"

    $ModuleVersion = Get-BuiltModuleVersion @GetBuiltModuleManifestParams
    $ModuleVersionObject = Split-ModuleVersion -ModuleVersion $ModuleVersion
    $ModuleVersionFolder = $ModuleVersionObject.Version
    $preReleaseTag = $ModuleVersionObject.PreReleaseString

    "`tModule Version           = '$ModuleVersion'"
    "`tModule Version Folder    = '$ModuleVersionFolder'"
    "`tPre-release Tag          = '$preReleaseTag'"

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

# Synopsis: Convert JaCoCo coverage so it supports a built module by way of ModuleBuilder.
task Convert_Pester_Coverage {
    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-SamplerProjectName -BuildRoot $BuildRoot
    }

    if ([System.String]::IsNullOrEmpty($SourcePath))
    {
        $SourcePath = Get-SamplerSourcePath -BuildRoot $BuildRoot
    }

    $OutputDirectory = Get-SamplerAbsolutePath -Path $OutputDirectory -RelativeTo $BuildRoot

    "`tProject Name             = '$ProjectName'"
    "`tSource Path              = '$SourcePath'"
    "`tOutput Directory         = '$OutputDirectory'"

    if ($VersionedOutputDirectory)
    {
        # VersionedOutputDirectory is not [bool]'' nor $false nor [bool]$null
        # Assume true, wherever it was set
        $VersionedOutputDirectory = $true
    }
    else
    {
        # VersionedOutputDirectory may be [bool]'' but we can't tell where it's
        # coming from, so assume the build info (Build.yaml) is right
        $VersionedOutputDirectory = $BuildInfo['VersionedOutputDirectory']
    }

    $GetBuiltModuleManifestParams = @{
        OutputDirectory          = $OutputDirectory
        BuiltModuleSubDirectory  = $BuiltModuleSubDirectory
        ModuleName               = $ProjectName
        VersionedOutputDirectory = $VersionedOutputDirectory
        ErrorAction              = 'Stop'
    }

    $builtModuleBase = Get-SamplerBuiltModuleBase @GetBuiltModuleManifestParams
    "`tBuilt Module Base        = '$builtModuleBase'"

    $builtModuleManifest = Get-SamplerBuiltModuleManifest @GetBuiltModuleManifestParams
    "`tBuilt Module Manifest    = '$builtModuleManifest'"

    if ($builtModuleRootScriptPath = Get-SamplerModuleRootPath -ModuleManifestPath $builtModuleManifest)
    {
        $builtModuleRootScriptPath = (Get-Item -Path $builtModuleRootScriptPath -ErrorAction SilentlyContinue).FullName
    }

    "`tBuilt ModuleRoot script  = '$builtModuleRootScriptPath'"

    $builtDscResourcesFolder = Get-SamplerAbsolutePath -Path 'DSCResources' -RelativeTo $builtModuleBase
    "`tBuilt DSC Resource Path  = '$builtDscResourcesFolder'"

    $ModuleVersion = Get-BuiltModuleVersion @GetBuiltModuleManifestParams
    $ModuleVersionObject = Split-ModuleVersion -ModuleVersion $ModuleVersion
    $ModuleVersionFolder = $ModuleVersionObject.Version
    $preReleaseTag = $ModuleVersionObject.PreReleaseString

    "`tModule Version           = '$ModuleVersion'"
    "`tModule Version Folder    = '$ModuleVersionFolder'"
    "`tPre-release Tag          = '$preReleaseTag'"

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

    $moduleFileName = '{0}.psm1' -f $ProjectName

    "`tModule File Name         = '$moduleFileName'"

    $getCodeCoverageOutputFile = @{
        BuildInfo          = $BuildInfo
        PesterOutputFolder = $PesterOutputFolder
    }

    $CodeCoverageOutputFile = Get-SamplerCodeCoverageOutputFile @getCodeCoverageOutputFile

    if (-not $CodeCoverageOutputFile)
    {
        $CodeCoverageOutputFile = (Join-Path -Path $PesterOutputFolder -ChildPath "CodeCov_$pesterOutputFileFileName")
    }

    "`t"
    "`tCodeCoverageOutputFile         = $CodeCoverageOutputFile"

    $CodeCoverageOutputFileEncoding = $BuildInfo.Pester.CodeCoverageOutputFileEncoding

    if (-not $CodeCoverageOutputFileEncoding)
    {
        $CodeCoverageOutputFileEncoding = 'ascii'
    }

    "`tCodeCoverageOutputFileEncoding = $CodeCoverageOutputFileEncoding"
    ""

    #### TODO: Split Script Task Variables here

    $PesterOutputFileFileName = Get-PesterOutputFileFileName @getPesterOutputFileFileNameParameters

    $PesterResultObjectClixml = Join-Path $PesterOutputFolder "PesterObject_$PesterOutputFileFileName"

    Write-Build -Color 'White' -Text "`tPester Output Object = $PesterResultObjectClixml"

    if (-not (Test-Path -Path $PesterResultObjectClixml))
    {
        if ($CodeCoverageThreshold -eq 0)
        {
            Write-Build -Color 'Green' -Text 'Coverage bypassed. Nothing to convert.'

            return
        }
        else
        {
            throw "No command were tested, nothing to convert."
        }
    }
    else
    {
        $pesterObject = Import-Clixml -Path $PesterResultObjectClixml
    }

    # Get all missed commands that are in the main module file.
    $missedCommands = $pesterObject.CodeCoverage.MissedCommands |
        Where-Object -FilterScript { $_.File -match [RegEx]::Escape($moduleFileName) }

    # Get all hit commands that are in the main module file.
    $hitCommands = $pesterObject.CodeCoverage.HitCommands |
        Where-Object -FilterScript { $_.File -match [RegEx]::Escape($moduleFileName) }

    <#
        This command uses 'PassThru' very strange. It is needed to update the
        content of $missedCommands correctly (for it to add the SourceFile and
        SourceLineNumber properties).

        THe command Convert-LineNumber is part of ModuleBuilder.
    #>
    $missedCommands | Convert-LineNumber -ErrorAction 'Stop' -PassThru | Out-Null
    $hitCommands | Convert-LineNumber -ErrorAction 'Stop' -PassThru | Out-Null

    # Blank line in output.
    ""

    Write-Build -Color 'White' -Text "Missed commands in source files:"

    # Output missed commands to visualize it in the pipeline output.
    $allMissedCommandsInSourceFiles = $missedCommands + (
        $pesterObject.CodeCoverage.MissedCommands |
            Where-Object -FilterScript { $_.File -notmatch [RegEx]::Escape($moduleFileName) }
    )

    $allMissedCommandsInSourceFiles |
        Select-Object @{
            Name = 'File'
            Expr = {
                if ($_.SourceFile)
                {
                    $_.SourceFile
                }
                else
                {
                    $_.File
                }
            }
        },
        @{
            Name = 'Line'
            Expr = {
                if ($_.SourceLineNumber)
                {
                    $_.SourceLineNumber
                }
                else
                {
                    $_.Line
                }
            }
        }, Function, Command |
            Out-String

    # Blank line in output.
    ""

    Write-Build -Color 'White' -Text "Converting coverage file."

    <#
        Cannot find a good example how package and class relate to PowerShell.
        This implementation tries to mimic what Pester outputs in its coverage
        file.
    #>

    Write-Build -Color 'DarkGray' -Text "`tBuilding new code coverage file against source."

    [System.Xml.XmlDocument] $coverageXml = ''

    # XML header.
    $xmlDeclaration = $coverageXml.CreateXmlDeclaration('1.0', 'UTF-8', 'no')

    # DTD: https://www.jacoco.org/jacoco/trunk/coverage/report.dtd
    $xmlDocumentType = $coverageXml.CreateDocumentType('report', '-//JACOCO//DTD Report 1.1//EN', 'https://www.jacoco.org/jacoco/trunk/coverage/report.dtd', $null)

    $coverageXml.AppendChild($xmlDeclaration) | Out-Null
    $coverageXml.AppendChild($xmlDocumentType) | Out-Null

    # Root element 'report'.
    $xmlElementReport = $coverageXml.CreateNode('element', 'report', $null)
    $xmlElementReport.SetAttribute('name', 'Sampler ({0})' -f (Get-Date).ToString('yyyy-mm-dd HH:mm:ss'))

    <#
        Child element 'sessioninfo'.

        The attributes 'start' and 'dump' is the time it took to run the tests in
        milliseconds, but it is not used in the end, we just add a plausible number
        here so it passes the referenced DTD, or any other parsing that might be done
        in the future.
    #>
    $testRunLengthInMilliseconds = 1785237 # ~30 minutes

    [System.Int64] $sessionInfoEndTime = [System.Math]::Floor((New-TimeSpan -Start (Get-Date -Date '01/01/1970') -End (Get-Date)).TotalMilliseconds)
    [System.Int64] $sessionInfoStartTime = [System.Math]::Floor($sessionInfoEndTime - $testRunLengthInMilliseconds)

    $xmlElementSessionInfo = $coverageXml.CreateNode('element', 'sessioninfo', $null)
    $xmlElementSessionInfo.SetAttribute('id', 'this')
    $xmlElementSessionInfo.SetAttribute('start', $sessionInfoStartTime)
    $xmlElementSessionInfo.SetAttribute('dump', $sessionInfoEndTime)
    $xmlElementReport.AppendChild($xmlElementSessionInfo) | Out-Null

    <#
        This is how each object in $allCommands looks like:

        # A method in a PowerShell class located in the Classes folder.
        File             : C:\source\DnsServerDsc\output\MyModule\1.0.0\MyModule.psm1
        Line             : 168
        StartLine        : 168
        EndLine          : 168
        StartColumn      : 25
        EndColumn        : 36
        Class            : ResourceBase
        Function         : Compare
        Command          : $currentState = $this.Get() | ConvertTo-HashTableFromObject
        HitCount         : 86
        SourceFile       : .\Classes\001.ResourceBase.ps1
        SourceLineNumber : 153

        # A function located in private or public folder.
        File             : C:\source\DnsServerDsc\output\MyModule\1.0.0\MyModule.psm1
        Line             : 2658
        StartLine        : 2658
        EndLine          : 2658
        StartColumn      : 26
        EndColumn        : 29
        Class            :
        Function         : Get-LocalizedDataRecursive
        Command          : $localizedData = @{}
        HitCount         : 225
        SourceFile       : .\Private\Get-LocalizedDataRecursive.ps1
        SourceLineNumber : 35
    #>
    $allCommands = $hitCommands + $missedCommands

    $sourcePathFolderName = (Split-Path -Path $SourcePath -Leaf) -replace '\\','/'

    $commandsGroupedOnParentFolder = $allCommands | Group-Object -Property {
        Split-Path -Path $_.SourceFile -Parent
    }

    $reportCounterInstruction = @{
        Missed  = 0
        Covered = 0
    }

    $reportCounterLine = @{
        Missed  = 0
        Covered = 0
    }

    $reportCounterMethod = @{
        Missed  = 0
        Covered = 0
    }

    $reportCounterClass = @{
        Missed  = 0
        Covered = 0
    }

    foreach ($jaCocoPackage in $commandsGroupedOnParentFolder)
    {
        $packageCounterInstruction = @{
            Missed  = 0
            Covered = 0
        }

        $packageCounterLine = @{
            Missed  = 0
            Covered = 0
        }

        $packageCounterMethod = @{
            Missed  = 0
            Covered = 0
        }

        $packageCounterClass = @{
            Missed  = 0
            Covered = 0
        }

        $allSourceFileElements = @()

        # This is what the user expects to see.
        $packageDisplayName = ($jaCoCoPackage.Name -replace '^\.', $sourcePathFolderName) -replace '\\','/'

        <#
            The module version is what is expected to be in the XML.

            E.g. Codecov.io config converts this back to 'source' (or whatever
            is configured in 'codecov.yml').
        #>
        $xmlPackageName = ($jaCoCoPackage.Name -replace '^\.', $ModuleVersionFolder) -replace '\\','/'

        Write-Debug -Message ('Creating XML output for JaCoCo package ''{0}''.' -f $packageDisplayName)

        <#
            Child element 'package'.

            This implementation assumes the attribute 'name' of the element 'package'
            should be the path to the folder that contains the PowerShell script files
            (relative from GitHub repository root).
        #>
        $xmlElementPackage = $coverageXml.CreateElement('package')
        $xmlElementPackage.SetAttribute('name', $xmlPackageName)

        $commandsGroupedOnSourceFile = $jaCoCoPackage.Group | Group-Object -Property 'SourceFile'

        foreach ($jaCocoClass in $commandsGroupedOnSourceFile)
        {
            $classCounterInstruction = @{
                Missed  = 0
                Covered = 0
            }

            $classCounterLine = @{
                Missed  = 0
                Covered = 0
            }

            $classCounterMethod = @{
                Missed  = 0
                Covered = 0
            }

            $classDisplayName = ($jaCocoClass.Name -replace '^\.', $sourcePathFolderName) -replace '\\','/'

            <#
                The module version is what is expected to be in the XML.

                E.g. Codecov.io config converts this back to 'source' (or whatever
                is configured in 'codecov.yml').
            #>
            $sourceFilePath = ($jaCocoClass.Name -replace '^\.', $ModuleVersionFolder) -replace '\\','/'
            $xmlClassName = $sourceFilePath -replace '\.ps1'
            $sourceFileName = Split-Path -Path $sourceFilePath -Leaf

            Write-Debug -Message ("`tCreating XML output for JaCoCo class '{0}'." -f $classDisplayName)

            # Child element 'class'.
            $xmlElementClass = $coverageXml.CreateElement('class')
            $xmlElementClass.SetAttribute('name', $xmlClassName)
            $xmlElementClass.SetAttribute('sourcefilename', $sourceFileName)

            <#
                This assumes that a value in property Function is never $null. Test
                showed that commands at script level is assigned empty string in the
                Function property, so it should work for missed and hit commands at
                script level too.

                Sorting the objects after StartLine so they come in the order
                they appear in the code file. Also, it is necessary for the
                command Update-JoCaCoStatistic to work.
            #>
            $commandsGroupedOnFunction = $jaCocoClass.Group |
                    Group-Object -Property 'Function' |
                    Sort-Object -Property {
                        # Find the first line for each method.
                        ($_.Group.SourceLineNumber | Measure-Object -Minimum).Minimum
                    }

            foreach ($jaCoCoMethod in $commandsGroupedOnFunction)
            {
                $functionName = if ([System.String]::IsNullOrEmpty($jaCoCoMethod.Name))
                {
                    '<script>'
                }
                else
                {
                    $jaCoCoMethod.Name
                }

                Write-Debug -Message ("`t`tCreating XML output for JaCoCo method '{0}'." -f $functionName)

                <#
                    Sorting all commands in ascending order and using the first
                    'SourceLineNumber' as the first line of the method. Assuming
                    every code line for the method was in either $missedCommands
                    or $hitCommands which the sorting is based on.
                #>
                $methodFirstLine = $jaCoCoMethod.Group |
                    Sort-Object -Property 'SourceLineNumber' |
                        Select-Object -First 1 -ExpandProperty 'SourceLineNumber'

                # Child element 'method'.
                $xmlElementMethod = $coverageXml.CreateElement('method')
                $xmlElementMethod.SetAttribute('name', $functionName)
                $xmlElementMethod.SetAttribute('desc', '()')
                $xmlElementMethod.SetAttribute('line', $methodFirstLine)

                <#
                    Documentation for counters:
                    https://www.jacoco.org/jacoco/trunk/doc/counters.html
                #>

                <#
                    Child element 'counter' and type INSTRUCTION.

                    Each command can be hit multiple times, the INSTRUCTION counts
                    how many times the command was hit or missed.
                #>
                $numberOfInstructionsCovered = (
                    $jaCoCoMethod.Group |
                        Where-Object -FilterScript {
                            $_.HitCount -ge 1
                        }
                ).Count

                $numberOfInstructionsMissed = (
                    $jaCoCoMethod.Group |
                        Where-Object -FilterScript {
                            $_.HitCount -eq 0
                        }
                ).Count

                $xmlElementCounterMethodInstruction = $coverageXml.CreateElement('counter')
                $xmlElementCounterMethodInstruction.SetAttribute('type', 'INSTRUCTION')
                $xmlElementCounterMethodInstruction.SetAttribute('missed', $numberOfInstructionsMissed)
                $xmlElementCounterMethodInstruction.SetAttribute('covered', $numberOfInstructionsCovered)
                $xmlElementMethod.AppendChild($xmlElementCounterMethodInstruction) | Out-Null

                $classCounterInstruction.Covered += $numberOfInstructionsCovered
                $classCounterInstruction.Missed += $numberOfInstructionsMissed

                $packageCounterInstruction.Covered += $numberOfInstructionsCovered
                $packageCounterInstruction.Missed += $numberOfInstructionsMissed

                $reportCounterInstruction.Covered += $numberOfInstructionsCovered
                $reportCounterInstruction.Missed += $numberOfInstructionsMissed

                <#
                    Child element 'counter' and type LINE.

                    The LINE counts how many unique lines that was hit or missed.
                #>
                $numberOfLinesCovered = (
                    $jaCoCoMethod.Group |
                        Where-Object -FilterScript {
                            $_.HitCount -ge 1
                        } |
                            Sort-Object -Property 'SourceLineNumber' -Unique
                ).Count

                $numberOfLinesMissed = (
                    $jaCoCoMethod.Group |
                        Where-Object -FilterScript {
                            $_.HitCount -eq 0
                        } |
                            Sort-Object -Property 'SourceLineNumber' -Unique
                ).Count

                $xmlElementCounterMethodLine = $coverageXml.CreateElement('counter')
                $xmlElementCounterMethodLine.SetAttribute('type', 'LINE')
                $xmlElementCounterMethodLine.SetAttribute('missed', $numberOfLinesMissed)
                $xmlElementCounterMethodLine.SetAttribute('covered', $numberOfLinesCovered)
                $xmlElementMethod.AppendChild($xmlElementCounterMethodLine) | Out-Null

                $classCounterLine.Covered += $numberOfLinesCovered
                $classCounterLine.Missed += $numberOfLinesMissed

                $packageCounterLine.Covered += $numberOfLinesCovered
                $packageCounterLine.Missed += $numberOfLinesMissed

                $reportCounterLine.Covered += $numberOfLinesCovered
                $reportCounterLine.Missed += $numberOfLinesMissed

                <#
                    Child element 'counter' and type METHOD.

                    The METHOD counts as covered if at least one line was hit in
                    the method. This value seem not to be higher than 1, assuming
                    that is true.
                #>
                $isLineInMethodCovered = (
                    $jaCoCoMethod.Group |
                        Where-Object -FilterScript {
                            $_.HitCount -ge 1
                        }
                ).Count

                <#
                    If at least one instructions was covered in the method, then
                    method was covered.
                #>
                if ($isLineInMethodCovered)
                {
                    $methodCovered = 1
                    $methodMissed = 0

                    $classCounterMethod.Covered += 1

                    $packageCounterMethod.Covered += 1

                    $reportCounterMethod.Covered += 1
                }
                else
                {
                    $methodCovered = 0
                    $methodMissed = 1

                    $classCounterMethod.Missed += 1

                    $packageCounterMethod.Missed += 1

                    $reportCounterMethod.Missed += 1
                }

                $xmlElementCounterMethod = $coverageXml.CreateElement('counter')
                $xmlElementCounterMethod.SetAttribute('type', 'METHOD')
                $xmlElementCounterMethod.SetAttribute('missed', $methodMissed)
                $xmlElementCounterMethod.SetAttribute('covered', $methodCovered)
                $xmlElementMethod.AppendChild($xmlElementCounterMethod) | Out-Null

                $xmlElementClass.AppendChild($xmlElementMethod) | Out-Null
            }

            $xmlElementCounter_ClassInstruction = $coverageXml.CreateElement('counter')
            $xmlElementCounter_ClassInstruction.SetAttribute('type', 'INSTRUCTION')
            $xmlElementCounter_ClassInstruction.SetAttribute('missed', $classCounterInstruction.Missed)
            $xmlElementCounter_ClassInstruction.SetAttribute('covered', $classCounterInstruction.Covered)
            $xmlElementClass.AppendChild($xmlElementCounter_ClassInstruction) | Out-Null

            $xmlElementCounter_ClassLine = $coverageXml.CreateElement('counter')
            $xmlElementCounter_ClassLine.SetAttribute('type', 'LINE')
            $xmlElementCounter_ClassLine.SetAttribute('missed', $classCounterLine.Missed)
            $xmlElementCounter_ClassLine.SetAttribute('covered', $classCounterLine.Covered)
            $xmlElementClass.AppendChild($xmlElementCounter_ClassLine) | Out-Null

            if ($classCounterLine.Covered -gt 1)
            {
                $classCovered = 1
                $classMissed = 0

                $packageCounterClass.Covered += 1

                $reportCounterClass.Covered += 1
            }
            else
            {
                $classCovered = 0
                $classMissed = 1

                $packageCounterClass.Missed += 1

                $reportCounterClass.Missed += 1
            }

            $xmlElementCounter_ClassMethod = $coverageXml.CreateElement('counter')
            $xmlElementCounter_ClassMethod.SetAttribute('type', 'METHOD')
            $xmlElementCounter_ClassMethod.SetAttribute('missed', $classCounterMethod.Missed)
            $xmlElementCounter_ClassMethod.SetAttribute('covered', $classCounterMethod.Covered)
            $xmlElementClass.AppendChild($xmlElementCounter_ClassMethod) | Out-Null

            $xmlElementCounter_Class = $coverageXml.CreateElement('counter')
            $xmlElementCounter_Class.SetAttribute('type', 'CLASS')
            $xmlElementCounter_Class.SetAttribute('missed', $classMissed)
            $xmlElementCounter_Class.SetAttribute('covered', $classCovered)
            $xmlElementClass.AppendChild($xmlElementCounter_Class) | Out-Null

            $xmlElementPackage.AppendChild($xmlElementClass) | Out-Null

            <#
                Child element 'sourcefile'.

                Add sourcefile element to an array for each class. The array
                will be added to the XML document at the end of the package
                loop.
            #>
            $xmlElementSourceFile = $coverageXml.CreateElement('sourcefile')
            $xmlElementSourceFile.SetAttribute('name', $sourceFileName)

            $linesToReport = @()

            # Get all instructions that was covered by grouping on 'SourceLineNumber'.
            $linesCovered = $jaCocoClass.Group |
                Sort-Object -Property 'SourceLineNumber' |
                    Where-Object {
                        $_.HitCount -ge 1
                    } |
                        Group-Object -Property 'SourceLineNumber' -NoElement

            # Add each covered line with its count of instructions covered.
            $linesCovered |
                ForEach-Object {
                    $linesToReport += @{
                        Line    = [System.UInt32] $_.Name
                        Covered = $_.Count
                        Missed  = 0
                    }
                }

            # Get all instructions that was missed by grouping on 'SourceLineNumber'.
            $linesMissed = $jaCocoClass.Group |
                Sort-Object -Property 'SourceLineNumber' |
                    Where-Object {
                        $_.HitCount -eq 0
                    } |
                        Group-Object -Property 'SourceLineNumber' -NoElement

            # Add each missed line with its count of instructions missed.
            $linesMissed |
                ForEach-Object {
                    # Test if there are an existing line that is covered.
                    if ($linesToReport.Line -contains $_.Name)
                    {
                        $lineNumberToLookup = $_.Name

                        $coveredLineItem = $linesToReport |
                            Where-Object -FilterScript {
                                $_.Line -eq $lineNumberToLookup
                            }

                        $coveredLineItem.Missed += $_.Count
                    }
                    else
                    {
                        $linesToReport += @{
                            Line    = [System.UInt32] $_.Name
                            Covered = 0
                            Missed  = $_.Count
                        }
                    }
                }

            $linesToReport |
                Sort-Object -Property 'Line' |
                    ForEach-Object -Process {
                        $xmlElementLine = $coverageXml.CreateElement('line')
                        $xmlElementLine.SetAttribute('nr', $_.Line)

                        <#
                            Child element 'line'.

                            These attributes are best explained here:
                            https://stackoverflow.com/questions/33868761/how-to-interpret-the-jacoco-xml-file
                        #>

                        $xmlElementLine.SetAttribute('mi', $_.Missed)
                        $xmlElementLine.SetAttribute('ci', $_.Covered)
                        $xmlElementLine.SetAttribute('mb', 0)
                        $xmlElementLine.SetAttribute('cb', 0)

                        $xmlElementSourceFile.AppendChild($xmlElementLine) |
                            Out-Null
                        }

            <#
                Add counters to sourcefile element. Reuses those element that was
                created for the class element, as they will be the same.
            #>
            $xmlElementSourceFile.AppendChild($xmlElementCounter_ClassInstruction.CloneNode($false)) | Out-Null
            $xmlElementSourceFile.AppendChild($xmlElementCounter_ClassLine.CloneNode($false)) | Out-Null
            $xmlElementSourceFile.AppendChild($xmlElementCounter_ClassMethod.CloneNode($false)) | Out-Null
            $xmlElementSourceFile.AppendChild($xmlElementCounter_Class.CloneNode($false)) | Out-Null

            $allSourceFileElements += $xmlElementSourceFile
        } # end class loop

        # Add all sourcefile elements that was generated in the class-element-loop.
        $allSourceFileElements |
            ForEach-Object -Process {
                $xmlElementPackage.AppendChild($_) | Out-Null
            }

        # Add counters at the package level.
        $xmlElementCounter_PackageInstruction = $coverageXml.CreateElement('counter')
        $xmlElementCounter_PackageInstruction.SetAttribute('type', 'INSTRUCTION')
        $xmlElementCounter_PackageInstruction.SetAttribute('missed', $packageCounterInstruction.Missed)
        $xmlElementCounter_PackageInstruction.SetAttribute('covered', $packageCounterInstruction.Covered)
        $xmlElementPackage.AppendChild($xmlElementCounter_PackageInstruction) | Out-Null

        $xmlElementCounter_PackageLine = $coverageXml.CreateElement('counter')
        $xmlElementCounter_PackageLine.SetAttribute('type', 'LINE')
        $xmlElementCounter_PackageLine.SetAttribute('missed', $packageCounterLine.Missed)
        $xmlElementCounter_PackageLine.SetAttribute('covered', $packageCounterLine.Covered)
        $xmlElementPackage.AppendChild($xmlElementCounter_PackageLine) | Out-Null

        $xmlElementCounter_PackageMethod = $coverageXml.CreateElement('counter')
        $xmlElementCounter_PackageMethod.SetAttribute('type', 'METHOD')
        $xmlElementCounter_PackageMethod.SetAttribute('missed', $packageCounterMethod.Missed)
        $xmlElementCounter_PackageMethod.SetAttribute('covered', $packageCounterMethod.Covered)
        $xmlElementPackage.AppendChild($xmlElementCounter_PackageMethod) | Out-Null

        $xmlElementCounter_PackageClass = $coverageXml.CreateElement('counter')
        $xmlElementCounter_PackageClass.SetAttribute('type', 'CLASS')
        $xmlElementCounter_PackageClass.SetAttribute('missed', $packageCounterClass.Missed)
        $xmlElementCounter_PackageClass.SetAttribute('covered', $packageCounterClass.Covered)
        $xmlElementPackage.AppendChild($xmlElementCounter_PackageClass) | Out-Null

        $xmlElementReport.AppendChild($xmlElementPackage) | Out-Null
    } # end package loop

    # Add counters at the report level.
    $xmlElementCounter_ReportInstruction = $coverageXml.CreateElement('counter')
    $xmlElementCounter_ReportInstruction.SetAttribute('type', 'INSTRUCTION')
    $xmlElementCounter_ReportInstruction.SetAttribute('missed', $reportCounterInstruction.Missed)
    $xmlElementCounter_ReportInstruction.SetAttribute('covered', $reportCounterInstruction.Covered)
    $xmlElementReport.AppendChild($xmlElementCounter_ReportInstruction) | Out-Null

    $xmlElementCounter_ReportLine = $coverageXml.CreateElement('counter')
    $xmlElementCounter_ReportLine.SetAttribute('type', 'LINE')
    $xmlElementCounter_ReportLine.SetAttribute('missed', $reportCounterLine.Missed)
    $xmlElementCounter_ReportLine.SetAttribute('covered', $reportCounterLine.Covered)
    $xmlElementReport.AppendChild($xmlElementCounter_ReportLine) | Out-Null

    $xmlElementCounter_ReportMethod = $coverageXml.CreateElement('counter')
    $xmlElementCounter_ReportMethod.SetAttribute('type', 'METHOD')
    $xmlElementCounter_ReportMethod.SetAttribute('missed', $reportCounterMethod.Missed)
    $xmlElementCounter_ReportMethod.SetAttribute('covered', $reportCounterMethod.Covered)
    $xmlElementReport.AppendChild($xmlElementCounter_ReportMethod) | Out-Null

    $xmlElementCounter_ReportClass = $coverageXml.CreateElement('counter')
    $xmlElementCounter_ReportClass.SetAttribute('type', 'CLASS')
    $xmlElementCounter_ReportClass.SetAttribute('missed', $reportCounterClass.Missed)
    $xmlElementCounter_ReportClass.SetAttribute('covered', $reportCounterClass.Covered)
    $xmlElementReport.AppendChild($xmlElementCounter_ReportClass) | Out-Null

    $coverageXml.AppendChild($xmlElementReport) | Out-Null

    if ($DebugPreference -ne 'SilentlyContinue')
    {
        $StringWriter = New-Object -TypeName 'System.IO.StringWriter'
        $XmlWriter = New-Object -TypeName 'System.XMl.XmlTextWriter' -ArgumentList $StringWriter

        $xmlWriter.Formatting = 'indented'
        $xmlWriter.Indentation = 2

        $coverageXml.WriteContentTo($XmlWriter)

        $XmlWriter.Flush()

        $StringWriter.Flush()

        # Blank row in output
        ""

        Write-Debug -Message ($StringWriter.ToString() | Out-String)
    }

    $newCoverageFilePath = Join-Path -Path $PesterOutputFolder -ChildPath 'JaCoCo_source_coverage.xml'

    Write-Build -Color 'DarkGray' -Text "`tWriting converted code coverage file to '$newCoverageFilePath'."

    $xmlSettings = New-Object -TypeName 'System.Xml.XmlWriterSettings'
    $xmlSettings.Indent = $true
    $xmlSettings.Encoding = [System.Text.Encoding]::$CodeCoverageOutputFileEncoding

    $xmlWriter = [System.Xml.XmlWriter]::Create($newCoverageFilePath, $xmlSettings)

    $coverageXml.Save($xmlWriter)

    $xmlWriter.Close()

    Write-Build -Color 'DarkGray' -Text "`tImporting original code coverage file '$CodeCoverageOutputFile'."

    $originalXml = New-Object -TypeName 'System.Xml.XmlDocument'
    $originalXml.Load($CodeCoverageOutputFile)

    $codeCoverageOutputBackupFile = $CodeCoverageOutputFile -replace '\.xml', '.bak.xml'
    $newCoverageFilePath = Join-Path -Path $PesterOutputFolder -ChildPath $codeCoverageOutputBackupFile

    Write-Build -Color 'DarkGray' -Text "`tWriting a backup of original code coverage file to '$codeCoverageOutputBackupFile'."

    $xmlSettings = New-Object -TypeName 'System.Xml.XmlWriterSettings'
    $xmlSettings.Indent = $true
    $xmlSettings.Encoding = [System.Text.Encoding]::$CodeCoverageOutputFileEncoding

    $xmlWriter = [System.Xml.XmlWriter]::Create($codeCoverageOutputBackupFile, $xmlSettings)

    $originalXml.Save($xmlWriter)

    $xmlWriter.Close()

    Write-Build -Color 'DarkGray' -Text "`tRemoving XML node from original code coverage."

    $xPath = '//package[@name="{0}"]' -f $ModuleVersionFolder

    Write-Build -Color 'DarkGray' -Text "`t`tUsing XPath: '$xPath'."

    $elementToRemove = Select-XML -Xml $originalXml -XPath $xPath

    if ($elementToRemove)
    {
        $elementToRemove.Node.ParentNode.RemoveChild($elementToRemove.Node) | Out-Null
    }

    Write-Build -Color 'DarkGray' -Text "`tMerging temporary code coverage file with the original code coverage file."

    $targetXmlDocument = Merge-JaCoCoReport -OriginalDocument $originalXml -MergeDocument $coverageXml

    Write-Build -Color 'DarkGray' -Text "`tUpdating statistics in the new code coverage file."

    $targetXmlDocument = Update-JaCoCoStatistic -Document $targetXmlDocument

    Write-Build -Color 'DarkGray' -Text "`tWriting back updated code coverage file to '$CodeCoverageOutputFile'."

    $xmlSettings = New-Object -TypeName 'System.Xml.XmlWriterSettings'
    $xmlSettings.Indent = $true
    $xmlSettings.Encoding = [System.Text.Encoding]::$CodeCoverageOutputFileEncoding

    $xmlWriter = [System.Xml.XmlWriter]::Create($CodeCoverageOutputFile, $xmlSettings)

    $originalXml.Save($xmlWriter)

    $xmlWriter.Close()

    Write-Build -Color Green -Text 'Code Coverage successfully converted.'
}

# Synopsis: Uploading Unit Test results to AppVeyor.
task Upload_Test_Results_To_AppVeyor -If { (property BuildSystem 'unknown') -eq 'AppVeyor' } {
    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-SamplerProjectName -BuildRoot $BuildRoot
    }

    $OutputDirectory = Get-SamplerAbsolutePath -Path $OutputDirectory -RelativeTo $BuildRoot
    $PesterOutputFolder = Get-SamplerAbsolutePath -Path $PesterOutputFolder -RelativeTo $OutputDirectory
    "`tProject Name             = '$ProjectName'"
    "`tOutput Directory         = '$OutputDirectory'"
    "`tPester Output Folder     = '$PesterOutputFolder'"

    if (-not (Test-Path -Path $PesterOutputFolder))
    {
        Write-Build -Color 'Yellow' -Text "Creating folder $PesterOutputFolder"

        $null = New-Item -Path $PesterOutputFolder -ItemType Directory -Force -ErrorAction 'Stop'
    }

    $osShortName = Get-OperatingSystemShortName

    if ($VersionedOutputDirectory)
    {
        # VersionedOutputDirectory is not [bool]'' nor $false nor [bool]$null
        # Assume true, wherever it was set
        $VersionedOutputDirectory = $true
    }
    else
    {
        # VersionedOutputDirectory may be [bool]'' but we can't tell where it's
        # coming from, so assume the build info (Build.yaml) is right
        $VersionedOutputDirectory = $BuildInfo['VersionedOutputDirectory']
    }

    $GetBuiltModuleManifestParams = @{
        OutputDirectory          = $OutputDirectory
        BuiltModuleSubDirectory  = $BuiltModuleSubDirectory
        ModuleName               = $ProjectName
        VersionedOutputDirectory = $VersionedOutputDirectory
        ErrorAction              = 'Stop'
    }

    $builtModuleBase = Get-SamplerBuiltModuleBase @GetBuiltModuleManifestParams
    "`tBuilt Module Base        = '$builtModuleBase'"

    $builtModuleManifest = Get-SamplerBuiltModuleManifest @GetBuiltModuleManifestParams
    "`tBuilt Module Manifest    = '$builtModuleManifest'"

    if ($builtModuleRootScriptPath = Get-SamplerModuleRootPath -ModuleManifestPath $builtModuleManifest)
    {
        $builtModuleRootScriptPath = (Get-Item -Path $builtModuleRootScriptPath -ErrorAction SilentlyContinue).FullName
    }

    "`tBuilt ModuleRoot script  = '$builtModuleRootScriptPath'"

    $builtDscResourcesFolder = Get-SamplerAbsolutePath -Path 'DSCResources' -RelativeTo $builtModuleBase
    "`tBuilt DSC Resource Path  = '$builtDscResourcesFolder'"

    $ModuleVersion = Get-BuiltModuleVersion @GetBuiltModuleManifestParams
    $ModuleVersionObject = Split-ModuleVersion -ModuleVersion $ModuleVersion
    $ModuleVersionFolder = $ModuleVersionObject.Version
    $preReleaseTag = $ModuleVersionObject.PreReleaseString

    "`tModule Version           = '$ModuleVersion'"
    "`tModule Version Folder    = '$ModuleVersionFolder'"
    "`tPre-release Tag          = '$preReleaseTag'"

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
task Pester_Tests_Stop_On_Fail Invoke_Pester_Tests, Upload_Test_Results_To_AppVeyor, Fail_Build_If_Pester_Tests_Failed
