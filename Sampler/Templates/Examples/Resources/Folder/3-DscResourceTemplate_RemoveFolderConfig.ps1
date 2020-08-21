<#PSScriptInfo
.VERSION 1.0.0
.GUID d30fd99e-405d-4f3e-a76f-ca03710fe701
.AUTHOR Microsoft Corporation
.COMPANYNAME Microsoft Corporation
.COPYRIGHT
.TAGS DSCConfiguration
.LICENSEURI https://github.com/PowerShell/PowerShellGet/blob/master/LICENSE
.PROJECTURI https://github.com/PowerShell/PowerShellGet
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES First version.
.PRIVATEDATA 2016-Datacenter,2016-Datacenter-Server-Core
#>

#Requires -module 'DscResource.Template'

<#
    .SYNOPSIS
        Configuration that will remove a folder.

    .DESCRIPTION
        Configuration that will remove a folder.

    .PARAMETER NodeName
        The names of one or more nodes to compile a configuration for.
        Defaults to 'localhost'.

    .PARAMETER Path
        The path to the folder to remove.

    .EXAMPLE
        DscResourceTemplate_RemoveFolderConfig -Path 'C:\DscTemp1'

        Compiles a configuration that creates the folder 'C:\DscTemp1' as SYSTEM.

    .EXAMPLE
        $configurationParameters = @{
            Path = 'C:\DscTemp1'
        }
        Start-AzureRmAutomationDscCompilationJob -ResourceGroupName '<resource-group>' -AutomationAccountName '<automation-account>' -ConfigurationName 'DscResourceTemplate_RemoveFolderConfig' -Parameters $configurationParameters

        Compiles a configuration in Azure Automation that creates the folder
        'C:\DscTemp1' as SYSTEM.
        Replace the <resource-group> and <automation-account> with correct values.
#>
Configuration DscResourceTemplate_RemoveFolderConfig
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Path
    )

    Import-DscResource -ModuleName 'DscResource.Template'

    node $NodeName
    {
        Folder 'RemoveFolder'
        {
            Ensure               = 'Absent'
            Path                 = $Path
            ReadOnly             = $false
        }
    }
}
