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
        $type = @('Default','Device','User')[$clientSetting.Type]
        $settings = Get-CMClientSetting -Name $ClientSettingName -Setting RemoteTools

        if ($settings)
        {
            if ($settings.FirewallExceptionProfiles -eq 0)
            {
                $toolsStatus = 'Disabled'
            }
            else
            {
                $firewallSetting = @()
                $firewallSetting += switch ($settings.FirewallExceptionProfiles)
                {
                    9  { 'Public' }
                    10 { 'Private' }
                    11 { 'Private','Public' }
                    12 { 'Domain' }
                    13 { 'Public','Domain' }
                    14 { 'Domain','Private' }
                    15 { 'Domain','Private','Public' }
                }

                $clientChange = [System.Convert]::ToBoolean($settings.AllowClientChange)
                $unattended = [System.Convert]::ToBoolean($settings.AllowRemCtrlToUnattended)
                $permRequired = [System.Convert]::ToBoolean($settings.PermissionRequired)
                $clipboard = [System.Convert]::ToBoolean($settings.ClipboardAccessPermissionRequired)
                $localAdmin = [System.Convert]::ToBoolean($settings.GrantPermissionToLocalAdministrator)
                $accessLevel = @('NoAccess','ViewOnly','FullControl')[[UInt32]$settings.AccessLevel]
                $viewers = [array]$settings.PermittedViewers
                $taskBar = [System.Convert]::ToBoolean($settings.RemCtrlTaskbarIcon)
                $sessionBar = [System.Convert]::ToBoolean($settings.RemCtrlConnectionBar)
                $audible = @('PlayNoSound','PlaySoundAtBeginAndEnd','PlaySoundRepeatedly')[[UInt32]$settings.AudibleSignal]
                $unsolRemoteAssist = [System.Convert]::ToBoolean($settings.ManageRA)
                $solRemoteAssist = [System.Convert]::ToBoolean($settings.EnforceRAandTSSettings)
                $levels = $settings.RemoteAssistanceAccessLevel
                $manageTS = [System.Convert]::ToBoolean($settings.ManageTS)
                $enableTS = [System.Convert]::ToBoolean($settings.EnableTS)
                $userAuth = [System.Convert]::ToBoolean($settings.TSUserAuthentication)
                $toolsStatus = 'Enabled'
            }
        }

        $status = 'Present'
    }
    else
    {
        $status = 'Absent'
    }

    return @{
        SiteCode                            = $SiteCode
        ClientSettingName                   = $ClientSettingName
        FirewallExceptionProfile            = $firewallSetting
        AllowClientChange                   = $clientChange
        AllowUnattendedComputer             = $unattended
        PromptUserForPermission             = $permRequired
        PromptUserForClipboardPermission    = $clipboard
        GrantPermissionToLocalAdministrator = $localAdmin
        AccessLevel                         = $accessLevel
        PermittedViewer                     = $viewers
        ShowNotificationIconOnTaskbar       = $taskBar
        ShowSessionConnectionBar            = $sessionBar
        AudibleSignal                       = $audible
        ManageUnsolicitedRemoteAssistance   = $unsolRemoteAssist
        ManageSolicitedRemoteAssistance     = $solRemoteAssist
        RemoteAssistanceAccessLevel         = $levels
        ManageRemoteDesktopSetting          = $manageTS
        AllowPermittedViewer                = $enableTS
        RequireAuthentication               = $userAuth
        ClientSettingStatus                 = $status
        ClientType                          = $type
        RemoteToolsStatus                   = $toolsStatus
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies a site code for the Configuration Manager site.

    .Parameter ClientSettingName
        Specifies which client settings policy to modify.

    .Parameter FirewallExceptionProfile
        Specifies if the firewall exceptions profiles for Remote Tools.

    .Parameter AllowClientChange
        Specifies if users can change policy or notifications settings in software center.

    .PARAMETER AllowUnattendedComputer
        Specifies if allow remote control of an unattended computer is enabled or disabled.

    .PARAMETER PromptUserForPermission
        Specifies if users are prompted for remote control permissions.

    .PARAMETER PromptUserForClipboardPermission
        Specifies if users are prompted for permission to transfer content from share clipboard.

    .PARAMETER GrantPermissionToLocalAdministrator
        Specifies if remote control permissions are granted to the local administrators group.

    .PARAMETER AccessLevel
        Specifies the access level allowed.

    .PARAMETER PermittedViewer
        Specifies the permitted viewers for remote control and remote assistance.

    .PARAMETER ShowNotificationIconOnTaskbar
        Specifies if session notifications are shown on the taskbar.

    .PARAMETER ShowSessionConnectionBar
        Specifies if the session connection bar is shown.

    .PARAMETER AudibleSignal
        Specifies if sound is played on the client.

    .PARAMETER ManageUnsolicitedRemoteAssistance
        Specifies if unsolicited remote assistance settings are managed.

    .PARAMETER ManageSolicitedRemoteAssistance
        Specifies if solicited remote assistance settings are managed.

    .PARAMETER RemoteAssistanceAccessLevel
        Specifies the level of access for remote assistance.

    .PARAMETER ManageRemoteDesktopSetting
        Specifies if remote desktop settings are managed.

    .PARAMETER AllowPermittedViewer
        Specifies if permitted viewers are allowed to connect by using remote desktop connection.

    .PARAMETER RequireAuthentication
        Specifies network level required authentication on computers that run Vista or later versions.
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
        [ValidateSet('Domain','Private','Public')]
        [String[]]
        $FirewallExceptionProfile,

        [Parameter()]
        [Boolean]
        $AllowClientChange,

        [Parameter()]
        [Boolean]
        $AllowUnattendedComputer,

        [Parameter()]
        [Boolean]
        $PromptUserForPermission,

        [Parameter()]
        [Boolean]
        $PromptUserForClipboardPermission,

        [Parameter()]
        [Boolean]
        $GrantPermissionToLocalAdministrator,

        [Parameter()]
        [ValidateSet('NoAccess','ViewOnly','FullControl')]
        [String]
        $AccessLevel,

        [Parameter()]
        [String[]]
        $PermittedViewer,

        [Parameter()]
        [Boolean]
        $ShowNotificationIconOnTaskbar,

        [Parameter()]
        [Boolean]
        $ShowSessionConnectionBar,

        [Parameter()]
        [ValidateSet('PlayNoSound','PlaySoundAtBeginAndEnd','PlaySoundRepeatedly')]
        [String]
        $AudibleSignal,

        [Parameter()]
        [Boolean]
        $ManageUnsolicitedRemoteAssistance,

        [Parameter()]
        [Boolean]
        $ManageSolicitedRemoteAssistance,

        [Parameter()]
        [ValidateSet('None','RemoteViewing','FullControl')]
        [String]
        $RemoteAssistanceAccessLevel,

        [Parameter()]
        [Boolean]
        $ManageRemoteDesktopSetting,

        [Parameter()]
        [Boolean]
        $AllowPermittedViewer,

        [Parameter()]
        [Boolean]
        $RequireAuthentication
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -ClientSettingName $ClientSettingName
    $schedResult = $true

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

        if ($state.RemoteToolsStatus -eq 'Disabled')
        {
            throw $script:localizedData.RemoteToolsDisabled
        }

        if (($PSBoundParameters.ContainsKey('AllowPermittedViewer') -or $PSBoundParameters.ContainsKey('RequireAuthentication')) -and
            ($ManageRemoteDesktopSetting -ne $true))
        {
            Write-Warning -Message $script:localizedData.ExtraSettings
            $defaultValues = @('AllowClientChange','AllowUnattendedComputer','PromptUserForPermission',
                'PromptUserForClipboardPermission','GrantPermissionToLocalAdministrator','AccessLevel',
                'ShowNotificationIconOnTaskbar','ShowSessionConnectionBar','AudibleSignal','ManageUnsolicitedRemoteAssistance',
                'ManageSolicitedRemoteAssistance','RemoteAssistanceAccessLevel','ManageRemoteDesktopSetting')
        }
        else
        {
            $defaultValues = @('AllowClientChange','AllowUnattendedComputer','PromptUserForPermission',
                'PromptUserForClipboardPermission','GrantPermissionToLocalAdministrator','AccessLevel',
                'ShowNotificationIconOnTaskbar','ShowSessionConnectionBar','AudibleSignal','ManageUnsolicitedRemoteAssistance',
                'ManageSolicitedRemoteAssistance','RemoteAssistanceAccessLevel','ManageRemoteDesktopSetting','AllowPermittedViewer',
                'RequireAuthentication')
        }

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

        if ($PSBoundParameters.ContainsKey('FirewallExceptionProfile'))
        {
            if (($state.FirewallExceptionProfile)  -and
                ($FirewallExceptionProfile.Count -eq $state.FirewallExceptionProfile.Count))
            {
                foreach ($item in $FirewallExceptionProfile)
                {
                    if (-not $($state.FirewallExceptionProfile).Contains($item))
                    {
                        $setFirewall = $true
                    }
                }
            }
            else
            {
                $setFirewall = $true
            }

            if ($setFirewall -eq $true)
            {
                Write-Verbose -Message ($script:localizedData.SetFirewall -f ($FirewallExceptionForWakeupProxy | Out-String))
                $buildingParams += @{
                    FirewallExceptionProfile = $FirewallExceptionProfile
                }
            }
        }

        if ($PSBoundParameters.ContainsKey('PermittedViewer'))
        {
            if (($state.PermittedViewer)  -and
                ($PermittedViewer.Count -eq $state.PermittedViewer.Count))
            {
                foreach ($item in $PermittedViewer)
                {
                    if (-not $($state.PermittedViewer).Contains($item))
                    {
                        $setViewer = $true
                    }
                }
            }
            else
            {
                $setViewer = $true
            }

            if ($setViewer -eq $true)
            {
                Write-Verbose -Message ($script:localizedData.SetPermittViewer -f ($PermittedViewer | Out-String))
                $buildingParams += @{
                    PermittedViewer = $PermittedViewer
                }
            }
        }

        if ($buildingParams)
        {
            if ($state.ClientType -eq 'Default')
            {
                Set-CMClientSettingRemoteTool -DefaultSetting @buildingParams
            }
            else
            {
                Set-CMClientSettingRemoteTool -Name $ClientSettingName @buildingParams
            }
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

    .Parameter FirewallExceptionProfile
        Specifies if the firewall exceptions profiles for Remote Tools.

    .Parameter AllowClientChange
        Specifies if users can change policy or notifications settings in software center.

    .PARAMETER AllowUnattendedComputer
        Specifies if allow remote control of an unattended computer is enabled or disabled.

    .PARAMETER PromptUserForPermission
        Specifies if users are prompted for remote control permissions.

    .PARAMETER PromptUserForClipboardPermission
        Specifies if users are prompted for permission to transfer content from share clipboard.

    .PARAMETER GrantPermissionToLocalAdministrator
        Specifies if remote control permissions are granted to the local administrators group.

    .PARAMETER AccessLevel
        Specifies the access level allowed.

    .PARAMETER PermittedViewer
        Specifies the permitted viewers for remote control and remote assistance.

    .PARAMETER ShowNotificationIconOnTaskbar
        Specifies if session notifications are shown on the taskbar.

    .PARAMETER ShowSessionConnectionBar
        Specifies if the session connection bar is shown.

    .PARAMETER AudibleSignal
        Specifies if sound is played on the client.

    .PARAMETER ManageUnsolicitedRemoteAssistance
        Specifies if unsolicited remote assistance settings are managed.

    .PARAMETER ManageSolicitedRemoteAssistance
        Specifies if solicited remote assistance settings are managed.

    .PARAMETER RemoteAssistanceAccessLevel
        Specifies the level of access for remote assistance.

    .PARAMETER ManageRemoteDesktopSetting
        Specifies if remote desktop settings are managed.

    .PARAMETER AllowPermittedViewer
        Specifies if permitted viewers are allowed to connect by using remote desktop connection.

    .PARAMETER RequireAuthentication
        Specifies network level required authentication on computers that run Windows Vista or later versions.
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
        [ValidateSet('Domain','Private','Public')]
        [String[]]
        $FirewallExceptionProfile,

        [Parameter()]
        [Boolean]
        $AllowClientChange,

        [Parameter()]
        [Boolean]
        $AllowUnattendedComputer,

        [Parameter()]
        [Boolean]
        $PromptUserForPermission,

        [Parameter()]
        [Boolean]
        $PromptUserForClipboardPermission,

        [Parameter()]
        [Boolean]
        $GrantPermissionToLocalAdministrator,

        [Parameter()]
        [ValidateSet('NoAccess','ViewOnly','FullControl')]
        [String]
        $AccessLevel,

        [Parameter()]
        [String[]]
        $PermittedViewer,

        [Parameter()]
        [Boolean]
        $ShowNotificationIconOnTaskbar,

        [Parameter()]
        [Boolean]
        $ShowSessionConnectionBar,

        [Parameter()]
        [ValidateSet('PlayNoSound','PlaySoundAtBeginAndEnd','PlaySoundRepeatedly')]
        [String]
        $AudibleSignal,

        [Parameter()]
        [Boolean]
        $ManageUnsolicitedRemoteAssistance,

        [Parameter()]
        [Boolean]
        $ManageSolicitedRemoteAssistance,

        [Parameter()]
        [ValidateSet('None','RemoteViewing','FullControl')]
        [String]
        $RemoteAssistanceAccessLevel,

        [Parameter()]
        [Boolean]
        $ManageRemoteDesktopSetting,

        [Parameter()]
        [Boolean]
        $AllowPermittedViewer,

        [Parameter()]
        [Boolean]
        $RequireAuthentication
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -ClientSettingName $ClientSettingName
    $result = $true
    $schedResult = $true

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
    elseif ($state.RemoteToolsStatus -eq 'Disabled')
    {
        Write-Warning -Message $script:localizedData.RemoteToolsDisabled
        $result = $false
    }
    else
    {
        if (($PSBoundParameters.ContainsKey('AllowPermittedViewer') -or $PSBoundParameters.ContainsKey('RequireAuthentication')) -and
            ($ManageRemoteDesktopSetting -ne $true))
        {
            Write-Warning -Message $script:localizedData.ExtraSettings
            $defaultValues = @('FirewallExceptionProfile','AllowClientChange','AllowUnattendedComputer','PromptUserForPermission',
                'PromptUserForClipboardPermission','GrantPermissionToLocalAdministrator','AccessLevel','PermittedViewer',
                'ShowNotificationIconOnTaskbar','ShowSessionConnectionBar','AudibleSignal','ManageUnsolicitedRemoteAssistance',
                'ManageSolicitedRemoteAssistance','RemoteAssistanceAccessLevel','ManageRemoteDesktopSetting')
        }
        else
        {
            $defaultValues = @('FirewallExceptionProfile','AllowClientChange','AllowUnattendedComputer','PromptUserForPermission',
                'PromptUserForClipboardPermission','GrantPermissionToLocalAdministrator','AccessLevel','PermittedViewer',
                'ShowNotificationIconOnTaskbar','ShowSessionConnectionBar','AudibleSignal','ManageUnsolicitedRemoteAssistance',
                'ManageSolicitedRemoteAssistance','RemoteAssistanceAccessLevel','ManageRemoteDesktopSetting','AllowPermittedViewer',
                'RequireAuthentication')
        }

        $testParams = @{
            CurrentValues = $state
            DesiredValues = $PSBoundParameters
            ValuesToCheck = $defaultValues
        }

        $result = Test-DscParameterState @testParams -TurnOffTypeChecking -Verbose -SortArrayValues
    }

    if ($result -eq $false -or $schedResult -eq $false -or $badInput -eq $true)
    {
        $return = $false
    }
    else
    {
        $return = $true
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $return)
    Set-Location -Path "$env:temp"
    return $return
}

Export-ModuleMember -Function *-TargetResource
