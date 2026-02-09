<#
    .SYNOPSIS
        Tasks for releasing modules.

    .PARAMETER OutputDirectory
        The base directory of all output. Defaults to folder 'output' relative to
        the $BuildRoot.

    .PARAMETER BuiltModuleSubdirectory
        The parent path of the module to be built.

    .PARAMETER VersionedOutputDirectory
        If the module should be built using a version folder, e.g. ./MyModule/1.0.0.
        Defaults to $true.

    .PARAMETER ChangelogPath
        The path to and the name of the changelog file. Defaults to 'CHANGELOG.md'.

    .PARAMETER ReleaseNotesPath
        The path to and the name of the release notes file. Defaults to 'ReleaseNotes.md'.

    .PARAMETER ProjectName
        The project name.

    .PARAMETER ModuleVersion
        The module version that was built.

    .PARAMETER GalleryApiToken
        The API token that gives permission to publish to the gallery.

    .PARAMETER NuGetPublishSource
        The source to publish nuget packages. Defaults to https://www.powershellgallery.com.

    .PARAMETER PSModuleFeed
        The name of the feed (repository) that is passed to command Publish-Module.
        Defaults to 'PSGallery'.

    .PARAMETER SkipPublish
        If publishing should be skipped. Defaults to $false.

    .PARAMETER PublishModuleWhatIf
        If the publish command will be run with '-WhatIf' to show what will happen
        during publishing. Defaults to $false.

    .PARAMETER ChocolateyBuildOutput
        Sub-Folder (or absolute path) of the Chocolatey build output folder (relative
        to $OutputDirectory). Contain the path to one or more Chocolatey packages.
        This variable $ChocolateyBuildOutput also used to determine if the repository
        is building a Chocolatey package. Defaults to 'choco'.
#>

param
(
    [Parameter()]
    [string]
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

    [Parameter()]
    [System.String]
    $BuiltModuleSubdirectory = (property BuiltModuleSubdirectory ''),

    [Parameter()]
    [System.Management.Automation.SwitchParameter]
    $VersionedOutputDirectory = (property VersionedOutputDirectory $true),

    [Parameter()]
    $ChangelogPath = (property ChangelogPath 'CHANGELOG.md'),

    [Parameter()]
    $ReleaseNotesPath = (property ReleaseNotesPath (Join-Path $OutputDirectory 'ReleaseNotes.md')),

    [Parameter()]
    [string]
    $ProjectName = (property ProjectName ''),

    [Parameter()]
    [System.String]
    $ModuleVersion = (property ModuleVersion ''),

    [Parameter()]
    [string]
    $GalleryApiToken = (property GalleryApiToken ''),

    [Parameter()]
    [string]
    $NuGetPublishSource = (property NuGetPublishSource 'https://www.powershellgallery.com/'),

    [Parameter()]
    $PSModuleFeed = (property PSModuleFeed 'PSGallery'),

    [Parameter()]
    $SkipPublish = (property SkipPublish ''),

    [Parameter()]
    $PublishModuleWhatIf = (property PublishModuleWhatIf ''),

    [Parameter()]
    [string]
    $ChocolateyBuildOutput = (property ChocolateyBuildOutput 'choco')
)

