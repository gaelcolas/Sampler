$script:localizedDataClassFolder = Get-LocalizedData -DefaultUICulture en-US -FileName 'DSC_ClassFolder.strings.psd1'

[DscResource()]
class DSC_ClassFolder
{
    [DscProperty(Key)]
    [string] $Path

    [DscProperty(Mandatory)]
    [bool] $ReadOnly

    [DscProperty()]
    [bool] $Hidden

    [DscProperty()]
    [Ensure] $Ensure

    [DscProperty(NotConfigurable)]
    [bool] $Shared

    [DscProperty(NotConfigurable)]
    [String] $ShareName

    [void] Set()
    {
        $getMethodResourceResult = $this.Get()

        if ($this.Ensure -eq [Ensure]::Present)
        {
            if ($getMethodResourceResult.Ensure -eq 'Absent')
            {
                Write-Verbose -Message (
                    $script:localizedDataClassFolder.CreateFolder `
                        -f $this.Path
                )

                $folder = New-Item -Path $this.Path -ItemType 'Directory' -Force
            }
            else
            {
                $folder = Get-item -Path $this.Path -Force
            }

            Write-Verbose -Message (
                $script:localizedDataClassFolder.SettingProperties `
                    -f $this.Path
            )

            $this.SetFileAttribute($folder, 'ReadOnly')
            $this.SetFileAttribute($folder, 'Hidden')
        }
        else
        {
            if ($getMethodResourceResult.Ensure -eq 'Present')
            {
                Write-Verbose -Message (
                    $script:localizedDataClassFolder.RemoveFolder `
                        -f $this.Path
                )

                Remove-Item -Path $this.Path -Force -ErrorAction Stop
            }
        }
    }

    [DSC_ClassFolder] Get()
    {
        Write-Verbose -Message (
            $script:localizedDataClassFolder.RetrieveFolder `
                -f $this.Path
        )

        $currentState = [DSC_ClassFolder]::New()
        $currentState.Path = $this.Path

        # Using -Force to find hidden folders.
        $folder = Get-Item -Path $this.Path -Force -ErrorAction 'SilentlyContinue' |
            Where-Object -FilterScript {
                $_.PSIsContainer -eq $true
            }

        if ($folder)
        {
            Write-Verbose -Message $script:localizedDataClassFolder.FolderFound
            # change to method
            $isReadOnly = $this.TestFileAttribute($folder, 'ReadOnly')
            $isHidden = $this.TestFileAttribute($folder, 'Hidden')

            $folderShare = Get-SmbShare |
                Where-Object -FilterScript {
                    $_.Path -eq $this.Path
                }

            # Cast the object to Boolean.
            $isShared = [System.Boolean] $folderShare
            if ($isShared)
            {
                $smbShareName = $folderShare.Name
            }
            else
            {
                $smbShareName = $null
            }

            $currentState.Ensure = [Ensure]::Present
            $currentState.ReadOnly = $isReadOnly
            $currentState.Hidden = $isHidden
            $currentState.Shared = $isShared
            $currentState.ShareName = $smbShareName
        }
        else
        {
            $currentState.Ensure = [Ensure]::Absent
            Write-Verbose -Message $script:localizedDataClassFolder.FolderNotFound
        }

        return $currentState
    }

    [bool] Test()
    {
        $testTargetResourceResult = $false
        $desiredValue = $this.ConvertToHashtable()
        $getTargetResourceResult = $this.Get().ConvertToHashtable()

        if ($this.Ensure -eq 'Present')
        {
            Write-Verbose -Message $script:localizedDataClassFolder.EvaluateProperties

            $valuesToCheck = @(
                'Ensure'
                'ReadOnly'
                'Hidden'
            )

            $testTargetResourceResult = Test-DscParameterState `
                -CurrentValues $getTargetResourceResult `
                -DesiredValues $desiredValue `
                -ValuesToCheck $valuesToCheck
        }
        else
        {
            if ($this.Ensure -eq $getTargetResourceResult.Ensure)
            {
                $testTargetResourceResult = $true
            }
        }

        return $testTargetResourceResult
    }

    [bool] TestFileAttribute (

        [System.IO.DirectoryInfo]
        $Folder,

        [System.IO.FileAttributes]
        $Attribute
    )
    {
        $attributeValue = $Folder.Attributes -band [System.IO.FileAttributes]$Attribute
        $isPresent = $false

        if ($attributeValue -gt 0 )
        {
            $isPresent = $true
        }

        return $isPresent
    }

    [void]SetFileAttribute (
        [System.IO.DirectoryInfo]
        $Folder,

        [System.IO.FileAttributes]
        $Attribute
    )
    {
        switch ($this.$Attribute)
        {
            $true
            {
                $Folder.Attributes = $Folder.Attributes -bor [System.IO.FileAttributes]$Attribute
            }
            $false
            {
                $Folder.Attributes = $Folder.Attributes -bxor [System.IO.FileAttributes]$Attribute
            }
        }
    }

    [hashtable] ConvertToHashtable ()
    {
        $hashResult = @{}

        $this.psobject.Properties | Foreach-Object {
            $hashResult[$_.Name] = $_.Value
        }

        return $hashResult
    }
}
