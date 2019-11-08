param(
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
    $ProjectName = (property ProjectName $(
            #Find the module manifest to deduce the Project Name
            (Get-ChildItem $BuildRoot\*\*.psd1 | Where-Object {
                    ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
                    $(try {
                            Test-ModuleManifest $_.FullName -ErrorAction Stop
                        }
                        catch {
                            $false
                        }) }
            ).BaseName
        )
    ),

    [Parameter()]
    [string]
    $ModuleVersion = (property ModuleVersion $(
            try {
                (gitversion | ConvertFrom-Json -ErrorAction Stop).InformationalVersion
            }
            catch {
                Write-Verbose "Error attempting to use GitVersion $($_)"
                ''
            }
        )),

    [Parameter()]
    [string]
    $GitHubToken = (property GitHubToken ''), # retrieves from Environment variable

    [Parameter()]
    [string]
    $ReleaseBranch = (property ReleaseBranch 'master'),

    [Parameter()]
    [string]
    $GitHubConfigUserEmail = (property GitHubConfigUserEmail ''),

    [Parameter()]
    [string]
    $GitHubConfigUserName = (property GitHubConfigUserName ''),

    [Parameter()]
    $GitHubFilesToAdd = (property GitHubFilesToAdd ''),

    [Parameter()]
    $BuildInfo = (property BuildInfo @{ }),

    [Parameter()]
    $SkipPublish = (property SkipPublish '')
)

# Until I can use a third party module
. $PSScriptRoot/GitHubRelease.functions.ps1

task Publish_release_to_GitHub -if ($GitHubToken) {
    if (!(Split-Path $OutputDirectory -IsAbsolute)) {
        $OutputDirectory = Join-Path $BuildRoot $OutputDirectory
    }

    if (!(Split-Path -isAbsolute $ReleaseNotesPath)) {
        $ReleaseNotesPath = Join-Path $OutputDirectory $ReleaseNotesPath
    }

    if ([String]::IsNullOrEmpty($ModuleVersion)) {
        $ModuleInfo = Import-PowerShellDataFile "$OutputDirectory/$ProjectName/*/$ProjectName.psd1" -ErrorAction Stop
        if ($PreReleaseTag = $ModuleInfo.PrivateData.PSData.Prerelease) {
            $ModuleVersion = $ModuleInfo.ModuleVersion + "-" + $PreReleaseTag
        }
        else {
            $ModuleVersion = $ModuleInfo.ModuleVersion
        }
    }
    else {
        # Remove metadata from ModuleVersion
        $ModuleVersion, $BuildMetadata = $ModuleVersion -split '\+', 2
        # Remove Prerelease tag from ModuleVersionFolder
        $ModuleVersionFolder, $PreReleaseTag = $ModuleVersion -split '\-', 2
    }

    # find Module's nupkg
    $PackageToRelease = Get-ChildItem (Join-Path $OutputDirectory "$ProjectName.$ModuleVersion.nupkg")
    $ReleaseTag = "v$ModuleVersion"

    Write-Build DarkGray "About to release $PackageToRelease v$ModuleVersion"
    $remoteURL = git remote get-url origin

    if ($remoteURL -notMatch 'github') {
        Write-Build Yellow "Skipping Publish GitHub release to $RemoteURL"
        return
    }

    # find owner repository / remote
    $Repo = GetHumanishRepositoryDetails -RemoteUrl $remoteURL

    # Retrieving ReleaseNotes or defaulting to Updated ChangeLog
    if (Import-Module ChangelogManagement -ErrorAction SilentlyContinue -PassThru) {
        $ReleaseNotes = (Get-ChangelogData -Path $ChangeLogPath).Unreleased.RawData -replace '\[unreleased\]', "[v$ModuleVersion]"
    }
    else {
        if (-not ($ReleaseNotes = (Get-Content -raw $ReleaseNotesPath -ErrorAction SilentlyContinue))) {
            $ReleaseNotes = Get-Content -raw $ChangeLogPath -ErrorAction SilentlyContinue
        }
    }


    # if you want to create the tag on /release/v$ModuleVersion branch (default to master)
    $ReleaseBranch = $ExecutionContext.InvokeCommand.ExpandString($ReleaseBranch)

    $releaseParams = @{
        Owner       = $Repo.Owner
        Repository  = $Repo.Repository
        Tag         = $ReleaseTag
        ReleaseName = $ReleaseTag
        Branch      = $ReleaseBranch
        AssetPath   = $PackageToRelease
        Prerelease  = [bool]($PreReleaseTag)
        Description = $ReleaseNotes
        GitHubToken = $GitHubToken
    }
    if (!$SkipPublish) {
        $APIResponse = Publish-GitHubRelease @releaseParams
    }
    Write-Build Green "Release Created. Follow the link -> $($APIResponse.html_url)"
}

