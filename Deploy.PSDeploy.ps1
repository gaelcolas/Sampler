if ($env:BuildSystem -eq 'AppVeyor') {

    Deploy AppveyorDeployment {

        By AppVeyorModule {
            FromSource .\output\$Env:ProjectName\$Env:ProjectName.psd1
            To AppVeyor
            WithOptions @{
                PackageName = $Env:ProjectName
                destinationPath = ".\output\$Env:ProjectName"
            }
            Tagged Appveyor
        }
    }
}
else {
    Write-Host "Not In AppVeyor. Skipped"
}
