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

Import-Module -Name "$PSScriptRoot/Common.Functions.psm1"

# Synopsis: Build the Module based on its Build.psd1 definition
Task Build_Module_ModuleBuilder {
    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-ProjectName -BuildRoot $BuildRoot
    }

    if ([System.String]::IsNullOrEmpty($SourcePath))
    {
        $SourcePath = Get-SourcePath -BuildRoot $BuildRoot
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
        $ProjectName = Get-ProjectName -BuildRoot $BuildRoot
    }

    if ([System.String]::IsNullOrEmpty($SourcePath))
    {
        $SourcePath = Get-SourcePath -BuildRoot $BuildRoot
    }

    "`tProject Name          = $ProjectName"
    "`tSource Path           = $SourcePath"
    "`tOutput Directory      = $OutputDirectory"
    "`tBuild Module Output   = $BuildModuleOutput"

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
                            -and $(
                                try
                                {
                                    Test-ModuleManifest -Path $_.FullName -ErrorAction 'Stop'
                                }
                                catch
                                {
                                    $false
                                }
                            )
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