task Create_ChangeLog_GitHub_PR -if ($GitHubToken) {
    # # This is how AzDO setup the environment:
    # git init
    # git remote add origin https://github.com/gaelcolas/Sampler
    # git config gc.auto 0
    # git config --get-all http.https://github.com/gaelcolas/Sampler.extraheader
    # git pull origin master
    # # git fetch --force --tags --prune --progress --no-recurse-submodules origin
    # # git checkout --progress --force (git rev-parse origin/master)

    foreach ($GitHubConfigKey in @('GitHubFilesToAdd', 'GitHubConfigUserName', 'GitHubConfigUserEmail', 'UpdateChangelogOnPrerelease')) {
        if ( -Not (Get-Variable -Name $GitHubConfigKey -ValueOnly -ErrorAction SilentlyContinue)) {
            # Variable is not set in context, use $BuildInfo.GitHubConfig.<varName>
            $ConfigValue = $BuildInfo.GitHubConfig.($GitHubConfigKey)
            Set-Variable -Name $GitHubConfigKey -Value $ConfigValue
            Write-Build DarkGray "`t...Set $GitHubConfigKey to $ConfigValue"
        }
    }

    git pull origin master --tag
    # Look at the tags on latest commit for origin/master (assume we're on detached head)
    $TagsAtCurrentPoint = git tag -l --points-at (git rev-parse origin/master)
    # Only Update changelog if last commit is a full release
    if ($UpdateChangelogOnPrerelease) {
        $TagVersion = [string]($TagsAtCurrentPoint | Select-Object -First 1)
        Write-Build Green "Updating Changelog for PRE-Release $TagVersion"
    }
    elseif ($TagVersion = [string]($TagsAtCurrentPoint.Where{ $_ -notMatch 'v.*\-' })) {
        Write-Build Green "Updating the ChangeLog for release $TagVersion"
    }
    else {
        Write-Build Yellow "No Release Tag found to update the ChangeLog from"
        return
    }

    $BranchName = "updateChangelogAfter$TagVersion"
    git checkout -B $BranchName
    try {
        Write-Build DarkGray "Updating Changelog file"
        Update-Changelog -ReleaseVersion ($TagVersion -replace '^v') -LinkMode None -Path $ChangelogPath -ErrorAction SilentlyContinue
        git add $GitHubFilesToAdd
        git config user.name $GitHubConfigUserName
        git config user.email $GitHubConfigUserEmail
        git commit -m "Updating ChangeLog since $TagVersion +semver:skip"

        $URI = [URI](git remote get-url origin)
        $URI = $Uri.Scheme + [URI]::SchemeDelimiter + $GitHubToken + '@' + $URI.Authority + $URI.PathAndQuery

        # Update the PUSH URI to use the Personal Access Token for Auth
        git remote set-url --push origin $URI

        # track this branch on the remote 'origin
        git push -u origin $BranchName

        # Grab the Repo info for creating new PR
        $RepoInfo = GetHumanishRepositoryDetails -RemoteUrl (git remote get-url origin)

        $NewPullRequestParams = @{
            GitHubToken = $GitHubToken
            Repository  = $RepoInfo.Repository
            Owner       = $RepoInfo.Owner
            Title       = "Updating ChangeLog since release of $TagVersion"
            Branch      = $BranchName
            ErrorAction = 'Stop'
        }
        $Response = New-GitHubPullRequest @NewPullRequestParams
        Write-Build Green "`n --> PR #$($Response.number) opened: $($Response.url)"
    }
    catch {
        Write-Build Red "Error trying to create ChangeLog Pull Request. Ignoring.`r`n $_"
    }
}
