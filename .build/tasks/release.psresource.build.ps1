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

# Synopsis: Packaging the module by Publishing to output folder (incl dependencies)
task package_psresource_nupkg {
    # Get the values for task variables, see https://github.com/gaelcolas/Sampler?tab=readme-ov-file#build-task-variables.
    . Set-SamplerTaskVariable

    # If we fail to import PSResourceGet, we won't be able to continue
    # This happens when PowerShellGet is already loaded
    Import-Module -Name 'Microsoft.PowerShell.PSResourceGet' -ErrorAction 'Stop'

    #region Set output/ as PSResourceRepository
    # Force registering the output repository mapping to the Project's output path
    try
    {
        Write-Build DarkGray "  Unregistering output repository."
        $null = Unregister-PSResourceRepository -Name output -ErrorAction Ignore
    }
    catch
    {
        Write-Build Yellow "  Output repository was not registered, skipping unregistering."
    }


    # Parse PublishModuleWhatIf to be boolean
    $null = [bool]::TryParse($PublishModuleWhatIf, [ref]$script:PublishModuleWhatIf)

    $RepositoryParams = @{
        Name            = 'output'
        uri             = $OutputDirectory
        Trusted         = $true
        ErrorAction     = 'Stop'
    }

    $null = Register-PSResourceRepository @RepositoryParams
    # Cleaning up existing packaged module
    if ($ModuleToRemove = Get-ChildItem -Path (Join-Path -Path $OutputDirectory -ChildPath "$ProjectName.*.nupkg"))
    {
        Write-Build DarkGray "  Removing existing $ProjectName package"
        Remove-Item -force -Path $ModuleToRemove -ErrorAction Stop
    }
    #endregion

    if (-not $BuiltModuleManifest)
    {
        throw "No valid manifest found for project $ProjectName."
    }

    Write-Build DarkGray "  Built module's Manifest found at $BuiltModuleManifest"

    # Uncomment release notes (the default in Plaster/New-ModuleManifest)
    $manifest = Get-SamplerModuleInfo -ModuleManifestPath $BuiltModuleManifest

    $manifestString = Get-Content -Raw $BuiltModuleManifest
    if ( $manifestString -match '#\sReleaseNotes\s?=' -and $manifest.PrivateData.psdata.keys -notcontains 'ReleaseNotes')
    {
        $manifestString = $manifestString -replace '#\sReleaseNotes\s?=', '  ReleaseNotes ='
        $Utf8NoBomEncoding = [System.Text.UTF8Encoding]::new($False)
        [System.IO.File]::WriteAllLines($BuiltModuleManifest, $manifestString, $Utf8NoBomEncoding)
        # reload module manifest
        $manifest = Get-SamplerModuleInfo -ModuleManifestPath $BuiltModuleManifest
    }

    $alreadyPublishedModules = @()
    $resourceToPublishQueue = [System.Collections.Queue]::new()
    $resourceToPublishQueue.Enqueue([Microsoft.PowerShell.Commands.ModuleSpecification]$BuiltModuleManifest)

    while ($resourceToPublishQueue.count -gt 0)
    {
        # Take first module in queue, if it has dependencies, add them first, and re-queue that module after, otherwise publish it if not already published
        $nextModuleSpecs = $resourceToPublishQueue.Dequeue()
        try
        {
            #TODO: If Module doesn't work on current env (OS, PSVersion, etc), we should not try to load it.
            $nextModule = $nextModuleSpecs | Import-Module -PassThru -ErrorAction Stop
            if ($nextModule.Count -gt 1)
            {
                # Maybe there were ScriptsToProcess, so we imported more than 1 elements
                # We need to find just the module, either by name or by its manifest path
                $nextModule = $nextModule.Where({
                    $nextModuleAbsolutePath = Get-SamplerAbsolutePath -Path $_.Path
                    $nextModuleSpecsPath = Get-SamplerAbsolutePath -Path $nextModuleSpecs.Name
                    $_.Name -eq $nextModuleSpecs.Name -or $nextModuleAbsolutePath -eq $nextModuleSpecsPath
                }, 1)

                Write-Build DarkGray ('  Found {0} elements importing {1}.' -f $nextModule.Count, $nextModuleSpecs.Name)
            }
        }
        catch
        {
            Write-Build Red "Error importing module $($nextModuleSpecs.Name) with version $($nextModuleSpecs.Version). $($_.Exception.Message)"
            throw "Cannot continue packaging the module. Error with $($nextModuleSpecs.Name) with version $($nextModuleSpecs.Version). $($_.Exception.Message)"
        }

        # Best way to deduce the module manifest I found
        $nextModuleManifestPath = '{0}{1}{2}.psd1' -f $nextModule.ModuleBase,[io.path]::DirectorySeparatorChar,$nextModule.Name
        # Using $nextModule.RequiredModule doesn't get the right value as it resolves them.
        $nextModuleManifest = Get-SamplerModuleInfo -ModuleManifestPath $nextModuleManifestPath
        $requiredModules = [Microsoft.PowerShell.Commands.ModuleSpecification[]]$nextModuleManifest.RequiredModules
        $externallyManagedModules = [Microsoft.PowerShell.Commands.ModuleSpecification[]]$nextModuleManifest.PrivateData.PSData.ExternalModuleDependencies
        # Only consider dependencies that are not already published and not externally managed
        $nextModuleSpecsDependencies = $requiredModules.Where{$_.Name -notin $externallyManagedModules.Name -and $_.Name -notin $alreadyPublishedModules.Name}
        # If there are dependencies, add them to the queue first, and then re-add the module itself at the end of the queue, otherwise publish it if not already published
        if ($nextModuleSpecsDependencies.count -gt 0)
        {
            foreach ($module in $nextModuleSpecsDependencies)
            {
                Write-Build DarkGray ('     Module {0} v{1} has dependency on module {2} {3}' -f $nextModule.Name, $nextModule.Version, $module.Name, $module.Version)
                $resourceToPublishQueue.Enqueue([Microsoft.PowerShell.Commands.ModuleSpecification[]]$module)
            }

            $resourceToPublishQueue.Enqueue($nextModuleSpecs)
        }
        else
        {
            if ($nextModuleSpecs.Name -notin $alreadyPublishedModules.Name)
            {
                # TODO: Maybe be more robust with the prerelease flag?

                if (Get-PSResourceRepository -Name output -ErrorAction Ignore)
                {
                    $isModuleInOutputRepo = $nextModule | Find-PSResource -repository 'output' -ErrorAction Ignore -Prerelease
                }
                else {
                    $isModuleInOutputRepo = $false
                }

                $nextReleaseTag = if ($nextModuleManifest.PrivateData.PSData.Prerelease)
                {
                     '-{0}' -f $nextModuleManifest.PrivateData.PSData.Prerelease
                }

                $moduleVersionWithTag = '{0}{1}' -f $nextModuleManifest.ModuleVersion, $nextReleaseTag
                if (-not $isModuleInOutputRepo)
                {
                    Write-Build Yellow ("  Packaging Required Module {0} v{1} from path '{2}'" -f $nextModuleManifest.Name, $moduleVersionWithTag, $nextModule.ModuleBase)
                    try
                    {
                        Publish-PSResource -Repository output -ErrorAction Stop -Path $nextModuleManifestPath -WhatIf:$PublishModuleWhatIf
                        Write-Build Green ("  Published Required Module {0} v{1} to output repository" -f $nextModuleManifest.Name, $moduleVersionWithTag)
                    }
                    catch
                    {
                        Write-Build Red ("  Failed to publish Required Module {0} v{1} to output repository. Error: {2}" -f $nextModuleManifest.Name, $moduleVersionWithTag, $_)
                        throw
                    }
                }
                else
                {
                    Write-Build DarkGray ("  Required Module {0} v{1} already in output repository, skipping packaging" -f $nextModuleManifest.Name, $moduleVersionWithTag)
                }

                $alreadyPublishedModules += $nextModuleSpecs
            }
        }
    }

    Write-Build Green "`n  Packaged $ProjectName NuGet package `n"
    Write-Build DarkGray "  Cleaning up"

    $null = Unregister-PSResourceRepository -Name output -ErrorAction SilentlyContinue
}

# Synopsis: Publish a built PowerShell module to a gallery.
task publish_module_to_psresource_gallery -if ($GalleryApiToken -and (Get-Command -Name 'Publish-PSResource' -ErrorAction 'SilentlyContinue')) {
    # Get the values for task variables, see https://github.com/gaelcolas/Sampler?tab=readme-ov-file#build-task-variables.
    . Set-SamplerTaskVariable

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
        Write-Build DarkGray "  Outputting configured repositories using command Get-PSResourceRepository"
        Get-PSResourceRepository

        Write-Build DarkGray "  Publishing using command Publish-PSResource"
        $PublishModuleParams['ApiKey'] = $GalleryApiToken
        Publish-PSResource @PublishModuleParams
    }

    Write-Build Green "Package Published to PS Resource Gallery."
}
