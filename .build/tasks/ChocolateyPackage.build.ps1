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
    $ChocolateyPackageSource = (property ChocolateyPackageSource 'Chocolatey'),

    # Base directory of all output (default to 'output')
    [Parameter()]
    [string]
    $OutputDirectory = (property OutputDirectory (Join-Path -Path $BuildRoot -ChildPath 'output')),

    [Parameter()]
    [string]
    $RequiredModulesDirectory = (property RequiredModulesDirectory $(Join-Path -Path $OutputDirectory -ChildPath 'RequiredModules')),

    [Parameter()]
    [string]
    # Sub-Folder (or absolute path) of the Chocolatey build output folder (relative to $OutputDirectory)
    $ChocolateyBuildOutput = (property ChocolateyBuildOutput 'choco'),

    [Parameter()]
    [string[]]
    # The Chocolatey Package IDs (name) to build. Can be * to build all of them.
    $ChocolateyPackageId = (property ChocolateyPackageId '*'),

    [Parameter()]
    [string]
    # Version for the package(s), leave empty if you prefer the version to be managed by GitVersion or Build.yaml.
    # There is only one version for all packages of a repository, but maybe another task can replace the version in nuspec (i.e. AutoUpdate)
    $ChocolateyPackageVersion = (property ChocolateyPackageVersion ''),

    [Parameter()]
    [string]
    $ReleaseNotesPath = (property ReleaseNotesPath (Join-Path $OutputDirectory 'ReleaseNotes.md')),

    [Parameter()]
    [string]
    $ChangelogPath = (property ChangelogPath 'CHANGELOG.md'),

    [Parameter()]
    [string]
    $ChocoPushSource = (property ChocoPushSource ''),

    [Parameter()]
    [string]
    $ChocoPushSourceApiKey = (property ChocoPushSourceApiKey ''),

    [Parameter()]
    [string]
    $SkipChocoPush = (property SkipChocoPush ''),

    [Parameter()]
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)

task copy_chocolatey_source_to_staging {
    . Set-SamplerTaskVariable -AsNewBuild
    $ChocolateyBuildOutput = Get-SamplerAbsolutePath -Path $ChocolateyBuildOutput -RelativeTo $OutputDirectory
    $ChocolateyPackageSource = Get-SamplerAbsolutePath -Path $ChocolateyPackageSource -RelativeTo $SourcePath

    "        ChocolateyPackageSource = $ChocolateyPackageSource"
    "        ChocolateyBuildOuptut = $ChocolateyBuildOutput"
    "" # Empty line

    $chocoPackages = Get-ChildItem -Directory -Path $ChocolateyPackageSource | Where-Object -FilterScript { $_.BaseName -Like $ChocolateyPackageId}

    foreach ($chocoPackage in $chocoPackages)
    {
        Write-Build DarkGray "        Copy-Item -Path '$chocoPackage' -Destination '$(Join-Path -Path $ChocolateyBuildOutput -ChildPath $chocoPackage.BaseName)' -Force -Recurse"
        Copy-Item -Path $chocoPackage -Destination (Join-Path -Path $ChocolateyBuildOutput -ChildPath $chocoPackage.BaseName) -Force -Recurse
    }
}

