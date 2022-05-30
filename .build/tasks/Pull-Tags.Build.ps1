param
(
    # Base directory of all output (default to 'output')
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
    # Sub-Folder (or absolute path) of the Chocolatey build output folder (relative to $OutputDirectory)
    # Contain the path to one or more Chocolatey packages.
    # This variable here is used to determine if the repository is building a Chocolatey package.
    $ChocolateyBuildOutput = (property ChocolateyBuildOutput 'choco'),

    # Build Configuration object
    [Parameter()]
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)

# Synopsis: Create ReleaseNotes from changelog and update the Changelog for release
task pull_tags_from_public_repo {
    # Get the vales for task variables, see https://github.com/gaelcolas/Sampler#task-variables.
    . Set-SamplerTaskVariable

    # $ReleaseTag = "v$ModuleVersion"

    # Assuming a public repo on GitHub, a GithubToken
    # Assuming a private repo NOT on GitHub
    # Assuming you're running in your local clone of the private repo

    $publicRepo = $BuildInfo.GitHubConfig.PublicRepo
    if ($publicRepo)
    {
        "        Public Repo                = '$publicRepo'`r`n"
    }
    else
    {
        Write-Build Red 'No Public Repo configured in Build.yml/GitHubConfig.PublicRepo.'
        return
    }

    [string] $currentLocalBranch = Invoke-SamplerGit -Argument @('branch','--show-current')
    if ($currentLocalBranch -ne 'main' )
    {
        Write-Build White 'Checking out main branch.'
        Invoke-SamplerGit -Argument @('checkout', 'main', '--quiet')
    }

    Write-Build DarkGray 'Reverting to latest code on local repo.'
    Write-Build DarkGray $(Invoke-SamplerGit -Argument @('fetch', 'origin'))
    Write-Build DarkGray $(Invoke-SamplerGit -Argument @('reset', '--hard', 'origin/main'))
    # list tags from Public repo
    # (git for-each-ref --sort=creatordate --format '%(refname) %(objectname)' refs/tags).Foreach{$_ -replace 'refs/tags/'}
    $remoteTags = Invoke-SamplerGit -Argument @('ls-remote', '--tags', $publicRepo)
    $remoteTags.Foreach({
        Write-Build DarkGray $_
        $id,$tagname = $_ -split '\s+'
        $tagname = $tagname -replace 'refs/tags/'
        Write-Verbose -Message ('Tag {0} at commit id {1}' -f $tagname,$id)

        if (-not [string]::IsNullOrEmpty($id) -and -not (git show-ref -s $tagname))
        {
            Write-Build White ('Missing tag ''{0}'' for commitid ''{1}''.' -f $tagname,$id)
            # Content from remote/public repo can't be retrieved without checkout (need access to object)
            try
            {
                $null = Invoke-SamplerGit -Argument @('tag', $tagname, $id) -ErrorAction Stop
                Write-Build Green ('Tag ''{0}'' added.' -f $tagname)
            }
            catch
            {
                Write-Build Yellow ('Error adding tag ''{0}'' at id {1}.' -f $tagname, $id)
            }
        }
        elseif (-not [string]::IsNullOrEmpty($id))
        {
            Write-Build DarkGray ('Tag ''{0}'' is already present at ''{1}''.' -f $tagname,$id)
        }

        Write-Build DarkGray ' '
    })
}

task Save_Git_Work {
    # Get the vales for task variables, see https://github.com/gaelcolas/Sampler#task-variables.
    . Set-SamplerTaskVariable

    [string] $saveToBranch = 'save/wip{0}' -f (Get-Date -Format 'yyyyMMddHHmm')
    # Save unstaged changed if any.
    [string[]] $unstagedChangedFiles = Invoke-SamplerGit -Argument @('diff', '--name-only')
    [string[]] $stagedChangedFiles = Invoke-SamplerGit -Argument @('diff', '--name-only', '--cached')
    if ($unstagedChangedFiles.count -gt 0 -or $stagedChangedFiles.Count -gt 0)
    {
        Write-Build Yellow "Committing changes to [$($unstagedChangedFiles -join ',')]."
        Invoke-SamplerGit -Argument @('commit', '-a', '-m', "Saving changes for '$saveToBranch'...")
        Write-Build Green "Changes committed as '$saveToBranch'."
    }

    $commitsBehind, $commitsAhead = (Invoke-SamplerGit -Argument @('rev-list', '--left-right', '--count', 'origin/main...main')) -split '\s+'
    if ([int]$commitsAhead -gt 0)
    {
        Write-Build Yellow "Saving your $commitsAhead commits to a new local branch named 'save/wip_$pullRequestId'."
        Invoke-SamplerGit -Argument @('branch', $saveToBranch)
    }
}

