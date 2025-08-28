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
    $GCPackagesOutputPath = (property GCPackagesOutputPath 'GCPackages'),

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

# Synopsis: Building the Azure Policy Guest Configuration Packages
task build_guestconfiguration_packages {
    # Get the values for task variables, see https://github.com/gaelcolas/Sampler?tab=readme-ov-file#build-task-variables.
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
        Write-Build Magenta "`r`n`tPackaging Guest Configuration Package '$($_.Name)'"
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
            Write-Build Magenta "`t Creating GC Package from MOF file: '$MOFFile'"
        }
        else
        {
            Write-Build DarkGray "`t Creating GC Package from Configuration file: '$ConfigurationFile'"
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

                $MOFFile = [string]($MOFFile[0]) # ensure it's a single string
                Write-Build White "`t Compiled '$MOFFile'."

                if ((Split-Path -Leaf -Path $MOFFile -ErrorAction 'SilentlyContinue') -eq 'localhost.mof')
                {
                    $destinationMof = Join-Path -Path (Join-Path -Path $OutputDirectory -ChildPath 'MOFs') -ChildPath ('{0}.mof' -f $GCPackageName)
                    Write-Build DarkGray "`t Renaming MOF to '$destinationMof'."
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
            Write-Build DarkGray "`t Using extra parameters from '$newPackageParamsFile'."
        }
        else
        {
            $newPackageExtraParams = @{}
        }

        Write-Verbose -Message "Package Name '$GCPackageName' with Configuration '$MOFFile', OutputDirectory $OutputDirectory, GCPackagesOutputPath '$GCPackagesOutputPath'."
        $GCPackageOutput = Get-SamplerAbsolutePath -Path $GCPackagesOutputPath -RelativeTo $OutputDirectory

        $NewGCPackageParams = @{
            Configuration = [string]$MOFFile
            Name          = $GCPackageName
            Path          = $GCPackageOutput
            Force         = $true
            Version       = $ModuleVersion
            Type          = 'AuditAndSet'
        }

        foreach ($paramName in (Get-Command -Name 'New-GuestConfigurationPackage' -ErrorAction Stop).Parameters.Keys.Where({$_ -in $newPackageExtraParams.Keys}))
        {
            Write-Verbose -Message "`t Testing for parameter '$paramName'."
            Write-Build DarkGray "`t`t Using configured parameter '$paramName' with value '$($newPackageExtraParams[$paramName])'."
            # Override the Parameters from the $GCPackageName.psd1
            $NewGCPackageParams[$paramName] = $newPackageExtraParams[$paramName]
        }

        $ZippedGCPackage = (&{
            New-GuestConfigurationPackage @NewGCPackageParams
        } 2>&1).Where{
            if ($_ -isnot [System.Management.Automation.ErrorRecord])
            {
                # Filter out the Error records from New-GuestConfigurationPackage
                $true
            }
            elseif ($_.Exception.Message -notmatch '^A second CIM class definition')
            {
                # Write non-terminating errors that are not "A second CIM class definition for .... was found..."
                $false
                Write-Error -Message $_ -ErrorAction Continue
            }
            else
            {
                $false
            }
        }

        Write-Build DarkGray "`t Zips created, you may want to delete the unzipped folders under '$GCPackagesOutputPath'..."

        if ($ModuleVersion)
        {
            $GCPackageWithVersionZipName = ('{0}_{1}.zip' -f $GCPackageName,$ModuleVersion)
            $GCPackageOutputPath = Get-SamplerAbsolutePath -Path $GCPackagesOutputPath -RelativeTo $OutputDirectory
            $versionedGCPackageName = Join-Path -Path $GCPackageOutputPath -ChildPath $GCPackageWithVersionZipName
            Write-Build DarkGray "`t Renaming Zip as '$versionedGCPackageName'."
            $ZippedGCPackagePath = Move-Item -Path $ZippedGCPackage.Path -Destination $versionedGCPackageName -Force -PassThru
            $ZippedGCPackage = @{
                Name = $ZippedGCPackage.Name
                Path = $ZippedGCPackagePath.FullName
            }
        }

        Write-Build Green "`tZipped Guest Config Package: $($ZippedGCPackage.Path)"
    }
}

task gcpack clean,build,build_guestconfiguration_packages
