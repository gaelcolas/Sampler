##Import Classes
$ClassLoadOrder = Import-PowerShellDataFile -Path $PSScriptRoot\Classes\classes.psd1 -ErrorAction SilentlyContinue
foreach ($class in $ClassLoadOrder.LoadingData) {
    $path = '{0}\classes\{1}.ps1' -f $PSScriptRoot, $class[0]
    if (Test-Path $path) {
        . $path
    }
}

#Get public and private function definition files.
$Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

#Dot source the files
Foreach($import in @($Public + $Private))
{
    Try
    {
        . $import.fullname
    }
    Catch
    {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

Export-ModuleMember -Function $Public.Basename


######{{{{EDIT BELOW ONLY}}}}