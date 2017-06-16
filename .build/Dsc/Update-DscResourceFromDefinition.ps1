function Update-DscResourceFromObjectMetadata {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [io.DirectoryInfo]$SourceFolder,

        [PSCustomObject]
        $DscResourceMetadata = (Get-Content -Raw "$((Resolve-Path $SourceFolder).Path)\DscResources\DSCResourcesDefinitions.json"| ConvertFrom-Json)
    )

    if (![io.path]::IsPathRooted($SourceFolder)) {
        $SourceFolder =  (Resolve-Path $SourceFolder).Path
    }
    foreach ($Resource in $DscResourceMetadata)
    {
        $DscProperties = @()
        $ResourceName = $Resource.psobject.Properties.Name
        Write-Verbose "Preparing $ResourceName"
        foreach ($DscProperty in $Resource.($ResourceName)) {
            $resourceParams = @{}
            $DscProperty.psobject.properties | % { $resourceParams[$_.Name] = $_.value }
            $DscProperties += New-xDscResourceProperty @resourceParams
        }
        
        if (Test-Path "$SourceFolder\DscResources\$ResourceName") {
            $DscResourceParams = @{
                Property     = $DscProperties 
                Path         = "$SourceFolder\DscResources\$ResourceName"
                FriendlyName = $ResourceName 
            }
            Update-xDscResource @DscResourceParams -Force
        }
        else {
            $DscResourceParams = @{
                Name         = $ResourceName 
                Property     = $DscProperties 
                Path         = "$SourceFolder\"
                FriendlyName = $ResourceName 
            }
            New-xDscResource @DscResourceParams
        }
    }
}