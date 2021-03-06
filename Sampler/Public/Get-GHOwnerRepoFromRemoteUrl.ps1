
# from https://github.com/PowerShell/vscode-powershell/blob/master/tools/GitHubTools.psm1
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
function Get-GHOwnerRepoFromRemoteUrl
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter()]
        [System.String]
        $RemoteUrl
    )

    if ($RemoteUrl.EndsWith('.git'))
    {
        $RemoteUrl = $RemoteUrl.Substring(0, $RemoteUrl.Length - 4)
    }
    else
    {
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
