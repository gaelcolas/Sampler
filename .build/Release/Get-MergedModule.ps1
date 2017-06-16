function Get-MergedModule {
    param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [String]$Name,

        [Parameter(ValueFromPipelineByPropertyName)]
        [io.DirectoryInfo]$SourceFolder,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ScriptBlock]$Order,

        [String]$Separator = "`n`n",

        [switch]
        $DeleteSource
    )

    begin {
        $usingList = New-Object System.Collections.Generic.List[String]
        $merge = New-Object System.Text.StringBuilder
        $ListOfFileToDelete = New-Object System.Collections.Generic.List[String]
    }

    process {
        Write-Verbose "Processing $Name"
        $FilePath = [io.path]::Combine($SourceFolder,$Name)
        Get-ChildItem $FilePath -Filter *.ps1 -Recurse | Sort-Object $Order | ForEach-Object {
            $content = $_ | Get-Content | ForEach-Object {
                if ($_ -match '^using') {
                    $usingList.Add($_)
                } else {
                    $_.TrimEnd()
                }
            } | Out-String
            $null = $merge.AppendFormat('{0}{1}', $content.Trim(), $Separator)
            $ListOfFileToDelete.Add($_.FullName)
        }
    }

    end {
        $null = $merge.Insert(0, ($usingList | Sort-Object | Get-Unique | Out-String))
        if ($DeleteSource) {
            $ListOfFileToDelete | Remove-Item -Confirm:$false
        }
        $merge.ToString()
    }
}

#Courtesy of Chris Dent https://github.com/indented-automation/