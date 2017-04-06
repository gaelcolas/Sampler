function Get-Something {
    <#
      .SYNOPSIS
      Sample Function to return input string.

      .DESCRIPTION
      This function is only a sample Advanced function that returns the Data given via parameter Data.

      .EXAMPLE
      Get-Something -Data 'Get me this text'


      .PARAMETER Data
      The Data parameter is the data that will be returned without transformation.

      #>
    [cmdletBinding(
            SupportsShouldProcess=$true,
            ConfirmImpact='Low'
            )]
    Param(
        [Parameter(
            Mandatory
            ,ValueFromPipeline
            ,ValueFromPipelineByPropertyName
            )]
        [String]
        $Data
    )

    Process {
        if ($pscmdlet.ShouldProcess($Data)) {
            Write-Verbose ('Returning the data: {0}' -f $Data)
            Get-PrivateFunction -PrivateData $Data
        }
    }

}