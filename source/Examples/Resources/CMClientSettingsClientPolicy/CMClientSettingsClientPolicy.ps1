<#
    .SYNOPSIS
        A DSC configuration script to modify client policy settings for client policy.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMClientSettingsClientPolicy DefaultAgent
        {
            SiteCode                   = 'Lab'
            EnableUserPolicyOnInternet = $false
            EnableUserPolicy           = $true
            ClientSettingName          = 'Default Client Agent Settings'
            PolicyPollingMins          = 60
            EnableUserPolicyOnTS       = $false
        }

        CMClientSettingsClientPolicy DeviceAgent
        {
            SiteCode                   = 'Lab'
            EnableUserPolicyOnInternet = $false
            EnableUserPolicy           = $true
            ClientSettingName          = 'ClientTest'
            PolicyPollingMins          = 15
            EnableUserPolicyOnTS       = $false
        }
    }
}
