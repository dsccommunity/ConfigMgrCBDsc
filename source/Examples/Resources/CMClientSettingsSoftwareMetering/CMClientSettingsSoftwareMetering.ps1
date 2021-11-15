<#
    .SYNOPSIS
        A DSC configuration script to modify client policy settings for software metering settings.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMClientSettingsSoftwareMetering DefaultAgent
        {
            SiteCode          = 'Lab'
            Enable            = $true
            RecurInterval     = 4
            Start             = '2/1/1970 00:00'
            ClientSettingName = 'Default Client Agent Settings'
            ScheduleType      = 'Hours'
        }

        CMClientSettingsSoftwareMetering DeviceAgent
        {
            SiteCode          = 'Lab'
            Enable            = $false
            ClientSettingName = 'ClientTest'
        }
    }
}
