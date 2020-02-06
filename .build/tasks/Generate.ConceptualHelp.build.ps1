param
(
    # Project path
    [Parameter()]
    [string]
    $ProjectPath = (property ProjectPath $BuildRoot),

    [Parameter()]
    # Base directory of all output (default to 'output')
    [string]
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

    [Parameter()]
    [string]
    $ProjectName = (property ProjectName $(
            (
                Get-ChildItem $BuildRoot\*\*.psd1 | Where-Object {
                    ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
                    $(
                        try
                        {
                            Test-ModuleManifest $_.FullName -ErrorAction Stop
                        }
                        catch
                        {
                            $false
                        }
                    )
                }
            ).BaseName
        )
    ),

    [Parameter()]
    [string]
    $ModuleVersion = (property ModuleVersion $(
            try
            {
                (gitversion | ConvertFrom-Json -ErrorAction Stop).InformationalVersion
            }
            catch
            {
                Write-Verbose "Error attempting to use GitVersion $($_), falling back to default of '0.0.1'."
                '0.0.1'
            }
        )),

    # Build Configuration object
    [Parameter()]
    $BuildInfo = (property BuildInfo @{ })
)

# Synopsis: This task generates conceptual help for DSC resources.
task Generate_Conceptual_Help {
    if (-not (Split-Path -IsAbsolute $OutputDirectory))
    {
        $OutputDirectory = Join-Path -Path $ProjectPath -ChildPath $OutputDirectory
    }

    $builtModulePath = Join-Path -Path (Join-Path -Path $OutputDirectory -ChildPath $ProjectName) -ChildPath $ModuleVersion

    #region Get the source folder
    $sourceFolders = 'source|src|{0}' -f (Split-Path -Path $BuildRoot -Leaf)

    $escapedProjectPath = [RegEx]::Escape($ProjectPath)

    $sourcePath = (Get-ChildItem -Path $ProjectPath -Directory).FullName | Where-Object -FilterScript {
        ($_ -replace $escapedProjectPath) -match $sourceFolders
    }
    #endregion

    "`tProject Path            = $ProjectPath"
    "`tProject Name            = $ProjectName"
    "`tModule Version          = $ModuleVersion"
    "`tSource Path             = $sourcePath"
    "`tBuilt Module Path       = $builtModulePath"

    Write-Build Magenta "Generating conceptual help for all DSC resources based on source."

    New-DscResourcePowerShellHelp -ModulePath $sourcePath -DestinationModulePath $builtModulePath
}
