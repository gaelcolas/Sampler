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
    $HelpFolder = (property HelpFolder 'help'),

    [Parameter()]
    [System.String]
    $BuildOutput = (property BuildOutput 'output'),

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
    $HelpCultureInfo = 'en-US'
)

Task Generate_md_help_from_module {
    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-SamplerProjectName -BuildRoot $BuildRoot
    }

    if ([System.String]::IsNullOrEmpty($SourcePath))
    {
        $SourcePath = Get-SamplerSourcePath -BuildRoot $BuildRoot
    }

    $OutputDirectory = Get-SamplerAbsolutePath -Path $OutputDirectory -RelativeTo $BuildRoot
    $PesterOutputFolder = Get-SamplerAbsolutePath -Path $PesterOutputFolder -RelativeTo $OutputDirectory

    "`tProject Name             = '$ProjectName'"
    "`tOutput Directory         = '$OutputDirectory'"
    "`tPester Output Folder     = '$PesterOutputFolder"

    if ($VersionedOutputDirectory)
    {
        # VersionedOutputDirectory is not [bool]'' nor $false nor [bool]$null
        # Assume true, wherever it was set
        $VersionedOutputDirectory = $true
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

    $builtModuleBase = Get-SamplerBuiltModuleBase @GetBuiltModuleManifestParams
    "`tBuilt Module Base        = '$builtModuleBase'"

    $builtModuleManifest = Get-SamplerBuiltModuleManifest @GetBuiltModuleManifestParams
    "`tBuilt Module Manifest    = '$builtModuleManifest'"

    if ($builtModuleRootScriptPath = Get-SamplerModuleRootPath -ModuleManifestPath $builtModuleManifest)
    {
        $builtModuleRootScriptPath = (Get-Item -Path $builtModuleRootScriptPath -ErrorAction SilentlyContinue).FullName
    }

    "`tBuilt ModuleRoot script  = '$builtModuleRootScriptPath'"

    $ModuleVersion = Get-BuiltModuleVersion @GetBuiltModuleManifestParams
    $ModuleVersionObject = Split-ModuleVersion -ModuleVersion $ModuleVersion
    $ModuleVersionFolder = $ModuleVersionObject.Version
    $preReleaseTag       = $ModuleVersionObject.PreReleaseString

    "`tModule Version           = '$ModuleVersion'"
    "`tModule Version Folder    = '$ModuleVersionFolder'"
    "`tPre-release Tag          = '$preReleaseTag'"

    $HelpFolder = Get-SamplerAbsolutePath -Path $HelpFolder -RelativeTo $SourcePath
    "`tHelp Folder Path         = '$HelpFolder'"

    $HelpOutputFolder =  Get-SamplerAbsolutePath -Path $HelpOutputFolder -RelativeTo $OutputDirectory
    "`tHelp output Folder        = '$HelpOutputFolder'"

    $HelpOutputVersionFolder = Get-SamplerAbsolutePath -Path $ModuleVersion -RelativeTo $HelpOutputFolder
    "`tHelp output Version Folder= '$HelpOutputVersionFolder'"

    $HelpOutputCultureFolder = Get-SamplerAbsolutePath -Path $HelpCultureInfo -RelativeTo $HelpOutputVersionFolder
    "`tHelp output Culture path  = '$HelpOutputCultureFolder'"

    $generateHelpCommands = @(
        '$env:PSModulePath = "{0}"' -f $Env:PSModulePath
        'Import-Module -Name "{0}" -Force' -f $ProjectName
        '$newMarkdownHelpParams = @{{ Module = "{0}"; OutputFolder = "{1}"; AlphabeticParamsOrder = ${2}; WithModulePage = ${3}; ExcludeDontShow = ${4}; Force = $true}}' -f $ProjectName, $HelpOutputCultureFolder, $true, $true, $true
        'New-MarkdownHelp @newMarkdownHelpParams'
        'New-ExternalHelp -Path "{0}" -OutputPath "{1}" -Force' -f $HelpFolder, $HelpOutputCultureFolder
    )

    Write-Build -Color DarkGray -Text "$generateHelpCommands"
    $sb = [ScriptBlock]::create(($generateHelpCommands -join "`r`n"))
    Write-Build -Color DarkGray -Text "$sb"

    $pwshPath = (Get-Process -Id $PID).Path
    &$pwshPath -c $sb -ep 'ByPass'
}

