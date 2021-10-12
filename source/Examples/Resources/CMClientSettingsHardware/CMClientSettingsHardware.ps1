<#
    .SYNOPSIS
        A DSC configuration script to modify client policy settings for hardware settings.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMClientSettingsHardware DefaultAgent
        {
            SiteCode             = 'Lab'
            Enable               = $true
            RecurInterval        = 1
            MaxRandomDelayMins   = 240
            Start                = '2/1/1970 00:00'
            MaxThirdPartyMifSize = 250
            CollectMifFile       = 'None'
            ClientSettingName    = 'Default Client Agent Settings'
            ScheduleType         = 'Days'
        }

        CMClientSettingsHardware DeviceAgent
        {
            SiteCode           = 'Lab'
            Enable             = $true
            RecurInterval      = 1
            MaxRandomDelayMins = 240
            Start              = '2/1/1970 00:00'
            ClientSettingName  = 'ClientTest'
            ScheduleType       = 'Hours'
        }
    }
}
