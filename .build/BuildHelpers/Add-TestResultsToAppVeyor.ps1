<#
.SYNOPSIS
    Short description

.DESCRIPTION
    Long description

.EXAMPLE
    Example of how to use this cmdlet

.EXAMPLE
    Another example of how to use this cmdlet

.INPUTS
    Inputs to this cmdlet (if any)

.OUTPUTS
    Output from this cmdlet (if any)

.NOTES
    General notes
#>
function Add-TestResultsToAppveyor {
    [CmdletBinding()]
    [OutputType([void])]
    Param (
        # Appveyor Job ID
        [int]
        $APPVEYOR_JOB_ID = $Env:APPVEYOR_JOB_ID,

        [ValidateSet('mstest','xunit','nunit','nunit3','junit')]
        $ResultType = 'nunit',

        # List of files to be uploaded
        [Parameter(Mandatory,
                   Position,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName,
                   ValueFromRemainingArguments
        )]
        [Alias("FullName")]
        [string[]]
        $TestFile
    )
    
    begin {
            $wc = New-Object 'System.Net.WebClient'
    }
    
    process {
        foreach ($File in $TestFile) {
            if (Test-Path $File) {
                Write-Verbose "Uploading $File for Job ID: $APPVEYOR_JOB_ID"
                $wc.UploadFile("https://ci.appveyor.com/api/testresults/$ResultType/$($APPVEYOR_JOB_ID)", $File)
            }
        }
    }
    
    end {
        $wc.Dispose()
    }
}