# Synopsis: Create ReleaseNotes from changelog and update the Changelog for release
task Create_changelog_release_output {
    # Get the values for task variables, see https://github.com/gaelcolas/Sampler?tab=readme-ov-file#build-task-variables.
    . Set-SamplerTaskVariable

    $ChangeLogOutputPath = Get-SamplerAbsolutePath -Path 'CHANGELOG.md' -RelativeTo $OutputDirectory

    "`tChangeLogOutputPath   = '$ChangeLogOutputPath'"

    # Parse the Changelog and extract unreleased
    try
    {
        Import-Module ChangelogManagement -ErrorAction Stop

        # Update the source changelog file
        Write-Build DarkGray "`tCreating '$ChangeLogOutputPath'..."
        Update-Changelog -Path $ChangeLogPath -OutputPath $ChangeLogOutputPath -ErrorAction Stop -ReleaseVersion $ModuleVersion -LinkMode none

        # Get the updated CHANGELOG.md
        $changeLogData = Get-ChangelogData -Path $ChangeLogOutputPath

        # Filter out the latest module version change log entries
        $changeLogDataForLatestRelease = $changeLogData.Released | Where-Object -FilterScript {
            $_.Version -eq $ModuleVersion
        }

        <#
            Get the raw markdown release notes for the module manifest. The
            module manifest release notes has a hard size limit when publishing
            to PowerShell Gallery.
        #>
        if ($changeLogDataForLatestRelease.RawData.Length -gt 10000)
        {
            $moduleManifestReleaseNotes = $changeLogDataForLatestRelease.RawData.Substring(0, 10000)
        }
        else
        {
            $moduleManifestReleaseNotes = $changeLogDataForLatestRelease.RawData
        }

        # Create a ReleaseNotes from the Updated changelog
        ConvertFrom-Changelog -Path $ChangeLogOutputPath -Format Release -NoHeader -OutputPath $ReleaseNotesPath -ErrorAction Stop
    }
    catch
    {
        Write-Build Red "Error creating the Changelog Output and/or ReleaseNotes. $($_.Exception.Message)"
    }

    if (-not ($ReleaseNotes = (Get-Content -raw $ReleaseNotesPath -ErrorAction SilentlyContinue)))
    {
        $ReleaseNotes = Get-Content -raw $ChangeLogOutputPath -ErrorAction SilentlyContinue
    }

    if ($ReleaseNotes -and -not [string]::IsNullOrEmpty($builtModuleManifest) -and (Test-Path -Path $builtModuleManifest -ErrorAction SilentlyContinue))
    {
        try
        {
            Import-Module Configuration -ErrorAction Stop
        }
        catch
        {
            Write-Build Red "Issue importing Configuration module. $($_.Exception.Message)"
            return
        }

        Write-Build DarkGray "Built Manifest $builtModuleManifest"
        # No need to test the manifest again here, because the pipeline tested all manifests via the where-clause already

        # Uncomment release notes (the default in Plaster/New-ModuleManifest)
        $ManifestString = Get-Content -raw $builtModuleManifest
        if ( $ManifestString -match '#\sReleaseNotes\s?=')
        {
            $ManifestString = $ManifestString -replace '#\sReleaseNotes\s?=', '  ReleaseNotes ='
            $Utf8NoBomEncoding = [System.Text.UTF8Encoding]::new($False)
            [System.IO.File]::WriteAllLines($BuiltModuleManifest, $ManifestString, $Utf8NoBomEncoding)
        }

        $UpdateReleaseNotesParams = @{
            Path         = $builtModuleManifest
            PropertyName = 'PrivateData.PSData.ReleaseNotes'
            Value        = $moduleManifestReleaseNotes
            ErrorAction  = 'SilentlyContinue'
        }

        Update-Manifest @UpdateReleaseNotesParams
    }
    else
    {
        if ([string]::IsNullOrEmpty($ReleaseNotes))
        {
            Write-Build -Color Red "No Release notes found to insert."
        }

        if ([string]::IsNullOrEmpty($builtModuleManifest) -or -not (Test-Path -Path $builtModuleManifest))
        {
            if ([string]::IsNullOrEmpty($ProjectName))
            {
                Write-Build -Color DarkGray "No PowerShell module name found. We assume you are not building a PowerShell Module."
            }
            else
            {
                Write-Build -Color Red "No valid manifest found for project '$ProjectName'. Cannot update the Release Notes."
            }
        }
    }
}

