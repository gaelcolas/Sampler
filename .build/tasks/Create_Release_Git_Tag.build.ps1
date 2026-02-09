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
    [string]
    $GitConfigUserEmail = (property GitConfigUserEmail ''),

    [Parameter()]
    [string]
    $GitConfigUserName = (property GitConfigUserName ''),

    [Parameter()]
    $BuildInfo = (property BuildInfo @{ })
)

# Synopsis: Creates a git tag for the release that is published to a Gallery
task Create_Release_Git_Tag {
    if ($SkipPublish)
    {
        Write-Build Yellow ('Skipping the creating of a tag for module version ''{0}'' since ''$SkipPublish'' was set to ''$true''.' -f $ModuleVersion)

        return
    }

    . Set-SamplerTaskVariable

    <#
        This will return the tag on the HEAD commit, or blank if it
        fails (the error that is catched to $null).

        This call should not use Invoke-SamplerGit since it should not throw
        on error, but return $null if failing.
    #>
    try
    {
        $isCurrentTag = git describe --contains 2> $null
    }
    catch
    {
        Write-Verbose -Message 'There is no tag defined yet.'
    }

    $releaseTag = 'v{0}' -f $ModuleVersion

    if ($isCurrentTag)
    {
        Write-Build Green ('Found a tag. Assuming a full release has been pushed for module version ''{0}''. Exiting.' -f $ModuleVersion)
    }
    else
    {
        Write-Build DarkGray ('About to create the tag ''{0}'' for module version ''{1}''.' -f $releaseTag, $ModuleVersion)

        foreach ($gitConfigKey in @('UserName', 'UserEmail'))
        {
            $gitConfigVariableName = 'GitConfig{0}' -f $gitConfigKey

            if (-not (Get-Variable -Name $gitConfigVariableName -ValueOnly -ErrorAction 'SilentlyContinue'))
            {
                # Variable is not set in context, use $BuildInfo.ChangelogConfig.<varName>
                $configurationValue = $BuildInfo.GitConfig.($gitConfigKey)

                Set-Variable -Name $gitConfigVariableName -Value $configurationValue

                Write-Build DarkGray "`t...Set property $gitConfigVariableName to the value $configurationValue"
            }
        }

        Write-Build DarkGray "`tSetting git configuration."

        Sampler\Invoke-SamplerGit -Argument @('config', 'user.name', $GitConfigUserName)
        Sampler\Invoke-SamplerGit -Argument @('config', 'user.email', $GitConfigUserEmail)

        # Make empty line in output
        ''

        Write-Build DarkGray ("`tGetting HEAD commit for the default branch '{0}." -f $MainGitBranch)

        $defaultBranchHeadCommit = Sampler\Invoke-SamplerGit -Argument @('rev-parse', "origin/$MainGitBranch")

        Write-Build DarkGray ("`tCreating tag '{0}' on the commit '{1}'." -f $releaseTag, $defaultBranchHeadCommit)

        Sampler\Invoke-SamplerGit -Argument @('tag', $releaseTag, $defaultBranchHeadCommit)

        Write-Build DarkGray ("`tPushing created tag '{0}' to the default branch '{1}'." -f $releaseTag, $MainGitBranch)

        $pushArguments = @()

        if ($BasicAuthPAT)
        {
            Write-Build DarkGray "`t`tUsing personal access token to push the tag."

            $patBase64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(('{0}:{1}' -f 'PAT', $BasicAuthPAT)))

            $pushArguments += @('-c', ('http.extraheader="AUTHORIZATION: basic {0}"' -f $patBase64))
        }

        $pushArguments += @('-c', 'http.sslbackend=schannel', 'push', 'origin', '--tags')

        Sampler\Invoke-SamplerGit -Argument $pushArguments

        <#
            Wait for a few seconds so the tag have time to propegate.
            This way next task have chance to find the tag.
        #>
        Start-Sleep -Seconds 5

        Write-Build Green 'Tag created and pushed.'
    }
}
