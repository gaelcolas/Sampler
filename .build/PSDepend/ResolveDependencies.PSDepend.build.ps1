Param (
    [String[]]
    $GalleryRepository = (property GalleryRepository 'PSGallery'), #propagate the property if set, or use default

    [uri]
    $GalleryProxy = $(try { property GalleryProxy } catch { }), #propagate or use $null

    [pscredential]
    $GalleryPSCredential = $(try { property GalleryPSCredential } catch { }), #propagate or use $null

    [string]
    $Dependency = $(try { property Dependency } catch { '.\Dependencies.psd1' }), #propagate or use $null

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

    Install-Module @installModuleParams
} 

task ResolveDependencies InstallPSDepend, {
    $LineSeparation
    Invoke-PSDepend $Dependency -Force   
}

task ResolveTasksModuleDependencies {
    #look at each tasks' `#require -Modules` statements
    # Download the module if not present
}