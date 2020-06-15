<#
    .SYNOPSIS
        A DSC configuration script to enable heartbeat discovery in Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMHeartbeatDiscovery ExampleSettings
        {
            SiteCode         = 'Lab'
            Enabled          = $true
            ScheduleInterval = 'Days'
            ScheduleCount    = '4'
        }
    }
}
