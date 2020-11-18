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
    [Reason[]] $Reasons

    [DscProperty(NotConfigurable)]
    [bool] $Shared

    [DscProperty(NotConfigurable)]
    [String] $ShareName

    [DSC_ClassFolder] Get()
    {
        Write-Verbose -Message (
            $script:localizedData.RetrieveFolder `
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
            Write-Verbose -Message $script:localizedData.FolderFound

            $isReadOnly = Test-FileAttribute -Folder $folder -Attribute 'ReadOnly'
            $isHidden = Test-FileAttribute -Folder $folder -Attribute 'Hidden'

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

            $valuesToCheck = @(
                'Ensure'
                'ReadOnly'
                'Hidden'
            )

            $CompareState = Compare-DscParameterState `
                -CurrentValues ($currentState | ConvertTo-HashtableFromObject) `
                -DesiredValues ($this | ConvertTo-HashtableFromObject) `
                -ValuesToCheck $valuesToCheck | Where-Object {$_.InDesiredState -eq $false }

            $currentState.reasons = switch ($CompareState)
            {
                {$_.Property -eq 'Ensure'}{
                    [Reason]@{
                        Code = '{0}:{0}:Ensure' -f $this.GetType()
                        Phrase = $script:localizedData.FolderFoundShouldBeNot -f $this.Path
                    }
                    continue
                }
                {$_.Property -eq 'ReadOnly'}{
                    [Reason]@{
                        Code = '{0}:{0}:ReadOnly' -f $this.GetType()
                        Phrase = $script:localizedData.DontBeReadOnly -f $this.ReadOnly,$currentState.ReadOnly
                    }
                    continue
                }
                {$_.Property -eq 'Hidden'}{
                    [Reason]@{
                        Code = '{0}:{0}:Hidden' -f $this.GetType()
                        Phrase = $script:localizedData.DontBeHidden -f $this.Hidden,$currentState.Hidden
                    }
                    continue
                }
            }
        }
        else
        {
            $currentState.Ensure = [Ensure]::Absent
            Write-Verbose -Message $script:localizedData.FolderNotFound
            if ($this.Ensure -eq [Ensure]::Present)
            {
                $currentState.reasons = [Reason]@{
                    Code = '{0}:{0}:Ensure' -f $this.GetType()
                    Phrase = $script:localizedData.FolderNotFound
                }
            }
        }

        return $currentState
    }

    [void] Set()
    {
        $getMethodResourceResult = $this.Get()

        if ($this.Ensure -eq [Ensure]::Present)
        {
            if ($getMethodResourceResult.Ensure -eq [Ensure]::Absent)
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

            Set-FileAttribute -Folder $folder -Attribute 'ReadOnly' -Enabled $this.ReadOnly
            Set-FileAttribute -Folder $folder -Attribute 'Hidden' -Enabled $this.ReadOnly
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

    [bool] Test()
    {
        $testTargetResourceResult = $false
        $getTargetResourceResult = $this.Get()

        if ($this.Ensure -eq [Ensure]::Present)
        {
            Write-Verbose -Message $script:localizedDataClassFolder.EvaluateProperties

            $testTargetResourceResult = $getTargetResourceResult.Reasons.count -eq 0
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
}
