<#
    .SYNOPSIS
        This build task creates and pushes a preview release tag to the default
        branch.

    .DESCRIPTION
        This build task creates and pushes a preview release tag to the default
        branch.

        This task is primarily meant to be used for SCM's that does not have
        releases that connects to tags like GitHub does with GitHub Releases, but
        this task can also be used as an alternative when using GitHub as SCM.

    .PARAMETER ProjectPath
        The root path to the project. Defaults to $BuildRoot.

    .PARAMETER OutputDirectory
        The base directory of all output. Defaults to folder 'output' relative to
        the $BuildRoot.

    .PARAMETER BuiltModuleSubdirectory
        The parent path of the module to be built.

    .PARAMETER VersionedOutputDirectory
        If the module should be built using a version folder, e.g. ./MyModule/1.0.0.
        Defaults to $true.

    .PARAMETER ProjectName
        The project name.

    .PARAMETER SourcePath
        The path to the source folder.

    .PARAMETER SkipPublish
        If publishing should be skipped. Defaults to $false.

    .PARAMETER MainGitBranch
        The name of the default branch. Defaults to 'main'.

    .PARAMETER BasicAuthPAT
        The personal access token used for accessing hte Git repository.

    .PARAMETER BuildInfo
        The build info object from ModuleBuilder. Defaults to an empty hashtable.

    .PARAMETER BuildCommit
        The commit SHA that was built and tested. If not provided, defaults to:
          - GitHub Actions: $env:GITHUB_SHA
          - Azure Pipelines: $env:BUILD_SOURCEVERSION
          - Otherwise: git rev-parse HEAD

    .PARAMETER DryRun
        If set to $true, the task will not push the tag to the remote repository
        and will not perform verification. Instead, it will output what would
        have been done. Defaults to $false.

    .NOTES
        This is a build task that is primarily meant to be run by Invoke-Build but
        wrapped by the Sampler project's build.ps1 (https://github.com/gaelcolas/Sampler).
#>
param
(
    [Parameter()]
    [System.String]
    $ProjectPath = (property ProjectPath $BuildRoot),

    [Parameter()]
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
    $SourcePath = (property SourcePath ''),

    [Parameter()]
    $SkipPublish = (property SkipPublish ''),

    [Parameter()]
    $MainGitBranch = (property MainGitBranch 'main'),

    [Parameter()]
    $BasicAuthPAT = (property BasicAuthPAT ''),

    [Parameter()]
    [System.String]
    $GitConfigUserEmail = (property GitConfigUserEmail ''),

    [Parameter()]
    [System.String]
    $GitConfigUserName = (property GitConfigUserName ''),

    [Parameter()]
    $BuildInfo = (property BuildInfo @{ }),

    [Parameter()]
    [System.String]
    $BuildCommit = (property BuildCommit $(
        # Prefer CI-provided SHAs; fall back to local HEAD
        if ($env:GITHUB_SHA) { return $env:GITHUB_SHA }
        if ($env:BUILD_SOURCEVERSION) { return $env:BUILD_SOURCEVERSION }
        try { Sampler\Invoke-SamplerGit -Argument @('rev-parse', 'HEAD') } catch { '' }
    )),

    [Parameter()]
    $DryRun = (property DryRun $false)
)

