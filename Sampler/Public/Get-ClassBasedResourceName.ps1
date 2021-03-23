
<#
    .SYNOPSIS
        Get the Names of the Class-based DSC Resources defined in a file using AST.

    .DESCRIPTION
        This command returns all Class-based Resource Names in a file,
        by parsing the file and looking for classes with the [DscResource()] attribute.

        For MOF-based DSC Resources, look at the `Get-MofSchemaName` function.

    .PARAMETER Path
        Path of the file to parse and search the Class-Based DSC Resources.

    .EXAMPLE
        Get-ClassBasedResourceName -Path source/Classes/MyDscResource.ps1

        Get-ClassBasedResourceName -Path (Join-Path -Path (Get-Module MyResourceModule).ModuleBase -ChildPath (Get-Module MyResourceModule).RootModule)

#>
function Get-ClassBasedResourceName
{
   [CmdletBinding()]
   [OutputType([String[]])]
   param
   (
       [Parameter(Mandatory = $true)]
       [Alias('FilePath')]
       [System.String]
       $Path
   )

   $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)

   $classDefinition = $ast.FindAll(
       {
           ($args[0].GetType().Name -like "TypeDefinitionAst") -and `
           ($args[0].Attributes.TypeName.Name -contains 'DscResource')
       },
       $true
   )

   return $classDefinition.Name

}
