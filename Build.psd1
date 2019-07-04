@{
    Path                 = "./Sampler/Sampler.psd1"
    OutputDirectory      = "./output/Sampler"

    # Load Tasks:
    # https://github.com/nightroman/Invoke-Build/blob/64f3434e1daa806814852049771f4b7d3ec4d3a3/Tasks/Import/README.md#example-2-import-from-a-module-with-tasks
    LoadTasksFromModule  = @{
        # ModuleName = 'alias to search'
        Sampler = '*.ib.tasks' # will dot source all aliases ending with .ib.tasks exported by sampler module
    }


    BuildWorkflow        = @{
        '.' = @('Clean',
            'Set_Build_Environment_Variables',
            'Build_Module_ModuleBuilder',
            'Pester_Tests_Stop_On_Fail',
            'Pester_if_Code_Coverage_Under_Threshold'
            )
        'test' = @('Build_Module_ModuleBuilder','Pester_Tests_Stop_On_Fail','Pester_if_Code_Coverage_Under_Threshold')
    }


    TaskHeader           = '
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
}