# Synopsis: Creates a git tag for the release that is published to a Gallery
task Create_Release_Git_Tag {
    if ($SkipPublish)
    {
        Write-Build Yellow ("Skipping the creating of a tag for module version '{0}' since '$SkipPublish' was set to '$true'." -f $ModuleVersion)

        return
    }

    . Set-SamplerTaskVariable

    $commitTag = $null

    <#
        This will return the tag on the commit being built. No tag on commit,
        command will return $null and a preview tag must be created.

        This call should not use Invoke-SamplerGit since it should not throw
        on error, but return $null if failing.
    #>
    $commitTag = git describe --contains --abbrev=0 --tags $BuildCommit 2> $null

    if ($commitTag)
    {
        Write-Build Green ('Found a tag ''{0}''. Assuming a full release has been pushed for module version v{1}. Exiting.' -f $commitTag, $ModuleVersion)

        return
    }

    Write-Verbose -Message 'There is no tag defined yet.'

    $releaseTag = 'v{0}' -f $ModuleVersion

    # Debug: log how BuildCommit was resolved
    $sourceHint = 'parameter'

    if (-not $PSBoundParameters.ContainsKey('BuildCommit') -or [string]::IsNullOrWhiteSpace($BuildCommit))
    {
        if ($env:GITHUB_SHA -and $BuildCommit -eq $env:GITHUB_SHA)
        {
            $sourceHint = 'GITHUB_SHA'
        }
        elseif ($env:BUILD_SOURCEVERSION -and $BuildCommit -eq $env:BUILD_SOURCEVERSION)
        {
            $sourceHint = 'BUILD_SOURCEVERSION'
        }
        else
        {
            $sourceHint = 'git rev-parse HEAD'
        }
    }

    Write-Build DarkGray ("`tModuleVersion: {0}" -f $ModuleVersion)
    Write-Build DarkGray ("`tRelease tag:  {0}" -f $releaseTag)
    Write-Build Cyan     ("`tBuildCommit:  {0} (source: {1})" -f $BuildCommit, $sourceHint)

    if (-not $BuildCommit -or $BuildCommit.Trim().Length -eq 0)
    {
        throw "Unable to determine the commit to tag. Provide -BuildCommit, or ensure CI exposes GITHUB_SHA/BUILD_SOURCEVERSION, or that git rev-parse HEAD works."
    }

    foreach ($gitConfigKey in @('UserName', 'UserEmail'))
    {
        $gitConfigVariableName = 'GitConfig{0}' -f $gitConfigKey

        if (-not (Get-Variable -Name $gitConfigVariableName -ValueOnly -ErrorAction 'SilentlyContinue'))
        {
            # Variable is not set in context, use $BuildInfo.GitConfig.<varName>
            $configurationValue = $BuildInfo.GitConfig.($gitConfigKey)

            Set-Variable -Name $gitConfigVariableName -Value $configurationValue

            Write-Build DarkGray "`t...Set property $gitConfigVariableName to the value $configurationValue"
        }
    }

    Write-Build DarkGray "`tSetting git configuration."

    if ($GitConfigUserName)
    {
        Sampler\Invoke-SamplerGit -Argument @('config', 'user.name', $GitConfigUserName)
    }
    if ($GitConfigUserEmail)
    {
        Sampler\Invoke-SamplerGit -Argument @('config', 'user.email', $GitConfigUserEmail)
    }

    # Ensure we have latest tags/refs locally to avoid stale state
    try
    {
        Write-Build DarkGray "`tFetching tags and pruning..."
        Sampler\Invoke-SamplerGit -Argument @('fetch', '--tags', '--prune', 'origin')
    }
    catch
    {
        Write-Build Yellow "`tFetch failed or not required; continuing."
    }

    # If the tag already exists on remote, skip (prevents overlap collisions)
    $lsRemoteArgs = @('ls-remote', '--tags', 'origin', $releaseTag)
    if ($BasicAuthPAT)
    {
        $patBase64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(('PAT:{0}' -f $BasicAuthPAT)))

        $lsRemoteArgs = @('-c', ('http.extraheader="AUTHORIZATION: basic {0}"' -f $patBase64)) + $lsRemoteArgs

        Write-Build DarkGray "`tUsing PAT auth for remote queries."
    }

    $existingRemoteTag = $null

    try
    {
        $existingRemoteTag = Sampler\Invoke-SamplerGit -Argument $lsRemoteArgs
    }
    catch
    {
        # ignore - treat as non-existing
    }

    if ($existingRemoteTag)
    {
        Write-Build Green ("Found existing remote tag '{0}'. Assuming release for module version '{1}' has already been pushed. Exiting." -f $releaseTag, $ModuleVersion)

        return
    }

    # Validate that the commit exists locally; if not, attempt to fetch it
    $commitExists = $true

    try
    {
        Sampler\Invoke-SamplerGit -Argument @('cat-file', '-e', $BuildCommit)
    }
    catch
    {
        $commitExists = $false
    }

    if (-not $commitExists)
    {
        Write-Build DarkGray ("`tCommit '{0}' not found locally; fetching from origin." -f $BuildCommit)

        try
        {
            Sampler\Invoke-SamplerGit -Argument @('fetch', 'origin', $BuildCommit)
            Sampler\Invoke-SamplerGit -Argument @('cat-file', '-e', $BuildCommit)
        }
        catch
        {
            throw ("Unable to fetch or verify commit '{0}' from origin." -f $BuildCommit)
        }
    }

    Write-Build DarkGray ("`tCreating tag '{0}' on the commit '{1}'." -f $releaseTag, $BuildCommit)

    # Create a lightweight tag to minimize change in behavior
    Sampler\Invoke-SamplerGit -Argument @('tag', $releaseTag, $BuildCommit)

    Write-Build DarkGray ("`tPushing created tag '{0}' to origin." -f $releaseTag)

    $pushArguments = @()
    if ($BasicAuthPAT)
    {
        Write-Build DarkGray "`t`tUsing personal access token to push the tag."
        $patBase64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(('PAT:{0}' -f $BasicAuthPAT)))
        $pushArguments += @('-c', ('http.extraheader="AUTHORIZATION: basic {0}"' -f $patBase64))
    }

    # Keep existing SSL backend behavior
    $pushArguments += @('-c', 'http.sslbackend="schannel"', 'push', 'origin', 'refs/tags/{0}:refs/tags/{0}' -f $releaseTag)

    if ($DryRun)
    {
        Write-Build Yellow ("DRYRUN: Would have pushed refs/tags/{0}:refs/tags/{0}" -f $releaseTag)
    }
    else
    {
        Sampler\Invoke-SamplerGit -Argument $pushArguments
    }

    # Verify the tag points to the expected commit after push
    if ($DryRun)
    {
        Write-Build Yellow ("DRYRUN: Set tagged SHA to the commit that we would have expected to pushed tag to: {0}" -f $BuildCommit)

        $taggedSha = $BuildCommit
    }
    else
    {
       $taggedSha = Sampler\Invoke-SamplerGit -Argument @('rev-parse', $releaseTag)
    }

    Write-Build DarkGray ("`tTag '{0}' now points to '{1}'." -f $releaseTag, $taggedSha)

    if ($taggedSha -ne $BuildCommit) {
        throw ("Tag '{0}' points to '{1}', but expected '{2}'." -f $releaseTag, $taggedSha, $BuildCommit)
    }

    if (-not $DryRun)
    {
        # Give a few seconds for propagation so downstream steps can find the tag
        Start-Sleep -Seconds 5

        Write-Build Green 'Tag created and pushed.'
    }
}
