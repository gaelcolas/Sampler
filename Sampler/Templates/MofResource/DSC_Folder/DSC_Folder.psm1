$script:ParentModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:ParentModulePath -ChildPath 'Modules'

$script:CommonHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'DscResource.Common'
$script:ResourceHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'Folder.Common'
Import-Module $script:CommonHelperModulePath -ErrorAction Stop
Import-Module -Name (Join-Path -Path $script:resourceHelperModulePath -ChildPath 'Folder.Common.psm1')

$script:localizedData = Get-LocalizedData -DefaultUICulture en-US

<#
    .SYNOPSIS
        Returns the current state of the folder.

    .PARAMETER Path
        The path to the folder to retrieve.

    .PARAMETER ReadOnly
       If the files in the folder should be read only.
       Not used in Get-TargetResource.

    .NOTES
        The ReadOnly parameter was made mandatory in this example to show
        how to handle unused mandatory parameters.
        In a real scenario this parameter would not need to have the type
        qualifier Required in the schema.mof.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $ReadOnly
    )

    $getTargetResourceResult = @{
        Ensure        = 'Absent'
        Path          = $Path
        ReadOnly      = $false
        Hidden        = $false
        Shared        = $false
        ShareName     = $null
    }

    Write-Verbose -Message (
        $script:localizedData.RetrieveFolder `
            -f $Path
    )

    # Using -Force to find hidden folders.
    $folder = Get-Item -Path $Path -Force -ErrorAction 'SilentlyContinue' |
        Where-Object -FilterScript {
            $_.PSIsContainer -eq $true
        }

    if ($folder)
    {
        Write-Verbose -Message $script:localizedData.FolderFound

        $isReadOnly = Test-FileAttribute -Folder $folder -Attribute 'ReadOnly'
        $isHidden = Test-FileAttribute -Folder $folder -Attribute 'Hidden'

        $folderShare = Get-SmbShare |
            Where-Object -FilterScript {
            $_.Path -eq $Path
        }

        # Cast the object to Boolean.
        $isShared = [System.Boolean] $folderShare
        if ($isShared)
        {
            $shareName = $folderShare.Name
        }

        $getTargetResourceResult['Ensure'] = 'Present'
        $getTargetResourceResult['ReadOnly'] = $isReadOnly
        $getTargetResourceResult['Hidden'] = $isHidden
        $getTargetResourceResult['Shared'] = $isShared
        $getTargetResourceResult['ShareName'] = $shareName
    }
    else
    {
        Write-Verbose -Message $script:localizedData.FolderNotFound
    }

    return $getTargetResourceResult
}

<#
    .SYNOPSIS
        Creates or removes the folder.

    .PARAMETER Path
        The path to the folder to retrieve.

    .PARAMETER ReadOnly
       If the files in the folder should be read only.
       Not used in Get-TargetResource.

    .PARAMETER Hidden
        If the folder attribut should be hidden. Default value is $false.

    .PARAMETER Ensure
        Specifies the desired state of the folder. When set to 'Present', the folder will be created. When set to 'Absent', the folder will be removed. Default value is 'Present'.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $ReadOnly,

        [Parameter()]
        [System.Boolean]
        $Hidden,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    $getTargetResourceParameters = @{
        Path     = $Path
        ReadOnly = $ReadOnly
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    if ($Ensure -eq 'Present')
    {
        if ($getTargetResourceResult.Ensure -eq 'Absent')
        {
            Write-Verbose -Message (
                $script:localizedData.CreateFolder `
                    -f $Path
            )

            $folder = New-Item -Path $Path -ItemType 'Directory' -Force
        }
        else
        {
            $folder = Get-Item -Path $Path -Force
        }

        Write-Verbose -Message (
            $script:localizedData.SettingProperties `
                -f $Path
        )

        Set-FileAttribute -Folder $folder -Attribute 'ReadOnly' -Enabled $ReadOnly
        Set-FileAttribute -Folder $folder -Attribute 'Hidden' -Enabled $Hidden
    }
    else
    {
        if ($getTargetResourceResult.Ensure -eq 'Present')
        {
            Write-Verbose -Message (
                $script:localizedData.RemoveFolder `
                    -f $Path
            )

            Remove-Item -Path $Path -Force -ErrorAction Stop
        }
    }
}

<#
    .SYNOPSIS
        Creates or removes the folder.

    .PARAMETER Path
        The path to the folder to retrieve.

    .PARAMETER ReadOnly
       If the files in the folder should be read only.
       Not used in Get-TargetResource.

    .PARAMETER Hidden
        If the folder attribut should be hidden. Default value is $false.

    .PARAMETER Ensure
        Specifies the desired state of the folder. When set to 'Present', the folder will be created. When set to 'Absent', the folder will be removed. Default value is 'Present'.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $ReadOnly,

        [Parameter()]
        [System.Boolean]
        $Hidden,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    $getTargetResourceParameters = @{
        Path     = $Path
        ReadOnly = $ReadOnly
    }

    $testTargetResourceResult = $false

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    if ($Ensure -eq 'Present')
    {
        Write-Verbose -Message $script:localizedData.EvaluateProperties

        $valuesToCheck = @(
            'Ensure'
            'ReadOnly'
            'Hidden'
        )

        $testTargetResourceResult = Test-DscParameterState `
            -CurrentValues $getTargetResourceResult `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck $valuesToCheck
    }
    else
    {
        if ($Ensure -eq $getTargetResourceResult.Ensure)
        {
            $testTargetResourceResult = $true
        }
    }

    return $testTargetResourceResult
}
