task GitVersion -if (Get-Command -Name dotnet-gitversion.exe, gitversion.exe -ErrorAction SilentlyContinue) {

    $command = if (Get-Command -Name gitversion.exe -ErrorAction SilentlyContinue)
    {
        Write-Host 'Using gitversion.exe...'
        'gitversion.exe'
    }
    elseif (Get-Command -Name dotnet-gitversion -ErrorAction SilentlyContinue)
    {
        Write-Host 'Using dotnet-gitversion...'
        'dotnet-gitversion'
    }
    else
    {
        Write-Error 'Neither gitversion.exe nor dotnet-gitversion is available.'
        return
    }

    $gitVersionObject = & $command
    Write-Host -------------- GitVersion Outout --------------
    $gitVersionObject | Write-Host
    Write-Host -----------------------------------------------

    $gitVersionObject = $gitVersionObject | ConvertFrom-Json
    $longestKeyLength = ($gitVersionObject | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Sort-Object { $_.Length } | Select-Object -Last 1).Length
    $gitVersionObject.PSObject.Properties.ForEach{
        Write-Host -Object ("Setting Task Variable {0,-$longestKeyLength} with value '{1}'." -f $_.Name, $_.Value)
    }

    $isPreRelease = [bool]$gitVersionObject.PreReleaseLabel
    $versionElements = $gitVersionObject.MajorMinorPatch

    if ($isPreRelease)
    {
        if ($gitVersionObject.BranchName -eq 'main')
        {
            $nextPreReleaseNumber = $gitVersionObject.PreReleaseNumber
            $paddedNextPreReleaseNumber = '{0:D4}' -f $nextPreReleaseNumber

            $versionElements += $gitVersionObject.PreReleaseLabelWithDash
            $versionElements += $paddedNextPreReleaseNumber
        }
        else
        {
            $versionElements += $gitVersionObject.PreReleaseLabelWithDash
            $versionElements += '.' + $gitVersionObject.CommitsSinceVersionSource
        }
    }

    $versionString = -join $versionElements
    [System.Environment]::SetEnvironmentVariable('ModuleVersion', $versionString, 'Process')

    Write-Host "Writing version string '$versionString' to build / environment variable 'VersionString'."
    Write-Host "##vso[task.setvariable variable=VersionString;]$($versionString)"

    Write-Host "Updating build number to '$versionString'."
    Write-Host "##vso[build.updatebuildnumber]$($versionString)"
}