task copy_paths_to_choco_staging {
    . Set-SamplerTaskVariable -AsNewBuild

    $ChocolateyBuildOutput = Get-SamplerAbsolutePath -Path $ChocolateyBuildOutput -RelativeTo $OutputDirectory
    $ChocolateyPackageSource = Get-SamplerAbsolutePath -Path $ChocolateyPackageSource -RelativeTo $SourcePath

    "        ChocolateyPackageSource    = $ChocolateyPackageSource"
    "        ChocolateyBuildOuptut      = $ChocolateyBuildOutput"
    "" # Empty line

    $stagedPackages = Get-ChildItem -Path $ChocolateyBuildOutput -Directory
    $copyToPackage = $BuildInfo.Chocolatey.copyToPackage

    if (-not $copyToPackage)
    {
        Write-Build Yellow "`tNo file or folders to copy found in the Build.yml configuration (Chocolatey\copyToPackage)."
        return
    }

    foreach ($stagedPackage in $stagedPackages)
    {
        $packageName = $stagedPackage.BaseName
        $packagePath = Get-SamplerAbsolutePath -Path $packageName -RelativeTo $ChocolateyBuildOutput
        Write-Build DarkGray "`tCopying folders to '$packageName'..."
        foreach ($copyItem in $copyToPackage)
        {
            $CopyFoldersToChocoParams = @{
                Path = Get-SamplerAbsolutePath -Path $ExecutionContext.InvokeCommand.ExpandString($copyItem.source) -RelativeTo $BuildRoot
                Destination = Get-SamplerAbsolutePath -Path $ExecutionContext.InvokeCommand.ExpandString($copyItem.destination) -RelativeTo $packagePath
            }

            Write-Build DarkGray "`t... '$($CopyFoldersToChocoParams['Path'])' to '$($CopyFoldersToChocoParams['destination'])'."
            if ($copyItem.recurse -is [bool] -and -not $copyItem.recurse)
            {
                $CopyFoldersToChocoParams['recurse'] = $false
            }
            else
            {
                $CopyFoldersToChocoParams['recurse'] = $true
            }

            if ($null -eq $copyItem.packageName)
            {
                $packagesToCopyTo = [string[]]@('*')
            }
            else
            {
                $packagesToCopyTo = [string[]]$copyItem.packageName
            }

            if ($copyItem.Exclude)
            {
                $CopyFoldersToChocoParams['exclude'] = $copyItem.exclude
            }

            if ($copyItem.Force)
            {
                $CopyFoldersToChocoParams['Force'] = $copyItem.Force
            }

            if ($packageName -in $packagesToCopyTo -or '*' -in $packagesToCopyTo)
            {
                Write-Build DarkGray "$($CopyFoldersToChocoParams | Format-List | Out-String)"
                Copy-Item @CopyFoldersToChocoParams
            }
            else
            {
                Write-Build Yellow "skipping copy of '$($CopyFoldersToChocoParams['Path'])' for '$packageName'. [$($packagesToCopyTo -join ',')]."
            }
        }
    }
}

task upate_choco_nuspec_data {
    . Set-SamplerTaskVariable -AsNewBuild
    $ChocolateyBuildOutput = Get-SamplerAbsolutePath -Path $ChocolateyBuildOutput -RelativeTo $OutputDirectory
    $ChocolateyPackageSource = Get-SamplerAbsolutePath -Path $ChocolateyPackageSource -RelativeTo $SourcePath

    "        ChocolateyPackageSource = $ChocolateyPackageSource"
    "        ChocolateyBuildOuptut = $ChocolateyBuildOutput"

    $ChangeLogOutputPath = Get-SamplerAbsolutePath -Path 'CHANGELOG.md' -RelativeTo $OutputDirectory

    if (-not ($ReleaseNotes = (Get-Content -raw $ReleaseNotesPath -ErrorAction SilentlyContinue)))
    {
        $ReleaseNotes = Get-Content -raw $ChangeLogOutputPath -ErrorAction SilentlyContinue
    }

    "`tChangeLogOutputPath   = '$ChangeLogOutputPath'"
    "" # Empty line

    $stagedPackages = Get-ChildItem -Path $ChocolateyBuildOutput -Directory

    foreach ($stagedPackage in $stagedPackages)
    {
        $packageName = $stagedPackage.BaseName

        $nuspecPath = Join-Path -Path $stagedPackage.FullName -ChildPath ('{0}.nuspec' -f $packageName) -Resolve

        if ($BuildInfo.Chocolatey.UpdateNuspecData)
        {
            $xmlDoc = [xml]::new()
            $xmlDoc.Load($nuspecPath)
            $xmlNamespaces = [System.Xml.XmlNamespaceManager]::new($xmlDoc.NameTable)

            if ($BuildInfo.Chocolatey.xmlNamespaces.keys)
            {
                foreach ($nameSpaceKey in $BuildInfo.Chocolatey.xmlNamespaces.keys)
                {
                    Write-Debug -Message "adding XML Namespace '$nameSpaceKey' as '$($BuildInfo.Chocolatey.xmlNamespaces.$nameSpaceKey)'"
                    $xmlNamespaces.AddNamespace($nameSpaceKey, $BuildInfo.Chocolatey.xmlNamespaces.$nameSpaceKey)
                }
            }

            # $xmlNamespaces.AddNamespace('nuspec', "http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd")
            $nuspecPropertiesToUpdate = $BuildInfo.Chocolatey.UpdateNuspecData
            foreach ($nuspecElement in $nuspecPropertiesToUpdate.keys)
            {
                $xpath = $nuspecPropertiesToUpdate[$nuspecElement].xpath
                $value = $ExecutionContext.InvokeCommand.ExpandString($nuspecPropertiesToUpdate[$nuspecElement].value)
                $XmlNodes = $xmlDoc.SelectNodes($xpath, $xmlNamespaces)
                foreach ($node in $XmlNodes)
                {
                    if ($null -ne $node)
                    {
                        Write-Build DarkGray "        Updating '$xpath' with value '$value'."
                        if ($node.NodeType -eq "Element")
                        {
                            $node.InnerXml = $value
                        }
                        else
                        {
                            $node.Value = $value
                        }
                    }
                }
            }

            $xmlDoc.Save($nuspecPath)
        }
    }
}

