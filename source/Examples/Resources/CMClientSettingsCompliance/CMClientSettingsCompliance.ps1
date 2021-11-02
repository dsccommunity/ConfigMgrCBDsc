<#
    .SYNOPSIS
        A DSC configuration script to modify client policy settings for compliance.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMClientSettingsCompliance DefaultAgent
        {
            SiteCode                 = 'Lab'
            Enable                   = $true
            ScheduleType             = 'None'
            Start                    = '9/22/2021 21:48'
            ClientSettingName        = 'Default Client Agent Settings'
            EnableUserDataAndProfile = $true
        }

        CMClientSettingsCompliance DeviceAgent
        {
            SiteCode                 = 'Lab'
            Enable                   = $true
            ClientSettingName        = 'ClientTest'
            EnableUserDataAndProfile = $false
        }
    }
}
