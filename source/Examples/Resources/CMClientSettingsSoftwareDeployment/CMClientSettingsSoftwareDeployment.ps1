<#
    .SYNOPSIS
        A DSC configuration script to modify client policy settings for software deployment settings.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMClientSettingsSoftwareDeployment DefaultAgent
        {
            SiteCode          = 'Lab'
            RecurInterval     = 7
            Start             = '2/1/1970 00:00'
            ScheduleType      = 'Days'
            ClientSettingName = 'Default Client Agent Settings'
        }

        CMClientSettingsSoftwareDeployment DeviceAgent
        {
            SiteCode          = 'Lab'
            RecurInterval     = 1
            Start             = '2/1/1970 00:00'
            ScheduleType      = 'Hours'
            ClientSettingName = 'ClientTest'
        }
    }
}
