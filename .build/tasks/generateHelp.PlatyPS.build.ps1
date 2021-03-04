param
(
    [Parameter()]
    [System.IO.DirectoryInfo]
    $ProjectPath = (property ProjectPath $BuildRoot),

    [Parameter()]
    [System.String]
    $ProjectName = (property ProjectName ''),

    [Parameter()]
    [System.String]
    $SourcePath = (property SourcePath ''),

    [Parameter()]
    [System.String]
    $HelpFolder = (property HelpFolder 'docs'),

    [Parameter()]
    [System.String]
    $BuildOutput = (property BuildOutput 'C:\BuildOutput'),

    [Parameter()]
    [cultureInfo]
    $HelpCultureInfo = 'en-US',

    [Parameter()]
    [System.String]
    $LineSeparation = (property LineSeparation ('-' * 78))

)

Task UpdateHelp {
    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-SamplerProjectName -BuildRoot $BuildRoot
    }

    if ([System.String]::IsNullOrEmpty($SourcePath))
    {
        $SourcePath = Get-SamplerSourcePath -BuildRoot $BuildRoot
    }

    $LineSeparation
    "`t`t`t UPDATE HELP MARKDOWN FILE"
    $LineSeparation

    if (-not (Split-Path -Path $BuildOutput -IsAbsolute))
    {
        $BuildOutput = Join-Path -Path $ProjectPath.FullName -ChildPath $BuildOutput
    }

    if (-not (Split-Path -Path $HelpFolder -IsAbsolute))
    {
        $HelpFolder = Join-Path -Path $SourcePath -ChildPath $HelpFolder
    }

    Import-Module -Name $ProjectName -Force
    Update-MarkdownHelpModule -Path $HelpFolder
}


Task GenerateMamlFromMd {
    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-SamplerProjectName -BuildRoot $BuildRoot
    }

    if ([System.String]::IsNullOrEmpty($SourcePath))
    {
        $SourcePath = Get-SamplerSourcePath -BuildRoot $BuildRoot
    }

    $LineSeparation
    "`t`t`t GENERATE MAML IN BUILD OUTPUT"
    $LineSeparation

    if (-not (Split-Path -Path $BuildOutput -IsAbsolute))
    {
        $BuildOutput = Join-Path -Path $ProjectPath.FullName -ChildPath $BuildOutput
    }

    if (-not (Split-Path -Path $HelpFolder -IsAbsolute))
    {
        $HelpFolder = Join-Path -Path $SourcePath -ChildPath $HelpFolder
    }

    $BuiltModuleFolder = Join-Path -Path $BuildOutput -ChildPath $ProjectName
    $HelpFolder = Join-Path -Path $SourcePath -ChildPath $HelpFolder
    New-ExternalHelp -Path $HelpFolder -OutputPath "$(Join-Path $BuiltModuleFolder $HelpCultureInfo)" -Force
}
