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
    [System.Management.Automation.SwitchParameter]
    $VersionedOutputDirectory = (property VersionedOutputDirectory $true),

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
Task Build_ModuleOutput_ModuleBuilder {
    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-SamplerProjectName -BuildRoot $BuildRoot
    }

    if ([System.String]::IsNullOrEmpty($SourcePath))
    {
        $SourcePath = Get-SamplerSourcePath -BuildRoot $BuildRoot
    }

    $OutputDirectory = Get-SamplerAbsolutePath -Path $OutputDirectory -RelativeTo $BuildRoot
    $BuiltModuleSubdirectory = Get-SamplerAbsolutePath -Path $BuiltModuleSubdirectory -RelativeTo $OutputDirectory
    $moduleManifestPath = Get-SamplerAbsolutePath -Path "$ProjectName.psd1" -RelativeTo $SourcePath

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
    $ReleaseNotesPath = Get-SamplerAbsolutePath -Path $ReleaseNotesPath -RelativeTo $OutputDirectory

    "`tProject Name               = '$ProjectName'"
    "`tModule Version             = '$ModuleVersion'"
    "`tSource Path                = '$SourcePath'"
    "`tOutput Directory           = '$OutputDirectory'"
    "`tBuilt Module Subdirectory  = '$BuiltModuleSubdirectory'"
    "`tModule Manifest Path (src) = '$moduleManifestPath'"
    "`tRelease Notes path         = '$ReleaseNotesPath'"

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

    $OutputDirectory = Get-SamplerAbsolutePath -Path $OutputDirectory -RelativeTo $BuildRoot
    "`tOutputDirectory       = '$OutputDirectory'"
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
        BuiltModuleSubdirectory  = $BuiltModuleSubDirectory
        ModuleName               = $ProjectName
        VersionedOutputDirectory = $VersionedOutputDirectory
        ErrorAction              = 'Stop'
    }

    $builtModuleManifest = Get-SamplerBuiltModuleManifest @GetBuiltModuleManifestParams
    $builtModuleManifest = (Get-Item -Path $builtModuleManifest).FullName
    "`tBuilt Module Manifest = '$builtModuleManifest'"

    $builtModuleBase = Get-SamplerBuiltModuleBase @GetBuiltModuleManifestParams
    $builtModuleBase = (Get-Item -Path $builtModuleBase).FullName
    "`tBuilt Module Base     = '$builtModuleBase'"

    $moduleVersion = Get-BuiltModuleVersion @GetBuiltModuleManifestParams
    $moduleVersionObject = Split-ModuleVersion -ModuleVersion $moduleVersion
    $moduleVersionFolder = $moduleVersionObject.Version
    $preReleaseTag = $moduleVersionObject.PreReleaseString

    "`tModule Version        = '$ModuleVersion'"
    "`tModule Version Folder = '$moduleVersionFolder'"
    "`tPre-release Tag       = '$preReleaseTag'"

    Import-Module -Name 'ModuleBuilder' -ErrorAction 'Stop'

    $nestedModule = $BuildInfo.NestedModule
    $nestedModulesToAdd = @()

    foreach ($nestedModuleName in $nestedModule.Keys)
    {
        $cmdParam = $nestedModule[$nestedModuleName]

        $addToManifest = [bool]$cmdParam['AddToManifest']

        # Either copy only or Build
        if ([System.Boolean] $cmdParam['CopyOnly'])
        {
            Write-Build -Color 'Yellow' -Text "Copying Nested Module files for $nestedModuleName"

            $cmd = Get-Command -Name 'Copy-Item'

            if (-not $cmdParam.ContainsKey('Path') -and -not $cmdParam.ContainsKey('SourcePath'))
            {
                $cmdParam['Path'] = '$SourcePath/Modules/$nestedModuleName'
                Write-Build -Color 'DarkGray' -Text "    Default param Path is '$($cmdParam['Path'])'"
            }

            # Default to -Recurse unless the BuildInfo is alredy configured
            if (-not $cmdParam.ContainsKey('Recurse'))
            {
                $cmdParam['Recurse'] = $true
                Write-Build -Color 'DarkGray' -Text "    Default param Recurse is '$($cmdParam['Recurse'])'"
            }

            # Set default Destination (substitute later)
            if (-not $cmdParam.ContainsKey('Destination'))
            {
                $cmdParam['Destination'] = '$builtModuleBase/Modules/$nestedModuleName'
                Write-Build -Color 'DarkGray' -Text "    Default param Destination is '$($cmdParam['Destination'])'"
            }
        }
        else
        {
            # When we want to build the nested modules:
            $cmd = Get-Command -Name 'Build-Module'

            if (-not $cmdParam.ContainsKey('Path') -and -not $cmdParam.ContainsKey('SourcePath'))
            {
                $cmdParam['SourcePath'] = '$SourcePath/Modules/$nestedModuleName/$nestedModuleName.psd1'
                Write-Build -Color 'DarkGray' -Text "    Default param SourcePath is '$($cmdParam['SourcePath'])'"
            }

            if (-not $cmdParam.ContainsKey('OutputDirectory') -and -not $cmdParam.ContainsKey('Destination'))
            {
                $cmdParam['OutputDirectory'] = '$builtModuleBase/Modules/$nestedModuleName'
                Write-Build -Color 'DarkGray' -Text "    Default param OutputDirectory is '$($cmdParam['OutputDirectory'])'"
            }

            Write-Build -Color 'Yellow' -Text "Building Nested Module $nestedModuleName"
        }

        $cmdParamKeys = @() + $cmdParam.Keys

        foreach ($paramName in $cmdParamKeys)
        {
            if ($paramName -eq 'SourcePath' -or $paramName -eq 'Path')
            {
                if ($cmd.Verb -eq 'Copy')
                {
                    $cmdParam[$paramName] = Join-Path -Path $ExecutionContext.InvokeCommand.ExpandString($cmdParam[$paramName]) -ChildPath '*'
                    Write-Build -Color 'White' -Text "    The $paramName is: '$($cmdParam[$paramName])'"
                }
                else
                {
                    <#
                        To support building the nestedModule without a build manifest the SourcePath must be
                        set to the path to the source nested module manifest.
                    #>
                    $nestedModuleSourceManifest = $ExecutionContext.InvokeCommand.ExpandString($cmdParam[$paramName])
                    $nestedModuleSourceManifest = Get-SamplerAbsolutePath -Path $nestedModuleSourceManifest -RelativeTo $buildRoot

                    # If the BuildInfo has been defined with the SourcePath folder, Append the Module Manifest
                    if (([System.io.FileInfo]$nestedModuleSourceManifest).Extension -ne '.psd1')
                    {
                        $nestedModuleSourceManifest = Join-Path -Path $nestedModuleSourceManifest -ChildPath ('{0}.psd1' -f $nestedModuleName)
                    }

                    $cmdParam[$paramName] = $nestedModuleSourceManifest
                    Write-Build -Color 'White' -Text "    The SourcePath is: $($cmdParam[$paramName])"
                }
            }
            elseif ($paramName -notin @($cmd.Parameters.keys + $cmd.Parameters.values.aliases))
            {
                # remove param not available in command
                Write-Build -Color 'White' -Text "    Removing Parameter $paramName for $($cmd.Name)"

                $cmdParam.Remove($paramName)
            }
            elseif ($paramName -in @('Destination', 'OutputDirectory', 'SemVer'))
            {
                # Substitute & Resolve Resolve Path to absolutes (relative assumed is $BuildRoot)
                Write-Build -Color 'White' -Text "    Resolving Absolute path for $paramName $($cmdParam[$paramName])"

                $cmdParam[$paramName] = $ExecutionContext.InvokeCommand.ExpandString($cmdParam[$paramName])

                if ($paramName -ne 'SemVer')
                {
                    $cmdParam[$paramName] = Get-SamplerAbsolutePath -Path $cmdParam[$paramName] -RelativeTo $BuildRoot
                    if (-not (Test-Path -Path $cmdParam[$paramName]))
                    {
                        $null = New-Item -Path $cmdParam[$paramName] -ItemType Directory -Force -ErrorAction Stop
                    }
                }

                Write-Build -Color 'White' -Text "    The $paramName is: $($cmdParam[$paramName])"
            }
        }

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
                if ($cmdParam.ContainsKey('OutputDirectory'))
                {
                    $nestedModulePath = $cmdParam['OutputDirectory']
                }
                else
                {
                    $nestedModulePath = $cmdParam['Destination']
                }
            }

            Write-Build -Color 'DarkMagenta' -Text "  Looking in '$nestedModulePath'"

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

    $ModuleInfo = Get-SamplerModuleInfo -ModuleManifestPath $builtModuleManifest

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

    $OutputDirectory = Get-SamplerAbsolutePath -Path $OutputDirectory -RelativeTo $BuildRoot

    "`tProject Name             = '$ProjectName'"
    "`tSource Path              = '$SourcePath'"
    "`tOutput Directory         = '$OutputDirectory'"

    Import-Module -Name 'ModuleBuilder' -ErrorAction 'Stop'

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
    $builtModuleBase = (Get-Item -Path $builtModuleBase).FullName
    "`tBuilt Module Base        = '$builtModuleBase'"

    $builtModuleManifest = Get-SamplerBuiltModuleManifest @GetBuiltModuleManifestParams
    $builtModuleManifest = (Get-Item -Path $builtModuleManifest).FullName
    "`tBuilt Module Manifest    = '$builtModuleManifest'"

    $builtModuleRootScriptPath = Get-SamplerModuleRootPath -ModuleManifestPath $builtModuleManifest

    if ($builtModuleRootScriptPath)
    {
        $builtModuleRootScriptPath = (Get-Item -Path $builtModuleRootScriptPath -ErrorAction 'SilentlyContinue').FullName
    }

    "`tBuilt Module Root Script  = '$builtModuleRootScriptPath'"

    $builtDscResourcesFolder = Get-SamplerAbsolutePath -Path 'DSCResources' -RelativeTo $builtModuleBase
    "`tBuilt DSC Resource Path  = '$builtDscResourcesFolder'"

    $ModuleVersion = Get-BuiltModuleVersion @GetBuiltModuleManifestParams
    $ModuleVersionObject = Split-ModuleVersion -ModuleVersion $ModuleVersion
    $ModuleVersionFolder = $ModuleVersionObject.Version
    $preReleaseTag = $ModuleVersionObject.PreReleaseString

    "`tModule Version           = '$ModuleVersion'"
    "`tModule Version Folder    = '$ModuleVersionFolder'"
    "`tPre-release Tag          = '$preReleaseTag'"

    $DSCResourcesToAdd = @()

    #Check if there are classes based resource in psm1
    if ($null -ne $builtModuleRootScriptPath -and (Test-Path -Path $builtModuleRootScriptPath))
    {
        Write-Build -Color 'Yellow' -Text "Looking in $builtModuleRootScriptPath"

        $builtClassDscResourcesNames = Get-ClassBasedResourceName -Path $builtModuleRootScriptPath

        if ($builtClassDscResourcesNames)
        {
            Write-Build -Color 'White' -Text "  Adding $($builtClassDscResourcesNames -join ',') to the list of DscResource will be write in module manifest."

            $DSCResourcesToAdd = $DSCResourcesToAdd + $builtClassDscResourcesNames
        }
    }

    #Check if DSCResource Folder has DSCResources
    Write-Build -Color 'Yellow' -Text "Looking in $builtDscResourcesFolder"

    if ($builtMofDscFolder = (Get-ChildItem -Path $builtDscResourcesFolder -Directory -ErrorAction SilentlyContinue))
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

    $ModuleInfo = Get-SamplerModuleInfo -ModuleManifestPath $builtModuleManifest

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
