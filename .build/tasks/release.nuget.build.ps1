param(
    # Base directory of all output (default to 'output')
    [string]$OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

    $ChangelogPath = (property ChangelogPath 'CHANGELOG.md'),

    [string]
    $ProjectName = (property ProjectName $(
            #Find the module manifest to deduce the Project Name
            (Get-ChildItem $BuildRoot\*\*.psd1 | Where-Object {
                    ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
                    $(try {
                            Test-ModuleManifest $_.FullName -ErrorAction Stop
                        }
                        catch {
                            $false
                        }) }
            ).BaseName
        )
    ),

    [string]
    $ModuleVersion = (property ModuleVersion $(
            try {
                (gitversion | ConvertFrom-Json -ErrorAction Stop).InformationalVersion
            }
            catch {
                Write-Verbose "Error attempting to use GitVersion $($_)"
                ''
            }
        )),

    [string]
    # retrieves from Environment variable
    $GitHubToken = (property GitHubToken ''),

    [string]
    $GalleryApiToken = (property GalleryApiToken ''),

    [string]
    $NuGetPublishSource = (property NuGetPublishSource 'https://www.powershellgallery.com/')
)

task publish_nupkg_to_gallery -if ((Get-Command nuget) -and $GalleryApiToken) {
    if ([String]::IsNullOrEmpty($ModuleVersion)) {
        $ModuleInfo = Import-PowerShellDataFile "$OutputDirectory/$ProjectName/*/$ProjectName.psd1" -ErrorAction Stop
        if ($ModuleInfo.PrivateData.PSData.Prerelease) {
            $ModuleVersion = $ModuleInfo.ModuleVersion + "-" + $ModuleInfo.PrivateData.PSData.Prerelease
        }
        else {
            $ModuleVersion = $ModuleInfo.ModuleVersion
        }
    }
    else {
        # Remove metadata from ModuleVersion
        $ModuleVersion, $BuildMetadata = $ModuleVersion -split '\+', 2
        # Remove Prerelease tag from ModuleVersionFolder
        $ModuleVersionFolder, $PreReleaseTag = $ModuleVersion -split '\-', 2
    }

    # find Module's nupkg
    $PackageToRelease = Get-ChildItem (Join-Path $OutputDirectory "$ProjectName.$PSModuleVersion.nupkg")
    $ReleaseTag = "v$PSModuleVersion"

    Write-Build DarkGray "About to release $PackageToRelease"
    $response = &nuget push $PackageToRelease -source $nugetPublishSource -ApiKey $GalleryApiToken
    Write-Build Green $response
}
