@{
    LoadingData = @(
        ('FileName', 'ExportClass', 'ScriptToProcess', 'Description')
        ('Class1'  , $true        , $true            , 'Primary class')
        ('Class11' , $true        , $false           , 'first Inherited class from class1')
        ('Class12' , $false       , $false           , 'Second Inherited class from class1')
        ('Class2'  , $false       , $true            , 'Secondary Class')
    )
}