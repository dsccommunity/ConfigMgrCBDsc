<#
    .SYNOPSIS
        A DSC configuration script to modify client policy settings for software inventory settings.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMClientSettingsSoftwareInventory DefaultAgent
        {
            SiteCode          = 'Lab'
            Enable            = $false
            ClientSettingName = 'Default Client Agent Settings'
        }

        CMClientSettingsSoftwareInventory DeviceAgent
        {
            SiteCode          = 'Lab'
            Enable            = $true
            RecurInterval     = 7
            Start             = '2/1/1970 00:00'
            ScheduleType      = 'Days'
            ReportOption      = 'ProductOnly'
            ClientSettingName = 'ClientTest'
        }
    }
}
