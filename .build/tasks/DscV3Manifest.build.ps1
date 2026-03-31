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
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

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

# Synopsis: Build DSC v3 resource manifests using DscSchemaGenerator
Task Build_DscV3_Manifests {
    # Get the values for task variables
    . Set-SamplerTaskVariable

    # Get DscV3Manifest configuration from build.yaml
    $dscManifestConfig = $BuildInfo.DscV3Manifest

    if (-not $dscManifestConfig)
    {
        Write-Build DarkGray 'No DscV3Manifest configuration found in build.yaml. Skipping DSC manifest generation.'
        return
    }

    # Import the DSCSchemaGenerator module
    Import-Module -Name DSCSchemaGenerator -ErrorAction Stop

    # Determine paths
    $builtModulePath = Join-Path -Path $BuildModuleOutput -ChildPath $ProjectName
    if ($ModuleVersion)
    {
        $builtModulePath = Join-Path -Path $builtModulePath -ChildPath $ModuleVersion
    }

    # Get configuration options
    $resourceTypePrefix = $dscManifestConfig.ResourceTypePrefix
    if (-not $resourceTypePrefix)
    {
        $resourceTypePrefix = ''
    }

    $manifestVersion = $dscManifestConfig.Version
    if (-not $manifestVersion)
    {
        $manifestVersion = $ModuleVersion
    }
    if (-not $manifestVersion)
    {
        $manifestVersion = '0.0.1'
    }

    $tags = $dscManifestConfig.Tags
    if (-not $tags)
    {
        $tags = @()
    }

    # Get return type configuration for set and test operations
    $setReturns = $dscManifestConfig.SetReturns
    if (-not $setReturns)
    {
        $setReturns = 'state'
    }

    $testReturns = $dscManifestConfig.TestReturns
    if (-not $testReturns)
    {
        $testReturns = 'state'
    }

    # Find the module manifest file
    $moduleManifestPath = Join-Path -Path $builtModulePath -ChildPath "$ProjectName.psd1"
    if (-not (Test-Path -Path $moduleManifestPath))
    {
        Write-Build Red "Module manifest not found: $moduleManifestPath"
        return
    }

    # Find the module script module file
    $moduleScriptPath = Join-Path -Path $builtModulePath -ChildPath "$ProjectName.psm1"
    if (-not (Test-Path -Path $moduleScriptPath))
    {
        Write-Build Red "Module script not found: $moduleScriptPath"
        return
    }

    Write-Build Green "`n`tGenerating DSC v3 Manifests"
    Write-Build DarkGray "`t  Built Module Path    : $builtModulePath"
    Write-Build DarkGray "`t  Resource Type Prefix : $resourceTypePrefix"
    Write-Build DarkGray "`t  Manifest Version     : $manifestVersion"
    Write-Build DarkGray "`t  Set Returns          : $setReturns"
    Write-Build DarkGray "`t  Test Returns         : $testReturns"
    Write-Build DarkGray "`t------------------------------------------------`r`n"

    # Get DSC resources from configuration or discover from Classes folder
    $resources = $dscManifestConfig.Resources
    if (-not $resources -or $resources.Count -eq 0)
    {
        # Discover resources from Classes folder
        $classesPath = Join-Path -Path $SourcePath -ChildPath 'Classes'
        if (Test-Path -Path $classesPath)
        {
            $classFiles = Get-ChildItem -Path $classesPath -Filter '*.ps1' -ErrorAction SilentlyContinue
            $resources = @()
            foreach ($classFile in $classFiles)
            {
                # Parse the file using AST to get the actual class name
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($classFile.FullName, [ref]$null, [ref]$null)

                # Find class definitions with [DscResource()] attribute
                $classDefinitions = $ast.FindAll({
                    param($node)
                    $node -is [System.Management.Automation.Language.TypeDefinitionAst] -and
                    $node.IsClass -and
                    $node.Attributes.TypeName.Name -contains 'DscResource'
                }, $true)

                foreach ($classDef in $classDefinitions)
                {
                    $resources += @{
                        Name = $classDef.Name
                        ClassFile = $classFile.Name
                    }
                }
            }
        }
    }

    if (-not $resources -or $resources.Count -eq 0)
    {
        Write-Build Yellow "No DSC resources found to process. Skipping DSC manifest generation."
        return
    }

    # Check for resource.ps1 in module root
    $resourceScript = Join-Path -Path $builtModulePath -ChildPath 'resource.ps1'
    $hasRootResourceScript = Test-Path -Path $resourceScript

    if (-not $hasRootResourceScript)
    {
        Write-Build Yellow "Warning: No resource.ps1 found in module root. DSC v3 operations may not function correctly."
    }

    foreach ($resource in $resources)
    {
        $resourceName = if ($resource -is [hashtable]) { $resource.Name } else { $resource }
        Write-Build Magenta "`tProcessing resource: $resourceName"

        try
        {
            # Calculate the script path for the manifest
            $scriptPath = './resource.ps1'

            # Find the class file
            $classFilePath = Join-Path -Path $builtModulePath -ChildPath "Classes/$resourceName.ps1"

            # Output manifest to module root (next to resource.ps1)
            $manifestPath = Join-Path -Path $builtModulePath -ChildPath "$resourceName.dsc.resource.json"

            if (Test-Path -Path $classFilePath)
            {
                Write-Build DarkGray "`t  Generating manifest from class file: $classFilePath"

                $manifestParams = @{
                    ScriptFile         = $classFilePath
                    ResourceName       = $resourceName
                    OutputPath         = $manifestPath
                    ResourceTypePrefix = $resourceTypePrefix
                    Version            = $manifestVersion
                    ScriptPath         = $scriptPath
                    SetReturn          = $setReturns
                    TestReturn         = $testReturns
                }

                if ($tags.Count -gt 0)
                {
                    $manifestParams['Tags'] = $tags
                }

                New-DscManifestFromFile @manifestParams

                if (-not (Test-Path -Path $manifestPath))
                {
                    throw "Manifest file was not created: $manifestPath"
                }

                Write-Build Green "`t  Created manifest: $manifestPath"
            }
            else
            {
                # Try using the main module file
                Write-Build DarkGray "`t  Generating manifest from module: $moduleScriptPath"

                $manifestParams = @{
                    ModuleFile         = $moduleScriptPath
                    ResourceName       = $resourceName
                    OutputPath         = $manifestPath
                    ResourceTypePrefix = $resourceTypePrefix
                    Version            = $manifestVersion
                    ScriptPath         = $scriptPath
                    SetReturn          = $setReturns
                    TestReturn         = $testReturns
                }

                if ($tags.Count -gt 0)
                {
                    $manifestParams['Tags'] = $tags
                }

                New-DscManifestFromFile @manifestParams

                if (-not (Test-Path $manifestPath))
                {
                    throw "Manifest file was not created: $manifestPath"
                }

                Write-Build Green "`t  Created manifest: $manifestPath"
            }
        }
        catch
        {
            Write-Build Red "`t  Error generating manifest for $resourceName : $_"
        }
    }

    Write-Build Green "`n`tDSC v3 Manifest generation complete"
}
