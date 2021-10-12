<#
    .SYNOPSIS
        A DSC configuration script to modify client policy settings for state messaging settings.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMClientSettingsStateMessaging DefaultAgent
        {
            SiteCode           = 'Lab'
            ReportingCycleMins = 100
            ClientSettingName  = 'Default Client Agent Settings'
        }

        CMClientSettingsStateMessaging DeviceAgent
        {
            SiteCode           = 'Lab'
            ReportingCycleMins = 60
            ClientSettingName  = 'ClientTest'
        }
    }
}