Task UpdateHelp {
    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-SamplerProjectName -BuildRoot $BuildRoot
    }

    if ([System.String]::IsNullOrEmpty($SourcePath))
    {
        $SourcePath = Get-SamplerSourcePath -BuildRoot $BuildRoot
    }

    $OutputDirectory = Get-SamplerAbsolutePath -Path $OutputDirectory -RelativeTo $BuildRoot
    $PesterOutputFolder = Get-SamplerAbsolutePath -Path $PesterOutputFolder -RelativeTo $OutputDirectory

    "`tProject Name             = '$ProjectName'"
    "`tOutput Directory         = '$OutputDirectory'"
    "`tPester Output Folder     = '$PesterOutputFolder"

    if ($VersionedOutputDirectory)
    {
        # VersionedOutputDirectory is not [bool]'' nor $false nor [bool]$null
        # Assume true, wherever it was set
        $VersionedOutputDirectory = $true
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

    $builtModuleBase = Get-SamplerBuiltModuleBase @GetBuiltModuleManifestParams
    "`tBuilt Module Base        = '$builtModuleBase'"

    $builtModuleManifest = Get-SamplerBuiltModuleManifest @GetBuiltModuleManifestParams
    "`tBuilt Module Manifest    = '$builtModuleManifest'"

    if ($builtModuleRootScriptPath = Get-SamplerModuleRootPath -ModuleManifestPath $builtModuleManifest)
    {
        $builtModuleRootScriptPath = (Get-Item -Path $builtModuleRootScriptPath -ErrorAction SilentlyContinue).FullName
    }

    "`tBuilt ModuleRoot script  = '$builtModuleRootScriptPath'"

    $ModuleVersion = Get-BuiltModuleVersion @GetBuiltModuleManifestParams
    $ModuleVersionObject = Split-ModuleVersion -ModuleVersion $ModuleVersion
    $ModuleVersionFolder = $ModuleVersionObject.Version
    $preReleaseTag       = $ModuleVersionObject.PreReleaseString

    "`tModule Version           = '$ModuleVersion'"
    "`tModule Version Folder    = '$ModuleVersionFolder'"
    "`tPre-release Tag          = '$preReleaseTag'"

    $HelpFolder = Get-SamplerAbsolutePath -Path $HelpFolder -RelativeTo $SourcePath
    "`tHelp Folder Path         = '$HelpFolder'"

    $generateHelpCommands = @(
        '$env:PSModulePath = "{0}"' -f $Env:PSModulePath
        'Import-Module -Name "{0}" -Force' -f $ProjectName
        'Update-MarkdownHelpModule -Path "{0}" -Force' -f $HelpFolder
    )

    $sb = [ScriptBlock]::create(($generateHelpCommands -join "`r`n"))
    Write-Build -Color DarkGray -Text "$sb"

    $pwshPath = (Get-Process -Id $PID).Path
    &$pwshPath -c $sb -ep 'ByPass'
}

Task Generate_Maml_From_Md {
    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-SamplerProjectName -BuildRoot $BuildRoot
    }

    if ([System.String]::IsNullOrEmpty($SourcePath))
    {
        $SourcePath = Get-SamplerSourcePath -BuildRoot $BuildRoot
    }

    $OutputDirectory = Get-SamplerAbsolutePath -Path $OutputDirectory -RelativeTo $BuildRoot
    $PesterOutputFolder = Get-SamplerAbsolutePath -Path $PesterOutputFolder -RelativeTo $OutputDirectory

    "`tProject Name             = '$ProjectName'"
    "`tOutput Directory         = '$OutputDirectory'"
    "`tPester Output Folder     = '$PesterOutputFolder"

    if ($VersionedOutputDirectory)
    {
        # VersionedOutputDirectory is not [bool]'' nor $false nor [bool]$null
        # Assume true, wherever it was set
        $VersionedOutputDirectory = $true
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

    $builtModuleBase = Get-SamplerBuiltModuleBase @GetBuiltModuleManifestParams
    "`tBuilt Module Base        = '$builtModuleBase'"

    $builtModuleManifest = Get-SamplerBuiltModuleManifest @GetBuiltModuleManifestParams
    "`tBuilt Module Manifest    = '$builtModuleManifest'"

    if ($builtModuleRootScriptPath = Get-SamplerModuleRootPath -ModuleManifestPath $builtModuleManifest)
    {
        $builtModuleRootScriptPath = (Get-Item -Path $builtModuleRootScriptPath -ErrorAction SilentlyContinue).FullName
    }

    "`tBuilt ModuleRoot script  = '$builtModuleRootScriptPath'"

    $ModuleVersion = Get-BuiltModuleVersion @GetBuiltModuleManifestParams
    $ModuleVersionObject = Split-ModuleVersion -ModuleVersion $ModuleVersion
    $ModuleVersionFolder = $ModuleVersionObject.Version
    $preReleaseTag       = $ModuleVersionObject.PreReleaseString

    "`tModule Version           = '$ModuleVersion'"
    "`tModule Version Folder    = '$ModuleVersionFolder'"
    "`tPre-release Tag          = '$preReleaseTag'"

    $HelpFolder = Get-SamplerAbsolutePath -Path $HelpFolder -RelativeTo $SourcePath
    "`tHelp Folder Path         = '$HelpFolder'"

    $HelpOutputFolder =  Get-SamplerAbsolutePath -Path $HelpOutputFolder -RelativeTo $OutputDirectory
    "`tHelp output Folder        = '$HelpOutputFolder'"

    $HelpOutputVersionFolder = Get-SamplerAbsolutePath -Path $ModuleVersion -RelativeTo $HelpOutputFolder
    "`tHelp output Version Folder= '$HelpOutputVersionFolder'"

    $HelpOutputCultureFolder = Get-SamplerAbsolutePath -Path $HelpCultureInfo -RelativeTo $HelpOutputVersionFolder
    "`tHelp output Culture path  = '$HelpOutputCultureFolder'"

    $generateHelpCommands = @(
        '$env:PSModulePath = "{0}"' -f $Env:PSModulePath
        'New-ExternalHelp -Path "{0}" -OutputPath "{1}" -Force' -f $HelpFolder, $HelpOutputCultureFolder
    )

    $sb = [ScriptBlock]::create(($generateHelpCommands -join "`r`n"))
    Write-Build -Color DarkGray -Text "$sb"

    $pwshPath = (Get-Process -Id $PID).Path
    &$pwshPath -c $sb -ep 'ByPass'
    # pwsh -NoProfile -Command $sb
}
