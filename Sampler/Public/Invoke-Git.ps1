<#
    .SYNOPSIS
        Executes git with the provided arguments.

    .DESCRIPTION
        This command executes git with the provided arguments and throws an error
        if the call failed.

    .PARAMETER Argument
        Specifies the arguments to call git with. It is passes as an array of strings,
        e.g. @('tag', 'v2.0.0').

    .EXAMPLE
        Invoke-Git -Argument @('config', 'user.name', 'MyName')

        Calls git to set user name in the git config.

    .NOTES
        Git does not throw an error that can be caught by the pipeline. For example
        this git command error but does not throw 'hello' as one would expect.
        ```
        PS> try { git describe --contains } catch { throw 'hello' }
        fatal: cannot describe '144e0422398e89cc8451ebba738c0a410b628302'
        ```
        So we have to determine if git worked or not by checking the last exit code
        and then throw an error to stop the pipeline.
#>
function Invoke-Git
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Argument
    )

    # The catch is triggered only if 'git' can't be found.
    try
    {
        & git $Argument
    }
    catch
    {
        throw $_
    }

    <#
        This will trigger an error if git returned an error code from the above
        execution. Git will also have outputted an error message to the console
        so we just need to throw a generic error.
    #>
    if ($LASTEXITCODE)
    {
        throw "git returned exit code $LASTEXITCODE indicated failure."
    }
}