task git_hard_reset_origin_main {
    # Get the vales for task variables, see https://github.com/gaelcolas/Sampler#task-variables.
    . Set-SamplerTaskVariable

    Write-Build Yellow 'This task meant to run on a local clone of the origin repo.'
    [string] $currentLocalBranch = Invoke-SamplerGit -Argument @('branch','--show-current')
    if ($currentLocalBranch -ne 'main' )
    {
        Invoke-SamplerGit -Argument @('checkout', 'main', '--quiet')
    }

    # Get the repo back to origin main HEAD (that assumes the current local repo is the private one)
    Write-Build White 'fetching origin.'
    Write-Build DarkGray $(Invoke-SamplerGit -Argument @('fetch', 'origin'))
    Write-Build White 'Resetting to origin/main.'
    Write-Build DarkGray $(Invoke-SamplerGit -Argument @('reset', '--hard', 'origin/main'))
}

task Pull_public_GitHub_PR_to_local_private {
    # Get the vales for task variables, see https://github.com/gaelcolas/Sampler#task-variables.
    . Set-SamplerTaskVariable

    Write-Build Yellow 'This task is meant to run on a local clone of the private repo (in a public/private relase scenario).'
    Write-Build DarkGray 'It should be used in a public/private repo to pull a public PR.'
    $publicRepo = $BuildInfo.GitHubConfig.PublicRepo
    if ($publicRepo)
    {
        "        Public Repo                = '$publicRepo'`r`n"
    }
    else
    {
        Write-Build Red 'No Public Repo configured in Build.yml/GitHubConfig.PublicRepo.'
        return
    }

    $pullRequestId = Read-Host -Prompt 'What is the Pull Request ID you would like to pull? (i.e. 379)'
    $remoteHeadId,$null = (Invoke-SamplerGit -Argument @('ls-remote', $publicRepo, 'HEAD') -ErrorAction Stop) -split '\s+'
    $prBranch = "pr/publicpr#$pullRequestId"
    try
    {
        # If the public remote is already configured, just skip (no override)
        $publicRemoteUrl = Invoke-SamplerGit -Argument @('remote', 'get-url', 'public') -ErrorAction Stop
        Write-Build Green ('The remote ''public'' is already set to ''{0}''' -f $publicRemoteUrl)
    }
    catch
    {
        Invoke-SamplerGit -Argument @('remote', 'add', 'public', $publicRepo, '--quiet')
        # Validate it worked and report
        $publicRemoteUrl = Invoke-SamplerGit -Argument @('remote', 'get-url', 'public') -ErrorAction Stop
        Write-Build Green ('Added remote ''public'' with URL ''{0}''.' -f $publicRemoteUrl)
    }

    try
    {
        # Create the public PR branch or throw
        Invoke-SamplerGit -Argument @('branch', $prBranch) -ErrorAction Stop
    }
    catch
    {
        # the prBranch already exists, let's move to the branch
        Invoke-SamplerGit -Argument @('checkout', $prBranch, '--quiet') -ErrorAction Stop
    }

    $publicPRCommitId, $ref = (Invoke-SamplerGit -Argument @('ls-remote', 'public', "pull/$pullRequestId/head")) -split '\s+'
    # Get latest local commit
    $localHeadId = Invoke-SamplerGit -Argument @('rev-parse', 'HEAD')
    Invoke-SamplerGit -Argument @('pull', 'public', "refs/pull/$pullRequestId/head", '--track' ) # Make sure our local head is the same as remote origin head
    # $null = Invoke-SamplerGit -Argument @('fetch', 'public', "pull/$pullRequestId/head:$prBranch") -ErrorAction Stop
    # $null = Invoke-SamplerGit -Argument @('cherry-pick', "$($localHeadId)..$($prHead)")
}
