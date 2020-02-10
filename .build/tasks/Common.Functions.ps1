function Convert-HashtableToString
{
    param
    (
        [Parameter()]
        [System.Collections.Hashtable]
        $Hashtable
    )
    $values = @()
    foreach ($pair in $Hashtable.GetEnumerator())
    {
        if ($pair.Value -is [System.Array])
        {
            $str = "$($pair.Key)=($($pair.Value -join ","))"
        }
        elseif ($pair.Value -is [System.Collections.Hashtable])
        {
            $str = "$($pair.Key)={$(Convert-HashtableToString -Hashtable $pair.Value)}"
        }
        else
        {
            $str = "$($pair.Key)=$($pair.Value)"
        }
        $values += $str
    }

    [array]::Sort($values)
    return ($values -join "; ")
}

function Get-CodeCoverageThreshold
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.String]
        $CodeCoverageThreshold,

        [Parameter()]
        [PSObject]
        $BuildInfo
    )

    # If no codeCoverageThreshold configured at runtime, look for BuildInfo settings.
    if ($CodeCoverageThreshold -eq '')
    {
        if ($BuildInfo.ContainsKey('Pester') -and $BuildInfo.Pester.ContainsKey('CodeCoverageThreshold'))
        {
            $CodeCoverageThreshold = $BuildInfo.Pester.CodeCoverageThreshold
            Write-Debug -Message "Loaded Code Coverage Threshold from Config file: $CodeCoverageThreshold %."
        }
        else
        {
            $CodeCoverageThreshold = 0
            Write-Debug -Message "No code coverage threshold value found (param nor config), using the default value."
        }
    }
    else
    {
        $CodeCoverageThreshold = [int] $CodeCoverageThreshold
        Write-Debug -Message "Loading CodeCoverage Threshold from Parameter ($CodeCoverageThreshold %)."
    }

    return $CodeCoverageThreshold
}

function Get-ModuleVersion
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.String]
        $OutputDirectory,

        [Parameter()]
        [System.String]
        $ProjectName,

        [Parameter()]
        [System.String]
        $ModuleVersion
    )

    if ([System.String]::IsNullOrEmpty($ModuleVersion))
    {
        $moduleInfo = Import-PowerShellDataFile "$OutputDirectory/$ProjectName/*/$ProjectName.psd1" -ErrorAction 'Stop'

        if ($preReleaseTag = $moduleInfo.PrivateData.PSData.Prerelease)
        {
            $moduleVersion = $moduleInfo.ModuleVersion + "-" + $preReleaseTag
        }
        else
        {
            $moduleVersion = $moduleInfo.ModuleVersion
        }
    }
    else
    {
        <#
            A version sting returned by the CI pipeline can look like this:
            1.15.0-pr0224-0022+Sha.47ae45eb2cfed02b249f239a7c55e5c71b26ab76.Date.2020-01-07
        #>
        $moduleVersion = ($moduleVersion -split '\+', 2)[0]
    }

    return $moduleVersion
}

function Get-OperatingSystemShortName
{
    [CmdletBinding()]
    param ()

    $osShortName = if ($isWindows -or $PSVersionTable.PSVersion.Major -le 5)
    {
        'Windows'
    }
    elseif ($isMacOS)
    {
        'MacOS'
    }
    else
    {
        'Linux'
    }

    return $osShortName
}

function Get-PesterOutputFileFileName
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ProjectName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ModuleVersion,

        [Parameter(Mandatory = $true)]
        [System.String]
        $OsShortName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PowerShellVersion
    )

    return '{0}_v{1}.{2}.{3}.xml' -f $ProjectName, $ModuleVersion, $OsShortName, $PowerShellVersion
}

function Get-CodeCoverageOutputFile
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [PSObject]
        $BuildInfo,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PesterOutputFolder
    )

    if ($BuildInfo.ContainsKey('Pester') -and $BuildInfo.Pester.ContainsKey('CodeCoverageOutputFile'))
    {
        $codeCoverageOutputFile = $executioncontext.invokecommand.expandstring($BuildInfo.Pester.CodeCoverageOutputFile)

        if (-not (Split-Path -IsAbsolute $codeCoverageOutputFile))
        {
            $codeCoverageOutputFile = Join-Path -Path $PesterOutputFolder -ChildPath $codeCoverageOutputFile

            Write-Debug -Message "Absolute path to code coverage output file is $codeCoverageOutputFile."
        }
    }
    else
    {
        $codeCoverageOutputFile = $null
    }

    return $codeCoverageOutputFile
}

function Get-CodeCoverageOutputFileEncoding
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [PSObject]
        $BuildInfo
    )

    if ($BuildInfo.ContainsKey('Pester') -and $BuildInfo.Pester.ContainsKey('CodeCoverageOutputFileEncoding'))
    {
        $codeCoverageOutputFileEncoding = $BuildInfo.Pester.CodeCoverageOutputFileEncoding
    }
    else
    {
        $codeCoverageOutputFileEncoding = $null
    }

    return $codeCoverageOutputFileEncoding
}
