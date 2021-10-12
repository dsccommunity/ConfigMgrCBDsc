<#
    .SYNOPSIS
        A DSC configuration script to modify client policy settings for powered settings.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMClientSettingsPower DefaultAgent
        {
            SiteCode                        = 'Lab'
            Enable                          = $true
            AllowUserToOptOutFromPowerPlan  = $false
            EnableWakeUpProxy               = $false
            NetworkWakeUpOption             = 'NotConfigured'
            ClientSettingName               = 'Default Client Agent Settings'
        }

        CMClientSettingsPower DeviceAgent
        {
            SiteCode                        = 'Lab'
            Enable                          = $true
            WakeupProxyDirectAccessPrefix   = '2001:0DB8:0000:000b::/64,2001:0DB8:0000:000b::/62'
            AllowUserToOptOutFromPowerPlan  = $false
            WakeupProxyPort                 = 10
            FirewallExceptionForWakeupProxy = 'Domain','Private'
            EnableWakeUpProxy               = $true
            WakeOnLanPort                   = 50
            NetworkWakeUpOption             = 'Enabled'
            ClientSettingName               = 'ClientTest'
        }
    }
}
