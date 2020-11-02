<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        resource DSC_CLassFolder.
#>

ConvertFrom-StringData @'
    RetrieveFolder = Retrieving folder information of '{0}'.
    FolderFound = Folder was found, evaluating all properties.
    FolderNotFound = Folder was not found.
    CreateFolder = Creating folder '{0}'.
    EvaluateProperties = Evaluating properties of folder '{0}'.
    SettingProperties = Setting properties to correct values of folder '{0}'.
    RemoveFolder = Removing folder '{0}'.
    FolderFoundShouldBeNot = Folder {0} was found, but should be absent.
    DontBeReadOnly = Folder should be {0} for ReadOnly attribute, but he is {1}.
    DontBeHidden = Folder should be {0} for Hidden attribute, but he is {1}.
'@
