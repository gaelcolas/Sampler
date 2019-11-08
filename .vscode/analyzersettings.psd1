@{
    <#
        For the custom rules to work, the DscResource.Tests repo must be
        cloned. It is automatically clone as soon as any unit or
        integration tests are run.
    #>
    CustomRulePath = '.\output\RequiredModules\DscResource.AnalyzerRules'

    IncludeRules   = @(
        # DSC Resource Kit style guideline rules.
        'PSAvoidDefaultValueForMandatoryParameter',
        'PSAvoidDefaultValueSwitchParameter',
        'PSAvoidInvokingEmptyMembers',
        'PSAvoidNullOrEmptyHelpMessageAttribute',
        'PSAvoidUsingCmdletAliases',
        'PSAvoidUsingComputerNameHardcoded',
        'PSAvoidUsingDeprecatedManifestFields',
        'PSAvoidUsingEmptyCatchBlock',
        'PSAvoidUsingInvokeExpression',
        'PSAvoidUsingPositionalParameters',
        'PSAvoidShouldContinueWithoutForce',
        'PSAvoidUsingWMICmdlet',
        'PSAvoidUsingWriteHost',
        'PSDSCReturnCorrectTypesForDSCFunctions',
        'PSDSCStandardDSCFunctionsInResource',
        'PSDSCUseIdenticalMandatoryParametersForDSC',
        'PSDSCUseIdenticalParametersForDSC',
        'PSMisleadingBacktick',
        'PSMissingModuleManifestField',
        'PSPossibleIncorrectComparisonWithNull',
        'PSProvideCommentHelp',
        'PSReservedCmdletChar',
        'PSReservedParams',
        'PSUseApprovedVerbs',
        'PSUseCmdletCorrectly',
        'PSUseOutputTypeCorrectly',
        'PSAvoidGlobalVars',
        'PSAvoidUsingConvertToSecureStringWithPlainText',
        'PSAvoidUsingPlainTextForPassword',
        'PSAvoidUsingUsernameAndPasswordParams',
        'PSDSCUseVerboseMessageInDSCResource',
        'PSShouldProcess',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSUsePSCredentialType',

        <#
            This is to test all the DSC Resource Kit custom rules.
            The name of the function-blocks of each custom rule start
            with 'Measure*'.
        #>
        'Measure-*'
    )

    IncludeDefaultRules = $true

    ExcludeRules    = @(
        # Excluding rules as this project uses
        # brackets on same line
        'Measure-IfStatement',
        'Measure-ForEachStatement',
        'Measure-TryStatement',
        'Measure-CatchClause',
        'Measure-FunctionBlockBrace*', # new name from DscResource.AnalyzerRules
        'Measure-DoUntilStatement',
        'Measure-DoWhileStatement',
        'Measure-WhileStatement',
        'Measure-SwitchStatement',
        'Measure-ForStatement',
        'Measure-ParameterBlockMandatoryNamedArgument' # Param(Mandatory) or =$true?
    )
}
