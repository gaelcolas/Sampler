# This should not be in this folder but submitted up to PowerShellForGitHub
# That's the goal, but I needed to get moving here first.
#
# Adapted from https://github.com/PowerShell/vscode-powershell/blob/master/tools/GitHubTools.psm1
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
function Publish-GitHubRelease {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]
        $Owner,

        [Parameter(Mandatory)]
        [string]
        $Repository,

        [Parameter(Mandatory)]
        [string]
        $Tag,

        [Parameter(Mandatory)]
        [string]
        $ReleaseName,

        [Parameter(Mandatory)]
        [string]
        $Description,

        [Parameter(Mandatory)]
        [string]
        $GitHubToken,

        [Parameter()]
        [Alias('Branch', 'Commit')]
        [string]
        $Commitish,

        [Parameter()]
        [string[]]
        $AssetPath,

        [Parameter()]
        [switch]
        $Draft,

        [Parameter()]
        [switch]
        $Prerelease
    )

    $restParams = @{
        tag_name   = $Tag
        name       = $ReleaseName
        body       = $Description
        draft      = [bool]$Draft
        prerelease = [bool]$Prerelease
    }

    if ($Commitish) {
        $restParams.target_commitish = $Commitish
    }

    $restBody = ConvertTo-Json -InputObject $restParams
    $uri = "https://api.github.com/repos/$Owner/$Repository/releases"
    $headers = @{
        Accept        = 'application/vnd.github.v3+json'
        Authorization = "token $GitHubToken"
    }

    $response = Invoke-RestMethod -Method Post -Uri $uri -Body $restBody -Headers $headers
    $AddMemberParams = @{
        MemberType = 'NoteProperty'
        Name = 'ReleaseID'
        Value = $response.id
        TypeName = 'GitHub.Release.Created'
        ErrorAction = 'SilentlyContinue'
    }
    $response | Add-Member @AddMemberParams

    if ($AssetPath) {
        $AddGitHubAssetToRelease = @{
            Owner       = $Owner
            Repository  = $Repository
            GitHubToken = $GitHubToken
            AssetPath   = $AssetPath
            ReleaseID   = $response.id
        }
        $null = Add-GitHubAssetToRelease @AddGitHubAssetToRelease

        $GetGitHubReleaseParams = @{
            Owner       = $Owner
            Repository  = $Repository
            ReleaseID   = $response.id
            GitHubToken = $GitHubToken
        }
        $response = Get-GitHubReleaseFromReleaseID @GetGitHubReleaseParams
    }

    return $response
}

function Get-GitHubReleaseFromTagName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Owner,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Repository,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Tag,

        [Parameter(Mandatory)]
        [string]
        $GitHubToken
    )

    $uri = "https://api.github.com/repos/$Owner/$Repository/releases/tags/$Tag"
    $headers = @{
        Accept        = 'application/vnd.github.v3+json'
        Authorization = "token $GitHubToken"
    }

    $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
    $AddMemberParams = @{
        MemberType = 'NoteProperty'
        Name = 'ReleaseID'
        Value = $response.id
        TypeName = 'GitHub.Release'
        ErrorAction = 'SilentlyContinue'
    }
    $response | Add-Member @AddMemberParams

    return $response
}

function Get-GitHubReleaseFromReleaseID {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Owner,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Repository,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $ReleaseID,

        [Parameter(Mandatory)]
        [string]
        $GitHubToken
    )

    $uri = "https://api.github.com/repos/$Owner/$Repository/releases/$ReleaseID"
    $headers = @{
        Accept        = 'application/vnd.github.v3+json'
        Authorization = "token $GitHubToken"
    }

    $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
    $AddMemberParams = @{
        MemberType = 'NoteProperty'
        Name = 'ReleaseID'
        Value = $response.id
        TypeName = 'GitHub.Release'
        ErrorAction = 'SilentlyContinue'
    }
    $response | Add-Member @AddMemberParams

    return $response
}

function Set-GitHubRelease {
    [CmdletBinding(DefaultParameterSetName = 'ByTagName')]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Owner,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Repository,

        [Parameter(Mandatory, ParameterSetName = 'ByTagName', ValueFromPipelineByPropertyName)]
        [string]
        $Tag,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $NewTagName,

        [Parameter(Mandatory, ParameterSetName = 'ByReleaseID', ValueFromPipelineByPropertyName)]
        [string]
        $ReleaseID,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $ReleaseName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $Description,

        [Parameter(Mandatory)]
        [string]
        $GitHubToken,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('Branch', 'Commit')]
        [string]
        $Commitish,

        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]
        $Draft,

        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]
        $Prerelease
    )

    if ($PSCmdlet.ParameterSetName -eq 'ByTagName') {
        $GetReleaseFromTagParams = @{
            ErrorAction = 'Stop'
            Owner       = $Owner
            Repository  = $Repository
            Tag         = $Tag
            GitHubToken = $GitHubToken
        }
        $ReleaseID = (Get-GitHubReleaseFromTagName @GetReleaseFromTagParams).id
    }


    $restParams = @{}
    switch ($PSBoundParameters.keys) {
        'NewTagName'    { $restParams.tag_name   = $NewTagName       }
        'ReleaseName'   { $restParams.name       = $ReleaseName      }
        'Description'   { $restParams.body       = $Description      }
        'Draft'         { $restParams.draft      = [bool]$Draft      }
        'Prerelease'    { $restParams.prerelease = [bool]$Prerelease }
        'Commitish'     { $restParams.target_commitish = $Commitish  }
    }

    $restBody = ConvertTo-Json -InputObject $restParams
    $uri = "https://api.github.com/repos/$Owner/$Repository/releases/$ReleaseID"
    $headers = @{
        Accept        = 'application/vnd.github.v3+json'
        Authorization = "token $GitHubToken"
    }

    $response = Invoke-RestMethod -Method Patch -Uri $uri -Body $restBody -Headers $headers
    $AddMemberParams = @{
        MemberType = 'NoteProperty'
        Name = 'ReleaseID'
        Value = $response.id
        TypeName = 'GitHub.Release'
        ErrorAction = 'SilentlyContinue'
    }
    $response | Add-Member @AddMemberParams

    return $response
}

