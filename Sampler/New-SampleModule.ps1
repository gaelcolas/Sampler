function New-SampleModule
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        [ValidateSet('SimpleModule_NoBuild','SimpleModule','CustomModule', 'CompleteModule', 'CompleteModule_NoBuild', 'dsccommunity')]
        $ModuleType,

        [Parameter()]
        [string]
        $ModuleAuthor = $Env:USERNAME,

        [Parameter()]
        [string]
        $ModuleName,

        [Parameter()]
        [string]
        $ModuleDescription,

        [Parameter()]
        [string]
        $CustomRepo,

        [Parameter()]
        [string]
        $ModuleVersion = '0.0.1',

        [Parameter()]
        [string]
        [ValidateSet('Apache','MIT','None')]
        $LicenseType,

        [Parameter()]
        [string]
        # Validate source, src, $ModuleName
        [ValidateSet('source','src')]
        $SourceDirectory
    )



}