task Build_Chocolatey_Package {

    $null = Get-Command -Name choco -ErrorAction Stop

    . Set-SamplerTaskVariable -AsNewBuild
    $ChocolateyBuildOutput = Get-SamplerAbsolutePath -Path $ChocolateyBuildOutput -RelativeTo $OutputDirectory
    $ChocolateyPackageSource = Get-SamplerAbsolutePath -Path $ChocolateyPackageSource -RelativeTo $SourcePath

    "        ChocolateyPackageSource = $ChocolateyPackageSource"
    "        ChocolateyBuildOuptut = $ChocolateyBuildOutput"
    "" # Empty line

    $stagedPackages = Get-ChildItem -Path $ChocolateyBuildOutput -Directory

    $stagedPackages | ForEach-Object -Process {
        $pkgNuspec = Get-Item -Path (Join-Path -Path $_.FullName -ChildPath "$($_.BaseName).nuspec") -ErrorAction Stop
        choco pack $pkgNuspec --outputdirectory $ChocolateyBuildOutput | ForEach-Object -Process {
            switch -regex ($_)
            {
                "created\spackage\s'(?<path>.*)'"
                {
                    $Matches.path
                }

                'Invalid|not\sa\svalid'
                {
                    throw $_
                }

                Default
                {
                    Write-Verbose -Message $_
                }
            }
        }
    }
}

task Push_Chocolatey_Package {

    $null = Get-Command -Name choco -ErrorAction Stop

    . Set-SamplerTaskVariable -AsNewBuild
    $ChocolateyBuildOutput = Get-SamplerAbsolutePath -Path $ChocolateyBuildOutput -RelativeTo $OutputDirectory
    $ChocolateyPackageSource = Get-SamplerAbsolutePath -Path $ChocolateyPackageSource -RelativeTo $SourcePath

    "        ChocolateyPackageSource   = '$ChocolateyPackageSource'"
    "        ChocolateyBuildOuptut     = '$ChocolateyBuildOutput'"

    if (-not [string]::IsNullOrEmpty($ChocoPushSource))
    {
        "        ChocoPushSource           = '$ChocoPushSource'"
    }
    elseif ([string]::IsNullOrEmpty($ChocoPushSource) -and $BuildInfo.Chocolatey.ChocoPushSource)
    {
        $ChocoPushSource = $BuildInfo.Chocolatey.ChocoPushSource
        "        ChocoPushSource           = '$ChocoPushSource'"
    }
    else
    {
        "        ChocoPushSource           = [using the Chocolatey Sources configured on the system]"
    }

    if ([string]::IsNullOrEmpty($ChocoPushSourceApiKey) -and $BuildInfo.Chocolatey.ChocoPushSourceApiKey)
    {
        $ChocoPushSourceApiKey = $BuildInfo.Chocolatey.ChocoPushSourceApiKey
    }

    "        ChocoPushSourceApiKey     = '$(if (-not [string]::IsNullOrEmpty($ChocoPushSourceApiKey)){"[**REDACTED**]"})'"
    $null = [bool]::TryParse($SkipChocoPush, [ref]$SkipChocoPush)

    "        SkipChocoPush             = '`$$($SkipChocoPush)'"
    "" # Empty line

    $packedPackages = Get-ChildItem -Path $ChocolateyBuildOutput -File | Where-Object -FilterScript { $_.Extension -eq '.nupkg'}

    foreach ($packedPackage in $packedPackages)
    {
        Write-Build DarkGray "        Pushing package '$($packedPackage.FullName)'."
        $chocoPushArgs = @('push', $packedPackage.FullName)

        if (-not [string]::IsNullOrEmpty($ChocoPushSource))
        {
            $chocoPushArgs += @('--source', $ChocoPushSource)
        }

        if (-not [string]::IsNullOrEmpty($ChocoPushSourceApiKey))
        {
            $chocoPushArgs += @('--api-key', $ChocoPushSourceApiKey)
        }

        if (-not [bool]::Parse($SkipChocoPush))
        {
            if ($ChocoPushSourceApiKey)
            {
                $paramsToShow = $chocoPushArgs
                $paramsToShow[-1] = "[**REDACTED**]"
            }
            else
            {
                $paramsToShow = $chocoPushArgs
            }

            Write-Build DarkGray "`tchoco $($paramsToShow -join ' ')" # Empty line
            &choco $chocoPushArgs
        }
        else
        {
            Write-Build Yellow "        Skipping pushing $($packedPackage.FullName)"
        }
    }
}
