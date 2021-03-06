param
(
    [Parameter()]
    [System.String]
    $ProjectName = (property ProjectName ''),

    [Parameter()]
    [System.String]
    $SourcePath = (property SourcePath ''),

    [Parameter()]
    [System.String]
    $GCPackagesPath = (property GCPackagesPath 'GCPackages'),

    [Parameter()]
    [System.String]
    $GCPoliciesPath = (property GCPoliciesPath 'GCPolicies'),

    [Parameter()]
    [System.String]
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot "output")),

    [Parameter()]
    [System.String]
    $BuiltModuleSubdirectory = (property BuiltModuleSubdirectory ''),

    [Parameter()]
    [System.String]
    $BuildModuleOutput = (property BuildModuleOutput (Join-Path $OutputDirectory $BuiltModuleSubdirectory)),

    [Parameter()]
    [System.String]
    $ReleaseNotesPath = (property ReleaseNotesPath (Join-Path $OutputDirectory 'ReleaseNotes.md')),

    [Parameter()]
    [System.String]
    $ModuleVersion = (property ModuleVersion ''),

    [Parameter()]
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)

# SYNOPSIS: Building the Azure Policy Guest Configuration Packages
task build_guestconfiguration_packages {
    if ([System.String]::IsNullOrEmpty($ProjectName))
    {
        $ProjectName = Get-ProjectName -BuildRoot $BuildRoot
    }

    if ([System.String]::IsNullOrEmpty($SourcePath))
    {
        $SourcePath = Get-SourcePath -BuildRoot $BuildRoot
    }

    if (-not (Split-Path -IsAbsolute $GCPackagesPath))
    {
        $GCPackagesPath = Join-Path -Path $SourcePath -ChildPath $GCPackagesPath
    }

    if (-not (Split-Path -IsAbsolute $GCPoliciesPath))
    {
        $GCPoliciesPath = Join-Path -Path $SourcePath -ChildPath $GCPoliciesPath
    }

    $moduleManifestPath = "$SourcePath/$ProjectName.psd1"

    $getBuildVersionParameters = @{
        ModuleManifestPath = $moduleManifestPath
        ModuleVersion      = $ModuleVersion
    }

    <#
        This will get the version from $ModuleVersion if is was set as a parameter
        or as a property. If $ModuleVersion is $null or an empty string the version
        will fetched from GitVersion if it is installed. If GitVersion is _not_
        installed the version is fetched from the module manifest in SourcePath.
    #>
    $ModuleVersion = Get-BuildVersion @getBuildVersionParameters

    "`tProject Name         = $ProjectName"
    "`tModule Version       = $ModuleVersion"
    "`tSource Path          = $SourcePath"
    "`tOutput Directory     = $OutputDirectory"
    "`tBuild Module Output  = $BuildModuleOutput"
    "`tModule Manifest Path = $moduleManifestPath"
    "`tGC Packages Path     = $GCPackagesPath"
    "`t------------------------------------------------`r`n"

    Get-ChildItem -Path $GCPackagesPath -Directory -ErrorAction SilentlyContinue | ForEach-Object -Process {
        "`t`tPackaging Policy '$($_.Name)'"
        $GCPackageName = $_.Name
        $ConfigurationFile = Join-Path -Path $_.FullName -ChildPath "$GCPackageName.config.ps1"
        $MOFFile = Join-Path -Path $_.FullName -ChildPath "$GCPackageName.mof"

        if (-not (Test-Path -Path $ConfigurationFile) -and -not (Test-Path -Path $MOFFile))
        {
            throw "The configuration '$ConfigurationFile' could not be found. Cannot compile MOF for '$GCPackageName' policy Package"
        }

        if (Test-Path -Path $MOFFile)
        {
            "`t`tCreating GC Package from MOF file: '$MOFFile'"
        }
        else
        {
            "`t`tCreating GC Package from Configuration file: '$ConfigurationFile'"
            try
            {
                $MOFFileAndErrors = &{
                    . $ConfigurationFile
                    &$GCPackageName -OutputPath (Join-Path -Path $OutputDirectory -ChildPath 'MOFs') -ErrorAction SilentlyContinue
                } 2>&1

                $CompilationErrors = @()
                $MOFFile = $MOFFileAndErrors.Foreach{
                    if ($_ -isnot [System.Management.Automation.ErrorRecord])
                    {
                        $_
                    }
                    else
                    {
                        $CompilationErrors += $_
                    }
                }
            }
            catch
            {
                throw "Compilation error. $($_.Exception.Message)"
            }
        }

        $ZippedGCPackage = (
            &{
                $NewGCPackageParams = @{
                    Configuration = $MOFFile
                    Name          = $GCPackageName
                    Path          = (Join-Path -Path $OutputDirectory -ChildPath 'GCPolicyPackages')
                    Force         = $true
                }

                New-GuestConfigurationPackage @NewGCPackageParams
            } 2>&1
        ).Where{
            if ($_ -isnot [System.Management.Automation.ErrorRecord])
            {
                # Filter out the Error records from New-GuestConfigurationPackage
                $true
            }
            elseif ($_.Exception.Message -notmatch '^A second CIM class definition')
            {
                # Write non-terminating errors that are not "A second CIM class definition for .... was found..."
                $false
                Write-Error $_ -ErrorAction Continue
            }
            else
            {
                $false
            }
        }

        "`t`tGuest Config Package creation in progress..."

        if ($ModuleVersion)
        {
            $GCPackageWithVersionZipName = ('{0}_{1}.zip' -f $GCPackageName,$ModuleVersion)
            $GCPackageOutputPath = (Join-Path -Path $OutputDirectory -ChildPath 'GCPolicyPackages')
            $ZippedGCPackagePath = Move-Item -Path $ZippedGCPackage.Path -Destination (Join-Path -Path $GCPackageOutputPath -ChildPath $GCPackageWithVersionZipName) -PassThru
            $ZippedGCPackage = @{
                Name = $ZippedGCPackage.Name
                Path = $ZippedGCPackagePath.FullName
            }
        }

        "`t`tZipped Guest Config Package: $($ZippedGCPackage.Path)"

        # If we're running on Windows as admin, we can test the package
        if (-not $IsLinux -and [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
        {
            # We ought to test the the package on a purposed-built vm (i.e. with TK)
            Test-GuestConfigurationPackage -Path $ZippedGCPackage.Path -Verbose
        }
        else
        {
            Write-Warning -Message "Testing the Package will fail on Linux or if not running elevated on Windows. Skipping."
        }
    }
}

task gcpack clean,build,build_guestconfiguration_packages
