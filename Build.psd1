@{
    ####################################################
    #region    ModuleBuilder Configuration             #
    ####################################################
    # Path to the Module Manifest to build (where path will be resolved from)
    Path             = "./Sampler/Sampler.psd1"
    # Output Directory where ModuleBuilder will build the Module
    OutputDirectory  = "./output/Sampler"
    # Copy those folders into the Module Base, relative to the Manifest's path
    CopyDirectories          = @(
        'DscResources',
        'HelperSubmodule',
        '..\.build\tasks',
        'en',
        'assets',
        'PlasterTemplate'
    )
    # Suffix to add to Root module PSM1 after merge (here, the Set-Alias)
    suffix = 'suffix.ps1'
        # SubModules = CopyDirectories          = @(
        #     './DscResources/*'
        # )
    VersionedOutputDirectory = $true
    #endRegion

    ####################################################
    #region Sampler Pipeline Configuration             #
    ####################################################
    # Load InvokeBuild Tasks from modules:
    # https://github.com/nightroman/Invoke-Build/blob/64f3434e1daa806814852049771f4b7d3ec4d3a3/Tasks/Import/README.md#example-2-import-from-a-module-with-tasks
    ModuleBuildTasks = @{
        # ModuleName = 'alias to search'
        Sampler = '*.ib.tasks' # this means: import (dot source) all aliases ending with .ib.tasks exported by sampler module
    }
    BuildWorkflow    = @{
        # "." is the default Invoke-Build workflow. It is called when no -Tasks is specified to the build.ps1
        '.'    = @(
            'Clean',
            'Set_Build_Environment_Variables',
            'Build_Module_ModuleBuilder',
            'Pester_Tests_Stop_On_Fail',
            'Pester_if_Code_Coverage_Under_Threshold',
            'Deploy_with_PSDeploy'
        )
        # defining test task to be run when invoking `./build.ps1 -Tasks test`
        'test' = @('Build_Module_ModuleBuilder', 'Pester_Tests_Stop_On_Fail', 'Pester_if_Code_Coverage_Under_Threshold')
    }

    # Invoke-Build Header to be used to 'decorate' the terminal output of the tasks.
    TaskHeader               = '
        param($Path)
        ""
        "=" * 79
        Write-Build Cyan "`t`t`t$($Task.Name.replace("_"," ").ToUpper())"
        Write-Build DarkGray  "$(Get-BuildSynopsis $Task)"
        "-" * 79
        Write-Build DarkGray "  $Path"
        Write-Build DarkGray "  $($Task.InvocationInfo.ScriptName):$($Task.InvocationInfo.ScriptLineNumber)"
        ""
    '
    #endRegion
}
