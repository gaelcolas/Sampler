
[CmdletBinding()]
param(

    [String]$DependencyFile = 'RequiredModules.psd1',

    # Path for PSDepend to be bootstrapped and save other dependencies.
    # Can also be CurrentUser or AllUsers if you wish to install the modules in such scope
    # Default to $PWD.Path/output/modules
    $PSDependTarget = (Join-Path $PWD.path './output/modules'),

    # URI to use for Proxy when attempting to Bootstrap PackageProvider & PowerShellGet
    [uri]$Proxy,

    # Credential to contact the Proxy when provided
    [pscredential]$ProxyCredential,

    # Scope to bootstrap the PackageProvider and PSGet if not available
    [ValidateSet('CurrentUser', 'AllUsers')]
    $Scope = 'CurrentUser',

    # Gallery to use when bootstrapping PackageProvider, PSGet and when calling PSDepend (can be overriden in Dependency files)
    [String]$Gallery = 'PSGallery',

    # Credentials to use with the Gallery specified above
    [Parameter()]
    [PSCredential]$GalleryCredential,


    # Allow you to use a locally installed version of PowerShellGet older than 1.6.0 (not recommended, default to $False)
    [switch]$AllowOldPowerShellGetModule,

    # Allow you to specify a minimum version fo PSDepend, if you're after specific features.
    [String]$MinimumPSDependVersion,

    [Switch]$AllowPrerelease
)

Write-Progress -Activity "Bootstrap:" -PercentComplete 0 -CurrentOperation "NuGet Bootstrap"

if (!(Get-PackageProvider -Name NuGet -ForceBootstrap -ErrorAction SilentlyContinue)) {
    $providerBootstrapParams = @{
        Name           = 'nuget'
        force          = $true
        ForceBootstrap = $true
        ErrorAction    = 'Stop'
    }

    switch ($PSBoundParameters.Keys) {
        'Proxy' { $providerBootstrapParams.Add('Proxy', $Proxy) }
        'ProxyCredential' { $providerBootstrapParams.Add('ProxyCredential', $ProxyCredential) }
        'Scope' { $providerBootstrapParams.Add('Scope', $Scope) }
    }

    if($AllowPrerelease) {
        $providerBootstrapParams.Add('AllowPrerelease',$true)
    }

    Write-Information "Bootstrap: Installing NuGet Package Provider from the web (Make sure Microsoft addresses/ranges are allowed)"
    $null = Install-PackageProvider @providerBootstrapParams
    $latestNuGetVersion = (Get-PackageProvider -Name NuGet -ListAvailable | Select-Object -First 1).Version.ToString()
    Write-Information "Bootstrap: Importing NuGet Package Provider version $latestNuGetVersion to current session."
    $Null = Import-PackageProvider -Name NuGet -RequiredVersion $latestNuGetVersion -Force
}

Write-Progress -Activity "Bootstrap:" -PercentComplete 10 -CurrentOperation "Ensuring Gallery $Gallery is trusted"

# Fail if the given PSGallery is not Registered
$Policy = (Get-PSRepository $Gallery -ErrorAction Stop).InstallationPolicy
Set-PSRepository -Name $Gallery -InstallationPolicy Trusted -ErrorAction Ignore

Write-Progress -Activity "Bootstrap:" -PercentComplete 25 -CurrentOperation "Checking PowerShellGet"
# Ensure the module is loaded and retrieve the version you have
$PowerShellGetVersion = (Import-Module PowerShellGet -PassThru -ErrorAction SilentlyContinue).Version

Write-Verbose "Bootstrap: The PowerShellGet version is $PowerShellGetVersion"
# Versions below 1.6.0 are considered old, unreliable & not recommended
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
        'Proxy' { $InstallPSGetParam.Add('Proxy', $Proxy) }
        'ProxyCredential' { $InstallPSGetParam.Add('ProxyCredential', $ProxyCredential) }
        'GalleryCredential' { $InstallPSGetParam.Add('Credential', $GalleryCredential)}
    }

    Install-Module @InstallPSGetParam
    Remove-Module PowerShellGet -force -ErrorAction SilentlyContinue
    Import-Module PowerShellGet -Force
    $NewLoadedVersion = (Get-Module PowerShellGet).Version.ToString()
    Write-Information "Bootstrap: PowerShellGet version loaded is $NewLoadedVersion"
    Write-Progress -Activity "Bootstrap:" -PercentComplete 60 -CurrentOperation "Installing newer version of PowerShellGet"
}

# Try to import the PSDepend module from the available modules
try {
    $ImportPSDependParam = @{
        Name        = 'PSDepend'
        ErrorAction = 'Stop'
        Force       = $true
    }

    if ($MinimumPSDependVersion) {
        $ImportPSDependParam.add('MinimumVersion', $MinimumPSDependVersion)
    }
    $null = Import-Module @ImportPSDependParam
}
catch {
    # PSDepend module not found, installing or saving it
    if ($PSDependTarget -in 'CurrentUser', 'AllUsers') {
        Write-Debug "PSDepend module not found. Attempting to install from Gallery $Gallery"
        Write-Verbose "Installing PSDepend in $PSDependTarget Scope"
        $InstallPSdependParam = @{
            Name               = 'PSDepend'
            Repository         = $Gallery
            Force              = $true
            Scope              = $PSDependTarget
            SkipPublisherCheck = $true
            AllowClobber       = $true
        }

        if ($MinimumPSDependVersion) {
            $InstallPSdependParam.add('MinimumVersion', $MinimumPSDependVersion)
        }

        Write-Progress -Activity "Bootstrap:" -PercentComplete 75 -CurrentOperation "Installing PSDepend from $Gallery"
        Install-Module @InstallPSdependParam
    }
    else {
        Write-Debug "PSDepend module not found. Attempting to Save from Gallery $Gallery to $PSDependTarget"
        $SaveModuelParam = @{
            Name       = 'PSDepend'
            Repository = $Gallery
            Path       = $PSDependTarget
        }

        if ($MinimumPSDependVersion) {
            $SaveModuelParam.add('MinimumVersion', $MinimumPSDependVersion)
        }

        Write-Progress -Activity "Bootstrap:" -PercentComplete 75 -CurrentOperation "Saving & Importing PSDepend from $Gallery to $Scope"
        Save-Module @SaveModuelParam
    }
}
finally {
    Write-Progress -Activity "Bootstrap:" -PercentComplete 100 -CurrentOperation "Loading PSDepend"
    # We should have successfully bootstrapped PSDepend. Fail if not available
    Import-Module PSDepend -ErrorAction Stop
}

Write-Progress -Activity "PSDepend:" -PercentComplete 0 -CurrentOperation "Restoring Build Dependencies"
if (Test-Path $DependencyFile) {
    $PSDependParams = @{
        Force = $true
        Path  = $DependencyFile
    }

    if ($PSDependTarget) {
        $PSDependParams.add('Target', $PSDependTarget)
    }

    Invoke-PSDepend @PSDependParams
}
Write-Progress -Activity "PSDepend:" -PercentComplete 100 -CurrentOperation "Dependencies restored" -Completed

# Reverting the Installation Policy for the given gallery
Set-PSRepository -Name $Gallery -InstallationPolicy $Policy
Write-Verbose "Project Bootstrapped, returning to Invoke-Build"
