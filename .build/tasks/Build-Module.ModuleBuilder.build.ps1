Param (

    [Parameter()]
    [string]
    $ProjectName = (property ProjectName $(
            #Find the module manifest to deduce the Project Name
            (Get-ChildItem $BuildRoot\*\*.psd1 -Exclude 'build.psd1', 'analyzersettings.psd1' | Where-Object {
                    ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
                    $(try
                        {
                            Test-ModuleManifest $_.FullName -ErrorAction Stop
                        }
                        catch
                        {
                            Write-Warning $_
                            $false
                        }) }
            ).BaseName
        )
    ),

    [Parameter()]
    [string]
    $SourcePath = (property SourcePath ((Get-ChildItem $BuildRoot\*\*.psd1 -Exclude 'build.psd1', 'analyzersettings.psd1' | Where-Object {
                    ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
                    $(try
                        {
                            Test-ModuleManifest $_.FullName -ErrorAction Stop
                        }
                        catch
                        {
                            Write-Warning $_
                            $false
                        }) }
            ).Directory.FullName)
    ),

    [Parameter()]
    [string]
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot "output")),

    [Parameter()]
    [String]
    $BuiltModuleSubdirectory = (property BuiltModuleSubdirectory ''),

    [Parameter()]
    [String]
    $BuildModuleOutput = (property BuildModuleOutput (Join-Path $OutputDirectory $BuiltModuleSubdirectory)),

    [Parameter()]
    [String]
    $ReleaseNotesPath = (property ReleaseNotesPath (Join-Path $OutputDirectory 'ReleaseNotes.md')),

    [Parameter()]
    [string]
    $ModuleVersion = (property ModuleVersion ''),

    [Parameter()]
    [System.Collections.IDictionary]
    $BuildInfo = (property BuildInfo @{ })
)

Import-Module -Name "$PSScriptRoot/Common.Functions.psm1"

# Synopsis: Build the Module based on its Build.psd1 definition
Task Build_Module_ModuleBuilder {
    $getModuleVersionParameters = @{
        ModuleManifestPath = "$SourcePath\$ProjectName.psd1"
        ModuleVersion      = $ModuleVersion
    }

    <#
        This will get the version from $ModuleVersion if is was set as a parameter
        or as a property. If $ModuleVersion is $null or an empty string the version
        will fetched from GitVersion if it is installed. If GitVersion is _not_
        installed the version is fetched from the module manifest in SourcePath.
    #>
    $ModuleVersion = Get-ModuleVersion @getModuleVersionParameters

    " Project Name      = $ProjectName"
    " ModuleVersion     = $ModuleVersion"
    " Source Path       = $SourcePath"
    " OutputDirectory   = $OutputDirectory"
    " BuildModuleOutput = $BuildModuleOutput"

    # because of a bug in ModuleBuilder, and I want to leave using build.psd1
    # an option, we only override Source path if Build.psd1 does not target source
    if (Test-Path $SourcePath -PathType Container)
    {
        $BuildPsd1 = Join-Path $SourcePath '[Bb]uild.psd1'
        if (Test-Path $BuildPsd1)
        {
            $data = Import-Metadata $BuildPsd1
            if (!$data.containsKey('SourcePath'))
            {
                $SourcePath = Join-Path $SourcePath "$ProjectName.psd1"
                " Source Path       = $SourcePath"
            }
        }
    }

    if (!(Split-Path -isAbsolute $ReleaseNotesPath))
    {
        $ReleaseNotesPath = Join-Path $OutputDirectory $ReleaseNotesPath
    }

    Import-Module ModuleBuilder -ErrorAction Stop
    $BuildModuleParams = @{ }

    foreach ($ParamName in (Get-Command Build-Module).Parameters.Keys)
    {
        # If Build-Module parameters are available in current session, use those
        # otherwise use params from BuildInfo if specified
        if ($ValueFromBuildParam = Get-Variable -Name $ParamName -ValueOnly -ErrorAction SilentlyContinue)
        {
            Write-Build -Color DarkGray "Adding $ParamName with value $ValueFromBuildParam from current Variables"
            if ($ParamName -eq 'OutputDirectory')
            {
                $BuildModuleParams.add($ParamName, (Join-Path $BuildModuleOutput $ProjectName))
            }
            else
            {
                $BuildModuleParams.Add($ParamName, $ValueFromBuildParam)
            }
        }
        elseif ($ValueFromBuildInfo = $BuildInfo[$ParamName])
        {
            Write-Build -Color DarkGray "Adding $ParamName with value $ValueFromBuildInfo from Build Info"
            $BuildModuleParams.Add($ParamName, $ValueFromBuildInfo)
        }
        else
        {
            Write-Debug -Message "No value specified for $ParamName"
        }
    }

    Write-Build -Color Green "Building Module to $($BuildModuleParams['OutputDirectory'])..."
    $BuiltModule = Build-Module @BuildModuleParams -SemVer $ModuleVersion -Passthru

    if (Test-Path $ReleaseNotesPath)
    {
        $RelNote = Get-Content -raw $ReleaseNotesPath
        $OutputManifest = $BuiltModule.Path
        Update-Metadata -Path $OutputManifest -PropertyName PrivateData.PSData.ReleaseNotes -Value $RelNote
    }
}

