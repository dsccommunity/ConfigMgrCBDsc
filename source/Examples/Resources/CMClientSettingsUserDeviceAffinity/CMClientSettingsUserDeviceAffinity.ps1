<#
    .SYNOPSIS
        A DSC configuration script to modify client policy settings for user device affinity settings.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMClientSettingsUserDeviceAffinity DefaultAgent
        {
            SiteCode            = 'Lab'
            UsageThresholdDays  = 30
            AutoApproveAffinity = $true
            ClientSettingName   = 'Default Client Agent Settings'
            LogOnThresholdMins  = 2880
            AllowUserAffinity   = $true
        }

        CMClientSettingsUserDeviceAffinity DeviceAgent
        {
            SiteCode            = 'Lab'
            UsageThresholdDays  = 30
		    AutoApproveAffinity = $false
		    ClientSettingName   = 'ClientTest'
		    LogOnThresholdMins  = 2880
        }

        CMClientSettingsUserDeviceAffinity UserAgent
        {
            SiteCode          = 'Lab'
            ClientSettingName = 'UserTest'
            AllowUserAffinity = $true
        }
    }
}
