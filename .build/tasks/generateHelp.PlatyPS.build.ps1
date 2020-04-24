Param (
    [Parameter()]
    [io.DirectoryInfo]
    $ProjectPath = (property ProjectPath $BuildRoot),

    [Parameter()]
    [string]
    $ProjectName = (property ProjectName ''),

    [Parameter()]
    [string]
    $SourcePath = (property SourcePath ''),

    [Parameter()]
    [string]
    $HelpFolder = (property HelpFolder 'docs'),

    [Parameter()]
    [string]
    $BuildOutput = (property BuildOutput 'C:\BuildOutput'),

    [Parameter()]
    [cultureInfo]
    $HelpCultureInfo = 'en-US',

    [Parameter()]
    [string]
    $LineSeparation = (property LineSeparation ('-' * 78))

)

Task UpdateHelp {
    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-ProjectName -BuildRoot $BuildRoot
    }

    if ([System.String]::IsNullOrEmpty($SourcePath))
    {
        $SourcePath = Get-SourcePath -BuildRoot $BuildRoot
    }

    $LineSeparation
    "`t`t`t UPDATE HELP MARKDOWN FILE"
    $LineSeparation

    if (!(Split-Path -IsAbsolute $BuildOutput))
    {
        $BuildOutput = Join-Path -Path $ProjectPath.FullName -ChildPath $BuildOutput
    }

    if (!(Split-Path -IsAbsolute $HelpFolder))
    {
        $HelpFolder = Join-Path $SourcePath $HelpFolder
    }


    import-module -Force $ProjectName
    Update-MarkdownHelpModule -Path $HelpFolder
}


Task GenerateMamlFromMd {
    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-ProjectName -BuildRoot $BuildRoot
    }

    if ([System.String]::IsNullOrEmpty($SourcePath))
    {
        $SourcePath = Get-SourcePath -BuildRoot $BuildRoot
    }

    $LineSeparation
    "`t`t`t GENERATE MAML IN BUILD OUTPUT"
    $LineSeparation

    if (!(Split-Path -IsAbsolute $BuildOutput))
    {
        $BuildOutput = Join-Path -Path $ProjectPath.FullName -ChildPath $BuildOutput
    }

    if (!(Split-Path -IsAbsolute $HelpFolder))
    {
        $HelpFolder = Join-Path $SourcePath $HelpFolder
    }


    $BuiltModuleFolder = Join-Path $BuildOutput $ProjectName

    $HelpFolder = Join-Path $SourcePath $HelpFolder
    New-ExternalHelp -Path $HelpFolder -OutputPath "$(Join-Path $BuiltModuleFolder $HelpCultureInfo)" -Force

}
