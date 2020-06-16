<#
    .SYNOPSIS
        A DSC configuration script to modify client status settings.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMClientStatusSettings ExampleSettings
        {
            SiteCode               = 'Lab'
            IsSingleInstance       = 'Yes'
            ClientPolicyDays       = 7
            HeartbeatDiscoveryDays = 7
            SoftwareInventoryDays  = 7
            HardwareInventoryDays  = 7
            StatusMessageDays      = 7
            HistoryCleanupDays     = 31
        }
    }
}
