<#
    .SYNOPSIS
        This build task updates the changelog with the release and creates a branch
        to merge.

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

    .PARAMETER ChangelogPath
        The path to and the name of the changelog file. Defaults to 'CHANGELOG.md'.

    .PARAMETER GitConfigUserEmail
        The user email to use when committing the changes.

    .PARAMETER GitConfigUserName
        The user name to use when committing the changes.

    .PARAMETER ChangelogFilesToAdd
        One or more files to the commit before pushing the changes. Defaults to
        'CHANGELOG.md'.

    .PARAMETER ChangelogUpdateChangelogOnPrerelease
        If the changelog should be updated on pre-releases. Defaults to
        $false.

    .PARAMETER MainGitBranch
        The name of the default branch. Defaults to 'main'. It is used to compare
        and target the branch against.

    .PARAMETER BasicAuthPAT
        The personal access token to use to access the Azure DevOps Git repository.
        If left out the task assumes the authentication works without an personal
        access token, e.g Windows integrated security.

    .PARAMETER BuildInfo
        The build info object from ModuleBuilder. Defaults to an empty hashtable.

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
    $ChangelogPath = (property ChangelogPath 'CHANGELOG.md'),

    [Parameter()]
    [string]
    $GitConfigUserEmail = (property GitConfigUserEmail ''),

    [Parameter()]
    [string]
    $GitConfigUserName = (property GitConfigUserName ''),

    [Parameter()]
    $ChangelogFilesToAdd = (property ChangelogFilesToAdd @('CHANGELOG.md')),

    [Parameter()]
    $ChangelogUpdateChangelogOnPrerelease = (property ChangelogUpdateChangelogOnPrerelease $false),

    [Parameter()]
    $MainGitBranch = (property MainGitBranch 'main'),

    [Parameter()]
    $BasicAuthPAT = (property BasicAuthPAT ''),

    [Parameter()]
    $BuildInfo = (property BuildInfo @{ })
)

