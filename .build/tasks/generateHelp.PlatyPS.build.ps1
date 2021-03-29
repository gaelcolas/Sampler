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
    $HelpSourceFolder = (property HelpSourceFolder 'docs'),

    [Parameter()]
    [System.String]
    $OutputDirectory = (property OutputDirectory 'output'),

    [Parameter()]
    [System.String]
    $BuiltModuleSubdirectory = (property BuiltModuleSubdirectory ''),

    [Parameter()]
    [System.Management.Automation.SwitchParameter]
    $VersionedOutputDirectory = (property VersionedOutputDirectory $true),

    [Parameter()]
    [System.String]
    $HelpOutputFolder = (property HelpOutputFolder 'help'),

    [Parameter()]
    [cultureInfo]
    $HelpCultureInfo = 'en-US',

    [Parameter()]
    [System.Management.Automation.SwitchParameter]
    $CopyHelpMamlToBuiltModuleBase = (property CopyHelpMamlToBuiltModuleBase $true),

    # Build Configuration object
    [Parameter()]
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)

function Get-GenerateHelpPlatyPSVariables
{
    param ()

    if ([string]::IsNullOrEmpty($ProjectName))
    {
        $script:ProjectName = Get-SamplerProjectName -BuildRoot $BuildRoot
    }

    if ([string]::IsNullOrEmpty($SourcePath))
    {
        $script:SourcePath = (Get-SamplerSourcePath -BuildRoot $BuildRoot)
    }

    $script:ProjectPath = Get-SamplerAbsolutePath -Path $ProjectPath -RelativeTo $BuildRoot
    $script:OutputDirectory = Get-SamplerAbsolutePath -Path $OutputDirectory -RelativeTo $BuildRoot
    $script:PesterOutputFolder = Get-SamplerAbsolutePath -Path $PesterOutputFolder -RelativeTo $OutputDirectory

    "`tProject Name               = '$ProjectName'"
    "`tProject Path               = '$ProjectPath'"
    "`tOutput Directory           = '$OutputDirectory'"
    "`tPester Output Folder       = '$PesterOutputFolder"

    if ($VersionedOutputDirectory)
    {
        # VersionedOutputDirectory is not [bool]'' nor $false nor [bool]$null
        # Assume true, wherever it was set
        $null = [bool]::TryParse($VersionedOutputDirectory, [ref]$script:VersionedOutputDirectory)
    }
    else
    {
        # VersionedOutputDirectory may be [bool]'' but we can't tell where it's
        # coming from, so assume the build info (Build.yaml) is right
        $VersionedOutputDirectory = $BuildInfo['VersionedOutputDirectory']
    }

    $GetBuiltModuleManifestParams = @{
        OutputDirectory          = $OutputDirectory
        BuiltModuleSubDirectory  = $BuiltModuleSubDirectory
        ModuleName               = $ProjectName
        VersionedOutputDirectory = $VersionedOutputDirectory
        ErrorAction              = 'Stop'
    }

    $script:builtModuleBase = Get-SamplerBuiltModuleBase @GetBuiltModuleManifestParams
    if ($builtModuleBase)
    {
        $script:builtModuleBase = Get-Item -Path $builtModuleBase -ErrorAction 'SilentlyContinue'
    }

    "`tBuilt Module Base          = '$builtModuleBase'"

    $script:builtModuleManifest = Get-SamplerBuiltModuleManifest @GetBuiltModuleManifestParams
    if ($builtModuleManifest)
    {
        $script:builtModuleManifest = Get-Item -Path $builtModuleManifest -ErrorAction 'SilentlyContinue'
    }

    "`tBuilt Module Manifest      = '$builtModuleManifest'"

    if ($builtModuleManifest -and ($script:builtModuleRootScriptPath = Get-SamplerModuleRootPath -ModuleManifestPath $builtModuleManifest))
    {
        $script:builtModuleRootScriptPath = (Get-Item -Path $builtModuleRootScriptPath -ErrorAction SilentlyContinue).FullName
    }

    "`tBuilt ModuleRoot script    = '$builtModuleRootScriptPath'"

    if ($builtModuleManifest)
    {
        $script:ModuleVersion = Get-BuiltModuleVersion @GetBuiltModuleManifestParams
        $script:ModuleVersionObject = Split-ModuleVersion -ModuleVersion $ModuleVersion
        $script:ModuleVersionFolder = $ModuleVersionObject.Version
        $script:preReleaseTag       = $ModuleVersionObject.PreReleaseString
    }

    "`tModule Version             = '$ModuleVersion'"
    "`tModule Version Folder      = '$ModuleVersionFolder'"
    "`tPre-release Tag            = '$preReleaseTag'"

    $script:HelpSourceFolder = Get-SamplerAbsolutePath -Path $HelpSourceFolder -RelativeTo $ProjectPath
    "`tHelp Source Folder         = '$HelpSourceFolder'"

    $script:HelpOutputFolder =  Get-SamplerAbsolutePath -Path $HelpOutputFolder -RelativeTo $OutputDirectory
    "`tHelp output Folder         = '$HelpOutputFolder'"

    if ($ModuleVersion)
    {
        $script:HelpOutputVersionFolder = Get-SamplerAbsolutePath -Path $ModuleVersion -RelativeTo $HelpOutputFolder
    }

    "`tHelp output Version Folder = '$HelpOutputVersionFolder'"

    $script:HelpOutputCultureFolder = Get-SamplerAbsolutePath -Path $HelpCultureInfo -RelativeTo $HelpOutputVersionFolder
    "`tHelp output Culture path   = '$HelpOutputCultureFolder'"

    $script:DocOutputFolder = Get-SamplerAbsolutePath -Path 'docs' -RelativeTo $OutputDirectory
    "`tDocs output folder path    = '$DocOutputFolder'"

    $null = [bool]::TryParse($CopyHelpMamlToBuiltModuleBase, [ref]$script:CopyHelpMamlToBuiltModuleBase)
    "`tCopy MAML to Built Module  = '$CopyHelpMamlToBuiltModuleBase'"
}


