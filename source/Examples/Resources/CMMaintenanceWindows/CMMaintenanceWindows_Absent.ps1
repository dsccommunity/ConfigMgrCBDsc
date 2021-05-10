<#
    .SYNOPSIS
        A DSC configuration script to remove a maintenance window from collections.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMMaintenanceWindows ExampleSettings
        {
            SiteCode       = 'Lab'
            CollectionName = 'Test'
            Name           = 'MW1'
            Ensure         = 'Absent'
        }
    }
}
