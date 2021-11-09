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
    $ModuleVersion = (property ModuleVersion ''),

    [Parameter()]
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)

# SYNOPSIS: Building the Azure Policy Guest Configuration Packages
task build_guestconfiguration_packages {
    # Get the vales for task variables, see https://github.com/gaelcolas/Sampler#task-variables.
    . Set-SamplerTaskVariable -AsNewBuild

    if (-not (Split-Path -IsAbsolute $GCPackagesPath))
    {
        $GCPackagesPath = Join-Path -Path $SourcePath -ChildPath $GCPackagesPath
    }

    if (-not (Split-Path -IsAbsolute $GCPoliciesPath))
    {
        $GCPoliciesPath = Join-Path -Path $SourcePath -ChildPath $GCPoliciesPath
    }

    "`tBuild Module Output  = $BuildModuleOutput"
    "`tGC Packages Path     = $GCPackagesPath"
    "`tGC Policies Path     = $GCPoliciesPath"
    "`t------------------------------------------------`r`n"

    Get-ChildItem -Path $GCPackagesPath -Directory -ErrorAction SilentlyContinue | ForEach-Object -Process {
        "`t`tPackaging Policy '$($_.Name)'"
        $GCPackageName = $_.Name
        $ConfigurationFile = Join-Path -Path $_.FullName -ChildPath ('{0}.config.ps1' -f $GCPackageName)
        $newPackageParamsFile = Join-Path -Path $_.FullName -ChildPath ('{0}.psd1' -f $GCPackageName)
        $MOFFile = Join-Path -Path $_.FullName -ChildPath ('{0}.mof' -f $GCPackageName)

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
                        # If the MOF name is localhost.mof, mv to PackageName.mof
                        $_
                    }
                    else
                    {
                        $CompilationErrors += $_
                    }
                }

                if ((Split-Path -Leaf $MOFFile -ErrorAction 'SilentlyContinue') -eq 'localhost.mof')
                {
                    $destinationMof = Join-Path -Path (Join-Path -Path $OutputDirectory -ChildPath 'MOFs') -ChildPath ('{0}.mof' -f $GCPackageName)
                    $null = Move-Item -Path $MOFFile -Destination $destinationMof -Force -ErrorAction Stop
                    $MOFFile = $destinationMof
                }
            }
            catch
            {
                throw "Compilation error. $($_.Exception.Message)"
            }
        }

        if (Test-Path -Path $newPackageParamsFile)
        {
            $newPackageExtraParams = Import-PowerShellDataFile -Path $newPackageParamsFile -ErrorAction 'Stop'
        }
        else
        {
            $newPackageExtraParams = @{}
        }

        $ZippedGCPackage = (
            &{
                $NewGCPackageParams = @{
                    Configuration = $MOFFile
                    Name          = $GCPackageName
                    Path          = (Join-Path -Path $OutputDirectory -ChildPath 'GCPolicyPackages')
                    Force         = $true
                }

                foreach ($paramName in (Get-Command -Name 'New-GuestConfigurationPackage').Parameters.Keys)
                {
                    # Override the Parameters from the $GCPackageName.psd1
                    $NewGCPackageParams[$paramName] = $newPackageExtraParams[$paramName]
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
            # We ought to test the the package on a purpose-built vm (i.e. with TK)
            Test-GuestConfigurationPackage -Path $ZippedGCPackage.Path -Verbose
        }
        else
        {
            Write-Warning -Message "Testing the Package will fail on Linux or if not running elevated on Windows. Skipping."
        }
    }
}

task gcpack clean,build,build_guestconfiguration_packages