# Synopsis: Generate MAML from the built module (and add to module Base).
Task Generate_MAML_from_built_module {

    Get-GenerateHelpPlatyPSVariables

    $AlphabeticParamOrder = $true
    $WithModulePage = $true
    $ExcludeDontShow = $true

    $generateHelpCommands = @"
    `$env:PSModulePath = '$Env:PSModulePath'
    `$targetModule = Import-Module -Name '$ProjectName' -ErrorAction Stop -Passthru

    `$newMarkdownHelpParams = @{
        Module                = '$ProjectName'
        OutputFolder          = '$DocOutputFolder'
        AlphabeticParamsOrder = `$$AlphabeticParamOrder
        WithModulePage        = `$$WithModulePage
        ExcludeDontShow       = `$$ExcludeDontShow
        Force                 = `$true
        ErrorAction           = 'Stop'
        Locale                = '$HelpCultureInfo'
        HelpVersion           = '$ModuleVersion'
    }

    New-MarkdownHelp @newMarkdownHelpParams
    New-ExternalHelp -Path "$DocOutputFolder" -OutputPath "$HelpOutputCultureFolder" -Force
"@

    Write-Build -Color DarkGray -Text "$generateHelpCommands"
    $sb = [ScriptBlock]::create($generateHelpCommands)

    $pwshPath = (Get-Process -Id $PID).Path
    &$pwshPath -Command $sb -ExecutionPolicy 'ByPass'

    if ($CopyHelpMamlToBuiltModuleBase)
    {
        # Copy the created MAML to the ModuleBase root folder (not in Locale as there's only 1 language)
        Get-ChildItem -Path $HelpOutputCultureFolder -ErrorAction 'SilentlyContinue' | Copy-Item -Destination $builtModuleBase -Force
    }
}

# Synopsis: Generate (if absent) or Update the Markdown help source files for each locale folder (i.e. docs/en-US).
Task Update_markdown_help_source {

    Get-GenerateHelpPlatyPSVariables
    $existingLocaleFolders = (Get-ChildItem -Path $HelpSourceFolder -Directory -ErrorAction 'SilentlyContinue').Name

    if ($existingLocaleFolders.count -le 0)
    {
        Write-Build -Color 'Yellow' -Text "No existing help locale folder found. Adding default 'en-US'"
        $existingLocaleFolders = @('en-US')
    }

    foreach ($Locale in $ExistingLocaleFolders)
    {
        $HelpSourceLocaleFolder = Join-Path -Path $HelpSourceFolder -ChildPath $Locale
        Write-Build -Color 'Yellow' -Text "Updating help for locale '$Locale'"

        $AlphabeticParamOrder = $true
        $WithModulePage = $true
        $ExcludeDontShow = $true
        $MarkdownHelpMetadataAsString = '@{GeneratedBy = "Sampler update_help_source task"}'

        $generateHelpCommands = @"
            `$env:PSModulePath = '$Env:PSModulePath'
            `$targetModule = Import-Module -Name '$ProjectName' -ErrorAction Stop -Passthru

            try
            {
                Update-MarkdownHelpModule -Path '$HelpSourceLocaleFolder' -Force -ErrorAction 'Stop'
            }
            catch
            {
                `$newMarkdownHelpParams = @{
                    Module                = '$ProjectName'
                    OutputFolder          = '$HelpSourceLocaleFolder'
                    AlphabeticParamsOrder = `$$AlphabeticParamOrder
                    WithModulePage        = `$$WithModulePage
                    ExcludeDontShow       = `$$ExcludeDontShow
                    Force                 = `$true
                    ErrorAction           = 'Stop'
                    Locale                = '$Locale'
                    HelpVersion           = '$ModuleVersion'
                    Metadata              = $MarkdownHelpMetadataAsString
                }

                New-MarkdownHelp @newMarkdownHelpParams
            }
