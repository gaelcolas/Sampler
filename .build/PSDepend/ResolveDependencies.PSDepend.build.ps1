Param (
    [String[]]
    $GalleryRepository = (property GalleryRepository 'PSGallery'), #propagate the property if set, or use default

    [uri]
    $GalleryProxy = $(try { property GalleryProxy } catch { }), #propagate or use $null

    [pscredential]
    $GalleryPSCredential = $(try { property GalleryPSCredential } catch { }), #propagate or use $null

    [string]
    $Dependency = (property Dependency '.\Dependencies.psd1'), #propagate or use $null

    [String]
    $DependencyTarget = $(try {property DependencyTarget} catch {$null}),

    [string]
    $LineSeparation = (property LineSeparation ('-' * 78)) 
)

task InstallPSDepend -if {!(Get-Module -ListAvailable PSDepend)} {
    $LineSeparation
    "Installing PSDepends from $GalleryRepository"
    ""
    "`tProxy = $GalleryProxy"
    "`tCredentialUser = $($GalleryPSCredential.UserName)"
    "`tGallery = $GalleryRepository"

    $installModuleParams = @{
        Name = 'PSDepend'
        Repository = @($GalleryRepository)
        force = $true
    }

    if ($GalleryPSCredential) {
        $installModuleParams.Add('Credential',$GalleryPSCredential)
    }

    if (!$DependencyTarget) {
        Install-Module @installModuleParams
    }
    else {
        "Saving module to $DependencyTarget"
        Save-Module @installModuleParams -Path $DependencyTarget
    }
} 

task ResolveDependencies InstallPSDepend, {
    $LineSeparation
    $PSDependParams = @{
        Force = $true
        Path  = $Dependency
    }
    if ($DependencyTarget) {
        $PSDependParams.Add('Target',$DependencyTarget)
    }
    Invoke-PSDepend @PSDependParams
}

task ResolveTasksModuleDependencies {
    #look at each tasks' `#require -Modules` statements
    # Download the module if not present
}