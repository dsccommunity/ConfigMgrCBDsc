<#
    .SYNOPSIS
        A DSC configuration script to disable heartbeat discovery in Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMHeartbeatDiscovery ExampleSettings
        {
            SiteCode = 'Lab'
            Enabled  = $false
        }
    }
}
