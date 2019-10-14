param(
    # Base directory of all output (default to 'output')
    [string]$OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

    $ChangelogPath = (property ChangelogPath 'CHANGELOG.md'),

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

    [string]
    $GitHubToken = (property GitHubToken ''), # retrieves from Environment variable

    [string]
    $ReleaseBranch = (property ReleaseBranch 'master'),

    [string]
    $GitHubConfigUserEmail = (property GitHubConfigUserEmail ''),

    [string]
    $GitHubConfigUserName = (property GitHubConfigUserName ''),

    $GitHubFilesToAdd = (property GitHubFilesToAdd ''),

    $BuildInfo = (property BuildInfo @{})
)

# Until I can use a third party module
. $PSScriptRoot/GitHubRelease.functions.ps1

task Publish_release_to_GitHub -if ($GitHubToken) {

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

    # Prerelease label?
    if ($PreReleaseTag) {
        $Prerelease = $true
    }

    # compile changelog for that version
    if (!(Split-Path $ChangelogPath -isAbsolute)) {
        $ChangelogPath = Join-Path $BuildRoot $ChangelogPath | Convert-Path
    }

    # Parse the Changelog and extract unreleased
    if ((Get-Content -raw $ChangelogPath -ErrorAction SilentlyContinue) -match '\[Unreleased\](?<changeLog>[.\s\w\W]*)\n## \[') {
        $ChangeLog = $matches.ChangeLog
    }
    else {
        $ChangeLog = Get-Content -raw $ChangelogPath -ErrorAction SilentlyContinue
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
        Description = $ChangeLog
        GitHubToken = $GitHubToken
    }
    $APIResponse = Publish-GitHubRelease @releaseParams
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

    foreach ($GitHubConfigKey in @('GitHubFilesToAdd', 'GitHubConfigUserName','GitHubConfigUserEmail','UpdateChangelogOnPrerelease')) {
        if ( -Not (Get-Variable -Name $GitHubConfigKey -ValueOnly)) {
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
        $TagVersion = $TagsAtCurrentPoint[0]
        Write-Build Green "Updating Changelog for PRE-Release $TagVersion"
    }
    elseif($TagVersion = $TagsAtCurrentPoint.Where{ $_ -notMatch 'v.*\-' }) {
        Write-Build Green "Updating the ChangeLog for release $TagVersion"
    }
    else {
        Write-Build Yellow "No Release Tag found to update the ChangeLog from"
        return
    }

    $TagVersion = $TagsAtCurrentPoint
    Write-Build DarkGray "Updating Changelog since Tag $TagVersion"
    $BranchName = "updateChangelogAfter$TagVersion"
    git checkout -B $BranchName
    try {
        Update-Changelog -ReleaseVersion ($TagVersion -replace '^v') -LinkMode None -OutputPath .\CHANGELOG.md -Path .\CHANGELOG.md -ErrorAction SilentlyContinue
        git add $GitHubFilesToAdd
        git commit -m "Updating ChangeLog since $TagVersion +semver:skip"
        git config --global user.name $GitHubConfigUserName
        git config --global user.email $GitHubConfigUserEmail

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
    }
    catch {
        Write-Build Yellow "Error trying to create ChangeLog Pull Request. Ignoring. $_"
    }
    Write-Build Green "`n --> PR #$($Response.number) opened: $($Response.url)"
}