# Synopsis: Publish Nuget package to a gallery.
task publish_nupkg_to_gallery -if ($GalleryApiToken -and ((Get-Command -Name 'nuget' -ErrorAction 'SilentlyContinue') -or (Get-Command -Name 'dotnet' -ErrorAction 'SilentlyContinue'))) {
    # Get the values for task variables, see https://github.com/gaelcolas/Sampler?tab=readme-ov-file#build-task-variables.
    . Set-SamplerTaskVariable

    Import-Module -Name 'ModuleBuilder' -ErrorAction 'Stop'

    $ChangeLogOutputPath = Join-Path -Path $OutputDirectory -ChildPath 'CHANGELOG.md'

    "`tChangeLogOutputPath = $ChangeLogOutputPath"

    # find Module's nupkg
    $PackageToRelease = Get-ChildItem -Path (Join-Path -Path $OutputDirectory -ChildPath "$ProjectName.$ModuleVersion.nupkg")

    Write-Build DarkGray "About to release $PackageToRelease"
    if (-not $SkipPublish)
    {
        # Determine whether to use nuget or .NET SDK nuget
        if (Get-Command -Name 'nuget' -ErrorAction 'SilentlyContinue')
        {
            Write-Build DarkGray 'Publishing package with nuget'
            $command = 'nuget'
            $nugetArgs = @('push', $PackageToRelease, '-Source', $nugetPublishSource, '-ApiKey', $GalleryApiToken)
        }
        else
        {
            Write-Build DarkGray 'Publishing package with .NET SDK nuget'
            $command = 'dotnet'
            $nugetArgs = @('nuget', 'push', $PackageToRelease, '--source', $nugetPublishSource, '--api-key', $GalleryApiToken)
        }
        $response = & $command $nugetArgs
    }

    Write-Build Green "Response = " + $response
}

# Synopsis: Packaging the module by Publishing to output folder (incl dependencies)
task package_module_nupkg {
    # Get the values for task variables, see https://github.com/gaelcolas/Sampler?tab=readme-ov-file#build-task-variables.
    . Set-SamplerTaskVariable

    #region Set output/ as PSRepository
    # Force registering the output repository mapping to the Project's output path
    $null = Unregister-PSRepository -Name output -ErrorAction SilentlyContinue

    # Parse PublishModuleWhatIf to be boolean
    $null = [bool]::TryParse($PublishModuleWhatIf, [ref]$script:PublishModuleWhatIf)

    $RepositoryParams = @{
        Name            = 'output'
        SourceLocation  = $OutputDirectory
        PublishLocation = $OutputDirectory
        ErrorAction     = 'Stop'
    }

    $null = Register-PSRepository @RepositoryParams

    # Cleaning up existing packaged module
    if ($ModuleToRemove = Get-ChildItem (Join-Path $OutputDirectory "$ProjectName.*.nupkg"))
    {
        Write-Build DarkGray "  Remove existing $ProjectName package"
        Remove-Item -force -Path $ModuleToRemove -ErrorAction Stop
    }
    #endregion

    if (-not $BuiltModuleManifest)
    {
        throw "No valid manifest found for project $ProjectName."
    }

    Write-Build DarkGray "  Built module's Manifest found at $BuiltModuleManifest"

    # Uncomment release notes (the default in Plaster/New-ModuleManifest)
    $ManifestString = Get-Content -raw $BuiltModuleManifest
    if ( $ManifestString -match '#\sReleaseNotes\s?=')
    {
        $ManifestString = $ManifestString -replace '#\sReleaseNotes\s?=', '  ReleaseNotes ='
        $Utf8NoBomEncoding = [System.Text.UTF8Encoding]::new($False)
        [System.IO.File]::WriteAllLines($BuiltModuleManifest, $ManifestString, $Utf8NoBomEncoding)
    }

    # load module manifest
    $ModuleInfo = Get-SamplerModuleInfo -ModuleManifestPath $builtModuleManifest

    # Publish dependencies (from environment) so we can publish the built module
    foreach ($module in $ModuleInfo.RequiredModules)
    {
        if (!([Microsoft.PowerShell.Commands.ModuleSpecification]$module | Find-Module -repository output -ErrorAction SilentlyContinue))
        {
            # Replace the module by first (path & version) resolved in PSModulePath
            $module = Get-Module -ListAvailable -FullyQualifiedName $module | Select-Object -First 1

            if ($Prerelease = $module.PrivateData.PSData.Prerelease)
            {
                $Prerelease = "-" + $Prerelease
            }

            Write-Build Yellow ("  Packaging Required Module {0} v{1}{2} from path '{3}'" -f $Module.Name, $Module.Version.ToString(), $Prerelease, $module.ModuleBase)

            if ($PublishModuleWhatIf)
            {
                $PublishModuleParams['WhatIf'] = $True
            }

            # Release notes will be used from module manifest
            Publish-Module -Repository output -ErrorAction SilentlyContinue -Path $module.ModuleBase
        }
    }

    $PublishModuleParams = @{
        Path            = $BuiltModuleBase
        Repository      = 'output'
        ErrorAction     = 'Stop'
        Force           = $true
    }

    if ($PublishModuleWhatIf)
    {
        $PublishModuleParams['WhatIf'] = $True
    }

    Publish-Module @PublishModuleParams

    Write-Build Green "`n  Packaged $ProjectName NuGet package `n"
    Write-Build DarkGray "  Cleaning up"

    $null = Unregister-PSRepository -Name output -ErrorAction SilentlyContinue
}

