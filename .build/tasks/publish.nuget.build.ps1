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
    $PublishModuleWhatIf = (property PublishModuleWhatIf '')
)

# Synopsis: (dotnet) nuget push package to a gallery.
task publish_nupkg_to_gallery -if ($GalleryApiToken -and ((Get-Command -Name 'nuget' -ErrorAction 'SilentlyContinue') -or (Get-Command -Name 'dotnet' -ErrorAction 'SilentlyContinue'))) {
    # Get the values for task variables, see https://github.com/gaelcolas/Sampler?tab=readme-ov-file#build-task-variables.
    . Set-SamplerTaskVariable

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
            #TODO: Make the GalleryApiToken optional
            $nugetArgs = @('push', $PackageToRelease, '-Source', $nugetPublishSource, '-ApiKey', $GalleryApiToken)
        }
        else
        {
            Write-Build DarkGray 'Publishing package with .NET SDK nuget'
            $command = 'dotnet'
            #TODO: Make the GalleryApiToken optional
            $nugetArgs = @('nuget', 'push', $PackageToRelease, '--source', $nugetPublishSource, '--api-key', $GalleryApiToken)
        }

        $response = & $command $nugetArgs
    }

    Write-Build Green "Response = " + $response
}