"@

        Write-Build -Color DarkGray -Text $generateHelpCommands
        $sb = [ScriptBlock]::create($generateHelpCommands)
        Write-Build -Color DarkGray -Text "$sb"

        $pwshPath = (Get-Process -Id $PID).Path
        &$pwshPath -Command $sb -ExecutionPolicy 'ByPass'
    }
}

# Synopsis: Generates the MAML for each Locale found under the Help source folder (i.e. docs/en-US).
Task Generate_MAML_from_markdown_help_source {

    Get-GenerateHelpPlatyPSVariables

    $existingLocaleFolders = (Get-ChildItem -Path $HelpSourceFolder -Directory -ErrorAction 'SilentlyContinue').Name

    # if the docs folder exists, but it has no subfolders, try to find md files directly within docs/
    if ($existingLocaleFolders.count -le 0 -and (Test-Path -Path $HelpSourceFolder))
    {
        Write-Build -Color 'Yellow' -Text "No existing help locale folder found. Trying '$HelpSourceFolder'"
        $existingLocaleFolders = @('')
    }

    foreach ($Locale in $ExistingLocaleFolders)
    {
        $HelpSourceLocaleFolder = Join-Path -Path $HelpSourceFolder -ChildPath $Locale
        Write-Build -Color 'Yellow' -Text "Generating MAML for locale '$Locale' if markdown is present."

        $HelpOutputCultureFolder = Join-Path -Path $HelpOutputVersionFolder -ChildPath $Locale

        $generateHelpCommands = @(
            '$env:PSModulePath = "{0}"' -f $Env:PSModulePath
            'New-ExternalHelp -Path "{0}" -OutputPath "{1}" -Force' -f $HelpSourceLocaleFolder, $HelpOutputCultureFolder
        )

        $sb = [ScriptBlock]::create(($generateHelpCommands -join "`r`n"))
        Write-Build -Color DarkGray -Text "$sb"

        $pwshPath = (Get-Process -Id $PID).Path
        &$pwshPath -Command $sb -ExecutionPolicy 'ByPass'
    }

    if ($CopyHelpMamlToBuiltModuleBase)
    {
        Get-ChildItem -Path $HelpOutputVersionFolder -ErrorAction 'SilentlyContinue' |
            Copy-Item -Recurse -Destination $builtModuleBase -Force
    }
}
