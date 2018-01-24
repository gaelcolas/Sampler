Param (
    [string]
    $ProjectName = (property ProjectName (Split-Path -Leaf $BuildRoot) ),

    [string]
    $SourceFolder = $ProjectName,

    [string]
    $BuildOutput = (property BuildOutput 'C:\BuildOutput'),
    
    [string]
    $ModuleVersion = (property ModuleVersion $(
        if($ModuleVersion = Get-NextPSGalleryVersion -Name $ProjectName -ea 0) { $ModuleVersion } else { '0.0.1' }
        )),

    $MergeList = (property MergeList @('enum*','class*','priv*','pub*') ),
    
    [string]
    $LineSeparation = (property LineSeparation ('-' * 78))

)

# Synopsis: Copy the Module Source files to the BuildOutput
Task Copy_Source_To_Module_BuildOutput {
    if (![io.path]::IsPathRooted($BuildOutput)) {
        $BuildOutput = Join-Path -Path $BuildRoot -ChildPath $BuildOutput
    }
    $BuiltModuleFolder = [io.Path]::Combine($BuildOutput,$ProjectName)
    "Copying $BuildRoot\$SourceFolder To $BuiltModuleFolder\"
    Copy-Item -Path "$BuildRoot\$SourceFolder" -Destination "$BuiltModuleFolder\" -Recurse -Force -Exclude '*.bak'
}

# Synopsis: Merging the PS1 files into the PSM1.
Task Merge_Source_Files_To_PSM1 {
    if(!$MergeList) {$MergeList = @('enum*','class*','priv*','pub*') }
    "`tORDER: [$($MergeList -join ', ')]`r`n"

    if (![io.path]::IsPathRooted($BuildOutput)) {
        $BuildOutput = Join-Path -Path $BuildRoot -ChildPath $BuildOutput
    }

    $BuiltModuleFolder = [io.Path]::Combine($BuildOutput,$ProjectName)
    # Merge individual PS1 files into a single PSM1, and delete merged files
    $OutModulePSM1 = [io.path]::Combine($BuiltModuleFolder,"$ProjectName.psm1")
    Write-Build Green "  Merging to $OutModulePSM1"
    $MergeList | Get-MergedModule -DeleteSource -SourceFolder $BuiltModuleFolder | Out-File $OutModulePSM1 -Force
}

# Synopsis: Removing Empty folders from the Module Build output
Task Clean_Empty_Folders_from_Build_Output {

    if (![io.path]::IsPathRooted($BuildOutput)) {
        $BuildOutput = Join-Path -Path $BuildRoot -ChildPath $BuildOutput
    }

    Get-ChildItem $BuildOutput -Recurse -Force | Sort-Object -Property FullName -Descending | Where-Object {
        $_.PSIsContainer -and
        $_.GetFiles().count -eq 0 -and
        $_.GetDirectories().Count -eq 0 
    } | Remove-Item
}

# Synopsis: Update the Module Manifest with the $ModuleVersion and setting the module functions
Task Update_Module_Manifest {
    if (![io.path]::IsPathRooted($BuildOutput)) {
        $BuildOutput = Join-Path -Path $BuildRoot -ChildPath $BuildOutput
    }
    
    $BuiltModule = [io.path]::Combine($BuildOutput,$ProjectName,"$ProjectName.psd1")
    Write-Build Green "  Updating Module functions in Module Manifest..."
    Set-ModuleFunctions -Path $BuiltModule
    if($ModuleVersion) {
        Write-Build Green "  Updating Module version in Manifest to $ModuleVersion"
        Update-Metadata -path $BuiltModule -PropertyName ModuleVersion -Value $ModuleVersion
    }
    ''
}