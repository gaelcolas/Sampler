param
(
    [Parameter()]
    [System.String]
    $ProjectName = (property ProjectName ''),

    [Parameter()]
    [System.String]
    $SourcePath = (property SourcePath ''),

    [Parameter()]
    [System.String]
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot "output")),

    [Parameter()]
    [System.String]
    $BuiltModuleSubdirectory = (property BuiltModuleSubdirectory ''),

    [Parameter()]
    [System.String]
    $BuildModuleOutput = (property BuildModuleOutput (Join-Path $OutputDirectory $BuiltModuleSubdirectory)),

    [Parameter()]
    [System.String]
    $ReleaseNotesPath = (property ReleaseNotesPath (Join-Path $OutputDirectory 'ReleaseNotes.md')),

    [Parameter()]
    [System.String]
    $ModuleVersion = (property ModuleVersion ''),

    [Parameter()]
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)

# Synopsis: Build the Module based on its Build.psd1 definition
Task Build_ModuleOutPut_ModuleBuilder {
    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-SamplerProjectName -BuildRoot $BuildRoot
    }

    if ([System.String]::IsNullOrEmpty($SourcePath))
    {
        $SourcePath = Get-SamplerSourcePath -BuildRoot $BuildRoot
    }

    $moduleManifestPath = "$SourcePath/$ProjectName.psd1"

    $getBuildVersionParameters = @{
        ModuleManifestPath = $moduleManifestPath
        ModuleVersion      = $ModuleVersion
    }

    <#
        This will get the version from $ModuleVersion if is was set as a parameter
        or as a property. If $ModuleVersion is $null or an empty string the version
        will fetched from GitVersion if it is installed. If GitVersion is _not_
        installed the version is fetched from the module manifest in SourcePath.
    #>
    $ModuleVersion = Get-BuildVersion @getBuildVersionParameters

    "`tProject Name         = $ProjectName"
    "`tModule Version       = $ModuleVersion"
    "`tSource Path          = $SourcePath"
    "`tOutput Directory     = $OutputDirectory"
    "`tBuild Module Output  = $BuildModuleOutput"
    "`tModule Manifest Path = $moduleManifestPath"

    if (-not (Split-Path -IsAbsolute $ReleaseNotesPath))
    {
        $ReleaseNotesPath = Join-Path -Path $OutputDirectory -ChildPath $ReleaseNotesPath
    }

    Import-Module -Name ModuleBuilder -ErrorAction 'Stop'

    $buildModuleParams = @{}

    foreach ($paramName in (Get-Command -Name Build-Module).Parameters.Keys)
    {
        if ($paramName -eq 'SourcePath')
        {
            <#
                To support building the without a build manifest the SourcePath must be
                set to the path to the source module manifest.
            #>
            $buildModuleParams.Add($paramName, $moduleManifestPath)
        }
        else
        {
            $valueFromBuildParam = Get-Variable -Name $paramName -ValueOnly -ErrorAction 'SilentlyContinue'
            $valueFromBuildInfo = $BuildInfo[$paramName]

            <#
                If Build-Module parameters are available in current session, use those
                otherwise use params from BuildInfo if specified.
            #>
            if ($valueFromBuildParam)
            {
                Write-Build -Color 'DarkGray' -Text "Adding $paramName with value $valueFromBuildParam from current Variables"

                if ($paramName -eq 'OutputDirectory')
                {
                    $buildModuleParams.Add($paramName, (Join-Path -Path $BuildModuleOutput -ChildPath $ProjectName))
                }
                else
                {
                    $buildModuleParams.Add($paramName, $valueFromBuildParam)
                }
            }
            elseif ($valueFromBuildInfo)
            {
                Write-Build -Color 'DarkGray' "Adding $paramName with value $valueFromBuildInfo from Build Info"

                $buildModuleParams.Add($paramName, $valueFromBuildInfo)
            }
            else
            {
                Write-Debug -Message "No value specified for $paramName"
            }
        }
    }

    Write-Build -Color 'Green' -text "Building Module to $($buildModuleParams['OutputDirectory'])..."

    $BuiltModule = Build-Module @buildModuleParams -SemVer $ModuleVersion -PassThru

    # if we built the PSM1 on Windows with a BOM, re-write without BOM
    if ($PSVersionTable.PSVersion.Major -le 5)
    {
        if (Split-Path -IsAbsolute -Path $BuiltModule.RootModule)
        {
            $Psm1Path = $BuiltModule.RootModule
        }
        else
        {
            $Psm1Path = Join-Path -Path $BuiltModule.ModuleBase -ChildPath $BuiltModule.RootModule
        }

        $RootModuleDefinition = Get-Content -Raw -Path $Psm1Path
        [System.IO.File]::WriteAllLines($Psm1Path, $RootModuleDefinition)
    }

    if (Test-Path -Path $ReleaseNotesPath)
    {
        $releaseNotes = Get-Content -Path $ReleaseNotesPath -Raw

        $outputManifest = $BuiltModule.Path

        Update-Metadata -Path $outputManifest -PropertyName 'PrivateData.PSData.ReleaseNotes' -Value $releaseNotes
    }
}

