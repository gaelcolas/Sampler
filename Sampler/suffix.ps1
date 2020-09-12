# Inspired from https://github.com/nightroman/Invoke-Build/blob/64f3434e1daa806814852049771f4b7d3ec4d3a3/Tasks/Import/README.md#example-2-import-from-a-module-with-tasks
Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'tasks\*') -Include '*.build.*' |
    ForEach-Object -Process {
        $ModuleName = ([System.IO.FileInfo] $MyInvocation.MyCommand.Name).BaseName
        $taskFileAliasName = "$($_.BaseName).$ModuleName.ib.tasks"

        Set-Alias -Name $taskFileAliasName -Value $_.FullName

        Export-ModuleMember -Alias $taskFileAliasName
    }