function Add-GitHubAssetToRelease {
    [CmdletBinding(DefaultParameterSetName = 'ByTagName')]
    [OutputType([PSObject])]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Owner,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Repository,

        [Parameter(Mandatory, ParameterSetName = 'ByTagName', ValueFromPipelineByPropertyName)]
        [string]
        $Tag,

        [Parameter(Mandatory, ParameterSetName = 'ByReleaseID', ValueFromPipelineByPropertyName)]
        [string]
        $ReleaseID,

        [Parameter(Mandatory)]
        [string]
        $GitHubToken,

        [Parameter()]
        [string[]]
        $AssetPath
    )

    if ($PSCmdlet.ParameterSetName -eq 'ByTagName') {
        $GetReleaseFromTagParams = @{
            ErrorAction = 'Stop'
            Owner       = $Owner
            Repository  = $Repository
            Tag         = $Tag
            GitHubToken = $GitHubToken
        }
        $ReleaseID = (Get-GitHubReleaseFromTagName @GetReleaseFromTagParams).id
    }

    $assetBaseUri = "https://uploads.github.com/repos/$Owner/$Repository/releases/$releaseId/assets"
    foreach ($asset in $AssetPath) {
        if (-Not (Split-Path -IsAbsolute $asset)) {
            $asset = Convert-Path $asset -ErrorAction Stop
        }
        $extension = [System.IO.Path]::GetExtension($asset)
        $fileName = [uri]::EscapeDataString([System.IO.Path]::GetFileName($asset))
        $contentType = 'text/plain'
        switch ($extension) {
            { $_ -in '.zip', '.vsix', 'nupkg' } {
                $contentType = 'application/zip'
                break
            }

            '.json' {
                $contentType = 'application/json'
                break
            }
        }

        $assetUri = "${assetBaseUri}?name=$fileName"
        $headers = @{
            Authorization = "token $GitHubToken"
        }
        # This can be very slow, but it does work
        $null = Invoke-RestMethod -Method Post -Uri $assetUri -InFile $asset -ContentType $contentType -Headers $headers
    }

    $GetGitHubReleaseParams = @{
        Owner       = $Owner
        Repository  = $Repository
        ReleaseID   = $ReleaseID
        GitHubToken = $GitHubToken
    }
    $response = Get-GitHubReleaseFromReleaseID @GetGitHubReleaseParams

    return $response
}

# from https://github.com/PowerShell/vscode-powershell/blob/master/tools/GitHubTools.psm1
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
filter GetHumanishRepositoryDetails {
    param(
        [Parameter()]
        [string]
        $RemoteUrl
    )

    if ($RemoteUrl.EndsWith('.git')) {
        $RemoteUrl = $RemoteUrl.Substring(0, $RemoteUrl.Length - 4)
    }
    else {
        $RemoteUrl = $RemoteUrl.Trim('/')
    }

    $lastSlashIdx = $RemoteUrl.LastIndexOf('/')
    $repository = $RemoteUrl.Substring($lastSlashIdx + 1)
    $secondLastSlashIdx = $RemoteUrl.LastIndexOfAny(('/', ':'), $lastSlashIdx - 1)
    $Owner = $RemoteUrl.Substring($secondLastSlashIdx + 1, $lastSlashIdx - $secondLastSlashIdx - 1)

    return @{
        Owner      = $Owner
        Repository = $repository
    }
}

function New-GitHubPullRequest {
    param(
        [Parameter(Mandatory)]
        [string]
        $Branch,

        [Parameter(Mandatory)]
        [string]
        $Title,

        [Parameter(Mandatory)]
        [string]
        $GitHubToken,

        [Parameter(Mandatory)]
        [string]
        $Owner,

        [Parameter(Mandatory)]
        $Repository,

        [Parameter()]
        [string]
        $TargetBranch = 'master',

        [Parameter()]
        [string]
        $Description = '',

        [Parameter()]
        [string]
        $FromOwner
    )

    $uri = "https://api.github.com/repos/$Owner/$Repository/pulls"

    if ($FromOwner -and $FromOwner -ne $Owner) {
        $Branch = "${FromOwner}:${Branch}"
    }

    $body = @{
        title                 = $Title
        body                  = $Description
        head                  = $Branch
        base                  = $TargetBranch
        maintainer_can_modify = $true
    } | ConvertTo-Json

    $headers = @{
        Accept        = 'application/vnd.github.v3+json'
        Authorization = "token $GitHubToken"
    }

    Write-Verbose "Opening new GitHub pull request on '$Owner/$Repository' with title '$Title'"
    $response = Invoke-RestMethod -Method Post -Uri $uri -Body $body -Headers $headers

    return $response
}