# Synopsis: Publish a built PowerShell module to a gallery.
task publish_module_to_gallery -if ($GalleryApiToken -and (Get-Command -Name @('Publish-Module', 'Publish-PSResource') -ErrorAction 'SilentlyContinue')) {
    # Get the values for task variables, see https://github.com/gaelcolas/Sampler?tab=readme-ov-file#build-task-variables.
    . Set-SamplerTaskVariable

    Import-Module -Name 'ModuleBuilder' -ErrorAction 'Stop'

    # Parse PublishModuleWhatIf to be boolean
    $null = [bool]::TryParse($PublishModuleWhatIf, [ref]$script:PublishModuleWhatIf)

    if (-not $BuiltModuleManifest)
    {
        throw "No valid manifest found for project $ProjectName."
    }

    # Uncomment release notes (the default in Plaster/New-ModuleManifest)
    $ManifestString = Get-Content -Raw $BuiltModuleManifest
    if ( $ManifestString -match '#\sReleaseNotes\s?=')
    {
        $ManifestString = $ManifestString -replace '#\sReleaseNotes\s?=', '  ReleaseNotes ='
        $Utf8NoBomEncoding = [System.Text.UTF8Encoding]::new($False)
        [System.IO.File]::WriteAllLines($BuiltModuleManifest, $ManifestString, $Utf8NoBomEncoding)
    }

    Write-Build DarkGray "`nAbout to release '$BuiltModuleBase'."

    $PublishModuleParams = @{
        Path            = $BuiltModuleBase
        Repository      = $PSModuleFeed
        ErrorAction     = 'Stop'
    }

    if ($PublishModuleWhatIf)
    {
        $PublishModuleParams['WhatIf'] = $true
    }

    if (-not $SkipPublish)
    {
        # When publishing, release notes will be used from module manifest.

        if ((Get-Module -Name 'Microsoft.PowerShell.PSResourceGet' -ListAvailable))
        {
            Write-Build DarkGray "  Outputting configured repositories using command Get-PSResourceRepository"

            Get-PSResourceRepository

            Write-Build DarkGray "  Publishing using command Publish-PSResource"

            $PublishModuleParams['ApiKey'] = $GalleryApiToken

            Publish-PSResource @PublishModuleParams
        }
        else
        {
            Write-Build DarkGray "  Publishing using command Publish-Module"

            $PublishModuleParams['NuGetApiKey'] = $GalleryApiToken

            Publish-Module @PublishModuleParams
        }
    }

    Write-Build Green "Package Published to PSGallery."
}
