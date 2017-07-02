if ($env:BuildSystem -eq 'AppVeyor') {

    Deploy AppveyorDeployment {

        By AppVeyorModule {
            FromSource .\BuildOutput\$Env:ProjectName
            To AppVeyor
            WithOptions @{
                Version = $Env:APPVEYOR_BUILD_VERSION
                Description = 'Sample Module with integrated Build process'
                Author = "Gael Colas"
                Owners = "Gael Colas"
                destinationPath = ".\BuildOutput\$Env:ProjectName"
            }
            Tagged Appveyor
        }
    }
}
else {
    Write-Host "Not In AppVeyor. Skipped"
}
