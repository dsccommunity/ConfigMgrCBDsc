$script:dscResourceCommonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'
$script:configMgrResourcehelper = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\ConfigMgrCBDsc.ResourceHelper'

Import-Module -Name $script:dscResourceCommonPath
Import-Module -Name $script:configMgrResourcehelper

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        This will return a hashtable of results.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .Parameter ClientSettingName
        Specifies which client settings policy to modify.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SiteCode,

        [Parameter(Mandatory = $true)]
        [String]
        $ClientSettingName
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $clientSetting = Get-CMClientSetting -Name $ClientSettingName

    if ($clientSetting)
    {
        $type = @('Default', 'Device', 'User')[$clientSetting.Type]
        $settings = Get-CMClientSetting -Name $ClientSettingName -Setting ComputerRestart

        if ($settings)
        {
            $countdownMins = $settings.RebootLogoffNotificationCountdownDuration
            $finalWindowMins = $settings.RebootLogoffNotificationFinalWindow
            $replaceToast = [System.Convert]::ToBoolean($settings.RebootNotificationsDialog)
            $noRebootEnforcement = -not [System.Convert]::ToBoolean($settings.EnforeReboot)
        }

        $status = 'Present'
    }
    else
    {
        $status = 'Absent'
    }

    return @{
        SiteCode                           = $SiteCode
        ClientSettingName                  = $ClientSettingName
        CountdownMins                      = $countdownMins
        FinalWindowMins                    = $finalWindowMins
        ReplaceToastNotificationWithDialog = $replaceToast
        NoRebootEnforcement                = $noRebootEnforcement
        ClientSettingStatus                = $status
        ClientType                         = $type
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies a site code for the Configuration Manager site.

    .Parameter ClientSettingName
        Specifies which client settings policy to modify.

    .PARAMETER CountdownMins
        Specifies countdown, in minutes, for restart to take place.

    .PARAMETER FinalWindowMins
        Specifies the time window a restart has to take place in.

    .PARAMETER ReplaceToastNotificationWithDialog
        Specifies if toast notifications are replaced with dialog windows.

    .PARAMETER NoRebootEnforcement
        Specifies if reboots are not enforced.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SiteCode,

        [Parameter(Mandatory = $true)]
        [String]
        $ClientSettingName,

        [Parameter()]
        [ValidateRange(1, 1440)]
        [uint32]
        $CountdownMins,

        [Parameter()]
        [ValidateRange(1, 1440)]
        [uint32]
        $FinalWindowMins,

        [Parameter()]
        [bool]
        $ReplaceToastNotificationWithDialog,

        [Parameter()]
        [bool]
        $NoRebootEnforcement
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -ClientSettingName $ClientSettingName

    try
    {
        if ($state.ClientSettingStatus -eq 'Absent')
        {
            throw ($script:localizedData.ClientPolicySetting -f $ClientSettingName)
        }

        if ($state.ClientType -eq 'User')
        {
            throw $script:localizedData.WrongClientType
        }

        if ($CountdownMins -le $FinalWindowMins)
        {
            throw ($script:localizedData.CountdownLessFinalWindow -f $CountdownMins, $FinalWindowMins)
        }

        $defaultValues = @('CountdownMins', 'FinalWindowMins', 'ReplaceToastNotificationWithDialog', 'NoRebootEnforcement')

        foreach ($param in $PSBoundParameters.GetEnumerator())
        {
            if ($defaultValues -contains $param.Key)
            {
                if ($param.Value -ne $state[$param.Key])
                {
                    Write-Verbose -Message ($script:localizedData.SettingValue -f $param.Key, $param.Value)
                    $buildingParams += @{
                        $param.Key = $param.Value
                    }
                }
            }
        }

        if ($buildingParams)
        {
            Set-CMClientSettingComputerRestart -Name $ClientSettingName @buildingParams
        }
    }
    catch
    {
        throw $_
    }
    finally
    {
        Set-Location -Path "$env:temp"
    }
}

<#
    .SYNOPSIS
        This will test the desired state.

    .PARAMETER SiteCode
        Specifies a site code for the Configuration Manager site.

    .Parameter ClientSettingName
        Specifies which client settings policy to modify.

    .PARAMETER CountdownMins
        Specifies countdown, in minutes, for restart to take place.

    .PARAMETER FinalWindowMins
        Specifies the time window a restart has to take place in.

    .PARAMETER ReplaceToastNotificationWithDialog
        Specifies if toast notifications are replaced with dialog windows.

    .PARAMETER NoRebootEnforcement
        Specifies if reboots are not enforced.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SiteCode,

        [Parameter(Mandatory = $true)]
        [String]
        $ClientSettingName,

        [Parameter()]
        [ValidateRange(1, 1440)]
        [uint32]
        $CountdownMins,

        [Parameter()]
        [ValidateRange(1, 1440)]
        [uint32]
        $FinalWindowMins,

        [Parameter()]
        [bool]
        $ReplaceToastNotificationWithDialog,

        [Parameter()]
        [bool]
        $NoRebootEnforcement
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -ClientSettingName $ClientSettingName
    $result = $true

    if ($state.ClientSettingStatus -eq 'Absent')
    {
        Write-Warning -Message ($script:localizedData.ClientPolicySetting -f $ClientSettingName)
        $result = $false
    }
    elseif ($state.ClientType -eq 'User')
    {
        Write-Warning -Message $script:localizedData.WrongClientType
        $result = $false
    }
    else
    {
        $defaultValues = @('CountdownMins', 'FinalWindowMins', 'ReplaceToastNotificationWithDialog', 'NoRebootEnforcement')

        $testParams = @{
            CurrentValues = $state
            DesiredValues = $PSBoundParameters
            ValuesToCheck = $defaultValues
        }

        $result = Test-DscParameterState @testParams -TurnOffTypeChecking -Verbose
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path "$env:temp"
    return $result
}

Export-ModuleMember -Function *-TargetResource
