if ($env:BuildSystem -eq 'AppVeyor') {

    Deploy AppveyorDeployment {

        By AppVeyorModule {
            FromSource .\OutputDirectory\$Env:ProjectName\$Env:ProjectName.psd1
            To AppVeyor
            WithOptions @{
                Version = $Env:APPVEYOR_BUILD_VERSION
                PackageName = $Env:ProjectName
                Description = 'Sample Module with integrated Build process'
                Author = "Gael Colas"
                Owners = "Gael Colas"
                destinationPath = ".\output\$Env:ProjectName"
            }
            Tagged Appveyor
        }
    }
}
else {
    Write-Host "Not In AppVeyor. Skipped"
}
