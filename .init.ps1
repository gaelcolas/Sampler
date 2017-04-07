Param (
    [switch]
    $NoBuild,

    [String]
    $BuildOutput = "$PSScriptRoot\BuildOutput",

    [String]
    $DependencyTarget = $BuildOutput
)
#Worth noting InvokeBuild supports to attach the Invoke-build.ps1 file in the repo, dot source it and use Invoke-Build alias



# Grab nuget bits, install modules, set build variables, start build.
if (!(Get-PackageProvider -Name NuGet -ForceBootstrap)) {
    $null = Install-PackageProvider nuget -force -ForceBootstrap
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
}

Save-Module InvokeBuild -Force -ErrorAction Stop -Path $DependencyTarget

#If there's a .build.configuration.json or .build.configuration.psd1 in the current folder,
#  load and create a parameter hashtable for Invoke-Build
#else, 
#  Call Invoke-Build without params
<#
if (!$NoBuild) {
    Push-Location -Path $PSScriptRoot
    Invoke-Build
}
#>