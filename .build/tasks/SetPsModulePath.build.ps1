param
(
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
    $ReleaseNotesPath = (property ReleaseNotesPath (Join-Path $OutputDirectory 'ReleaseNotes.md')),

    [Parameter()]
    [string]
    $GitHubToken = (property GitHubToken ''), # retrieves from Environment variable

    [Parameter()]
    [string]
    $ReleaseBranch = (property ReleaseBranch 'main'),

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
    $SkipPublish = (property SkipPublish ''),

    [Parameter()]
    $MainGitBranch = (property MainGitBranch 'main')
)

<#
Configuring this task in the 'build.yaml' file looks like this:

SetPSModulePath:
    #PSModulePath: C:\Users\Install\OneDrive\Documents\WindowsPowerShell\Modules;C:\Program Files\WindowsPowerShell\Modules;C:\Windows\system32\WindowsPowerShell\v1.0\Modules;c:\Users\Install\.vscode\extensions\ms-vscode.powershell-2022.5.1\modules;
    RemovePersonal: true
    RemoveProgramFiles: true
    RemoveWindows: false
    SetSystemDefault: false

#>

Task Set_PSModulePath {

    . Set-SamplerTaskVariable

    $param = $PSBoundParameters

    $mainConfigurationKey = 'SetPsModulePath'
    $configurationKeys = 'PSModulePath',
    'RemovePersonal',
    'RemoveProgramFiles',
    'RemoveWindows',
    'SetSystemDefault',
    'PassThru'

    foreach ($configKey in $configurationKeys)
    {
        if (-not (Get-Variable -Name $configKey -ValueOnly -ErrorAction SilentlyContinue))
        {
            # Variable is not set in context, use $BuildInfo.$mainConfigurationKey.$configKey
            $configValue = $BuildInfo.$mainConfigurationKey.$configKey
            if ($configValue)
            {
                $param.$configKey = $configValue
                Set-Variable -Name $configKey -Value $configValue
                Write-Build DarkGray "`t...Set $configKey to $configValue"
            }
        }
    }

    Set-Variable -Name RequiredModulesDirectory -Value $RequiredModulesDirectory
    Set-Variable -Name BuiltModuleSubdirectory -Value $BuiltModuleSubdirectory

    $param.BuiltModuleSubdirectory = $BuiltModuleSubdirectory
    $param.RequiredModulesDirectory = $RequiredModulesDirectory

    $newPSModulePath = Set-SamplerPSModulePath @param -PassThru
    Write-Build darkGray "`t...The new 'PSModulePath' is '$newPSModulePath'"

}