Task Build_NestedModules_ModuleBuilder {
    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-SamplerProjectName -BuildRoot $BuildRoot
    }

    if ([System.String]::IsNullOrEmpty($SourcePath))
    {
        $SourcePath = Get-SamplerSourcePath -BuildRoot $BuildRoot
    }

    "`tProject Name          = $ProjectName"
    "`tSource Path           = $SourcePath"
    "`tOutput Directory      = $OutputDirectory"
    "`tBuild Module Output   = $BuildModuleOutput"

    $isImportPowerShellDataFileAvailable = Get-Command -Name Import-PowerShellDataFile -ErrorAction SilentlyContinue

    if ($PSversionTable.PSversion.Major -le 5 -and -not $isImportPowerShellDataFileAvailable)
    {
        Import-Module -Name Microsoft.PowerShell.Utility -RequiredVersion 3.1.0.0
    }

    Import-Module -Name 'ModuleBuilder' -ErrorAction 'Stop'

    $builtModuleManifest = "$BuildModuleOutput/$ProjectName/*/$ProjectName.psd1"

    "`tBuilt Module Manifest = $builtModuleManifest"

    $getModuleVersionParameters = @{
        OutputDirectory = $BuildModuleOutput
        ProjectName     = $ProjectName
    }

    $ModuleVersion = Get-BuiltModuleVersion @getModuleVersionParameters
    $ModuleVersionFolder, $preReleaseTag = $ModuleVersion -split '\-', 2

    "`tModule Version        = $ModuleVersion"
    "`tModule Version Folder = $ModuleVersionFolder"
    "`tPre-release Tag       = $preReleaseTag"

    $nestedModule = $BuildInfo.NestedModule
    $nestedModulesToAdd = @()

    foreach ($nestedModuleName in $nestedModule.Keys)
    {
        $cmdParam = $nestedModule[$nestedModuleName]

        $addToManifest = [bool]$cmdParam['AddToManifest']

        # Either copy only or Build
        if ([System.Boolean] $cmdParam['CopyOnly'])
        {
            Write-Debug -Message "Using parameters to copy nested module from Source to Destination"

            $cmd = Get-Command -Name 'Copy-Item'

            if (-not $cmdParam.ContainsKey('Path'))
            {
                $cmdParam['Path'] = '$SourcePath/Modules/$nestedModuleName'
            }

            if (-not $cmdParam.ContainsKey('Recurse'))
            {
                $cmdParam['Recurse'] = $true
            }

            # Set default Destination (substitute later)
            if (-not $cmdParam.ContainsKey('Destination'))
            {
                $cmdParam['Destination'] = '$BuildModuleOutput/$ProjectName/$ModuleVersionFolder/Modules/$nestedModuleName'
            }

            Write-Build -Color 'Yellow' -Text "Copying Nested Module files for $nestedModuleName"
        }
        else
        {
            $cmd = Get-Command -Name 'Build-Module'

            Write-Build -Color 'Yellow' -Text "Building Nested Module $nestedModuleName"
        }

        $cmdParamKeys = @() + $cmdParam.Keys

        foreach ($paramName in $cmdParamKeys)
        {
            # remove param not available in command
            if ($paramName -notin @($cmd.Parameters.keys + $cmd.Parameters.values.aliases))
            {
                Write-Build -Color 'White' -Text "Removing Parameter $paramName for $($cmd.Name)"

                $cmdParam.Remove($paramName)
            }
            elseif ($paramName -in @('Path', 'Destination', 'OutputDirectory', 'SemVer'))
            {
                # Substitute & Resolve Resolve Path to absolutes (relative assumed is $BuildRoot)
                Write-Build -Color 'White' -Text "Resolving Absolute path for $paramName $($cmdParam[$paramName])"

                $cmdParam[$paramName] = $ExecutionContext.InvokeCommand.ExpandString($cmdParam[$paramName])

                if (-not (Split-Path -Path $cmdParam[$paramName] -IsAbsolute) -and $paramName -ne 'SemVer')
                {
                    $cmdParam[$paramName] = Join-Path -Path $BuildRoot -ChildPath $cmdParam[$paramName]
                }

                Write-Build -Color 'White' -Text "    The $paramName is: $($cmdParam[$paramName])"
            }
        }

        $builtModuleBase = Split-Path -Parent -Path $BuiltModuleManifest

        Write-Build -Color 'Green' -Text "$($cmd.Verb) $nestedModuleName..."

        if ($cmdParam.Verbose)
        {
            Write-Verbose -Message ($CmdParam | ConvertTo-Json) -Verbose
        }

        & $cmd @cmdParam

        if ($addToManifest)
        {
            Write-Build -Color 'DarkMagenta' -Text "  Preparing to Add to Manifest"

            if ($cmd.Name -eq 'Copy-Item')
            {
                $nestedModulePath = $cmdParam['Destination']
            }
            else
            {
                $nestedModulePath = $cmdParam['OutputDirectory']
            }

            Write-Build -Color 'DarkMagenta' -Text "  Looking in $nestedModulePath"

            $nestedModuleFile = (Get-ChildItem -Path $nestedModulePath -Recurse -Include '*.psd1' |
                    Where-Object -FilterScript {
                        (
                            $_.Directory.Name -eq $_.BaseName -or $_.Directory.Name -as [version]) `
                            -and $(Test-ModuleManifest -Path $_.FullName -ErrorAction 'SilentlyContinue' ).Version
                    }
            ).FullName -replace [Regex]::Escape($builtModuleBase), ".$([System.IO.Path]::DirectorySeparatorChar)"


            if (-not $nestedModuleFile)
            {
                $nestedModuleFile = Get-ChildItem -Path $nestedModulePath -Recurse -Include '*.psm1' |
                    ForEach-Object -Process {
                        $_.FullName -replace [Regex]::Escape($builtModuleBase), ".$([System.IO.Path]::DirectorySeparatorChar)"
                    }
            }

            Write-Build -Color 'DarkMagenta' -Text "Found $($nestedModuleFile -join ';')"

            $nestedModulesToAdd += $nestedModuleFile
        }

        Write-Build -Color 'Green' -Text "Done `r`n"
    }

    $ModuleInfo = Import-PowerShellDataFile -Path $BuiltModuleManifest -ErrorAction 'Stop'

    # Add to NestedModules to ModuleManifest
    if ($ModuleInfo.ContainsKey('NestedModules') -and $nestedModulesToAdd)
    {
        Write-Build -Color 'Green' -Text "Updating the Module Manifest's NestedModules key..."

        $nestedModulesToAdd = $ModuleInfo.NestedModules + $nestedModulesToAdd

        # Get Nested Module Manifest or PSM1
        $updateMetadataParams = @{
            Path         = (Get-Item -Path $BuiltModuleManifest).FullName
            PropertyName = 'NestedModules'
            Value        = $nestedModulesToAdd
            ErrorAction  = 'Stop'
        }

        Write-Build -Color 'Green' -Text "  Adding $($NestedModuleToAdd -join ', ') to Module Manifest $($updateMetadataParams.Path)"

        Update-Metadata @updateMetadataParams
    }
}

Task Build_DscResourcesToExport_ModuleBuilder {
    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-SamplerProjectName -BuildRoot $BuildRoot
    }

    if ([System.String]::IsNullOrEmpty($SourcePath))
    {
        $SourcePath = Get-SamplerSourcePath -BuildRoot $BuildRoot
    }

    "`tProject Name             = $ProjectName"
    "`tSource Path              = $SourcePath"
    "`tOutput Directory         = $OutputDirectory"
    "`tBuild Module Output      = $BuildModuleOutput"

    $isImportPowerShellDataFileAvailable = Get-Command -Name Import-PowerShellDataFile -ErrorAction SilentlyContinue

    if ($PSversionTable.PSversion.Major -le 5 -and -not $isImportPowerShellDataFileAvailable)
    {
        Import-Module -Name Microsoft.PowerShell.Utility -RequiredVersion 3.1.0.0
    }

    Import-Module -Name 'ModuleBuilder' -ErrorAction 'Stop'

    $builtModuleManifest = "$BuildModuleOutput/$ProjectName/*/$ProjectName.psd1"
    $builtModuleRootScriptPath = "$BuildModuleOutput/$ProjectName/*/$ProjectName.psm1"
    $builtDscResourcesFolder = "$BuildModuleOutput/$ProjectName/*/DSCResources/*"

    "`tBuilt Module Manifest    = $builtModuleManifest"

    $getModuleVersionParameters = @{
        OutputDirectory = $BuildModuleOutput
        ProjectName     = $ProjectName
    }

    $ModuleVersion = Get-BuiltModuleVersion @getModuleVersionParameters
    $ModuleVersionFolder, $preReleaseTag = $ModuleVersion -split '\-', 2

    "`tModule Version           = $ModuleVersion"
    "`tModule Version Folder    = $ModuleVersionFolder"
    "`tPre-release Tag          = $preReleaseTag"

    $DSCResourcesToAdd = @()

    #Check if there are classes based resource in psm1
    if ($builtModuleRootScriptFile = Get-Item -Path $builtModuleRootScriptPath -ErrorAction SilentlyContinue)
    {
        "`tBuilt Module Root Script = $($builtModuleRootScriptFile.FullName)"

        Write-Build -Color 'Yellow' -Text "Looking in $builtModuleRootScriptPath"

        $builtClassDscResourcesNames = Get-ClassBasedResourceName -Path $builtModuleRootScriptFile.FullName

        if ($builtClassDscResourcesNames)
        {
            Write-Build -Color 'White' -Text "  Adding $($builtClassDscResourcesNames -join ',') to the list of DscResource will be write in module manifest."

            $DSCResourcesToAdd = $DSCResourcesToAdd + $builtClassDscResourcesNames
        }
    }

    #Check if DSCResource Folder has DSCResources
    Write-Build -Color 'Yellow' -Text "Looking in $builtDscResourcesFolder"

    if ($builtMofDscFolder = (Get-ChildItem -Path $builtDscResourcesFolder -Directory))
    {
        if ($mofPath = $builtMofDscFolder | Get-ChildItem -Include '*.schema.mof' -File)
        {
            try
            {
                $builtMofDscResourcesNames = $mofPath.FullName | Get-MofSchemaName | ForEach-Object -Process {
                    if ([System.String]::IsNullOrEmpty($_['FriendlyName']))
                    {
                        $_.Name
                    }
                    else
                    {
                        $_.friendlyName
                    }
                }
            }
            catch
            {
                Write-Warning -Message ('Impossible to extract the name of the Mof based DSCResource, see the error : {0}' -f $_)
            }
        }
        else
        {
            Write-Warning -Message ('No mof file found in DscResource folder')
        }

        if ($builtMofDscResourcesNames)
        {
            Write-Build -Color 'White' -Text "  Adding $($builtMofDscResourcesNames -join ',') to the list of DscResource will be write in module manifest."

            $DSCResourcesToAdd = $DSCResourcesToAdd + $builtMofDscResourcesNames
        }
    }

    $ModuleInfo = Import-PowerShellDataFile -Path $BuiltModuleManifest -ErrorAction 'Stop'

    # Add to DscResourcesToExport to ModuleManifest
    if ($ModuleInfo.ContainsKey('DscResourcesToExport') -and $DSCResourcesToAdd)
    {
        Write-Build -Color 'Green' -Text "Updating the Module Manifest's DscResourcesToExport key..."

        $DSCResourcesToAdd = $ModuleInfo.DscResourcesToExport + $DSCResourcesToAdd | Select-Object -Unique

        $updateMetadataParams = @{
            Path         = (Get-Item -Path $BuiltModuleManifest).FullName
            PropertyName = 'DscResourcesToExport'
            Value        = [array]$DSCResourcesToAdd
            ErrorAction  = 'Stop'
        }

        Write-Build -Color 'Green' -Text "  Adding $($DSCResourcesToAdd -join ', ') to Module Manifest $($updateMetadataParams.Path)"

        Update-Metadata @updateMetadataParams
    }
}

Task Build_Module_ModuleBuilder Build_ModuleOutput_ModuleBuilder, Build_DscResourcesToExport_ModuleBuilder