# Synopsis: Creates a branch to update the changelog with the released version
task Create_Changelog_Branch {
    . Set-SamplerTaskVariable

    $ChangelogPath = Get-SamplerAbsolutePath -Path $ChangelogPath -RelativeTo $ProjectPath
    "`Changelog Path                 = '$ChangelogPath'"

    foreach ($changelogConfigKey in @('UpdateChangelogOnPrerelease', 'FilesToAdd'))
    {
        $changelogConfigVariableName = 'Changelog{0}' -f $changelogConfigKey

        if (-not (Get-Variable -Name $changelogConfigVariableName -ValueOnly -ErrorAction 'SilentlyContinue'))
        {
            # Variable is not set in context, use $BuildInfo.ChangelogConfig.<varName>
            $configurationValue = $BuildInfo.ChangelogConfig.($changelogConfigKey)

            Set-Variable -Name $changelogConfigVariableName -Value $configurationValue

            Write-Build DarkGray "`t...Set property $changelogConfigVariableName to the value $configurationValue."
        }
    }

    foreach ($gitConfigKey in @('UserName', 'UserEmail'))
    {
        $gitConfigVariableName = 'GitConfig{0}' -f $gitConfigKey

        if (-not (Get-Variable -Name $gitConfigVariableName -ValueOnly -ErrorAction 'SilentlyContinue'))
        {
            # Variable is not set in context, use $BuildInfo.ChangelogConfig.<varName>
            $configurationValue = $BuildInfo.GitConfig.($gitConfigKey)

            Set-Variable -Name $gitConfigVariableName -Value $configurationValue

            Write-Build DarkGray "`t...Set property $gitConfigVariableName to the value $configurationValue."
        }
    }

    Write-Build DarkGray "`tSetting git configuration."

    Sampler\Invoke-SamplerGit -Argument @('config', 'user.name', $GitConfigUserName)
    Sampler\Invoke-SamplerGit -Argument @('config', 'user.email', $GitConfigUserEmail)
    Sampler\Invoke-SamplerGit -Argument @('config', 'pull.rebase', 'true')

    Write-Build DarkGray ("`tPulling latest commits and tags from branch '{0}'." -f $MainGitBranch)

    $pullArguments = @()

    if ($BasicAuthPAT)
    {
        Write-Build DarkGray "`t`tUsing personal access token to pull commits and tags."

        $patBase64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(('{0}:{1}' -f 'PAT', $BasicAuthPAT)))

        $pullArguments += @('-c', ('http.extraheader="AUTHORIZATION: basic {0}"' -f $patBase64))
    }

    # Track this branch on the remote 'origin
    $pullArguments += @('-c', 'http.sslbackend=schannel', 'pull', 'origin', $MainGitBranch, '--tag')

    Sampler\Invoke-SamplerGit -Argument $pullArguments

    # Make empty line in output
    ""

    Write-Build DarkGray ("`tGetting HEAD commit for the default branch '{0}." -f $MainGitBranch)

    $defaultBranchHeadCommit = Sampler\Invoke-SamplerGit -Argument @('rev-parse', "origin/$MainGitBranch")

    Write-Build DarkGray ("`tGet tags at commit '{0}'." -f $defaultBranchHeadCommit)

    $tagsAtCommit = Sampler\Invoke-SamplerGit -Argument @('tag', '-l', '--points-at', $defaultBranchHeadCommit)

    Write-Build DarkGray ("`t`tFound tags: {0}" -f ($tagsAtCommit -join ' | '))

    # Only Update changelog if last commit is a full release
    if ($ChangelogUpdateChangelogOnPrerelease)
    {
        $tagVersion = [System.String] ($tagsAtCommit | Select-Object -First 1)

        Write-Build Green "Updating Changelog for PRE-Release $tagVersion."
    }
    else
    {
        $tagVersion = [System.String] ($tagsAtCommit.Where{ $_ -notMatch 'v.*\-' })

        if ($tagVersion)
        {
            Write-Build Green "Updating the Changelog for release $tagVersion."
        }
        else
        {
            Write-Build Yellow ("No release tag found to update the changelog from the available tags: {0}" -f ($tagsAtCommit -join ' | '))
            return
        }
    }

    # Make empty line in output
    ""

    Write-Build DarkGray ('About to create the branch for module version ''{0}''.' -f $ModuleVersion)

    $branchName = "updateChangelogAfter$tagVersion"

    Write-Build DarkGray "`tCreating branch $branchName."

    Sampler\Invoke-SamplerGit -Argument @('checkout', '-B', $branchName)

    Write-Build DarkGray "`tUpdating Changelog file."

    Update-Changelog -ReleaseVersion ($tagVersion -replace '^v') -LinkMode 'None' -Path $ChangelogPath -ErrorAction 'SilentlyContinue'

    Sampler\Invoke-SamplerGit -Argument @('add', $ChangelogFilesToAdd)

    Sampler\Invoke-SamplerGit -Argument @('commit', '-m', "Updating Changelog since $tagVersion +semver:skip")

    Write-Build DarkGray ("`tPushing commit on branch '{0}' to the repository." -f $branchName)

    $pushArguments = @()

    if ($BasicAuthPAT)
    {
        Write-Build DarkGray "`t`tUsing personal access token to push the tag."

        $patBase64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(('{0}:{1}' -f 'PAT', $BasicAuthPAT)))

        $pushArguments += @('-c', ('http.extraheader="AUTHORIZATION: basic {0}"' -f $patBase64))
    }

    # Track this branch on the remote 'origin
    $pushArguments += @('-c', 'http.sslbackend=schannel', 'push', '-u', 'origin', $BranchName)

    Sampler\Invoke-SamplerGit -Argument $pushArguments

    Write-Build Green ('Created and pushed the changelog branch ''{0}''.' -f $BranchName)
}
