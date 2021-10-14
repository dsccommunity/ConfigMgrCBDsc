<#
    .SYNOPSIS
        A DSC configuration script to modify client policy settings for remote tools settings.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMClientSettingsRemoteTools DefaultClient
        {
            SiteCode                            = 'Lab'
            GrantPermissionToLocalAdministrator = $false
            ManageRemoteDesktopSetting          = $true
            AllowUnattendedComputer             = $true
            RequireAuthentication               = $true
            AllowClientChange                   = $true
            PermittedViewer                     = 'Contoso\Remote Control Users'
            ClientSettingName                   = 'Default Client Agent Settings'
            FirewallExceptionProfile            = 'Domain'
            RemoteAssistanceAccessLevel         = 'None'
            PromptUserForClipboardPermission    = $true
            AccessLevel                         = 'FullControl'
            AudibleSignal                       = 'PlaySoundAtBeginAndEnd'
            PromptUserForPermission             = $false
            ShowSessionConnectionBar            = $true
            ManageSolicitedRemoteAssistance     = $true
            ManageUnsolicitedRemoteAssistance   = $true
            AllowPermittedViewer                = $true
            ShowNotificationIconOnTaskbar       = $true
        }

        CMClientSettingsRemoteTools DeviceClient
        {
            SiteCode                            = 'Lab'
            GrantPermissionToLocalAdministrator = $false
            ManageRemoteDesktopSetting          = $false
            AllowUnattendedComputer             = $false
            RequireAuthentication               = $true
            AllowClientChange                   = $false
            PermittedViewer                     = 'contoso\Remote Control Users'
            ClientSettingName                   = 'TestClient'
            RemoteAssistanceAccessLevel         = 'None'
            PromptUserForClipboardPermission    = $false
            AccessLevel                         = 'NoAccess'
            AudibleSignal                       = 'PlayNoSound'
            PromptUserForPermission             = $false
            ShowSessionConnectionBar            = $false
            ManageSolicitedRemoteAssistance     = $false
            ManageUnsolicitedRemoteAssistance   = $false
            AllowPermittedViewer                = $true
            ShowNotificationIconOnTaskbar       = $false
        }
    }
}
