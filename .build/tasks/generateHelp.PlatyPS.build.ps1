Param (
    [Parameter()]
    [io.DirectoryInfo]
    $ProjectPath = (property ProjectPath $BuildRoot),

    [Parameter()]
    [string]
    $ProjectName = (property ProjectName $(
            (Get-ChildItem $BuildRoot\*\*.psd1 | Where-Object {
                ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
                $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop }catch{$false}) }
            ).BaseName
        )
    ),

    [Parameter()]
    [string]
    $SourcePath = (property SourcePath ((Get-ChildItem $BuildRoot\*\*.psd1 | Where-Object {
                    ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
                    $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop }catch { $false }) }
            ).Directory.FullName)
    ),

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

Task UpdateHelp{
    $LineSeparation
    "`t`t`t UPDATE HELP MARKDOWN FILE"
    $LineSeparation

    if (!(Split-Path -IsAbsolute $BuildOutput)) {
        $BuildOutput = Join-Path -Path $ProjectPath.FullName -ChildPath $BuildOutput
    }

    if (!(Split-Path -IsAbsolute $HelpFolder)) {
        $HelpFolder = Join-Path $SourcePath $HelpFolder
    }


    import-module -Force $ProjectName
    Update-MarkdownHelpModule -Path $HelpFolder
}


Task GenerateMamlFromMd {
    $LineSeparation
    "`t`t`t GENERATE MAML IN BUILD OUTPUT"
    $LineSeparation

    if (!(Split-Path -IsAbsolute $BuildOutput)) {
        $BuildOutput = Join-Path -Path $ProjectPath.FullName -ChildPath $BuildOutput
    }

    if (!(Split-Path -IsAbsolute $HelpFolder)) {
        $HelpFolder = Join-Path $SourcePath $HelpFolder
    }


    $BuiltModuleFolder = Join-Path $BuildOutput $ProjectName

    $HelpFolder = Join-Path $SourcePath $HelpFolder
    New-ExternalHelp -Path $HelpFolder -OutputPath "$(Join-Path $BuiltModuleFolder $HelpCultureInfo)" -Force

}
