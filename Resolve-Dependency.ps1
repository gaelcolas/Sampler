
[CmdletBinding()]
param(

    [String]$DependencyFile = 'PSDepend.build.psd1',

    $PSDependTarget = './output/modules',

    [uri]
    $Proxy,

    [pscredential]
    $ProxyCredential,

    [ValidateSet("CurrentUser", "AllUsers")]
    $Scope = 'CurrentUser',

    [String]$Gallery = 'PSGallery',

    [Parameter()]
    [PSCredential]$GalleryCredential,

    [switch]$AllowOldPowerShellGetModule,

    [String]$MinimumPSDependVersion,

    [Switch]$AllowPrerelease
)

Write-Progress -Activity "Bootstrap:" -PercentComplete 0 -CurrentOperation "NuGet Bootstrap"

if (!(Get-PackageProvider -Name NuGet -ForceBootstrap -ErrorAction SilentlyContinue)) {
    $providerBootstrapParams = @{
        Name           = 'nuget'
        force          = $true
        ForceBootstrap = $true
    }

    switch ($PSBoundParameters.Keys) {
        'Proxy' { $providerBootstrapParams.Add('Proxy', $Proxy) }
        'ProxyCredential' { $providerBootstrapParams.Add('ProxyCredential', $ProxyCredential) }
        'Scope' { $providerBootstrapParams.Add('Scope', $Scope) }
    }

    Write-Information "Bootstrap: Installing NuGet Package Provider from the web (Make sure Microsoft addresses/ranges are allowed)"
    $null = Install-PackageProvider @providerBootstrapParams
    $latestNuGetVersion = (Get-PackageProvider -Name NuGet -ListAvailable | Select-Object -First 1).Version.ToString()
    Write-Information "Bootstrap: Importing NuGet Package Provider version $latestNuGetVersion to current session."
    $Null = Import-PackageProvider -Name NuGet -RequiredVersion $latestNuGetVersion -Force
}

Write-Progress -Activity "Bootstrap:" -PercentComplete 10 -CurrentOperation "Ensuring Gallery $Gallery is trusted"

$Policy = (Get-PSRepository $Gallery).InstallationPolicy
Set-PSRepository -Name $Gallery -InstallationPolicy Trusted -EA SilentlyContinue

Write-Progress -Activity "Bootstrap:" -PercentComplete 25 -CurrentOperation "Checking PowerShellGet"
# Ensure the module is loaded and retrieve the version you have
$PowerShellGetVersion = (Import-Module PowerShellGet -PassThru -ErrorAction SilentlyContinue).Version

Write-Verbose "Bootstrap: The PowerShellGet version is $PowerShellGetVersion"
if (!$PowerShellGetVersion -or ($PowerShellGetVersion -lt [System.version]'1.6.0' -and !$AllowOldPowerShellGetModule)) {
    Write-Progress -Activity "Bootstrap:" -PercentComplete 40 -CurrentOperation "Installing newer version of PowerShellGet"
    $InstallPSGetParam = @{
        Name               = 'PowerShellGet'
        Force              = $True
        SkipPublisherCheck = $true
        AllowClobber       = $true
        Scope              = $Scope
        Repository         = $Gallery
    }

    switch ($PSBoundParameters.Keys) {
        'Proxy'             { $InstallPSGetParam.Add('Proxy', $Proxy) }
        'ProxyCredential'   { $InstallPSGetParam.Add('ProxyCredential', $ProxyCredential) }
        'GalleryCredential' { $InstallPSGetParam.Add('Credential', $GalleryCredential)}
    }

    Install-Module @InstallPSGetParam
    Remove-Module PowerShellGet -force -ErrorAction SilentlyContinue
    Import-Module PowerShellGet -Force
    $NewLoadedVersion = (Get-Module PowerShellGet).Version.ToString()
    Write-Information "Bootstrap: PowerShellGet version loaded is $NewLoadedVersion"
    Write-Progress -Activity "Bootstrap:" -PercentComplete 60 -CurrentOperation "Installing newer version of PowerShellGet"
}

try {
    $ImportPSDependParam = @{
        Name        = 'PSDepend'
        ErrorAction = 'Stop'
        Force       = $true
    }

    if($MinimumPSDependVersion) {
        $GetModuleParam.add('MinimumVersion',$MinimumPSDependVersion)
    }
    $null = Import-Module @ImportPSDependParam
}
catch {
    $InstallPSdependParam = @{
        Name               = 'PSDepend'
        Repository         = $Gallery
        Force              = $true
        Scope              = $Scope
        SkipPublisherCheck = $true
        AllowClobber       = $true
    }

    if($MinimumPSDependVersion) {
        $InstallPSdependParam.add('MinimumVersion',$MinimumPSDependVersion)
    }
    Write-Progress -Activity "Bootstrap:" -PercentComplete 75 -CurrentOperation "Installing PSDepend from $Gallery"
    Install-Module @$InstallPSdependParam
}
finally {
    Write-Progress -Activity "Bootstrap:" -PercentComplete 100 -CurrentOperation "Loading PSDepend"
    Import-Module PSDepend -ErrorAction Stop
}

Write-Progress -Activity "PSDepend:" -PercentComplete 0 -CurrentOperation "Restoring Dependencies"
if(Test-Path $DependencyFile) {
    $PSDependParams = @{
        Force = $true
        Path  = $DependencyFile
    }

    if($PSDependTarget) {
        $PSDependParams.add('Target', $PSDependTarget)
    }

    Invoke-PSDepend @PSDependParams
}
Write-Progress -Activity "PSDepend:" -PercentComplete 100 -CurrentOperation "Dependencies restored" -Completed

Set-PSRepository -Name $Gallery -InstallationPolicy $Policy
Write-Verbose "Project Bootstrapped, returning to Invoke-Build"