Task Build_NestedModules_ModuleBuilder {
    " Project Name          = $ProjectName"
    " Source Path           = $SourcePath"
    " Output Directory      = $OutputDirectory"
    " Build Module Output   = $BuildModuleOutput"

    Import-Module ModuleBuilder -ErrorAction Stop
    $BuiltModuleManifest = "$BuildModuleOutput/$ProjectName/*/$ProjectName.psd1"

    " Built Module Manifest = $BuiltModuleManifest"

    $getModuleVersionParameters = @{
        OutputDirectory = $BuildModuleOutput
        ProjectName     = $ProjectName
        ModuleVersion   = $ModuleVersion
    }

    $ModuleVersion = Get-ModuleVersion @getModuleVersionParameters
    $ModuleVersionFolder, $PreReleaseTag = $ModuleVersion -split '\-', 2

    " Module Version        = $ModuleVersion"
    " Module Version Folder = $ModuleVersionFolder"
    " Pre-release Tag       = $PreReleaseTag"

    $NestedModule = $BuildInfo.NestedModule
    $NestedModulesToAdd = @()

    foreach ($NestedModuleName in $NestedModule.Keys)
    {
        $cmdParam = $NestedModule[$NestedModuleName]
        $AddToManifest = [bool]$cmdParam['AddToManifest']
        # either copy only or Build
        if ([bool]$cmdParam['CopyOnly'])
        {
            Write-Debug "Using parameters to copy nested module from Source to Destination"
            $cmd = Get-Command Copy-Item
            if (!$cmdParam.ContainsKey('Path'))
            {
                $cmdParam['Path'] = '$SourcePath/Modules/$NestedModuleName'
            }

            if (!$cmdParam.ContainsKey('Recurse'))
            {
                $cmdParam['Recurse'] = $true
            }
            # Set default Destination (substitute later)
            if (!$cmdParam.ContainsKey('Destination'))
            {
                $cmdParam['Destination'] = '$BuildModuleOutput/$ProjectName/$ModuleVersionFolder/Modules/$NestedModuleName'
            }
            Write-Build -color yellow "Copying Nested Module files for $NestedModuleName"
        }
        else
        {
            $cmd = Get-Command Build-Module
            Write-Build -color yellow "Building Nested Module $NestedModuleName"
        }

        $cmdParamKeys = @() + $cmdParam.Keys
        foreach ($ParamName in $cmdParamKeys)
        {
            # remove param not available in command
            if ($ParamName -notin @($cmd.Parameters.keys + $cmd.Parameters.values.aliases) )
            {
                Write-Build White "Removing Parameter $ParamName for $($cmd.Name)"
                $cmdParam.remove($ParamName)
            }
            elseif ($ParamName -in @('Path', 'Destination', 'OutputDirectory', 'SemVer'))
            {
                # Substitute & Resolve Resolve Path to absolutes (relative assumed is $BuildRoot)
                Write-Build White "Resolving Absolute path for $ParamName $($cmdParam[$ParamName])"
                $cmdParam[$ParamName] = $ExecutionContext.InvokeCommand.ExpandString($cmdParam[$ParamName])
                if (!(Split-Path -IsAbsolute $cmdParam[$ParamName]) -and $ParamName -ne 'SemVer')
                {
                    $cmdParam[$ParamName] = Join-Path -Path $BuildRoot -ChildPath $cmdParam[$ParamName]
                }
                Write-Build -color White "    The $ParamName is: $($cmdParam[$ParamName])"
            }
        }
        $BuiltModuleBase = Split-Path -Parent -Path $BuiltModuleManifest
        Write-Build -color Green "$($cmd.Verb) $NestedModuleName..."
        if ($cmdParam.Verbose)
        {
            Write-Verbose ($CmdParam | ConvertTo-Json) -Verbose
        }
        &$cmd @cmdParam

        if ($AddToManifest)
        {
            Write-Build DarkMagenta "  Preparing to Add to Manifest"
            if ($cmd.Name -eq 'Copy-Item')
            {
                $NestedModulePath = $cmdParam['Destination']
            }
            else
            {
                $NestedModulePath = $cmdParam['OutputDirectory']
            }
            Write-Build DarkMagenta "  Looking in $NestedModulePath"
            $NestedModuleFile = (Get-ChildItem -Path $NestedModulePath -Recurse -Include *.psd1 |
                    Where-Object {
                        ($_.Directory.Name -eq $_.BaseName -or $_.Directory.Name -as [version]) -and
                        $(try
                            {
                                Test-ModuleManifest $_.FullName -ErrorAction Stop
                            }
                            catch
                            {
                                $false
                            })
                    }
            ).FullName -replace [Regex]::Escape($BuiltModuleBase), ".$([io.path]::DirectorySeparatorChar)"


            if (!$NestedModuleFile)
            {
                $NestedModuleFile = Get-ChildItem -Path $NestedModulePath -Recurse -Include *.psm1 |
                    ForEach-Object {
                        $_.FullName -replace [Regex]::Escape($BuiltModuleBase), ".$([io.path]::DirectorySeparatorChar)"
                    }
            }
            Write-Build DarkMagenta "Found $($NestedModuleFile -join ';')"

            $NestedModulesToAdd += $NestedModuleFile
        }

        Write-Build -color Green "Done `r`n"
    }

    $ModuleInfo = Import-PowerShellDataFile $BuiltModuleManifest -ErrorAction Stop

    # Add to NestedModules to ModuleManifest
    if ($ModuleInfo.containsKey('NestedModules') -and $NestedModulesToAdd)
    {
        Write-Build -color Green "Updating the Module Manifest's NestedModules key..."
        $NestedModulesToAdd = $ModuleInfo.NestedModules + $NestedModulesToAdd
        # Get Nested Module Manifest or PSM1
        $updateMetadataParams = @{
            Path         = (Get-Item $BuiltModuleManifest).FullName
            PropertyName = 'NestedModules'
            Value        = $NestedModulesToAdd
            ErrorAction  = 'Stop'
        }
        Write-Build Green "  Adding $($NestedModuleToAdd -join ', ') to Module Manifest $($updateMetadataParams.Path)"
        Update-Metadata @updateMetadataParams
    }
}
