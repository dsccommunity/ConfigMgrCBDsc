<#
    .SYNOPSIS
        A DSC configuration script to remove a boundary from Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMBoundaries ExampleSettings
        {
            SiteCode    = 'Lab'
            DisplayName = 'Subnet 1'
            Type        = 'IPSubnet'
            Value       = '10.1.1.1/24'
            Ensure      = 'Absent'
        }
    }
}
