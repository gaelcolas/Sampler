@{
    Path                 = "./Sampler/Sampler.psd1"
    OutputDirectory      = "./output/Sampler"

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
