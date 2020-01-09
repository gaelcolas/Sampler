param
(
    # Project path
    [Parameter()]
    [string]
    $ProjectPath = (property ProjectPath $BuildRoot),

    [Parameter()]
    # Base directory of all output (default to 'output')
    [string]
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

    [Parameter()]
    [string]
    $ProjectName = (property ProjectName $(
            (
                Get-ChildItem $BuildRoot\*\*.psd1 | Where-Object {
                    ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
                    $(
                        try
                        {
                            Test-ModuleManifest $_.FullName -ErrorAction Stop
                        }
                        catch
                        {
                            $false
                        }
                    )
                }
            ).BaseName
        )
    ),

    [Parameter()]
    [string]
    $ModuleVersion = (property ModuleVersion $(
            try
            {
                (gitversion | ConvertFrom-Json -ErrorAction Stop).InformationalVersion
            }
            catch
            {
                Write-Verbose "Error attempting to use GitVersion $($_)"
                ''
            }
        )),

    [Parameter()]
    [string]
    $PesterOutputFolder = (property PesterOutputFolder 'testResults'),

    [Parameter()]
    [string]
    $PesterOutputFormat = (property PesterOutputFormat),

    [Parameter()]
    [String]
    $CodeCoverageThreshold = (property CodeCoverageThreshold ''),

    # Build Configuration object
    [Parameter()]
    $BuildInfo = (property BuildInfo @{ })
)

. $PSScriptRoot/Common.Functions.ps1

# Synopsis: This task parses the code coverage file.
task Parse_CodeCoverage {
    $getCodeCoverageThresholdParameters = @{
        CodeCoverageThreshold = $CodeCoverageThreshold
        BuildInfo = $BuildInfo
    }

    $CodeCoverageThreshold = Get-CodeCoverageThreshold @getCodeCoverageThresholdParameters

    if ($CodeCoverageThreshold -eq 0)
    {
        Write-Build Magenta "No code coverage should be gathered. Exiting build step."
        return
    }

    # JaCoCo format is the default, make sure it isn't set to another format.
    if ($BuildInfo.ContainsKey('Pester') -and $BuildInfo.Pester.ContainsKey('CodeCoverageOutputFileFormat'))
    {
        if ($BuildInfo.Pester.CodeCoverageOutputFileFormat -ne 'JaCoCo')
        {
            Write-Build Magenta "Parsing only support the format JaCoCo. Exiting build step."
            return
        }
    }

    if (-not (Split-Path -IsAbsolute $OutputDirectory))
    {
        $OutputDirectory = Join-Path -Path $ProjectPath -ChildPath $OutputDirectory
    }

    if (-not (Split-Path -IsAbsolute $PesterOutputFolder))
    {
        $PesterOutputFolder = Join-Path -Path $OutputDirectory -ChildPath $PesterOutputFolder
    }

    if (-not (Test-Path $PesterOutputFolder))
    {
        throw "Unable to find the folder '$PesterOutputFolder'."
    }

    $getCodeCoverageOutputFile = @{
        BuildInfo = $BuildInfo
        PesterOutputFolder = $PesterOutputFolder
    }

    $CodeCoverageOutputFile = Get-CodeCoverageOutputFile @getCodeCoverageOutputFile

    if (-not $CodeCoverageOutputFile)
    {
        $getModuleVersionParameters = @{
            OutputDirectory = $OutputDirectory
            ProjectName     = $ProjectName
            ModuleVersion   = $ModuleVersion
        }

        $ModuleVersion = Get-ModuleVersion @getModuleVersionParameters
        $osShortName = Get-OperatingSystemShortName
        $powerShellVersion = 'PSv.{0}' -f $PSVersionTable.PSVersion

        $getPesterOutputFileFileNameParameters = @{
            ProjectName = $ProjectName
            ModuleVersion = $ModuleVersion
            OsShortName = $osShortName
            PowerShellVersion = $powerShellVersion
        }

        $PesterOutputFileFileName = Get-PesterOutputFileFileName @getPesterOutputFileFileNameParameters

        $codeCoverageOutputFile = (Join-Path $PesterOutputFolder "CodeCov_$PesterOutputFileFileName")
    }

    "`tProject Path            = $ProjectPath"
    "`tProject Name            = $ProjectName"
    "`tOutputDirectory         = $OutputDirectory"
    "`tPesterOutputFolder      = $PesterOutputFolder"
    "`tCodeCoverageOutputFile  = $codeCoverageOutputFile"

    Write-Build Magenta "Parsing code coverage result file."

    $xmlJaCoCo = Select-Xml -Path $codeCoverageOutputFile -XPath '.'

    Write-Build DarkGray "  Changing to correct path in the XML element 'package'."

    $nodes = $xmlJaCoCo.Node.SelectNodes("/report/package")
    foreach ($node in $nodes)
    {
        $node.SetAttribute('name', ($node.GetAttribute('name') -replace '\d+\.\d+\.\d+', 'source'))
    }

    Write-Build DarkGray "  Changing to correct path in the XML element 'class'."

    $nodes = $xmlJaCoCo.Node.SelectNodes("/report/package/class")
    foreach ($node in $nodes)
    {
        $node.SetAttribute('name', ($node.GetAttribute('name') -replace '\d+\.\d+\.\d+', 'source'))
    }

    Write-Build Yellow "  Adding missing attributes to the XML element 'line'. Workaround for the Pester issue https://github.com/pester/Pester/issues/1419."

    $nodes = $xmlJaCoCo.Node.SelectNodes("/report/package/sourcefile/line")
    foreach ($node in $nodes)
    {
        $node.SetAttribute('mb', 0)
        $node.SetAttribute('cb', 0)
    }

    Write-Build Magenta "Saving parsed code coverage result file."

    $xmlJaCoCo.Node.Save($codeCoverageOutputFile)

    Write-Build Magenta "Changing encoding on the saved file."

    $fileContent = Get-Content -Path $codeCoverageOutputFile -Encoding 'Unicode' -Raw
    $fileContent | Out-File -FilePath $codeCoverageOutputFile -Encoding 'ascii'
}
