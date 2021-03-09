param (
    # Base directory of all output (default to 'output')
    [Parameter()]
    [string]
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

    [Parameter()]
    $ChangelogPath = (property ChangelogPath 'CHANGELOG.md'),

    [Parameter()]
    $ReleaseNotesPath = (property ReleaseNotesPath (Join-Path $OutputDirectory 'ReleaseNotes.md')),

    [Parameter()]
    [string]
    $ProjectName = (property ProjectName ''),

    [Parameter()]
    [string]
    $GalleryApiToken = (property GalleryApiToken ''),

    [Parameter()]
    [string]
    $NuGetPublishSource = (property NuGetPublishSource 'https://www.powershellgallery.com/'),

    [Parameter()]
    $PSModuleFeed = (property PSModuleFeed 'PSGallery'),

    [Parameter()]
    $SkipPublish = (property SkipPublish '')
)

# Synopsis: Create ReleaseNotes from changelog and update the Changelog for release
task Create_changelog_release_output {
    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-SamplerProjectName -BuildRoot $BuildRoot
    }

    "  OutputDirectory  = $OutputDirectory"
    "  ReleaseNotesPath = $ReleaseNotesPath"

    if (!(Split-Path -isAbsolute $OutputDirectory))
    {
        $OutputDirectory = Join-Path $BuildRoot $OutputDirectory
    }

    if (!(Split-Path -isAbsolute $ReleaseNotesPath))
    {
        $ReleaseNotesPath = Join-Path $OutputDirectory $ReleaseNotesPath
    }

    $ChangeLogOutputPath = Join-Path $OutputDirectory 'CHANGELOG.md'
    "  ChangeLogOutputPath = $ChangeLogOutputPath"

    $getModuleVersionParameters = @{
        OutputDirectory = $OutputDirectory
        ProjectName     = $ProjectName
    }

    $ModuleVersion = Get-BuiltModuleVersion @getModuleVersionParameters

    # Parse the Changelog and extract unreleased
    try
    {
        Import-Module ChangelogManagement -ErrorAction Stop

        # Update the source changelog file
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

    if ((Test-Path "$OutputDirectory/$ProjectName/*/$ProjectName.psd1" -ErrorAction SilentlyContinue) -and $ReleaseNotes)
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

        # find Module manifest
        $BuiltModuleManifest = (Get-ChildItem (Join-Path $OutputDirectory $ProjectName) -Depth 2 -Filter "$ProjectName.psd1").FullName |
            Where-Object {
                $(Test-ModuleManifest -Path $_ -ErrorAction 'SilentlyContinue').Version
            }
        if (-not $BuiltModuleManifest)
        {
            throw "No valid manifest found for project $ProjectName."
        }
        Write-Build DarkGray "Built Manifest $BuiltModuleManifest"
        # No need to test the manifest again here, because the pipeline tested all manifests via the where-clause already

        # Uncomment release notes (the default in Plaster/New-ModuleManifest)
        $ManifestString = Get-Content -raw $BuiltModuleManifest
        if ( $ManifestString -match '#\sReleaseNotes\s?=')
        {
            $ManifestString = $ManifestString -replace '#\sReleaseNotes\s?=', '  ReleaseNotes ='
            $Utf8NoBomEncoding = [System.Text.UTF8Encoding]::new($False)
            [System.IO.File]::WriteAllLines($BuiltModuleManifest, $ManifestString, $Utf8NoBomEncoding)
        }

        $UpdateReleaseNotesParams = @{
            Path         = "$OutputDirectory/$ProjectName/*/$ProjectName.psd1"
            PropertyName = 'PrivateData.PSData.ReleaseNotes'
            Value        = $moduleManifestReleaseNotes
            ErrorAction  = 'SilentlyContinue'
        }

        Update-Manifest @UpdateReleaseNotesParams
    }
}

task publish_nupkg_to_gallery -if ($GalleryApiToken -and (Get-Command -Name 'nuget' -ErrorAction 'SilentlyContinue')) {
    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-SamplerProjectName -BuildRoot $BuildRoot
    }

    if (!(Split-Path $OutputDirectory -IsAbsolute))
    {
        $OutputDirectory = Join-Path -Path $BuildRoot -ChildPath $OutputDirectory
    }

    $getModuleVersionParameters = @{
        OutputDirectory = $OutputDirectory
        ProjectName     = $ProjectName
    }

    $ModuleVersion = Get-BuiltModuleVersion @getModuleVersionParameters

    $ChangeLogOutputPath = Join-Path $OutputDirectory 'CHANGELOG.md'
    "  ChangeLogOutputPath = $ChangeLogOutputPath"

    # find Module's nupkg
    $PackageToRelease = Get-ChildItem (Join-Path $OutputDirectory "$ProjectName.$ModuleVersion.nupkg")

    Write-Build DarkGray "About to release $PackageToRelease"
    if (!$SkipPublish)
    {
        $response = &nuget push $PackageToRelease -source $nugetPublishSource -ApiKey $GalleryApiToken
    }

    Write-Build Green "Response = " + $response
}

