
<#
    .SYNOPSIS
        Parse a SemVer2 Version string.

    .DESCRIPTION
        This function parses a SemVer (semver.org) version string into an object
        with the following properties:
        - Version: The version without tag or metadata, as used by folder versioning in PowerShell modules.
        - PreReleaseString: A Publish-Module compliant prerelease tag (see below).
        - ModuleVersion: The Version and Prerelease tag compliant with Publish-Module.

        For instance, this is a valid SemVer: `1.15.0-pr0224-0022+Sha.47ae45eb2cfed02b249f239a7c55e5c71b26ab76.Date.2020-01-07`
        The Metadata is stripped: `1.15.0-pr0224-0022`
        The Version is `1.15.0`.
        The prerelease tag is `-pr0224-0022`
        However, Publish-Module (or NuGet/PSGallery) does not support such pre-release,
        so this function only keep the first part `-pr0224`

    .PARAMETER ModuleVersion
        Full SemVer version string with (optional) metadata and prerelease tag to be parsed.

    .EXAMPLE
        Split-ModuleVersion -ModuleVersion '1.15.0-pr0224-0022+Sha.47ae45eb2cfed02b249f239a7c55e5c71b26ab76.Date.2020-01-07'

        # Version PreReleaseString ModuleVersion
        # ------- ---------------- -------------
        # 1.15.0  pr0224           1.15.0-pr0224

#>
function Split-ModuleVersion
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param
    (
        [Parameter()]
        [System.String]
        $ModuleVersion
    )

    <#
        This handles a previous version of the module that suggested to pass
        a version string with metadata in the CI pipeline that can look like
        this: 1.15.0-pr0224-0022+Sha.47ae45eb2cfed02b249f239a7c55e5c71b26ab76.Date.2020-01-07
    #>
    $ModuleVersion = ($ModuleVersion -split '\+', 2)[0]

    $moduleVersion, $preReleaseString = $ModuleVersion -split '-', 2

    <#
        The cmldet Publish-Module does not yet support semver compliant
        pre-release strings. If the prerelease string contains a dash ('-')
        then the dash and everything behind is removed. For example
        'pr54-0012' is parsed to 'pr54'.
    #>
    $validPreReleaseString, $preReleaseStringSuffix = $preReleaseString -split '-'

    if ($validPreReleaseString)
    {
        $fullModuleVersion =  $moduleVersion + '-' + $validPreReleaseString
    }
    else
    {
        $fullModuleVersion =  $moduleVersion
    }

    $moduleVersionParts = [PSCustomObject]@{
        Version          = $moduleVersion
        PreReleaseString = $validPreReleaseString
        ModuleVersion    = $fullModuleVersion
    }

    return $moduleVersionParts
}
