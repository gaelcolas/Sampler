
<#
    .SYNOPSIS
        Gets the Name and Friendly Name of MOF-Based resources from their Schemas.

    .DESCRIPTION
        This function looks within a DSC resource's .MOF schema to find the name and
        friendly name of the class.

    .PARAMETER Path
        Path to the DSC Resource Schema MOF.

    .EXAMPLE
        Get-MofSchemaName -Path Source/DSCResources/MyResource/MyResource.schema.mof

#>
function Get-MofSchemaName
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [System.String]
        $Path
    )

    begin
    {
        $temporaryPath = $null

        # Determine the correct $env:TEMP drive
        switch ($true)
        {
            (-not (Test-Path -Path variable:IsWindows) -or $IsWindows)
            {
                # Windows PowerShell or PowerShell 6+
                $temporaryPath = $env:TEMP
            }

            $IsMacOS
            {
                $temporaryPath = $env:TMPDIR

                throw 'NotImplemented: Currently there is an issue using the type [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache] on macOS. See issue https://github.com/PowerShell/PowerShell/issues/5970 and issue https://github.com/PowerShell/MMI/issues/33.'
            }

            $IsLinux
            {
                $temporaryPath = '/tmp'
            }

            default
            {
                throw 'Cannot set the temporary path. Unknown operating system.'
            }
        }

        $tempFilePath = Join-Path -Path $temporaryPath -ChildPath "DscMofHelper_$((New-Guid).Guid).tmp"
    }

    process
    {
        #region Workaround for OMI_BaseResource inheritance not resolving.
        $rawContent = (Get-Content -Path $Path -Raw) -replace '\s*:\s*OMI_BaseResource'
        Set-Content -LiteralPath $tempFilePath -Value $rawContent -ErrorAction 'Stop'

        # .NET methods don't like PowerShell drives
        $tempFilePath = Convert-Path -Path $tempFilePath

        #endregion

        try
        {
            $exceptionCollection = [System.Collections.ObjectModel.Collection[System.Exception]]::new()
            $moduleInfo = [System.Tuple]::Create('Module', [System.Version] '1.0.0')

            $class = [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ImportClasses(
                $tempFilePath, $moduleInfo, $exceptionCollection
            )

            if ($exceptionCollection.Count -gt 0)
            {
                throw $exceptionCollection
            }
        }
        catch
        {
            Remove-Item -LiteralPath $tempFilePath -Force
            throw "Failed to import classes from file $Path. Error $_"
        }

        <#
            For most efficiency, we re-use the same temp file.
            We need to be sure that the file is empty before the next import.
            If no, we risk to import the same class twice.
        #>
        Set-Content -LiteralPath $tempFilePath -Value ''

        return @{
            Name = $class.CimClassName
            FriendlyName = ($class.Cimclassqualifiers | Where-Object -FilterScript { $_.Name -eq 'FriendlyName' }).Value
        }
    }

    end
    {
        Remove-Item -LiteralPath $tempFilePath -Force
    }
}