# Synopsis: Packaging the module by Publishing to output folder (incl dependencies)
task package_module_nupkg {

    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-SamplerProjectName -BuildRoot $BuildRoot
    }

    if (!(Split-Path -isAbsolute $ReleaseNotesPath))
    {
        $ReleaseNotesPath = Join-Path -Path $OutputDirectory -ChildPath $ReleaseNotesPath
    }

    #region Set output/ as PSRepository
    # Force registering the output repository mapping to the Project's output path
    $null = Unregister-PSRepository -Name output -ErrorAction SilentlyContinue
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

    $ChangeLogOutputPath = Join-Path -Path $OutputDirectory -ChildPath 'CHANGELOG.md'
    "  ChangeLogOutputPath = $ChangeLogOutputPath"

    # Do not try to generate ReleaseNotesForLatestRelease when updating Changelog after Major Release.
    if (Test-Path $ChangeLogOutputPath )
    {
        $changeLogData = Get-ChangelogData -Path $ChangeLogOutputPath
        # Filter out the latest module version change log entries
        $releaseNotesForLatestRelease = $changeLogData.Released | Where-Object -FilterScript {
            $_.Version -eq $ModuleVersion
        }
    }

    # find Module manifest
    $BuiltModuleManifest = (Get-ChildItem (Join-Path $OutputDirectory $ProjectName) -Depth 2 -Filter "$ProjectName.psd1").FullName |
        Where-Object {
            $(Test-ModuleManifest -Path $_ -ErrorAction 'SilentlyContinue' ).Version
        }

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
    $ModuleInfo = Import-PowerShellDataFile -Path $BuiltModuleManifest

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
            Write-Build Yellow ("  Packaging Required Module {0} v{1}{2}" -f $Module.Name, $Module.Version.ToString(), $Prerelease)
            Publish-Module -Repository output -ErrorAction SilentlyContinue -Path $module.ModuleBase
        }
    }

    $ModulePath = Join-Path -Path $OutputDirectory -ChildPath $ProjectName
    $PublishModuleParams = @{
        Path            = $ModulePath
        Repository      = 'output'
        ErrorAction     = 'Stop'
        ReleaseNotes    = $releaseNotesForLatestRelease
        Force           = $true
    }

    Publish-Module @PublishModuleParams
    Write-Build Green "`n  Packaged $ProjectName NuGet package `n"
    Write-Build DarkGray "  Cleaning up"

    $null = Unregister-PSRepository -Name output -ErrorAction SilentlyContinue
}

task publish_module_to_gallery -if ($GalleryApiToken -and (Get-Command -Name 'Publish-Module' -ErrorAction 'SilentlyContinue')) {
    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-SamplerProjectName -BuildRoot $BuildRoot
    }

    if (!(Split-Path $OutputDirectory -IsAbsolute))
    {
        $OutputDirectory = Join-Path $BuildRoot $OutputDirectory
    }

    $getModuleVersionParameters = @{
        OutputDirectory = $OutputDirectory
        ProjectName     = $ProjectName
    }

    $ModuleVersion = Get-BuiltModuleVersion @getModuleVersionParameters

    $ChangeLogOutputPath = Join-Path $OutputDirectory 'CHANGELOG.md'
    "  ChangeLogOutputPath = $ChangeLogOutputPath"

    $changeLogData = Get-ChangelogData -Path $ChangeLogOutputPath

    # Filter out the latest module version change log entries
    $releaseNotesForLatestRelease = $changeLogData.Released | Where-Object -FilterScript {
        $_.Version -eq $ModuleVersion
    }

    # find Module manifest
    $BuiltModuleManifest = (Get-ChildItem (Join-Path $OutputDirectory $ProjectName) -Depth 2 -Filter "$ProjectName.psd1").FullName |
        Where-Object {
            $(Test-ModuleManifest -Path $_ -ErrorAction 'SilentlyContinue' ).Version
        }

    # No need to test the manifest again here, because the pipeline tested all manifests via the where-clause already
    if (-not $BuiltModuleManifest)
    {
        throw "No valid manifest found for project $ProjectName."
    }

    # Uncomment release notes (the default in Plaster/New-ModuleManifest)
    $ManifestString = Get-Content -raw $BuiltModuleManifest
    if ( $ManifestString -match '#\sReleaseNotes\s?=')
    {
        $ManifestString = $ManifestString -replace '#\sReleaseNotes\s?=', '  ReleaseNotes ='
        $Utf8NoBomEncoding = [System.Text.UTF8Encoding]::new($False)
        [System.IO.File]::WriteAllLines($BuiltModuleManifest, $ManifestString, $Utf8NoBomEncoding)
    }


    $ModulePath = Join-Path -Path $OutputDirectory -ChildPath $ProjectName

    Write-Build DarkGray "`nAbout to release $ModulePath"

    $PublishModuleParams = @{
        Path            = $ModulePath
        NuGetApiKey     = $GalleryApiToken
        Repository      = $PSModuleFeed
        ErrorAction     = 'Stop'
        ReleaseNotes    = $releaseNotesForLatestRelease
    }

    if (!$SkipPublish)
    {
        Publish-Module @PublishModuleParams
    }

    Write-Build Green "Package Published to PSGallery"

}
