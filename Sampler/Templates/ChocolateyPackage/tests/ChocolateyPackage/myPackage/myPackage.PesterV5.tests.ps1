# Check package XML
#  - packageName is valid (no space, prefer -)
#  - version is valid
#  - URL is valid (PackageSourceUrl, projectUrl, iconUrl, licenseUrl, docsUrl, bugTrackerUrl)
#  - validate dependencies (otpional)
#  - If the chocolatey*ps1 use Get-UninstallRegistryKey or Get-PP... validate that choco extension 1.1.0 is present
#  - validate the files that get packaged
