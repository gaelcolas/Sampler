Param (
    [switch]
    $NoBuild
)
# Grab nuget bits, install modules, set build variables, start build.
if (!Get-PackageProvider -Name NuGet -ForceBootstrap) {
    $null = install-packageprovider nuget -force -ForceBootstrap
    #Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
}

Install-Module InvokeBuild -Force -ErrorAction Stop

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