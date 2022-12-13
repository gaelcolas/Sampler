<#
    .SYNOPSIS
        Gets the Name of composite DSC resources from their *.schema.psm1 file.

    .DESCRIPTION
        This function looks within a composite DSC resource's *.schema.psm1 file
        to find the name and friendly name of the class.

    .PARAMETER Path
        Path to the DSC Resource *.schema.psm1 file.

    .EXAMPLE
        Get-Psm1SchemaName -Path Source/DSCResources/MyCompositeResource/MyCompositeResource.schema.psm1

#>

function Get-Psm1SchemaName
{
    [CmdletBinding()]
    [OutputType([string[]])]
    param
    (
        [Parameter(
                Mandatory = $true,
                ValueFromPipeline = $true
        )]
        [System.String]
        $Path
    )

    process
    {
        $rawContent = Get-Content -Path $Path -Raw
        $parseErrors = $null
        $tokens = $null

        $ast = [System.Management.Automation.Language.Parser]::ParseInput($rawContent, [ref]$tokens, [ref]$parseErrors)
        $configurations = $ast.FindAll( { $args[0] -is [System.Management.Automation.Language.ConfigurationDefinitionAst] }, $true)

        if ($configurations.Count -ne 1)
        {
            Write-Error "It is expected to find only 1 configuration in the file '$Path' but found $($configurations.Count)"
        }
        else
        {
            Write-Verbose "Found Configuration '$($configurations[0].InstanceName)'"
            $configurations[0].InstanceName.Value
        }
    }

}
